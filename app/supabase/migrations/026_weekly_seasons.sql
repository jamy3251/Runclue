-- ============================================================================
-- 026 · 주간 시즌 #16 — 라운드제 + 자동 Top 10 다이아 분배
-- ============================================================================
-- 인터뷰 (CTO) — "라운드제·토너먼트, 시즌제 retention". CTA는 시즌 종료 보상.
--
-- 시즌 = KST 월요일 00:00 ~ 일요일 23:59:59. 주간 자동 롤오버.
-- 점수 = (시즌 내 완료 클루 수) × 100 + (시즌 내 코인 적립 합).
-- 보상 = Top 10에 다이아 자동 분배:
--   1등 500 / 2등 300 / 3등 200 / 4~5등 100 / 6~10등 50 = 합 1450 다이아.
--
-- 스케줄:
--   매주 일요일 15:00 UTC (= 월요일 00:00 KST)
--   → close_season_and_payout(현재 시즌) + ensure_current_season() (다음 시즌 생성)
--
-- 클라이언트가 홈 진입 시 ensure_current_season() 호출 (cron 누락 대비).
-- ============================================================================

-- 1. seasons 테이블
CREATE TABLE IF NOT EXISTS public.seasons (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  slug         text NOT NULL UNIQUE, -- 'YYYY-WW' (예: '2026-W21')
  start_at     timestamptz NOT NULL,
  end_at       timestamptz NOT NULL,
  status       text NOT NULL DEFAULT 'active',
  closed_at    timestamptz,
  created_at   timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT seasons_status_check
    CHECK (status IN ('scheduled','active','closed')),
  CONSTRAINT seasons_period_check CHECK (end_at > start_at)
);

CREATE INDEX IF NOT EXISTS seasons_status_idx
  ON public.seasons (status, start_at DESC);

ALTER TABLE public.seasons ENABLE ROW LEVEL SECURITY;

-- 모든 로그인 사용자가 시즌 정보 조회 가능
DROP POLICY IF EXISTS "seasons_all_select" ON public.seasons;
CREATE POLICY "seasons_all_select" ON public.seasons
  FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "seasons_admin_all" ON public.seasons;
CREATE POLICY "seasons_admin_all" ON public.seasons
  FOR ALL TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

-- 2. season_rewards — 시즌 종료 후 분배 기록 (UNIQUE 멱등성)
CREATE TABLE IF NOT EXISTS public.season_rewards (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  season_id    uuid NOT NULL REFERENCES public.seasons(id) ON DELETE CASCADE,
  user_id      uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  rank         integer NOT NULL,
  score        integer NOT NULL,
  reward_diamond integer NOT NULL,
  awarded_at   timestamptz NOT NULL DEFAULT now(),
  UNIQUE (season_id, user_id),
  CONSTRAINT season_rewards_rank_check CHECK (rank > 0)
);

CREATE INDEX IF NOT EXISTS season_rewards_user_idx
  ON public.season_rewards (user_id, awarded_at DESC);
CREATE INDEX IF NOT EXISTS season_rewards_season_rank_idx
  ON public.season_rewards (season_id, rank);

ALTER TABLE public.season_rewards ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "season_rewards_all_select" ON public.season_rewards;
CREATE POLICY "season_rewards_all_select" ON public.season_rewards
  FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "season_rewards_admin_all" ON public.season_rewards;
CREATE POLICY "season_rewards_admin_all" ON public.season_rewards
  FOR ALL TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

-- 3. ensure_current_season() — 현재 KST 주의 시즌 보장
-- 클라이언트가 홈 진입 시 호출 + cron이 매주 호출.
CREATE OR REPLACE FUNCTION public.ensure_current_season()
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  kst_now    timestamptz := now() AT TIME ZONE 'Asia/Seoul';
  kst_today  date := kst_now::date;
  weekday    integer := EXTRACT(ISODOW FROM kst_today); -- 1=월, 7=일
  start_kst  date := kst_today - (weekday - 1);
  end_kst    date := start_kst + 7;
  start_utc  timestamptz;
  end_utc    timestamptz;
  iso_year   integer;
  iso_week   integer;
  s_slug     text;
  s          seasons%ROWTYPE;
BEGIN
  start_utc := (start_kst::timestamp AT TIME ZONE 'Asia/Seoul');
  end_utc   := (end_kst::timestamp   AT TIME ZONE 'Asia/Seoul');
  iso_year  := EXTRACT(ISOYEAR FROM start_kst);
  iso_week  := EXTRACT(WEEK    FROM start_kst);
  s_slug    := iso_year || '-W' || lpad(iso_week::text, 2, '0');

  SELECT * INTO s FROM seasons WHERE slug = s_slug;
  IF NOT FOUND THEN
    INSERT INTO seasons (slug, start_at, end_at, status)
    VALUES (s_slug, start_utc, end_utc, 'active')
    RETURNING * INTO s;
  END IF;

  RETURN jsonb_build_object(
    'ok', true,
    'season_id', s.id,
    'slug', s.slug,
    'start_at', s.start_at,
    'end_at', s.end_at,
    'status', s.status
  );
END;
$$;

REVOKE EXECUTE ON FUNCTION public.ensure_current_season() FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION public.ensure_current_season() TO authenticated;

-- 4. season_leaderboard(season_id, top_n) — 점수 계산해서 순위 반환
-- 점수 = COUNT(participations 완료) × 100 + SUM(coin_ledger.delta>0)
CREATE OR REPLACE FUNCTION public.season_leaderboard(
  season_id_in uuid DEFAULT NULL,
  top_n integer DEFAULT 100
)
RETURNS TABLE (
  user_id        uuid,
  nickname       text,
  avatar_url     text,
  completed      integer,
  coin_earned    integer,
  score          integer,
  rank           integer
)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE
  s seasons%ROWTYPE;
BEGIN
  IF season_id_in IS NULL THEN
    SELECT * INTO s FROM seasons WHERE status = 'active' ORDER BY start_at DESC LIMIT 1;
  ELSE
    SELECT * INTO s FROM seasons WHERE id = season_id_in;
  END IF;
  IF NOT FOUND THEN RETURN; END IF;

  RETURN QUERY
  WITH clue_counts AS (
    SELECT p.user_id, count(*)::integer AS completed
      FROM participations p
     WHERE p.status = 'completed'
       AND p.completed_at >= s.start_at AND p.completed_at < s.end_at
     GROUP BY p.user_id
  ),
  coin_sums AS (
    SELECT cl.user_id, sum(cl.delta)::integer AS coin_earned
      FROM coin_ledger cl
     WHERE cl.created_at >= s.start_at AND cl.created_at < s.end_at
       AND cl.delta > 0
     GROUP BY cl.user_id
  ),
  combined AS (
    SELECT
      pr.id AS user_id,
      pr.nickname,
      pr.avatar_url,
      COALESCE(cc.completed, 0) AS completed,
      COALESCE(cs.coin_earned, 0) AS coin_earned,
      COALESCE(cc.completed, 0) * 100 + COALESCE(cs.coin_earned, 0) AS score
    FROM profiles pr
    LEFT JOIN clue_counts cc ON cc.user_id = pr.id
    LEFT JOIN coin_sums   cs ON cs.user_id = pr.id
    WHERE COALESCE(cc.completed, 0) > 0 OR COALESCE(cs.coin_earned, 0) > 0
  )
  SELECT
    c.user_id,
    c.nickname,
    c.avatar_url,
    c.completed,
    c.coin_earned,
    c.score,
    (ROW_NUMBER() OVER (ORDER BY c.score DESC, c.user_id))::integer AS rank
  FROM combined c
  ORDER BY c.score DESC, c.user_id
  LIMIT top_n;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.season_leaderboard(uuid, integer) FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION public.season_leaderboard(uuid, integer) TO authenticated;

-- 5. close_season_and_payout(season_id) — 시즌 종료 + Top 10에 다이아 분배
-- service_role/postgres만 호출 (cron이 호출).
CREATE OR REPLACE FUNCTION public.close_season_and_payout(season_id_in uuid)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  s         seasons%ROWTYPE;
  rec       record;
  diamond_v integer;
  awarded   integer := 0;
  total_dia integer := 0;
BEGIN
  SELECT * INTO s FROM seasons WHERE id = season_id_in FOR UPDATE;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'season_not_found');
  END IF;
  IF s.status = 'closed' THEN
    RETURN jsonb_build_object('ok', true, 'idempotent', true, 'season', s.slug);
  END IF;

  -- Top 10에 다이아 분배
  FOR rec IN
    SELECT * FROM public.season_leaderboard(season_id_in, 10)
  LOOP
    diamond_v := CASE rec.rank
      WHEN 1 THEN 500
      WHEN 2 THEN 300
      WHEN 3 THEN 200
      WHEN 4 THEN 100
      WHEN 5 THEN 100
      ELSE         50  -- 6~10등
    END;

    INSERT INTO season_rewards (season_id, user_id, rank, score, reward_diamond)
    VALUES (season_id_in, rec.user_id, rec.rank, rec.score, diamond_v)
    ON CONFLICT (season_id, user_id) DO NOTHING;

    PERFORM public.grant_diamond(
      rec.user_id, diamond_v, 'season_reward', s.slug
    );
    awarded := awarded + 1;
    total_dia := total_dia + diamond_v;
  END LOOP;

  UPDATE seasons SET status = 'closed', closed_at = now() WHERE id = s.id;

  RETURN jsonb_build_object(
    'ok', true,
    'season', s.slug,
    'awarded', awarded,
    'total_diamond', total_dia
  );
END;
$$;

REVOKE ALL ON FUNCTION public.close_season_and_payout(uuid) FROM PUBLIC, anon, authenticated;

-- 6. close_active_seasons_overdue() — cron이 호출. 종료 시각 지난 active 시즌 자동 close.
CREATE OR REPLACE FUNCTION public.close_active_seasons_overdue()
RETURNS integer
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  s record;
  cnt integer := 0;
BEGIN
  FOR s IN
    SELECT id FROM seasons
     WHERE status = 'active' AND end_at <= now()
  LOOP
    PERFORM public.close_season_and_payout(s.id);
    cnt := cnt + 1;
  END LOOP;
  -- 종료 후 새 시즌 생성 (KST 기준 ensure)
  PERFORM public.ensure_current_season();
  RETURN cnt;
END;
$$;

REVOKE ALL ON FUNCTION public.close_active_seasons_overdue() FROM PUBLIC, anon, authenticated;

-- 7. 첫 시즌 즉시 생성
SELECT public.ensure_current_season();
