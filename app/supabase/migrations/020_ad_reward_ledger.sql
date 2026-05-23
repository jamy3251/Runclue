-- ============================================================================
-- 020 · 광고 보상 ledger (트랙 C)
-- ============================================================================
-- 보상형 비디오 시청 → +20 coin. 일일 5회 캡.
--
-- MVP는 클라이언트 신뢰 (onUserEarnedReward 콜백 → claim_ad_reward RPC).
-- 본격 Google SSV 서버 검증은 Phase 2 (Edge Function ad-ssv-callback).
-- view_token = 클라이언트 nonce (또는 추후 SSV transaction_id) — 멱등성 키.
--
-- 일일 캡 강제:
--   1. 광고당 보상 20 coin (delta 한도 100 안)
--   2. day_date 별 5회 카운트 검사 — 6번째 거부
--   3. grant_coin 호출이 코인 일일 +500 캡까지 자동 적용
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.ad_views (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  ad_unit_id  text NOT NULL,
  view_token  text NOT NULL,
  reward_coin integer NOT NULL DEFAULT 20,
  day_date    date NOT NULL DEFAULT (now() AT TIME ZONE 'Asia/Seoul')::date,
  created_at  timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, view_token)
);

CREATE INDEX IF NOT EXISTS ad_views_user_day_idx
  ON public.ad_views (user_id, day_date DESC);

ALTER TABLE public.ad_views ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "ad_views_owner_select" ON public.ad_views;
CREATE POLICY "ad_views_owner_select" ON public.ad_views
  FOR SELECT TO authenticated USING (user_id = auth.uid());

DROP POLICY IF EXISTS "ad_views_admin_all" ON public.ad_views;
CREATE POLICY "ad_views_admin_all" ON public.ad_views
  FOR ALL TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

-- claim_ad_reward RPC
-- 입력: ad_unit_id, view_token (멱등성 — 같은 토큰 재호출 시 already_claimed)
-- 출력: { ok, reward_coin, today_count, balance }
CREATE OR REPLACE FUNCTION public.claim_ad_reward(
  ad_unit_id_in text,
  view_token_in text
)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  uid          uuid := auth.uid();
  today_date   date := (now() AT TIME ZONE 'Asia/Seoul')::date;
  today_count  integer;
  reward_amt   integer := 20;
  daily_cap    integer := 5;
  grant_result jsonb;
BEGIN
  IF uid IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'auth_required');
  END IF;
  IF ad_unit_id_in IS NULL OR length(trim(ad_unit_id_in)) = 0 THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'ad_unit_required');
  END IF;
  IF view_token_in IS NULL OR length(trim(view_token_in)) = 0 THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'view_token_required');
  END IF;

  -- 동일 토큰 재호출 멱등 처리
  IF EXISTS (
    SELECT 1 FROM ad_views
     WHERE user_id = uid AND view_token = view_token_in
  ) THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'already_claimed');
  END IF;

  -- 일일 5회 캡
  SELECT count(*) INTO today_count FROM ad_views
   WHERE user_id = uid AND day_date = today_date;
  IF today_count >= daily_cap THEN
    RETURN jsonb_build_object(
      'ok', false, 'reason', 'daily_cap_reached',
      'today_count', today_count, 'cap', daily_cap
    );
  END IF;

  -- 기록 + 보상 지급
  INSERT INTO ad_views (user_id, ad_unit_id, view_token, reward_coin)
  VALUES (uid, ad_unit_id_in, view_token_in, reward_amt);

  grant_result := public.grant_coin(uid, reward_amt, 'ad', view_token_in);

  RETURN jsonb_build_object(
    'ok', true,
    'reward_coin', reward_amt,
    'today_count', today_count + 1,
    'cap', daily_cap,
    'grant', grant_result
  );
END;
$$;

REVOKE EXECUTE ON FUNCTION public.claim_ad_reward(text, text) FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION public.claim_ad_reward(text, text) TO authenticated;

-- 오늘 광고 시청 카운트 helper (UI 표시)
CREATE OR REPLACE FUNCTION public.today_ad_count()
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE
  uid        uuid := auth.uid();
  today_date date := (now() AT TIME ZONE 'Asia/Seoul')::date;
  cnt        integer;
BEGIN
  IF uid IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'auth_required');
  END IF;
  SELECT count(*) INTO cnt FROM ad_views
   WHERE user_id = uid AND day_date = today_date;
  RETURN jsonb_build_object(
    'ok', true,
    'today_count', cnt,
    'cap', 5,
    'remaining', GREATEST(0, 5 - cnt)
  );
END;
$$;

REVOKE EXECUTE ON FUNCTION public.today_ad_count() FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION public.today_ad_count() TO authenticated;
