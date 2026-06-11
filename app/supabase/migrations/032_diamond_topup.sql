-- ============================================================================
-- 032 · 사용자 다이아 충전 — 토스 결제 → diamond_ledger 적립
-- ============================================================================
-- 사용자가 토스페이먼츠로 다이아 패키지를 구매하면 계정에 다이아 적립.
--
-- 플로우:
--   1. 앱: create_diamond_order(package_id) → diamond_topups pending row + order_id
--   2. 외부 브라우저: 토스 결제창 (pay.html) → 성공 redirect
--   3. pay-success.html → Edge Function toss-diamond-confirm
--      (토스 승인 API 검증 → confirm_diamond_topup RPC)
--   4. 다이아 적립 (profiles.diamond_balance + diamond_ledger)
--
-- 보안/정책 가드:
--   - confirm은 service_role 전용 (Edge Function만). 멱등: toss_payment_key UNIQUE.
--   - 금액 검증 2중: EF에서 토스 totalAmount == 주문 price_krw 확인.
--   - 환불·환금 불가 (약관 명시 필요 — OWNER_TODO P0 §2).
--   - iOS는 앱 내 노출 기본 비활성 (IAP 정책 — Flutter 쪽 플래그).
-- ============================================================================

-- 1. 다이아 패키지 카탈로그
CREATE TABLE IF NOT EXISTS public.diamond_packages (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name            text NOT NULL,
  diamond_amount  integer NOT NULL CHECK (diamond_amount > 0),
  price_krw       integer NOT NULL CHECK (price_krw >= 1000),
  bonus_label     text,                      -- '+10% 보너스' 등 표시용
  display_order   integer NOT NULL DEFAULT 100,
  active          boolean NOT NULL DEFAULT true,
  created_at      timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.diamond_packages ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "diamond_packages_read" ON public.diamond_packages;
CREATE POLICY "diamond_packages_read" ON public.diamond_packages
  FOR SELECT TO authenticated USING (active = true);
DROP POLICY IF EXISTS "diamond_packages_admin_all" ON public.diamond_packages;
CREATE POLICY "diamond_packages_admin_all" ON public.diamond_packages
  FOR ALL TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

-- 시드: 1다이아 ≈ 10원 기준 + 볼륨 보너스
INSERT INTO public.diamond_packages (name, diamond_amount, price_krw, bonus_label, display_order)
SELECT * FROM (VALUES
  ('다이아 100',   100,  1000,  NULL,          10),
  ('다이아 550',   550,  5000,  '+10% 보너스', 20),
  ('다이아 1150',  1150, 10000, '+15% 보너스', 30),
  ('다이아 3600',  3600, 30000, '+20% 보너스', 40)
) AS v(name, diamond_amount, price_krw, bonus_label, display_order)
WHERE NOT EXISTS (SELECT 1 FROM public.diamond_packages);

-- 2. 다이아 충전 주문 (wallet_topups 패턴 미러)
CREATE TABLE IF NOT EXISTS public.diamond_topups (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  package_id        uuid REFERENCES public.diamond_packages(id) ON DELETE SET NULL,
  diamond_amount    integer NOT NULL CHECK (diamond_amount > 0),
  price_krw         integer NOT NULL CHECK (price_krw > 0),
  order_id          text NOT NULL UNIQUE,        -- 'dia_' + uuid (토스 orderId)
  toss_payment_key  text UNIQUE,
  status            text NOT NULL DEFAULT 'pending',
  approved_at       timestamptz,
  raw_response      jsonb,
  created_at        timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT diamond_topups_status_check
    CHECK (status IN ('pending','approved','failed','cancelled'))
);

CREATE INDEX IF NOT EXISTS diamond_topups_user_idx
  ON public.diamond_topups (user_id, created_at DESC);

ALTER TABLE public.diamond_topups ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "diamond_topups_owner_select" ON public.diamond_topups;
CREATE POLICY "diamond_topups_owner_select" ON public.diamond_topups
  FOR SELECT TO authenticated USING (user_id = auth.uid());
DROP POLICY IF EXISTS "diamond_topups_admin_all" ON public.diamond_topups;
CREATE POLICY "diamond_topups_admin_all" ON public.diamond_topups
  FOR ALL TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

-- ============================================================================
-- create_diamond_order: 앱이 결제 시작 전 pending 주문 생성
-- ============================================================================
CREATE OR REPLACE FUNCTION public.create_diamond_order(package_id_in uuid)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  uid       uuid := auth.uid();
  pkg       diamond_packages%ROWTYPE;
  oid       text;
  topup_id  uuid;
BEGIN
  IF uid IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'auth_required');
  END IF;

  SELECT * INTO pkg FROM diamond_packages
   WHERE id = package_id_in AND active = true;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'package_not_found');
  END IF;

  -- 미결 pending 주문 정리 (10분 초과한 pending은 cancelled)
  UPDATE diamond_topups SET status = 'cancelled'
   WHERE user_id = uid AND status = 'pending'
     AND created_at + INTERVAL '10 minutes' < now();

  oid := 'dia_' || replace(gen_random_uuid()::text, '-', '');

  INSERT INTO diamond_topups
    (user_id, package_id, diamond_amount, price_krw, order_id, status)
  VALUES
    (uid, pkg.id, pkg.diamond_amount, pkg.price_krw, oid, 'pending')
  RETURNING id INTO topup_id;

  RETURN jsonb_build_object(
    'ok', true,
    'topup_id', topup_id,
    'order_id', oid,
    'amount', pkg.price_krw,
    'diamond_amount', pkg.diamond_amount,
    'order_name', pkg.name
  );
END;
$$;

REVOKE EXECUTE ON FUNCTION public.create_diamond_order(uuid) FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION public.create_diamond_order(uuid) TO authenticated;

-- ============================================================================
-- confirm_diamond_topup: Edge Function 전용 — 검증된 결제를 적립으로 확정
-- ============================================================================
CREATE OR REPLACE FUNCTION public.confirm_diamond_topup(
  order_id_in     text,
  payment_key_in  text,
  raw_in          jsonb DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  t           diamond_topups%ROWTYPE;
  new_balance integer;
BEGIN
  -- 멱등성: 같은 payment_key로 이미 승인된 주문이면 기존 결과 반환
  SELECT * INTO t FROM diamond_topups
   WHERE toss_payment_key = payment_key_in AND status = 'approved';
  IF FOUND THEN
    RETURN jsonb_build_object(
      'ok', true, 'idempotent', true,
      'topup_id', t.id, 'diamond_amount', t.diamond_amount
    );
  END IF;

  SELECT * INTO t FROM diamond_topups
   WHERE order_id = order_id_in FOR UPDATE;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'order_not_found');
  END IF;
  IF t.status <> 'pending' THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'invalid_status', 'status', t.status);
  END IF;

  UPDATE diamond_topups
     SET status = 'approved',
         toss_payment_key = payment_key_in,
         approved_at = now(),
         raw_response = COALESCE(raw_in, raw_response)
   WHERE id = t.id;

  UPDATE profiles SET diamond_balance = diamond_balance + t.diamond_amount
   WHERE id = t.user_id
   RETURNING diamond_balance INTO new_balance;

  INSERT INTO diamond_ledger (user_id, delta, source, source_id, balance_after)
  VALUES (t.user_id, t.diamond_amount, 'toss_topup', payment_key_in, new_balance);

  RETURN jsonb_build_object(
    'ok', true,
    'topup_id', t.id,
    'diamond_amount', t.diamond_amount,
    'balance', new_balance
  );
END;
$$;

-- service_role 전용 (Edge Function에서만 호출)
REVOKE ALL ON FUNCTION public.confirm_diamond_topup(text, text, jsonb)
  FROM PUBLIC, anon, authenticated;
