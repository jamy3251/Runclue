-- ============================================================================
-- 036 · Battle 오셀로 — 턴제 비동기 PvP (#24 4번째 게임)
-- ============================================================================
-- 모델: battle_matches.game_state(jsonb)에 보드 저장, battle_move RPC로 진행.
--   game_state: {board: [36칸 0/1/2], turn: 1|2, finished: bool}
--   challenger = 1(흑, 선공), opponent = 2(백)
--
-- 신뢰 모델 (기존 점수 게임과 동일한 클라 합의 수준):
--   - 서버 검증: 참가자/턴 소유권/보드 형식/돌 수 비감소
--   - 오셀로 풀 룰은 양쪽 클라이언트가 같은 엔진으로 검증
--   - 종료 판정·분배는 서버가 보드를 직접 세서 수행 (조작 불가)
--
-- vs CPU: 클라가 로컬 전판 플레이 후 최종 보드를 finished=true로 1회 제출.
-- PvP: 매 수마다 제출, 상대는 폴링으로 수신.
-- ============================================================================

ALTER TABLE public.battle_matches
  ADD COLUMN IF NOT EXISTS game_state jsonb;

ALTER TABLE public.battle_matches DROP CONSTRAINT IF EXISTS battle_game_type_check;
ALTER TABLE public.battle_matches ADD CONSTRAINT battle_game_type_check
  CHECK (game_type IN ('rps','tap','coin_grab','othello'));

-- ============================================================================
-- battle_enqueue: othello 허용 + PvP 매칭 성사 시 보드 초기화
-- ============================================================================
CREATE OR REPLACE FUNCTION public.battle_enqueue(
  stake_coin_in integer,
  game_type_in  text DEFAULT 'rps',
  clue_id_in    uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  uid           uuid := auth.uid();
  user_bal      integer;
  existing      battle_matches%ROWTYPE;
  new_match_id  uuid;
  init_state    jsonb;
BEGIN
  IF uid IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'auth_required');
  END IF;
  IF stake_coin_in < 10 OR stake_coin_in > 2000 THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'stake_out_of_range');
  END IF;
  IF game_type_in NOT IN ('rps','tap','coin_grab','othello') THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'unsupported_game');
  END IF;

  SELECT * INTO existing FROM battle_matches
   WHERE (challenger_id = uid OR opponent_id = uid)
     AND status IN ('queued','matched')
   ORDER BY created_at DESC LIMIT 1;
  IF FOUND THEN
    RETURN jsonb_build_object(
      'ok', true, 'already_in_queue', true,
      'match_id', existing.id, 'status', existing.status,
      'opponent_id', existing.opponent_id, 'vs_cpu', existing.vs_cpu,
      'game', existing.game_type
    );
  END IF;

  SELECT coin_balance INTO user_bal FROM profiles WHERE id = uid FOR UPDATE;
  IF user_bal IS NULL OR user_bal < stake_coin_in THEN
    RETURN jsonb_build_object(
      'ok', false, 'reason', 'insufficient_coin',
      'have', COALESCE(user_bal, 0), 'need', stake_coin_in
    );
  END IF;

  UPDATE profiles SET coin_balance = coin_balance - stake_coin_in
   WHERE id = uid RETURNING coin_balance INTO user_bal;
  INSERT INTO coin_ledger (user_id, delta, reason, source_id, balance_after)
  VALUES (uid, -stake_coin_in, 'battle_stake', game_type_in, user_bal);

  SELECT * INTO existing FROM battle_matches
   WHERE game_type = game_type_in
     AND stake_coin = stake_coin_in
     AND status = 'queued'
     AND challenger_id <> uid
     AND vs_cpu = false
   ORDER BY created_at ASC
   FOR UPDATE SKIP LOCKED
   LIMIT 1;

  IF FOUND THEN
    -- 오셀로 PvP: 초기 보드 세팅 (중앙 4칸, 흑=challenger 선공)
    IF game_type_in = 'othello' THEN
      init_state := jsonb_build_object(
        'board', (
          SELECT jsonb_agg(CASE
            WHEN i = 14 OR i = 21 THEN 2   -- (2,2),(3,3) 백
            WHEN i = 15 OR i = 20 THEN 1   -- (2,3),(3,2) 흑
            ELSE 0 END)
          FROM generate_series(0, 35) AS i
        ),
        'turn', 1,
        'finished', false
      );
    END IF;

    UPDATE battle_matches
       SET opponent_id = uid,
           status      = 'matched',
           matched_at  = now(),
           game_state  = COALESCE(init_state, game_state)
     WHERE id = existing.id;
    RETURN jsonb_build_object(
      'ok', true, 'match_id', existing.id, 'status', 'matched',
      'opponent_id', existing.challenger_id, 'vs_cpu', false,
      'stake', stake_coin_in, 'game', game_type_in,
      'role', 'opponent'
    );
  END IF;

  INSERT INTO battle_matches (clue_id, game_type, stake_coin, challenger_id, status)
  VALUES (clue_id_in, game_type_in, stake_coin_in, uid, 'queued')
  RETURNING id INTO new_match_id;

  RETURN jsonb_build_object(
    'ok', true, 'match_id', new_match_id, 'status', 'queued',
    'stake', stake_coin_in, 'game', game_type_in, 'role', 'challenger'
  );
END;
$$;

-- ============================================================================
-- battle_move: 오셀로 전용 — 수 제출 + 종료 시 서버 판정·분배
-- ============================================================================
CREATE OR REPLACE FUNCTION public.battle_move(
  match_id_in uuid,
  state_in    jsonb
)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  uid          uuid := auth.uid();
  m            battle_matches%ROWTYPE;
  my_role      integer;          -- challenger=1, opponent=2
  old_board    jsonb;
  new_board    jsonb;
  new_turn     integer;
  is_finished  boolean;
  i            integer;
  v            integer;
  old_stones   integer := 0;
  new_stones   integer := 0;
  cnt_ch       integer := 0;     -- 흑(challenger) 돌 수
  cnt_op       integer := 0;     -- 백(opponent) 돌 수
  winner_v     uuid;
  payout_v     integer;
  fee_v        integer;
BEGIN
  IF uid IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'auth_required');
  END IF;

  SELECT * INTO m FROM battle_matches WHERE id = match_id_in FOR UPDATE;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'match_not_found');
  END IF;
  IF m.game_type <> 'othello' THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'not_othello');
  END IF;
  IF m.status <> 'matched' THEN
    RETURN jsonb_build_object(
      'ok', false, 'reason', 'invalid_status', 'status', m.status,
      'winner_id', m.winner_id, 'payout', m.payout_to_winner
    );
  END IF;
  IF uid = m.challenger_id THEN my_role := 1;
  ELSIF uid = m.opponent_id THEN my_role := 2;
  ELSE
    RETURN jsonb_build_object('ok', false, 'reason', 'not_participant');
  END IF;

  -- 보드 형식 검증: 36칸, 값 0/1/2
  new_board := state_in->'board';
  IF new_board IS NULL OR jsonb_array_length(new_board) <> 36 THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'invalid_board');
  END IF;
  FOR i IN 0..35 LOOP
    v := (new_board->>i)::integer;
    IF v NOT IN (0, 1, 2) THEN
      RETURN jsonb_build_object('ok', false, 'reason', 'invalid_board');
    END IF;
    IF v = 1 THEN cnt_ch := cnt_ch + 1; END IF;
    IF v = 2 THEN cnt_op := cnt_op + 1; END IF;
    IF v <> 0 THEN new_stones := new_stones + 1; END IF;
  END LOOP;

  new_turn    := COALESCE((state_in->>'turn')::integer, 0);
  is_finished := COALESCE((state_in->>'finished')::boolean, false);

  IF m.vs_cpu THEN
    -- vs CPU: challenger가 로컬 전판 후 최종 보드만 제출
    IF my_role <> 1 THEN
      RETURN jsonb_build_object('ok', false, 'reason', 'not_participant');
    END IF;
    IF NOT is_finished THEN
      RETURN jsonb_build_object('ok', false, 'reason', 'cpu_requires_finished');
    END IF;
  ELSE
    -- PvP: 턴 소유권 + 돌 수 비감소 검증
    old_board := m.game_state->'board';
    IF old_board IS NULL THEN
      RETURN jsonb_build_object('ok', false, 'reason', 'state_not_initialized');
    END IF;
    IF COALESCE((m.game_state->>'turn')::integer, 0) <> my_role THEN
      RETURN jsonb_build_object('ok', false, 'reason', 'not_your_turn');
    END IF;
    FOR i IN 0..35 LOOP
      IF (old_board->>i)::integer <> 0 THEN old_stones := old_stones + 1; END IF;
    END LOOP;
    -- 정상 수는 돌 +1, 패스는 동일 (턴만 넘김)
    IF new_stones < old_stones OR new_stones > old_stones + 1 THEN
      RETURN jsonb_build_object('ok', false, 'reason', 'invalid_move');
    END IF;
    IF NOT is_finished AND new_turn <> (3 - my_role) THEN
      RETURN jsonb_build_object('ok', false, 'reason', 'invalid_turn');
    END IF;
  END IF;

  UPDATE battle_matches SET game_state = state_in WHERE id = m.id;

  IF NOT is_finished THEN
    RETURN jsonb_build_object('ok', true, 'status', 'ongoing');
  END IF;

  -- ── 종료: 서버가 보드 돌 수로 직접 판정 ──
  IF cnt_ch = cnt_op THEN
    -- 무승부: 양측 환불
    UPDATE profiles SET coin_balance = coin_balance + m.stake_coin
     WHERE id = m.challenger_id;
    INSERT INTO coin_ledger (user_id, delta, reason, source_id, balance_after)
    SELECT m.challenger_id, m.stake_coin, 'battle_refund', m.id::text, coin_balance
      FROM profiles WHERE id = m.challenger_id;
    IF NOT m.vs_cpu AND m.opponent_id IS NOT NULL THEN
      UPDATE profiles SET coin_balance = coin_balance + m.stake_coin
       WHERE id = m.opponent_id;
      INSERT INTO coin_ledger (user_id, delta, reason, source_id, balance_after)
      SELECT m.opponent_id, m.stake_coin, 'battle_refund', m.id::text, coin_balance
        FROM profiles WHERE id = m.opponent_id;
    END IF;
    UPDATE battle_matches
       SET status = 'draw', finished_at = now(),
           challenger_choice = cnt_ch::text, opponent_choice = cnt_op::text
     WHERE id = m.id;
    RETURN jsonb_build_object(
      'ok', true, 'status', 'draw',
      'my_count', CASE WHEN my_role = 1 THEN cnt_ch ELSE cnt_op END,
      'opp_count', CASE WHEN my_role = 1 THEN cnt_op ELSE cnt_ch END,
      'refund', m.stake_coin
    );
  END IF;

  winner_v := CASE WHEN cnt_ch > cnt_op THEN m.challenger_id ELSE m.opponent_id END;

  IF m.vs_cpu THEN
    payout_v := (m.stake_coin::bigint * 19 / 10)::integer;
    fee_v    := m.stake_coin - (m.stake_coin::bigint * 9 / 10)::integer;
    IF winner_v IS NULL THEN  -- CPU(opponent_id NULL) 승
      payout_v := 0;
      fee_v    := 0;
    END IF;
  ELSE
    payout_v := (m.stake_coin::bigint * 2 * 95 / 100)::integer;
    fee_v    := m.stake_coin * 2 - payout_v;
  END IF;

  IF winner_v IS NOT NULL AND payout_v > 0 THEN
    UPDATE profiles SET coin_balance = coin_balance + payout_v
     WHERE id = winner_v;
    INSERT INTO coin_ledger (user_id, delta, reason, source_id, balance_after)
    SELECT winner_v, payout_v, 'battle_win', m.id::text, coin_balance
      FROM profiles WHERE id = winner_v;
  END IF;

  UPDATE battle_matches
     SET status = 'finished', finished_at = now(),
         challenger_choice = cnt_ch::text, opponent_choice = cnt_op::text,
         winner_id = winner_v, payout_to_winner = payout_v, fee_coin = fee_v
   WHERE id = m.id;

  RETURN jsonb_build_object(
    'ok', true, 'status', 'finished',
    'winner', CASE WHEN winner_v = uid THEN 'me'
                   WHEN winner_v IS NULL THEN 'cpu'
                   ELSE 'opponent' END,
    'my_count', CASE WHEN my_role = 1 THEN cnt_ch ELSE cnt_op END,
    'opp_count', CASE WHEN my_role = 1 THEN cnt_op ELSE cnt_ch END,
    'payout', CASE WHEN winner_v = uid THEN payout_v ELSE 0 END,
    'fee', fee_v
  );
END;
$$;

REVOKE EXECUTE ON FUNCTION public.battle_move(uuid, jsonb) FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION public.battle_move(uuid, jsonb) TO authenticated;

-- battle_finish: 오셀로는 battle_move 경로 강제
CREATE OR REPLACE FUNCTION public.battle_finish(
  match_id_in   uuid,
  my_choice_in  text
)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  uid             uuid := auth.uid();
  m               battle_matches%ROWTYPE;
  ch_choice       text;
  op_choice       text;
  winner_v        uuid;
  loser_v         uuid;
  payout_v        integer;
  fee_v           integer;
  is_draw         boolean := false;
  random_idx      integer;
  score_cap       integer;
BEGIN
  IF uid IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'auth_required');
  END IF;

  SELECT * INTO m FROM battle_matches WHERE id = match_id_in FOR UPDATE;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'match_not_found');
  END IF;
  IF m.game_type = 'othello' THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'use_battle_move');
  END IF;
  IF m.status NOT IN ('matched') THEN
    RETURN jsonb_build_object(
      'ok', false, 'reason', 'invalid_status', 'status', m.status,
      'winner_id', m.winner_id, 'payout', m.payout_to_winner
    );
  END IF;
  IF uid <> m.challenger_id AND uid <> m.opponent_id THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'not_participant');
  END IF;

  IF m.game_type = 'rps' THEN
    IF my_choice_in NOT IN ('rock','paper','scissors') THEN
      RETURN jsonb_build_object('ok', false, 'reason', 'invalid_choice');
    END IF;
  ELSE
    score_cap := CASE m.game_type WHEN 'tap' THEN 150 ELSE 200 END;
    IF my_choice_in !~ '^[0-9]{1,3}$' OR my_choice_in::integer > score_cap THEN
      RETURN jsonb_build_object('ok', false, 'reason', 'invalid_choice');
    END IF;
  END IF;

  IF uid = m.challenger_id THEN
    IF m.challenger_choice IS NOT NULL THEN
      RETURN jsonb_build_object('ok', false, 'reason', 'already_chose');
    END IF;
    UPDATE battle_matches SET challenger_choice = my_choice_in WHERE id = m.id;
    m.challenger_choice := my_choice_in;
  ELSE
    IF m.opponent_choice IS NOT NULL THEN
      RETURN jsonb_build_object('ok', false, 'reason', 'already_chose');
    END IF;
    UPDATE battle_matches SET opponent_choice = my_choice_in WHERE id = m.id;
    m.opponent_choice := my_choice_in;
  END IF;

  IF m.vs_cpu AND m.opponent_choice IS NULL THEN
    IF m.game_type = 'rps' THEN
      random_idx := (floor(random() * 3))::integer;
      op_choice := CASE random_idx WHEN 0 THEN 'rock' WHEN 1 THEN 'paper' ELSE 'scissors' END;
    ELSIF m.game_type = 'tap' THEN
      op_choice := (55 + floor(random() * 31))::integer::text;
    ELSE
      op_choice := (35 + floor(random() * 31))::integer::text;
    END IF;
    UPDATE battle_matches SET opponent_choice = op_choice WHERE id = m.id;
    m.opponent_choice := op_choice;
  END IF;

  IF m.challenger_choice IS NULL OR m.opponent_choice IS NULL THEN
    RETURN jsonb_build_object(
      'ok', true, 'status', 'awaiting_opponent',
      'my_choice', my_choice_in
    );
  END IF;

  ch_choice := m.challenger_choice;
  op_choice := m.opponent_choice;

  IF m.game_type = 'rps' THEN
    IF ch_choice = op_choice THEN
      is_draw := true;
    ELSIF (ch_choice = 'rock' AND op_choice = 'scissors')
       OR (ch_choice = 'paper' AND op_choice = 'rock')
       OR (ch_choice = 'scissors' AND op_choice = 'paper') THEN
      winner_v := m.challenger_id;
      loser_v  := m.opponent_id;
    ELSE
      winner_v := m.opponent_id;
      loser_v  := m.challenger_id;
    END IF;
  ELSE
    IF ch_choice::integer = op_choice::integer THEN
      is_draw := true;
    ELSIF ch_choice::integer > op_choice::integer THEN
      winner_v := m.challenger_id;
      loser_v  := m.opponent_id;
    ELSE
      winner_v := m.opponent_id;
      loser_v  := m.challenger_id;
    END IF;
  END IF;

  IF is_draw THEN
    UPDATE profiles SET coin_balance = coin_balance + m.stake_coin
     WHERE id = m.challenger_id;
    INSERT INTO coin_ledger (user_id, delta, reason, source_id, balance_after)
    SELECT m.challenger_id, m.stake_coin, 'battle_refund', m.id::text, coin_balance
      FROM profiles WHERE id = m.challenger_id;

    IF NOT m.vs_cpu AND m.opponent_id IS NOT NULL THEN
      UPDATE profiles SET coin_balance = coin_balance + m.stake_coin
       WHERE id = m.opponent_id;
      INSERT INTO coin_ledger (user_id, delta, reason, source_id, balance_after)
      SELECT m.opponent_id, m.stake_coin, 'battle_refund', m.id::text, coin_balance
        FROM profiles WHERE id = m.opponent_id;
    END IF;

    UPDATE battle_matches
       SET status = 'draw', finished_at = now(),
           challenger_choice = ch_choice, opponent_choice = op_choice
     WHERE id = m.id;
    RETURN jsonb_build_object(
      'ok', true, 'status', 'draw',
      'my_choice', my_choice_in, 'opp_choice',
      (CASE WHEN uid = m.challenger_id THEN op_choice ELSE ch_choice END),
      'refund', m.stake_coin
    );
  END IF;

  IF m.vs_cpu THEN
    payout_v := (m.stake_coin::bigint * 19 / 10)::integer;
    fee_v    := m.stake_coin - (m.stake_coin::bigint * 9 / 10)::integer;
    IF winner_v IS NULL THEN
      payout_v := 0;
      fee_v    := 0;
    END IF;
  ELSE
    payout_v := (m.stake_coin::bigint * 2 * 95 / 100)::integer;
    fee_v    := m.stake_coin * 2 - payout_v;
  END IF;

  IF winner_v IS NOT NULL AND payout_v > 0 THEN
    UPDATE profiles SET coin_balance = coin_balance + payout_v
     WHERE id = winner_v;
    INSERT INTO coin_ledger (user_id, delta, reason, source_id, balance_after)
    SELECT winner_v, payout_v, 'battle_win', m.id::text, coin_balance
      FROM profiles WHERE id = winner_v;
  END IF;

  UPDATE battle_matches
     SET status = 'finished', finished_at = now(),
         challenger_choice = ch_choice, opponent_choice = op_choice,
         winner_id = winner_v, payout_to_winner = payout_v, fee_coin = fee_v
   WHERE id = m.id;

  RETURN jsonb_build_object(
    'ok', true, 'status', 'finished',
    'my_choice', my_choice_in,
    'opp_choice', (CASE WHEN uid = m.challenger_id THEN op_choice ELSE ch_choice END),
    'winner', CASE WHEN winner_v = uid THEN 'me'
                   WHEN winner_v IS NULL THEN 'cpu'
                   ELSE 'opponent' END,
    'payout', CASE WHEN winner_v = uid THEN payout_v ELSE 0 END,
    'fee', fee_v
  );
END;
$$;
