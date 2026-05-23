-- ============================================================================
-- 010 · 루틴 인증 (재방문 자동화)
-- ============================================================================
-- 배경: 인터뷰 3/3 "일회성" 우려 해결. 매일 가는 곳을 루틴으로 등록 →
--        그 위치 반경 안 체크인 1일 1회 → streak → retention 강화.
--
-- 테이블:
--   routines          : 사용자별 루틴 (위치 + 요일 + 시간 + streak 누적)
--   routine_checkins  : 일별 체크인 (UNIQUE(routine_id, checkin_date)로 1일 1회 강제)
--
-- RPC:
--   routine_checkin(routine_id, lat, lng)
--     → 위치 검증 + streak 자동 갱신 + 1일 1회 체크
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.routines (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  name            text NOT NULL,
  target_lat      double precision NOT NULL,
  target_lng      double precision NOT NULL,
  radius_m        integer NOT NULL DEFAULT 100,
  days_of_week    smallint[] NOT NULL DEFAULT '{1,2,3,4,5}',
  start_hour      smallint NOT NULL DEFAULT 6,
  end_hour        smallint NOT NULL DEFAULT 22,
  is_active       boolean NOT NULL DEFAULT true,
  current_streak  integer NOT NULL DEFAULT 0,
  longest_streak  integer NOT NULL DEFAULT 0,
  last_checkin_at timestamptz,
  created_at      timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT routines_radius_check CHECK (radius_m BETWEEN 30 AND 2000),
  CONSTRAINT routines_hours_check  CHECK (start_hour BETWEEN 0 AND 23 AND end_hour BETWEEN 0 AND 23)
);

CREATE TABLE IF NOT EXISTS public.routine_checkins (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  routine_id   uuid NOT NULL REFERENCES public.routines(id) ON DELETE CASCADE,
  user_id      uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  lat          double precision NOT NULL,
  lng          double precision NOT NULL,
  distance_m   double precision,
  checked_at   timestamptz NOT NULL DEFAULT now(),
  checkin_date date NOT NULL DEFAULT (now() AT TIME ZONE 'Asia/Seoul')::date,
  UNIQUE (routine_id, checkin_date)
);

CREATE INDEX IF NOT EXISTS routines_user_idx ON public.routines(user_id);
CREATE INDEX IF NOT EXISTS routine_checkins_user_date_idx
  ON public.routine_checkins(user_id, checked_at DESC);

ALTER TABLE public.routines         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.routine_checkins ENABLE ROW LEVEL SECURITY;

CREATE POLICY "routines_own"           ON public.routines         FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "routine_checkins_own"   ON public.routine_checkins FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "routines_admin"         ON public.routines         FOR ALL TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());
CREATE POLICY "routine_checkins_admin" ON public.routine_checkins FOR ALL TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

-- routine_checkin RPC: 위치 검증 + streak 자동 갱신 + 1일 1회 강제
CREATE OR REPLACE FUNCTION public.routine_checkin(
  routine_id_in uuid,
  user_lat      double precision,
  user_lng      double precision
)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  r          routines%ROWTYPE;
  d_m        double precision;
  today      date;
  yesterday  date;
  new_streak int;
BEGIN
  SELECT * INTO r FROM routines WHERE id = routine_id_in AND user_id = auth.uid();
  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'routine_not_found');
  END IF;

  d_m := 111320 * sqrt(
    power((r.target_lat - user_lat) * cos(radians(r.target_lat)), 2) +
    power(r.target_lng - user_lng, 2)
  );

  IF d_m > r.radius_m THEN
    RETURN jsonb_build_object(
      'ok', false, 'reason', 'too_far',
      'distance_m', d_m, 'radius_m', r.radius_m);
  END IF;

  today     := (now() AT TIME ZONE 'Asia/Seoul')::date;
  yesterday := today - INTERVAL '1 day';

  -- streak: 어제 체크인 있으면 연속, 없으면 1로 리셋
  IF r.last_checkin_at IS NOT NULL AND
     (r.last_checkin_at AT TIME ZONE 'Asia/Seoul')::date = yesterday THEN
    new_streak := r.current_streak + 1;
  ELSIF r.last_checkin_at IS NOT NULL AND
        (r.last_checkin_at AT TIME ZONE 'Asia/Seoul')::date = today THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'already_today');
  ELSE
    new_streak := 1;
  END IF;

  BEGIN
    INSERT INTO routine_checkins (routine_id, user_id, lat, lng, distance_m)
    VALUES (routine_id_in, auth.uid(), user_lat, user_lng, d_m);
  EXCEPTION WHEN unique_violation THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'already_today');
  END;

  UPDATE routines
     SET current_streak  = new_streak,
         longest_streak  = GREATEST(longest_streak, new_streak),
         last_checkin_at = now()
   WHERE id = routine_id_in;

  RETURN jsonb_build_object(
    'ok', true,
    'streak', new_streak,
    'longest', GREATEST(r.longest_streak, new_streak),
    'distance_m', d_m
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.routine_checkin TO authenticated;
