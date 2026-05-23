-- ============================================================================
-- 018 · 이중 통화 — 코인(무료) + 다이아(결제)
-- ============================================================================
-- 트랙 E 시작. 사용자 측 인게임 재화 ledger.
--
-- 코인 = 무료 획득 (광고/미니게임/걸음수/출석·미션) + 게임 내 소비 전용
-- 다이아 = 토스 결제 충전 + 기프티콘 교환·가게 커머스 구매에 사용
--
-- 환금성 분리: 코인↔다이아 ↔ 사장 풀 (별개 ledger). 사용자↔사용자 송금 없음.
-- 한국 전자금융업 라이선스 회피.
--
-- 일일 캡:
--   코인: |delta|+ 합 ≤ 500/일 (인플레이션 방지)
--   다이아: 일일 캡 없음 (결제로만 +, 사용으로만 −)
-- ============================================================================

-- 1. profiles 잔액 컬럼
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS coin_balance    integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS diamond_balance integer NOT NULL DEFAULT 0;

ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_balance_check;
ALTER TABLE public.profiles ADD  CONSTRAINT profiles_balance_check
  CHECK (coin_balance >= 0 AND diamond_balance >= 0);

-- 2. coin_ledger — 모든 코인 +/− 감사 추적
CREATE TABLE IF NOT EXISTS public.coin_ledger (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  delta       integer NOT NULL,
  reason      text NOT NULL,    -- 'ad' | 'minigame_win' | 'minigame_lose' | 'walk' | 'attendance' | 'quest' | 'spend_*' | 'admin_grant'
  source_id   text,             -- 광고 SSV 토큰 hash / minigame run id / quest_key 등
  balance_after integer NOT NULL,
  day_date    date NOT NULL DEFAULT (now() AT TIME ZONE 'Asia/Seoul')::date,
  created_at  timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT coin_ledger_delta_nonzero CHECK (delta <> 0)
);

CREATE INDEX IF NOT EXISTS coin_ledger_user_day_idx
  ON public.coin_ledger (user_id, day_date DESC);
CREATE INDEX IF NOT EXISTS coin_ledger_user_created_idx
  ON public.coin_ledger (user_id, created_at DESC);

ALTER TABLE public.coin_ledger ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "coin_ledger_owner_select" ON public.coin_ledger;
CREATE POLICY "coin_ledger_owner_select" ON public.coin_ledger
  FOR SELECT TO authenticated USING (user_id = auth.uid());
DROP POLICY IF EXISTS "coin_ledger_admin_all" ON public.coin_ledger;
CREATE POLICY "coin_ledger_admin_all" ON public.coin_ledger
  FOR ALL TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

-- 3. diamond_ledger — 다이아 +/− (토스 결제, 사용)
CREATE TABLE IF NOT EXISTS public.diamond_ledger (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  delta         integer NOT NULL,
  source        text NOT NULL,    -- 'toss_topup' | 'event_admin' | 'refund' | 'spend_gifticon' | 'spend_store'
  source_id     text,             -- toss_payment_key / redemption_id / store_purchase_id
  balance_after integer NOT NULL,
  created_at    timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT diamond_ledger_delta_nonzero CHECK (delta <> 0)
);

CREATE INDEX IF NOT EXISTS diamond_ledger_user_idx
  ON public.diamond_ledger (user_id, created_at DESC);

ALTER TABLE public.diamond_ledger ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "diamond_ledger_owner_select" ON public.diamond_ledger;
CREATE POLICY "diamond_ledger_owner_select" ON public.diamond_ledger
  FOR SELECT TO authenticated USING (user_id = auth.uid());
DROP POLICY IF EXISTS "diamond_ledger_admin_all" ON public.diamond_ledger;
CREATE POLICY "diamond_ledger_admin_all" ON public.diamond_ledger
  FOR ALL TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

-- 4. RPC grant_coin — 본인/admin, ±100 단발 제한, 일 500 누적 캡
CREATE OR REPLACE FUNCTION public.grant_coin(
  user_id_in   uuid,
  delta_in     integer,
  reason_in    text,
  source_id_in text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  caller_uid  uuid := auth.uid();
  today_date  date := (now() AT TIME ZONE 'Asia/Seoul')::date;
  today_sum   integer;
  new_balance integer;
BEGIN
  IF caller_uid IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'auth_required');
  END IF;
  IF caller_uid <> user_id_in AND NOT public.is_admin() THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'forbidden');
  END IF;
  IF delta_in = 0 THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'zero_delta');
  END IF;
  -- 1회 절대값 100 캡 (악용 방지) — admin은 제한 완화하지 않음 (운영 일관성)
  IF delta_in > 100 OR delta_in < -100 THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'delta_out_of_range');
  END IF;
  IF reason_in IS NULL OR length(trim(reason_in)) = 0 THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'reason_required');
  END IF;

  -- 일 누적 +500 캡 (positive grant만 카운트, 소비는 제한 없음)
  IF delta_in > 0 THEN
    SELECT COALESCE(sum(delta), 0) INTO today_sum
      FROM coin_ledger
     WHERE user_id = user_id_in
       AND day_date = today_date
       AND delta > 0;
    IF today_sum + delta_in > 500 THEN
      RETURN jsonb_build_object(
        'ok', false, 'reason', 'daily_cap_reached',
        'today_sum', today_sum, 'cap', 500
      );
    END IF;
  END IF;

  -- 잔액 갱신 (음수 시 0 이하 차단)
  UPDATE profiles
     SET coin_balance = coin_balance + delta_in
   WHERE id = user_id_in
     AND coin_balance + delta_in >= 0
   RETURNING coin_balance INTO new_balance;

  IF new_balance IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'insufficient_balance');
  END IF;

  INSERT INTO coin_ledger (user_id, delta, reason, source_id, balance_after)
  VALUES (user_id_in, delta_in, reason_in, source_id_in, new_balance);

  RETURN jsonb_build_object(
    'ok', true,
    'balance', new_balance,
    'delta', delta_in,
    'reason', reason_in
  );
END;
$$;

REVOKE EXECUTE ON FUNCTION public.grant_coin(uuid, integer, text, text) FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION public.grant_coin(uuid, integer, text, text) TO authenticated;

-- 5. RPC grant_diamond — service_role만 (Edge Function 토스 confirm 또는 운영 admin)
CREATE OR REPLACE FUNCTION public.grant_diamond(
  user_id_in   uuid,
  delta_in     integer,
  source_in    text,
  source_id_in text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  new_balance integer;
BEGIN
  IF delta_in = 0 THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'zero_delta');
  END IF;
  IF source_in IS NULL OR length(trim(source_in)) = 0 THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'source_required');
  END IF;

  UPDATE profiles
     SET diamond_balance = diamond_balance + delta_in
   WHERE id = user_id_in
     AND diamond_balance + delta_in >= 0
   RETURNING diamond_balance INTO new_balance;

  IF new_balance IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'insufficient_balance');
  END IF;

  INSERT INTO diamond_ledger (user_id, delta, source, source_id, balance_after)
  VALUES (user_id_in, delta_in, source_in, source_id_in, new_balance);

  RETURN jsonb_build_object(
    'ok', true,
    'balance', new_balance,
    'delta', delta_in,
    'source', source_in
  );
END;
$$;

-- service_role만 사용. anon/authenticated EXECUTE 완전 차단.
REVOKE ALL ON FUNCTION public.grant_diamond(uuid, integer, text, text)
  FROM PUBLIC, anon, authenticated;
