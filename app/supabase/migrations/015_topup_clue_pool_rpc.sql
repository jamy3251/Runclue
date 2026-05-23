-- ============================================================================
-- 015 · topup_clue_pool RPC
-- ============================================================================
-- Edge Function `toss-confirm`이 토스 결제 승인 후 호출.
-- service_role 키로만 호출 가능 (사용자 직접 호출 X).
--
-- 멱등성: toss_payment_key UNIQUE — 동일 결제 재호출 시 기존 row 반환.
--
-- 동작:
--   1. wallet_topups INSERT (status='approved', approved_at=now())
--      - UNIQUE 충돌 시 기존 row 반환 (재시도 안전)
--   2. clue_id 있으면 clues.reward_pool_net += net
--   3. 반환: { ok, topup_id, idempotent, new_pool_net }
-- ============================================================================

CREATE OR REPLACE FUNCTION public.topup_clue_pool(
  user_id_in       uuid,
  clue_id_in       uuid,
  gross_in         integer,
  fee_in           integer,
  net_in           integer,
  payment_key_in   text,
  order_id_in      text,
  raw_in           jsonb DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  existing  wallet_topups%ROWTYPE;
  inserted  wallet_topups%ROWTYPE;
  new_pool  integer;
BEGIN
  IF gross_in <> fee_in + net_in THEN
    RAISE EXCEPTION 'gross_in must equal fee_in + net_in (% != % + %)',
      gross_in, fee_in, net_in;
  END IF;

  -- 멱등 키로 기존 row 확인
  SELECT * INTO existing FROM wallet_topups WHERE toss_payment_key = payment_key_in;
  IF FOUND THEN
    RETURN jsonb_build_object(
      'ok', true,
      'idempotent', true,
      'topup_id', existing.id,
      'status', existing.status
    );
  END IF;

  INSERT INTO wallet_topups (
    clue_id, user_id, gross_amount, fee_amount, net_amount,
    toss_payment_key, toss_order_id, status, approved_at, raw_response
  ) VALUES (
    clue_id_in, user_id_in, gross_in, fee_in, net_in,
    payment_key_in, order_id_in, 'approved', now(), raw_in
  ) RETURNING * INTO inserted;

  IF clue_id_in IS NOT NULL THEN
    UPDATE clues
       SET reward_pool_net = reward_pool_net + net_in
     WHERE id = clue_id_in
     RETURNING reward_pool_net INTO new_pool;
  END IF;

  RETURN jsonb_build_object(
    'ok', true,
    'idempotent', false,
    'topup_id', inserted.id,
    'status', 'approved',
    'new_pool_net', new_pool
  );
END;
$$;

-- service_role만 EXECUTE 가능 (authenticated는 RLS로 wallet_topups 직접 INSERT 불가).
-- 그러나 RPC는 SECURITY DEFINER로 owner 권한 사용 — anon/authenticated에 EXECUTE 부여 안 함.
-- 명시적으로 모든 일반 권한 REVOKE.
REVOKE ALL ON FUNCTION public.topup_clue_pool(
  uuid, uuid, integer, integer, integer, text, text, jsonb
) FROM PUBLIC, anon, authenticated;
