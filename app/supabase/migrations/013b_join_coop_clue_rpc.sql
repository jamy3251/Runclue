-- ============================================================================
-- 013b · RPC join_coop_clue
-- ============================================================================
-- 사용자가 coop 클루의 lobby에 참여 → 임계값 도달 시 자동 시작.
--
-- 동작:
--   1. clue 검증 (coop · active · 만료 전 · 본인 클루 아님)
--   2. 이미 참여 중이면 idempotent — 현재 상태만 반환
--   3. participations INSERT (status='in_lobby')
--   4. lobby 인원 카운트 → coop_state='recruiting'으로 전환
--   5. 카운트 ≥ min_participants → coop_state='started' + 모든 in_lobby → in_progress
--      + lobby_started_at=now() + 본 클루 started_at은 첫 사용자가 활동 시작 시 갱신
--
-- 반환: { state, current, target, started: bool }
-- ============================================================================

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
    -- 이미 시작/취소/완료
    SELECT count(*) INTO lobby_count FROM participations
     WHERE clue_id = clue_id_in AND status IN ('in_lobby','in_progress','completed');
    RETURN jsonb_build_object(
      'ok', false, 'reason', 'lobby_closed',
      'state', c.coop_state, 'current', lobby_count, 'target', c.min_participants
    );
  END IF;

  -- 이미 참여 중인지 확인 (idempotent)
  IF EXISTS (SELECT 1 FROM participations WHERE clue_id = clue_id_in AND user_id = uid) THEN
    SELECT count(*) INTO lobby_count FROM participations
     WHERE clue_id = clue_id_in AND status IN ('in_lobby','in_progress');
    RETURN jsonb_build_object(
      'ok', true, 'already', true,
      'state', c.coop_state, 'current', lobby_count, 'target', c.min_participants
    );
  END IF;

  -- 1. lobby에 추가
  INSERT INTO participations (clue_id, user_id, status)
  VALUES (clue_id_in, uid, 'in_lobby');

  -- 2. 카운트
  SELECT count(*) INTO lobby_count FROM participations
   WHERE clue_id = clue_id_in AND status = 'in_lobby';

  -- 3. recruiting 상태로 (첫 lobby 진입 시)
  IF c.coop_state = 'idle' THEN
    UPDATE clues SET coop_state = 'recruiting' WHERE id = clue_id_in;
    c.coop_state := 'recruiting';
  END IF;

  -- 4. 임계값 도달 시 자동 시작
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

  -- 5. current_participants 동기화
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

GRANT EXECUTE ON FUNCTION public.join_coop_clue(uuid) TO authenticated;
