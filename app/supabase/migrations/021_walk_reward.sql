-- ============================================================================
-- 021 · 걸음수 보상 (트랙 E)
-- ============================================================================
-- 1k 걸음당 +10 코인, 일 최대 50 코인 (5k 걸음 이상은 보상 동일).
--
-- 클라이언트(health 패키지)가 오늘 누적 걸음 X 보고 → RPC가 보상 누적 비교.
-- delta = min(floor(X/1000)*10, 50) - 이미 받은 coin → delta>0면 추가 지급.
--
-- 어뷰 방지:
--   1. 일일 캡 50 (grant_coin이 코인 일 +500 캡 추가 적용)
--   2. UNIQUE (user_id, day_date) — 하루 1행, UPSERT
--   3. 클라이언트가 X를 부풀려도 50 코인이 최대 — 일일 상한 차단
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.walk_rewards (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  day_date        date NOT NULL DEFAULT (now() AT TIME ZONE 'Asia/Seoul')::date,
  steps_reported  integer NOT NULL DEFAULT 0,
  coins_awarded   integer NOT NULL DEFAULT 0,
  updated_at      timestamptz NOT NULL DEFAULT now(),
  created_at      timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT walk_rewards_steps_nonneg CHECK (steps_reported >= 0),
  CONSTRAINT walk_rewards_coins_nonneg CHECK (coins_awarded >= 0),
  UNIQUE (user_id, day_date)
);

CREATE INDEX IF NOT EXISTS walk_rewards_user_idx
  ON public.walk_rewards (user_id, day_date DESC);

ALTER TABLE public.walk_rewards ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "walk_rewards_owner_select" ON public.walk_rewards;
CREATE POLICY "walk_rewards_owner_select" ON public.walk_rewards
  FOR SELECT TO authenticated USING (user_id = auth.uid());

DROP POLICY IF EXISTS "walk_rewards_admin_all" ON public.walk_rewards;
CREATE POLICY "walk_rewards_admin_all" ON public.walk_rewards
  FOR ALL TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

-- claim_walk_reward RPC
-- 입력: steps_total_in (오늘 누적 걸음수)
-- 반환: { ok, eligible_coin, already_awarded, delta, balance }
CREATE OR REPLACE FUNCTION public.claim_walk_reward(steps_total_in integer)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  uid          uuid := auth.uid();
  today_date   date := (now() AT TIME ZONE 'Asia/Seoul')::date;
  daily_cap    integer := 50;
  step_per_coin integer := 100; -- 100걸음당 1코인 (1k=10코인)
  eligible     integer;
  already      integer := 0;
  delta_v      integer;
  grant_result jsonb;
BEGIN
  IF uid IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'auth_required');
  END IF;
  IF steps_total_in IS NULL OR steps_total_in < 0 THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'invalid_steps');
  END IF;

  eligible := LEAST(daily_cap, (steps_total_in / step_per_coin) * 10);
  IF eligible <= 0 THEN
    RETURN jsonb_build_object(
      'ok', false, 'reason', 'not_enough_steps',
      'steps', steps_total_in, 'need', 1000
    );
  END IF;

  -- 오늘 row 조회 (UPSERT)
  SELECT coins_awarded INTO already
    FROM walk_rewards
   WHERE user_id = uid AND day_date = today_date
   FOR UPDATE;
  IF already IS NULL THEN already := 0; END IF;

  delta_v := eligible - already;
  IF delta_v <= 0 THEN
    RETURN jsonb_build_object(
      'ok', false, 'reason', 'already_at_cap',
      'eligible', eligible, 'already_awarded', already
    );
  END IF;

  -- delta는 ±100 안 (eligible 최대 50) — grant_coin 호출 가능
  grant_result := public.grant_coin(uid, delta_v, 'walk', steps_total_in::text);

  -- grant_coin이 일일 캡 등으로 실패할 수 있음 → ok 검사
  IF (grant_result ->> 'ok')::boolean IS NOT TRUE THEN
    RETURN jsonb_build_object(
      'ok', false, 'reason', 'grant_failed',
      'grant', grant_result
    );
  END IF;

  -- UPSERT
  INSERT INTO walk_rewards (user_id, day_date, steps_reported, coins_awarded)
  VALUES (uid, today_date, steps_total_in, eligible)
  ON CONFLICT (user_id, day_date) DO UPDATE
    SET steps_reported = GREATEST(walk_rewards.steps_reported, EXCLUDED.steps_reported),
        coins_awarded  = EXCLUDED.coins_awarded,
        updated_at     = now();

  RETURN jsonb_build_object(
    'ok', true,
    'steps', steps_total_in,
    'eligible_coin', eligible,
    'already_awarded', already,
    'delta', delta_v,
    'grant', grant_result
  );
END;
$$;

REVOKE EXECUTE ON FUNCTION public.claim_walk_reward(integer) FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION public.claim_walk_reward(integer) TO authenticated;

-- 오늘 걸음 보상 상태 helper
CREATE OR REPLACE FUNCTION public.today_walk_status()
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE
  uid        uuid := auth.uid();
  today_date date := (now() AT TIME ZONE 'Asia/Seoul')::date;
  row_rec    walk_rewards%ROWTYPE;
BEGIN
  IF uid IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'auth_required');
  END IF;
  SELECT * INTO row_rec FROM walk_rewards
   WHERE user_id = uid AND day_date = today_date;
  RETURN jsonb_build_object(
    'ok', true,
    'steps_reported', COALESCE(row_rec.steps_reported, 0),
    'coins_awarded', COALESCE(row_rec.coins_awarded, 0),
    'cap', 50,
    'remaining', GREATEST(0, 50 - COALESCE(row_rec.coins_awarded, 0))
  );
END;
$$;

REVOKE EXECUTE ON FUNCTION public.today_walk_status() FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION public.today_walk_status() TO authenticated;
