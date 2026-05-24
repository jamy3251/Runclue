-- ============================================================================
-- 028 · Battle 보상 모드 (#22) — 코인 베팅 1v1 미니게임
-- ============================================================================
-- 사용자가 코인을 베팅하고 다른 사용자와 미니게임으로 경쟁.
-- 매칭 안 되면 CPU와 자동 매칭 (5분 후 cron).
--
-- 분배: 이긴 쪽이 (stake × 2 × 0.95) 코인 획득, 진 쪽은 0.
--   - 수수료 5% (코인 단위 — 플랫폼 매출).
--   - 무승부면 둘 다 stake 환불.
--   - CPU vs 사용자 시 CPU는 stake 안 냄 → 이기면 1.0× (stake 그대로 회수 + ?)
--     단순화: vs CPU 모드에선 이기면 stake×1.9, 지면 stake 잃음. 무승부 환불.
--
-- 베팅액 범위: 10~2000 코인.
-- 게임: 'rps' (MVP). 추후 'tap', 'coin_grab' 등 확장.
--
-- 흐름:
--   1. battle_enqueue(clue_id?, stake, game_type)
--      → 같은 stake+game_type의 queued row 있으면 즉시 매칭, 없으면 queued
--   2. battle_cpu_fallback() cron이 5분 이상 queued인 매치를 CPU로 전환
--   3. battle_finish(match_id, my_choice, opponent_choice?) — 결과 확정
--      vs CPU: opponent_choice는 RPC가 무작위로 생성
--      vs 사용자: 양측 모두 호출 (둘 다 호출되면 확정)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.battle_matches (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  clue_id         uuid REFERENCES public.clues(id) ON DELETE SET NULL,
  game_type       text NOT NULL,
  stake_coin      integer NOT NULL,
  challenger_id   uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  opponent_id     uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  vs_cpu          boolean NOT NULL DEFAULT false,
  status          text NOT NULL DEFAULT 'queued',
  challenger_choice text,
  opponent_choice   text,
  winner_id       uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  payout_to_winner integer NOT NULL DEFAULT 0,
  fee_coin        integer NOT NULL DEFAULT 0,
  created_at      timestamptz NOT NULL DEFAULT now(),
  matched_at      timestamptz,
  finished_at     timestamptz,
  CONSTRAINT battle_status_check
    CHECK (status IN ('queued','matched','finished','cancelled','draw')),
  CONSTRAINT battle_stake_range CHECK (stake_coin BETWEEN 10 AND 2000),
  CONSTRAINT battle_game_type_check CHECK (game_type IN ('rps'))
);

CREATE INDEX IF NOT EXISTS battle_queue_idx
  ON public.battle_matches (game_type, stake_coin, created_at)
  WHERE status = 'queued';
CREATE INDEX IF NOT EXISTS battle_user_idx
  ON public.battle_matches (challenger_id, created_at DESC);
CREATE INDEX IF NOT EXISTS battle_opponent_idx
  ON public.battle_matches (opponent_id, created_at DESC);

ALTER TABLE public.battle_matches ENABLE ROW LEVEL SECURITY;

-- 본인이 challenger 또는 opponent인 row만 조회
DROP POLICY IF EXISTS "battle_participant_select" ON public.battle_matches;
CREATE POLICY "battle_participant_select" ON public.battle_matches
  FOR SELECT TO authenticated
   USING (challenger_id = auth.uid() OR opponent_id = auth.uid());

DROP POLICY IF EXISTS "battle_admin_all" ON public.battle_matches;
CREATE POLICY "battle_admin_all" ON public.battle_matches
  FOR ALL TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

-- ============================================================================
-- battle_enqueue: 큐 진입 + 즉시 매칭 시도
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
  grant_result  jsonb;
BEGIN
  IF uid IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'auth_required');
  END IF;
  IF stake_coin_in < 10 OR stake_coin_in > 2000 THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'stake_out_of_range');
  END IF;
  IF game_type_in NOT IN ('rps') THEN
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
      'opponent_id', existing.opponent_id, 'vs_cpu', existing.vs_cpu
    );
  END IF;

  -- 잔액 확인 + 베팅 차감 (grant_coin via signed delta)
  SELECT coin_balance INTO user_bal FROM profiles WHERE id = uid FOR UPDATE;
  IF user_bal IS NULL OR user_bal < stake_coin_in THEN
    RETURN jsonb_build_object(
      'ok', false, 'reason', 'insufficient_coin',
      'have', COALESCE(user_bal, 0), 'need', stake_coin_in
    );
  END IF;

  -- 베팅 차감 (음수 grant_coin 호출) — multiplier 적용 X, 정액 차감
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
    -- 즉시 매칭
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

  -- 큐 진입
  INSERT INTO battle_matches (clue_id, game_type, stake_coin, challenger_id, status)
  VALUES (clue_id_in, game_type_in, stake_coin_in, uid, 'queued')
  RETURNING id INTO new_match_id;

  RETURN jsonb_build_object(
    'ok', true, 'match_id', new_match_id, 'status', 'queued',
    'stake', stake_coin_in, 'game', game_type_in, 'role', 'challenger'
  );
END;
$$;

REVOKE EXECUTE ON FUNCTION public.battle_enqueue(integer, text, uuid) FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION public.battle_enqueue(integer, text, uuid) TO authenticated;

-- ============================================================================
-- battle_finish: 결과 확정 + 보상 분배
-- ============================================================================
-- RPS 룰: 'rock'/'paper'/'scissors'. 같으면 무승부.
-- vs CPU: opponent_choice 자동 무작위 생성.
-- 양측 vs 사용자: 첫 호출자가 자기 choice 등록 (status='matched'), 두 번째 호출자가
--   양측 choice 비교하여 finished 처리.
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
  grant_result    jsonb;
  random_idx      integer;
BEGIN
  IF uid IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'auth_required');
  END IF;
  IF my_choice_in NOT IN ('rock','paper','scissors') THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'invalid_choice');
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

  -- vs CPU: opponent_choice 즉시 무작위 생성
  IF m.vs_cpu AND m.opponent_choice IS NULL THEN
    random_idx := (floor(random() * 3))::integer;
    op_choice := CASE random_idx WHEN 0 THEN 'rock' WHEN 1 THEN 'paper' ELSE 'scissors' END;
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

  -- RPS 판정
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

  IF is_draw THEN
    -- 무승부: 양측 stake 환불 (vs CPU도 동일 — challenger만 환불)
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

  -- 승부 결정 — 보상 계산
  IF m.vs_cpu THEN
    -- vs CPU: 이기면 stake × 1.9 받음 (5% 수수료, CPU 베팅 0)
    payout_v := (m.stake_coin::bigint * 19 / 10)::integer;
    fee_v    := m.stake_coin - (m.stake_coin::bigint * 9 / 10)::integer; -- 5% of stake
    IF winner_v IS NULL THEN
      -- CPU 승 — challenger는 stake 잃음
      payout_v := 0;
      fee_v    := 0;
    END IF;
  ELSE
    -- 사용자 vs 사용자: 이긴 쪽이 stake × 1.9 받음 (5% fee)
    payout_v := (m.stake_coin::bigint * 2 * 95 / 100)::integer;
    fee_v    := m.stake_coin * 2 - payout_v;
  END IF;

  IF winner_v IS NOT NULL AND payout_v > 0 THEN
    -- 직접 잔액 추가 + ledger (grant_coin은 ±200 한도라 큰 베팅 처리 불가 → 직접)
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

REVOKE EXECUTE ON FUNCTION public.battle_finish(uuid, text) FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION public.battle_finish(uuid, text) TO authenticated;

-- ============================================================================
-- battle_cpu_fallback: queued 5분 초과 매치를 CPU로 전환 (cron이 호출)
-- ============================================================================
CREATE OR REPLACE FUNCTION public.battle_cpu_fallback()
RETURNS integer
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  cnt integer := 0;
  m   record;
BEGIN
  FOR m IN
    SELECT id FROM battle_matches
     WHERE status = 'queued'
       AND created_at + INTERVAL '5 minutes' < now()
  LOOP
    UPDATE battle_matches
       SET vs_cpu = true,
           status = 'matched',
           matched_at = now()
     WHERE id = m.id;
    cnt := cnt + 1;
  END LOOP;
  RETURN cnt;
END;
$$;

REVOKE ALL ON FUNCTION public.battle_cpu_fallback() FROM PUBLIC, anon, authenticated;

-- ============================================================================
-- battle_cancel: 본인 queued 매치 취소 + stake 환불
-- ============================================================================
CREATE OR REPLACE FUNCTION public.battle_cancel(match_id_in uuid)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  uid uuid := auth.uid();
  m   battle_matches%ROWTYPE;
BEGIN
  IF uid IS NULL THEN RETURN jsonb_build_object('ok', false, 'reason', 'auth_required'); END IF;
  SELECT * INTO m FROM battle_matches WHERE id = match_id_in FOR UPDATE;
  IF NOT FOUND THEN RETURN jsonb_build_object('ok', false, 'reason', 'not_found'); END IF;
  IF m.challenger_id <> uid THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'not_challenger');
  END IF;
  IF m.status <> 'queued' THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'not_queued', 'status', m.status);
  END IF;
  UPDATE battle_matches SET status = 'cancelled', finished_at = now()
   WHERE id = m.id;
  UPDATE profiles SET coin_balance = coin_balance + m.stake_coin
   WHERE id = uid;
  INSERT INTO coin_ledger (user_id, delta, reason, source_id, balance_after)
  SELECT uid, m.stake_coin, 'battle_refund', m.id::text, coin_balance
    FROM profiles WHERE id = uid;
  RETURN jsonb_build_object('ok', true, 'refund', m.stake_coin);
END;
$$;

REVOKE EXECUTE ON FUNCTION public.battle_cancel(uuid) FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION public.battle_cancel(uuid) TO authenticated;
