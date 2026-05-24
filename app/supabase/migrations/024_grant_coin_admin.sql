-- ============================================================================
-- 024 · grant_coin_admin (service_role 전용)
-- ============================================================================
-- Edge Function (admob-ssv, 운영 admin 보상 부여 등)에서 auth.uid()=NULL
-- 컨텍스트로 호출. 기존 grant_coin은 auth.uid() 필요해서 SSV에서 못 씀.
--
-- 보안: anon/authenticated EXECUTE 완전 차단. service_role만 호출 가능.
-- 외부 인터넷에서 직접 호출 차단되어 있음 (REVOKE ALL).
-- 그래도 ±100 단발 + 일일 +500 캡 + ledger 기록 동일 적용.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.grant_coin_admin(
  user_id_in   uuid,
  delta_in     integer,
  reason_in    text,
  source_id_in text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  today_date  date := (now() AT TIME ZONE 'Asia/Seoul')::date;
  today_sum   integer;
  new_balance integer;
BEGIN
  IF delta_in = 0 THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'zero_delta');
  END IF;
  IF delta_in > 100 OR delta_in < -100 THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'delta_out_of_range');
  END IF;
  IF reason_in IS NULL OR length(trim(reason_in)) = 0 THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'reason_required');
  END IF;
  IF user_id_in IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'user_required');
  END IF;

  IF delta_in > 0 THEN
    SELECT COALESCE(sum(delta), 0) INTO today_sum
      FROM coin_ledger
     WHERE user_id = user_id_in
       AND day_date = today_date
       AND delta > 0;
    IF today_sum + delta_in > 500 THEN
      RETURN jsonb_build_object(
        'ok', false, 'reason', 'daily_cap_reached',
        'today_sum', today_sum, 'cap', 500
      );
    END IF;
  END IF;

  UPDATE profiles
     SET coin_balance = coin_balance + delta_in
   WHERE id = user_id_in
     AND coin_balance + delta_in >= 0
   RETURNING coin_balance INTO new_balance;

  IF new_balance IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'insufficient_balance');
  END IF;

  INSERT INTO coin_ledger (user_id, delta, reason, source_id, balance_after)
  VALUES (user_id_in, delta_in, reason_in, source_id_in, new_balance);

  RETURN jsonb_build_object(
    'ok', true,
    'balance', new_balance,
    'delta', delta_in,
    'reason', reason_in
  );
END;
$$;

-- service_role만. authenticated/anon EXECUTE 완전 차단.
REVOKE ALL ON FUNCTION public.grant_coin_admin(uuid, integer, text, text)
  FROM PUBLIC, anon, authenticated;
