-- ============================================================================
-- 031 · Battle 게임 타입 확장 — 'tap'(서로 때리기), 'coin_grab'(동전 줍기)
-- ============================================================================
-- 028의 RPS 전용 배틀을 점수 기반 게임으로 일반화.
--
-- 모델: RPS의 "비동기 choice 제출 → 양측 도착 시 판정"을 그대로 사용.
--   - 'tap'      : 10초 탭 연사 → 탭 수를 choice로 제출 (0~150)
--   - 'coin_grab': 15초 동전 줍기 → 점수를 choice로 제출 (0~200)
--   판정: 숫자 비교, 높은 쪽 승. 동점 무승부 (환불).
--
-- vs CPU 점수 범위 (경제 보호 — 약한 CPU면 베팅 1.9배가 코인 발행기가 됨):
--   - tap: 55~85 (인간 상위권 60~100과 경쟁)
--   - coin_grab: 35~65 (실측 평균 ~50과 경쟁)
--
-- 알려진 한계: 점수는 클라이언트 제출 (client-authoritative).
--   완화: 물리적 상한 캡 + 추후 서버 검증(입력 이벤트 로그) 예정.
-- ============================================================================

ALTER TABLE public.battle_matches DROP CONSTRAINT IF EXISTS battle_game_type_check;
ALTER TABLE public.battle_matches ADD CONSTRAINT battle_game_type_check
  CHECK (game_type IN ('rps','tap','coin_grab'));

-- ============================================================================
-- battle_enqueue: 지원 게임 타입 확장 (그 외 로직 028과 동일)
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
BEGIN
  IF uid IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'auth_required');
  END IF;
  IF stake_coin_in < 10 OR stake_coin_in > 2000 THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'stake_out_of_range');
  END IF;
  IF game_type_in NOT IN ('rps','tap','coin_grab') THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'unsupported_game');
  END IF;

  -- 중복 큐 방지 — 본인의 queued/matched 매치 있으면 그것 반환
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

  -- 잔액 확인 + 베팅 차감
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

  -- 매칭 시도: 같은 stake+game_type queued인 다른 사용자
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
    UPDATE battle_matches
       SET opponent_id = uid,
           status      = 'matched',
           matched_at  = now()
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
-- battle_finish: 게임별 choice 검증 + 판정으로 일반화
-- ============================================================================
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
  IF m.status NOT IN ('matched') THEN
    RETURN jsonb_build_object(
      'ok', false, 'reason', 'invalid_status', 'status', m.status,
      'winner_id', m.winner_id, 'payout', m.payout_to_winner
    );
  END IF;
  IF uid <> m.challenger_id AND uid <> m.opponent_id THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'not_participant');
  END IF;

  -- 게임별 choice 검증
  IF m.game_type = 'rps' THEN
    IF my_choice_in NOT IN ('rock','paper','scissors') THEN
      RETURN jsonb_build_object('ok', false, 'reason', 'invalid_choice');
    END IF;
  ELSE
    -- 점수 게임: 0~cap 정수 문자열만 허용
    score_cap := CASE m.game_type WHEN 'tap' THEN 150 ELSE 200 END;
    IF my_choice_in !~ '^[0-9]{1,3}$' OR my_choice_in::integer > score_cap THEN
      RETURN jsonb_build_object('ok', false, 'reason', 'invalid_choice');
    END IF;
  END IF;

  -- 호출자 choice 등록
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

  -- vs CPU: opponent_choice 즉시 생성 (게임별)
  IF m.vs_cpu AND m.opponent_choice IS NULL THEN
    IF m.game_type = 'rps' THEN
      random_idx := (floor(random() * 3))::integer;
      op_choice := CASE random_idx WHEN 0 THEN 'rock' WHEN 1 THEN 'paper' ELSE 'scissors' END;
    ELSIF m.game_type = 'tap' THEN
      op_choice := (55 + floor(random() * 31))::integer::text;        -- 55~85
    ELSE -- coin_grab
      op_choice := (35 + floor(random() * 31))::integer::text;        -- 35~65
    END IF;
    UPDATE battle_matches SET opponent_choice = op_choice WHERE id = m.id;
    m.opponent_choice := op_choice;
  END IF;

  -- 양측 choice 다 있으면 결과 확정
  IF m.challenger_choice IS NULL OR m.opponent_choice IS NULL THEN
    RETURN jsonb_build_object(
      'ok', true, 'status', 'awaiting_opponent',
      'my_choice', my_choice_in
    );
  END IF;

  ch_choice := m.challenger_choice;
  op_choice := m.opponent_choice;

  -- 게임별 판정
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
    -- 점수 비교: 높은 쪽 승
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

  -- 승부 결정 — 보상 계산 (028과 동일)
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
