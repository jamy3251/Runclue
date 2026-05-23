-- ============================================================================
-- 019 · 일일 출석 + 일일 미션 (트랙 E — 무료 코인 획득 채널)
-- ============================================================================
-- 4종 일일 미션:
--   attendance     — 출석 +5 코인, 7일 streak 도달 시 +30 보너스
--   first_clue     — 오늘 첫 클루 완료 +20 코인
--   first_comment  — 오늘 첫 댓글 +20 코인
--   first_minigame — 오늘 첫 미니게임 플레이 +10 코인
--
-- 검증은 모두 서버 측 (RPC SECURITY DEFINER + auth.uid()).
-- 클라이언트가 임의로 quest_key 보내도 조건 미충족 시 거부.
--
-- 일일 캡(코인 +500/일)은 grant_coin RPC가 자동 적용.
-- ============================================================================

-- 1. profiles 출석 streak 컬럼
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS attendance_streak     integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS last_attendance_date  date;

ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_attendance_streak_check;
ALTER TABLE public.profiles ADD  CONSTRAINT profiles_attendance_streak_check
  CHECK (attendance_streak >= 0);

-- 2. daily_quest_progress 테이블 (UNIQUE: 같은 사용자 같은 quest 같은 날 1회만)
CREATE TABLE IF NOT EXISTS public.daily_quest_progress (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  quest_key    text NOT NULL,
  day_date     date NOT NULL DEFAULT (now() AT TIME ZONE 'Asia/Seoul')::date,
  reward_coin  integer NOT NULL DEFAULT 0,
  bonus_coin   integer NOT NULL DEFAULT 0,
  completed_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT daily_quest_progress_key_check
    CHECK (quest_key IN ('attendance','first_clue','first_comment','first_minigame')),
  UNIQUE (user_id, quest_key, day_date)
);

CREATE INDEX IF NOT EXISTS daily_quest_progress_user_day_idx
  ON public.daily_quest_progress (user_id, day_date DESC);

ALTER TABLE public.daily_quest_progress ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "daily_quest_owner_select" ON public.daily_quest_progress;
CREATE POLICY "daily_quest_owner_select" ON public.daily_quest_progress
  FOR SELECT TO authenticated USING (user_id = auth.uid());
DROP POLICY IF EXISTS "daily_quest_admin_all" ON public.daily_quest_progress;
CREATE POLICY "daily_quest_admin_all" ON public.daily_quest_progress
  FOR ALL TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

-- 3. claim_quest_reward RPC
CREATE OR REPLACE FUNCTION public.claim_quest_reward(quest_key_in text)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  uid          uuid := auth.uid();
  today_date   date := (now() AT TIME ZONE 'Asia/Seoul')::date;
  yesterday    date := today_date - 1;
  reward_amt   integer := 0;
  bonus_amt    integer := 0;
  cnt          integer;
  prof_row     profiles%ROWTYPE;
  new_streak   integer;
  grant_result jsonb;
BEGIN
  IF uid IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'auth_required');
  END IF;

  -- 이미 받았는지 검사
  IF EXISTS (
    SELECT 1 FROM daily_quest_progress
     WHERE user_id = uid
       AND quest_key = quest_key_in
       AND day_date = today_date
  ) THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'already_claimed');
  END IF;

  -- quest별 조건 검증 + 보상량
  CASE quest_key_in
    WHEN 'attendance' THEN
      reward_amt := 5;
    WHEN 'first_clue' THEN
      SELECT count(*) INTO cnt FROM participations
       WHERE user_id = uid
         AND status = 'completed'
         AND (completed_at AT TIME ZONE 'Asia/Seoul')::date = today_date;
      IF cnt < 1 THEN
        RETURN jsonb_build_object('ok', false, 'reason', 'not_qualified',
                                  'quest', quest_key_in);
      END IF;
      reward_amt := 20;
    WHEN 'first_comment' THEN
      SELECT count(*) INTO cnt FROM post_comments
       WHERE author_id = uid
         AND (created_at AT TIME ZONE 'Asia/Seoul')::date = today_date;
      IF cnt < 1 THEN
        RETURN jsonb_build_object('ok', false, 'reason', 'not_qualified',
                                  'quest', quest_key_in);
      END IF;
      reward_amt := 20;
    WHEN 'first_minigame' THEN
      SELECT count(*) INTO cnt FROM coin_ledger
       WHERE user_id = uid
         AND day_date = today_date
         AND reason IN ('minigame_win','minigame_lose');
      IF cnt < 1 THEN
        RETURN jsonb_build_object('ok', false, 'reason', 'not_qualified',
                                  'quest', quest_key_in);
      END IF;
      reward_amt := 10;
    ELSE
      RETURN jsonb_build_object('ok', false, 'reason', 'unknown_quest_key');
  END CASE;

  -- attendance streak 갱신
  IF quest_key_in = 'attendance' THEN
    SELECT * INTO prof_row FROM profiles WHERE id = uid FOR UPDATE;
    IF prof_row.last_attendance_date = yesterday THEN
      new_streak := prof_row.attendance_streak + 1;
    ELSE
      new_streak := 1;
    END IF;
    UPDATE profiles
       SET attendance_streak    = new_streak,
           last_attendance_date = today_date
     WHERE id = uid;

    -- 매 7일마다 보너스
    IF new_streak > 0 AND new_streak % 7 = 0 THEN
      bonus_amt := 30;
    END IF;
  END IF;

  -- 진행 기록 (UNIQUE 제약으로 동시성 보호)
  INSERT INTO daily_quest_progress
    (user_id, quest_key, day_date, reward_coin, bonus_coin)
  VALUES
    (uid, quest_key_in, today_date, reward_amt, bonus_amt);

  -- 코인 지급 (grant_coin이 일일 캡 자동 적용)
  grant_result := public.grant_coin(
    uid, reward_amt, 'quest_' || quest_key_in, quest_key_in
  );

  IF bonus_amt > 0 THEN
    PERFORM public.grant_coin(
      uid, bonus_amt, 'attendance_streak_bonus', new_streak::text
    );
  END IF;

  RETURN jsonb_build_object(
    'ok', true,
    'quest', quest_key_in,
    'reward_coin', reward_amt,
    'bonus_coin', bonus_amt,
    'streak', COALESCE(new_streak, prof_row.attendance_streak),
    'grant', grant_result
  );
END;
$$;

REVOKE EXECUTE ON FUNCTION public.claim_quest_reward(text) FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION public.claim_quest_reward(text) TO authenticated;

-- 4. 오늘 미션 상태 조회 helper RPC
CREATE OR REPLACE FUNCTION public.today_quest_status()
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE
  uid        uuid := auth.uid();
  today_date date := (now() AT TIME ZONE 'Asia/Seoul')::date;
  yesterday  date := today_date - 1;
  prof_row   profiles%ROWTYPE;
  claimed    jsonb;
  clue_cnt   integer := 0;
  com_cnt    integer := 0;
  mg_cnt     integer := 0;
BEGIN
  IF uid IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'auth_required');
  END IF;

  SELECT * INTO prof_row FROM profiles WHERE id = uid;

  -- 오늘 이미 claim한 quest_key 모음
  SELECT COALESCE(
    jsonb_object_agg(quest_key, jsonb_build_object(
      'reward', reward_coin, 'bonus', bonus_coin, 'at', completed_at
    )), '{}'::jsonb
  ) INTO claimed
  FROM daily_quest_progress
  WHERE user_id = uid AND day_date = today_date;

  SELECT count(*) INTO clue_cnt FROM participations
   WHERE user_id = uid AND status = 'completed'
     AND (completed_at AT TIME ZONE 'Asia/Seoul')::date = today_date;
  SELECT count(*) INTO com_cnt FROM post_comments
   WHERE author_id = uid
     AND (created_at AT TIME ZONE 'Asia/Seoul')::date = today_date;
  SELECT count(*) INTO mg_cnt FROM coin_ledger
   WHERE user_id = uid AND day_date = today_date
     AND reason IN ('minigame_win','minigame_lose');

  RETURN jsonb_build_object(
    'ok', true,
    'today', today_date,
    'attendance_streak', prof_row.attendance_streak,
    'last_attendance_date', prof_row.last_attendance_date,
    'claimed', claimed,
    'progress', jsonb_build_object(
      'first_clue', clue_cnt,
      'first_comment', com_cnt,
      'first_minigame', mg_cnt
    )
  );
END;
$$;

REVOKE EXECUTE ON FUNCTION public.today_quest_status() FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION public.today_quest_status() TO authenticated;
