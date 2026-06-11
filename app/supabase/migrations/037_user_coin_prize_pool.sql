-- ============================================================================
-- 037 · 유저 코인 상금 풀 — 자기 코인을 걸어 클루 상금 만들기
-- ============================================================================
-- 기존: 보상 풀은 사장 토스 충전(KRW, reward_pool_net)만 가능.
-- 추가: 클루 생성자가 자기 "코인"을 결제해 상금 풀(reward_pool_coin)을 만든다.
--       1등 완료자(rank=1 또는 최초 완료자)가 전액 수령 — 1등 독식.
--
-- 경제 가드:
--   - 무료 재화(코인)만 — 다이아(유료)는 사행성 이슈로 금지
--   - 1회 펀딩 10~5,000 코인, 생성자 본인 클루만
--   - 수령은 서버가 완료/순위를 직접 검증, 멱등 (pool 0으로 전환)
-- ============================================================================

ALTER TABLE public.clues
  ADD COLUMN IF NOT EXISTS reward_pool_coin integer NOT NULL DEFAULT 0;

ALTER TABLE public.clues DROP CONSTRAINT IF EXISTS clues_reward_pool_coin_check;
ALTER TABLE public.clues ADD CONSTRAINT clues_reward_pool_coin_check
  CHECK (reward_pool_coin >= 0);

-- ============================================================================
-- fund_clue_pool_coin: 생성자가 자기 코인을 상금 풀로 결제
-- ============================================================================
CREATE OR REPLACE FUNCTION public.fund_clue_pool_coin(
  clue_id_in uuid,
  amount_in  integer
)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  uid      uuid := auth.uid();
  c        clues%ROWTYPE;
  new_bal  integer;
  new_pool integer;
BEGIN
  IF uid IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'auth_required');
  END IF;
  IF amount_in < 10 OR amount_in > 5000 THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'amount_out_of_range');
  END IF;

  SELECT * INTO c FROM clues WHERE id = clue_id_in FOR UPDATE;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'clue_not_found');
  END IF;
  IF c.creator_id <> uid THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'not_creator');
  END IF;
  IF c.status NOT IN ('active', 'approved') THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'clue_not_active');
  END IF;

  -- 코인 차감 (잔액 부족 시 0행)
  UPDATE profiles SET coin_balance = coin_balance - amount_in
   WHERE id = uid AND coin_balance >= amount_in
   RETURNING coin_balance INTO new_bal;
  IF new_bal IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'insufficient_coin');
  END IF;
  INSERT INTO coin_ledger (user_id, delta, reason, source_id, balance_after)
  VALUES (uid, -amount_in, 'clue_fund', clue_id_in::text, new_bal);

  UPDATE clues SET reward_pool_coin = reward_pool_coin + amount_in
   WHERE id = clue_id_in
   RETURNING reward_pool_coin INTO new_pool;

  RETURN jsonb_build_object(
    'ok', true, 'pool_coin', new_pool, 'balance', new_bal
  );
END;
$$;

REVOKE EXECUTE ON FUNCTION public.fund_clue_pool_coin(uuid, integer) FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION public.fund_clue_pool_coin(uuid, integer) TO authenticated;

-- ============================================================================
-- claim_coin_pool: 1등 완료자가 코인 상금 수령 (멱등 — 수령 시 풀 0)
-- ============================================================================
CREATE OR REPLACE FUNCTION public.claim_coin_pool(clue_id_in uuid)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  uid       uuid := auth.uid();
  c         clues%ROWTYPE;
  p         participations%ROWTYPE;
  first_id  uuid;
  prize     integer;
  new_bal   integer;
BEGIN
  IF uid IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'auth_required');
  END IF;

  SELECT * INTO c FROM clues WHERE id = clue_id_in FOR UPDATE;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'clue_not_found');
  END IF;
  IF c.reward_pool_coin <= 0 THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'no_pool');
  END IF;

  SELECT * INTO p FROM participations
   WHERE clue_id = clue_id_in AND user_id = uid AND status = 'completed';
  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'not_completed');
  END IF;

  -- 1등 검증: rank=1 또는 (rank 미산정 시) 최초 완료자
  IF COALESCE(p.rank, 0) <> 1 THEN
    SELECT user_id INTO first_id FROM participations
     WHERE clue_id = clue_id_in AND status = 'completed'
       AND completed_at IS NOT NULL
     ORDER BY completed_at ASC LIMIT 1;
    IF first_id IS DISTINCT FROM uid THEN
      RETURN jsonb_build_object('ok', false, 'reason', 'not_first');
    END IF;
  END IF;

  prize := c.reward_pool_coin;
  UPDATE clues SET reward_pool_coin = 0 WHERE id = clue_id_in;

  UPDATE profiles SET coin_balance = coin_balance + prize
   WHERE id = uid RETURNING coin_balance INTO new_bal;
  INSERT INTO coin_ledger (user_id, delta, reason, source_id, balance_after)
  VALUES (uid, prize, 'clue_prize', clue_id_in::text, new_bal);

  RETURN jsonb_build_object('ok', true, 'prize', prize, 'balance', new_bal);
END;
$$;

REVOKE EXECUTE ON FUNCTION public.claim_coin_pool(uuid) FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION public.claim_coin_pool(uuid) TO authenticated;
