-- ============================================================================
-- 012 · 포인트 자동 적립 + 만료 클루 자동 정리
-- ============================================================================
-- (a) add_user_points(user_id, delta, reason) RPC
--     - 미니게임/이벤트에서 호출
--     - 본인 또는 admin만 호출 가능 (악용 방지)
--     - 1회 절대값 100p 제한 (악용 방지)
--
-- (b) rewards INSERT → profiles.total_points 자동 적립 트리거
--     - reward.type='points' AND value > 0 일 때만
--     - 클루 완료 → reward 발급 → 포인트 자동 누적 흐름 완성
--
-- (c) expire_overdue_clues() RPC
--     - ends_at < now() 이면서 status='active'인 클루를 'completed' 처리
--     - 클라이언트가 홈 진입 시 호출 또는 별도 cron
-- ============================================================================

-- (a) add_user_points RPC: 본인/admin만, ±100p 제한
CREATE OR REPLACE FUNCTION public.add_user_points(
  user_id_in uuid,
  delta_in   integer,
  reason_in  text DEFAULT NULL
)
RETURNS integer
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  new_total integer;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'auth required';
  END IF;
  IF auth.uid() <> user_id_in AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF delta_in > 100 OR delta_in < -100 THEN
    RAISE EXCEPTION 'delta out of range';
  END IF;

  UPDATE profiles
     SET total_points = GREATEST(COALESCE(total_points, 0) + delta_in, 0)
   WHERE id = user_id_in
   RETURNING total_points INTO new_total;
  RETURN new_total;
END;
$$;

GRANT EXECUTE ON FUNCTION public.add_user_points TO authenticated;

-- (b) rewards INSERT → profiles.total_points 자동 적립 트리거
-- 컬럼명 주의: rewards.type, rewards.value (text). 'points' 타입일 때만 누적.
CREATE OR REPLACE FUNCTION public.tg_reward_to_points()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v integer;
BEGIN
  IF NEW.type = 'points' AND NEW.value IS NOT NULL THEN
    v := COALESCE(NULLIF(NEW.value, '')::numeric, 0)::integer;
    IF v > 0 THEN
      UPDATE profiles
         SET total_points = COALESCE(total_points, 0) + v
       WHERE id = NEW.user_id;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS rewards_to_points_sync ON public.rewards;
CREATE TRIGGER rewards_to_points_sync
  AFTER INSERT ON public.rewards
  FOR EACH ROW EXECUTE FUNCTION public.tg_reward_to_points();

-- (c) expire_overdue_clues RPC: ends_at < now() AND status='active' → 'completed'
CREATE OR REPLACE FUNCTION public.expire_overdue_clues()
RETURNS integer
LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  WITH updated AS (
    UPDATE public.clues
       SET status = 'completed'
     WHERE status = 'active'
       AND ends_at IS NOT NULL
       AND ends_at < now()
     RETURNING id
  )
  SELECT count(*)::integer FROM updated;
$$;

GRANT EXECUTE ON FUNCTION public.expire_overdue_clues TO anon, authenticated;
