-- ============================================================================
-- 022 · 기프티콘 카탈로그 + 다이아 교환 (트랙 E, Step 15)
-- ============================================================================
-- 다이아 사용처 활성화. 사용자가 다이아로 외부 기프티콘 교환.
--
-- 발급 흐름 (MVP — 수동 발급):
--   1. 사용자가 redeem_gifticon RPC 호출 → 다이아 차감 + 재고 차감
--   2. redemptions row 생성 (status='pending', coupon_code=NULL)
--   3. 운영자(admin)가 외부 기프티콘 API 또는 수동으로 발급 → coupon_code 채우고 status='issued'
--   4. 사용자가 redemptions 리스트에서 coupon_code 확인
--
-- 환금성 회피: RunClue가 사업자로서 기프티콘 매입 후 통신판매 형태로 발급 →
--               선불업 등록 의무 미해당 (통신판매업 신고로 충분).
-- ============================================================================

-- 1. gifticons — 카탈로그 (admin이 관리)
CREATE TABLE IF NOT EXISTS public.gifticons (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  partner_brand text NOT NULL,
  name          text NOT NULL,
  description   text,
  value_krw     integer NOT NULL,        -- 표시용 원 가치
  diamond_cost  integer NOT NULL,        -- 소비 다이아
  image_url     text,
  stock         integer NOT NULL DEFAULT 0,
  active        boolean NOT NULL DEFAULT true,
  display_order integer NOT NULL DEFAULT 100,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT gifticons_cost_check  CHECK (diamond_cost > 0),
  CONSTRAINT gifticons_stock_check CHECK (stock >= 0),
  CONSTRAINT gifticons_value_check CHECK (value_krw > 0)
);

CREATE INDEX IF NOT EXISTS gifticons_active_idx
  ON public.gifticons (active, display_order)
  WHERE active = true;

ALTER TABLE public.gifticons ENABLE ROW LEVEL SECURITY;

-- 모든 로그인 사용자가 활성 카탈로그 조회 가능
DROP POLICY IF EXISTS "gifticons_active_select" ON public.gifticons;
CREATE POLICY "gifticons_active_select" ON public.gifticons
  FOR SELECT TO authenticated USING (active = true);

DROP POLICY IF EXISTS "gifticons_admin_all" ON public.gifticons;
CREATE POLICY "gifticons_admin_all" ON public.gifticons
  FOR ALL TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

-- 2. redemptions — 사용자 교환 기록
CREATE TABLE IF NOT EXISTS public.redemptions (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  gifticon_id   uuid NOT NULL REFERENCES public.gifticons(id) ON DELETE RESTRICT,
  diamond_cost  integer NOT NULL,
  status        text NOT NULL DEFAULT 'pending',
  coupon_code   text,
  issued_at     timestamptz,
  expires_at    timestamptz,
  created_at    timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT redemptions_status_check
    CHECK (status IN ('pending','issued','failed','expired'))
);

CREATE INDEX IF NOT EXISTS redemptions_user_idx
  ON public.redemptions (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS redemptions_pending_idx
  ON public.redemptions (status, created_at)
  WHERE status = 'pending';

ALTER TABLE public.redemptions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "redemptions_owner_select" ON public.redemptions;
CREATE POLICY "redemptions_owner_select" ON public.redemptions
  FOR SELECT TO authenticated USING (user_id = auth.uid());

DROP POLICY IF EXISTS "redemptions_admin_all" ON public.redemptions;
CREATE POLICY "redemptions_admin_all" ON public.redemptions
  FOR ALL TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

-- 3. redeem_gifticon RPC
-- 입력: gifticon_id
-- 동작: 다이아 차감 + 재고 차감 + redemption pending 생성 (운영자 발급 대기)
-- 반환: { ok, redemption_id, diamond_cost, balance_after }
CREATE OR REPLACE FUNCTION public.redeem_gifticon(gifticon_id_in uuid)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  uid           uuid := auth.uid();
  g             gifticons%ROWTYPE;
  current_dia   integer;
  new_dia       integer;
  red_id        uuid;
BEGIN
  IF uid IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'auth_required');
  END IF;

  -- 카탈로그 조회 + 재고 잠금
  SELECT * INTO g FROM gifticons WHERE id = gifticon_id_in FOR UPDATE;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'gifticon_not_found');
  END IF;
  IF NOT g.active THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'gifticon_inactive');
  END IF;
  IF g.stock <= 0 THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'out_of_stock');
  END IF;

  -- 다이아 잔액 확인 + 차감 (조건부 UPDATE — 잔액 부족 시 NULL 반환)
  SELECT diamond_balance INTO current_dia FROM profiles WHERE id = uid FOR UPDATE;
  IF current_dia IS NULL OR current_dia < g.diamond_cost THEN
    RETURN jsonb_build_object(
      'ok', false, 'reason', 'insufficient_diamond',
      'have', COALESCE(current_dia, 0), 'need', g.diamond_cost
    );
  END IF;

  UPDATE profiles
     SET diamond_balance = diamond_balance - g.diamond_cost
   WHERE id = uid
   RETURNING diamond_balance INTO new_dia;

  -- diamond_ledger 기록
  INSERT INTO diamond_ledger (user_id, delta, source, source_id, balance_after)
  VALUES (uid, -g.diamond_cost, 'spend_gifticon', g.id::text, new_dia);

  -- 재고 차감
  UPDATE gifticons SET stock = stock - 1, updated_at = now() WHERE id = g.id;

  -- redemption pending 생성 (운영자가 coupon_code 채우고 issued로 전환)
  INSERT INTO redemptions (user_id, gifticon_id, diamond_cost, status)
  VALUES (uid, g.id, g.diamond_cost, 'pending')
  RETURNING id INTO red_id;

  RETURN jsonb_build_object(
    'ok', true,
    'redemption_id', red_id,
    'diamond_cost', g.diamond_cost,
    'balance_after', new_dia,
    'partner_brand', g.partner_brand,
    'name', g.name
  );
END;
$$;

REVOKE EXECUTE ON FUNCTION public.redeem_gifticon(uuid) FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION public.redeem_gifticon(uuid) TO authenticated;
