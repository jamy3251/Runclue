-- ============================================================================
-- 029 · versus 모드 (#23) — N명 경쟁, 1등 풀 독식
-- ============================================================================
-- 게임 모드 추가:
--   solo   — 혼자, 분배 모드 그대로 (first_come/rank/random/all)
--   coop   — 함께 모집, coop_split 분배 (N등분)
--   versus — N명 모집, 1등 독식 (versus_first)
--
-- versus의 lobby 메커니즘은 coop와 동일 — min_participants 모이면 자동 시작.
-- join_coop_clue를 game_mode IN ('coop','versus')에서 동작하도록 일반화.
--
-- 클루 종료 시점:
--   versus는 첫 번째 완료자가 풀 독식 → 그 시점에 lobby 다른 참여자 abandoned 처리?
--   MVP는 단순: 모든 참여자가 끝까지 풀 수 있음. 1등만 보상, 나머지 0.
--   이건 분배 로직에서 처리 (participation_service의 versus_first 케이스).
-- ============================================================================

-- 1. clue.game_mode CHECK 확장
ALTER TABLE public.clues DROP CONSTRAINT IF EXISTS clues_game_mode_check;
ALTER TABLE public.clues ADD  CONSTRAINT clues_game_mode_check
  CHECK (game_mode IN ('solo','coop','versus'));

-- 2. join_coop_clue를 game_mode IN ('coop','versus')에서 동작하도록 일반화
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
  -- coop 또는 versus 둘 다 lobby 모집 동일
  IF c.game_mode NOT IN ('coop','versus') THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'not_lobby_mode');
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
    RETURN jsonb_build_object('ok', false, 'reason', 'lobby_closed',
      'state', c.coop_state, 'current', lobby_count, 'target', c.min_participants);
  END IF;

  IF EXISTS (SELECT 1 FROM participations WHERE clue_id = clue_id_in AND user_id = uid) THEN
    SELECT count(*) INTO lobby_count FROM participations
     WHERE clue_id = clue_id_in AND status IN ('in_lobby','in_progress');
    RETURN jsonb_build_object('ok', true, 'already', true,
      'state', c.coop_state, 'current', lobby_count, 'target', c.min_participants);
  END IF;

  INSERT INTO participations (clue_id, user_id, status)
  VALUES (clue_id_in, uid, 'in_lobby');

  SELECT count(*) INTO lobby_count FROM participations
   WHERE clue_id = clue_id_in AND status = 'in_lobby';

  IF c.coop_state = 'idle' THEN
    UPDATE clues SET coop_state = 'recruiting', recruiting_started_at = now()
     WHERE id = clue_id_in;
    c.coop_state := 'recruiting';
  END IF;

  IF lobby_count >= c.min_participants THEN
    UPDATE clues SET coop_state = 'started', lobby_started_at = now()
     WHERE id = clue_id_in;
    UPDATE participations
       SET status = 'in_progress', started_at = COALESCE(started_at, now())
     WHERE clue_id = clue_id_in AND status = 'in_lobby';
    was_started := true;
    c.coop_state := 'started';
  END IF;

  UPDATE clues SET current_participants = lobby_count WHERE id = clue_id_in;

  RETURN jsonb_build_object('ok', true, 'state', c.coop_state,
    'current', lobby_count, 'target', c.min_participants,
    'started', was_started, 'game_mode', c.game_mode);
END;
$$;
