-- ============================================================================
-- 025 · Lobby 타임아웃 pg_cron (Step 18, 트랙 A 마무리)
-- ============================================================================
-- coop 클루가 recruiting 상태에서 lobby_window_minutes 초과하면 자동 cancelled.
-- in_lobby 참여자들은 abandoned로 표시.
-- 풀(reward_pool_net)은 그대로 보존 — 사장이 admin과 협의하여 환불 또는 재사용.
--
-- recruiting 시작 시점 추적을 위해 새 컬럼 `recruiting_started_at` 추가.
-- join_coop_clue RPC도 idle→recruiting 전환 시 timestamp 기록하도록 갱신.
--
-- pg_cron: 5분마다 expire_lobby_recruits 실행.
-- ============================================================================

-- 1. recruiting 시작 시점 컬럼
ALTER TABLE public.clues
  ADD COLUMN IF NOT EXISTS recruiting_started_at timestamptz;

-- 2. join_coop_clue RPC 업데이트 — recruiting 시작 시 timestamp
CREATE OR REPLACE FUNCTION public.join_coop_clue(clue_id_in uuid)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  c            clues%ROWTYPE;
  uid          uuid := auth.uid();
  lobby_count  integer;
  was_started  boolean := false;
BEGIN
  IF uid IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'auth_required');
  END IF;

  SELECT * INTO c FROM clues WHERE id = clue_id_in;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'clue_not_found');
  END IF;
  IF c.game_mode <> 'coop' THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'not_coop');
  END IF;
  IF c.status <> 'active' THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'clue_not_active');
  END IF;
  IF c.ends_at IS NOT NULL AND c.ends_at < now() THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'clue_expired');
  END IF;
  IF c.creator_id = uid THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'own_clue_not_joinable');
  END IF;

  IF c.coop_state NOT IN ('idle','recruiting') THEN
    SELECT count(*) INTO lobby_count FROM participations
     WHERE clue_id = clue_id_in AND status IN ('in_lobby','in_progress','completed');
    RETURN jsonb_build_object(
      'ok', false, 'reason', 'lobby_closed',
      'state', c.coop_state, 'current', lobby_count, 'target', c.min_participants
    );
  END IF;

  IF EXISTS (SELECT 1 FROM participations WHERE clue_id = clue_id_in AND user_id = uid) THEN
    SELECT count(*) INTO lobby_count FROM participations
     WHERE clue_id = clue_id_in AND status IN ('in_lobby','in_progress');
    RETURN jsonb_build_object(
      'ok', true, 'already', true,
      'state', c.coop_state, 'current', lobby_count, 'target', c.min_participants
    );
  END IF;

  INSERT INTO participations (clue_id, user_id, status)
  VALUES (clue_id_in, uid, 'in_lobby');

  SELECT count(*) INTO lobby_count FROM participations
   WHERE clue_id = clue_id_in AND status = 'in_lobby';

  -- 변경: idle → recruiting 전환 시 recruiting_started_at 기록
  IF c.coop_state = 'idle' THEN
    UPDATE clues
       SET coop_state            = 'recruiting',
           recruiting_started_at = now()
     WHERE id = clue_id_in;
    c.coop_state := 'recruiting';
  END IF;

  IF lobby_count >= c.min_participants THEN
    UPDATE clues
       SET coop_state       = 'started',
           lobby_started_at = now()
     WHERE id = clue_id_in;

    UPDATE participations
       SET status     = 'in_progress',
           started_at = COALESCE(started_at, now())
     WHERE clue_id = clue_id_in
       AND status   = 'in_lobby';

    was_started := true;
    c.coop_state := 'started';
  END IF;

  UPDATE clues
     SET current_participants = lobby_count
   WHERE id = clue_id_in;

  RETURN jsonb_build_object(
    'ok',      true,
    'state',   c.coop_state,
    'current', lobby_count,
    'target',  c.min_participants,
    'started', was_started
  );
END;
$$;

-- 3. expire_lobby_recruits RPC
-- 5분 단위 cron이 호출. recruiting 상태이고 lobby_window_minutes 초과한 클루를
-- cancelled로 전환 + in_lobby 참여자를 abandoned로.
-- 반환: 처리된 클루 수.
CREATE OR REPLACE FUNCTION public.expire_lobby_recruits()
RETURNS integer
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  expired_count integer := 0;
  c             record;
BEGIN
  FOR c IN
    SELECT id, lobby_window_minutes
      FROM clues
     WHERE coop_state = 'recruiting'
       AND recruiting_started_at IS NOT NULL
       AND recruiting_started_at + (lobby_window_minutes || ' minutes')::interval < now()
  LOOP
    UPDATE clues SET coop_state = 'cancelled' WHERE id = c.id;
    UPDATE participations
       SET status = 'abandoned',
           updated_at = now()
     WHERE clue_id = c.id
       AND status  = 'in_lobby';
    expired_count := expired_count + 1;
  END LOOP;
  RETURN expired_count;
END;
$$;

-- service_role / postgres만 호출 가능. anon/authenticated 차단.
REVOKE ALL ON FUNCTION public.expire_lobby_recruits() FROM PUBLIC, anon, authenticated;

-- 4. pg_cron 활성화 + 5분 단위 스케줄
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- 기존 동일 이름 job 제거 (멱등성)
SELECT cron.unschedule('expire_lobby_recruits')
  WHERE EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'expire_lobby_recruits');

-- 5분마다 실행
SELECT cron.schedule(
  'expire_lobby_recruits',
  '*/5 * * * *',
  $$SELECT public.expire_lobby_recruits()$$
);
