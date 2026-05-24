-- ============================================================================
-- 027 · 사용자 등급 차등 보상 배수 (#25 메타 등급제 확장)
-- ============================================================================
-- 사용자 레벨(total_points 기반)에 따라 코인 적립 시 배수 적용.
--
-- 임계값 (utils/user_level.dart와 일관):
--   Lv1 새싹       (0p)        : 1.00×  bps=10000
--   Lv2 브론즈     (100p)      : 1.05×  bps=10500
--   Lv3 실버       (500p)      : 1.10×  bps=11000
--   Lv4 골드       (2000p)     : 1.20×  bps=12000
--   Lv5 플래티넘   (5000p)     : 1.35×  bps=13500
--   Lv6 다이아     (10000p)    : 1.50×  bps=15000
--
-- 적용 범위: grant_coin / grant_coin_admin의 양수 delta. 음수(소비) 무관.
--   광고/미니게임/걸음수/일일미션/시즌 모두 코인 적립은 grant_coin 통과 →
--   자동으로 차등 적용. 다이아 적립(grant_diamond)은 무관 (시즌 등 별도 분배).
--
-- 단발 한도 확장: ±100 → ±200 (1.5× 적용 후 최대 150 안전 + 운영 여유).
-- 일일 캡(+500/일)은 multiplier 적용 후 누적값 기준 유지.
-- ============================================================================

-- 1. user_level_multiplier_bps(user_id) — 사용자 total_points → 배수 (basis points)
CREATE OR REPLACE FUNCTION public.user_level_multiplier_bps(user_id_in uuid)
RETURNS integer
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT CASE
    WHEN COALESCE(total_points, 0) >= 10000 THEN 15000  -- 다이아 1.50×
    WHEN COALESCE(total_points, 0) >=  5000 THEN 13500  -- 플래티넘 1.35×
    WHEN COALESCE(total_points, 0) >=  2000 THEN 12000  -- 골드 1.20×
    WHEN COALESCE(total_points, 0) >=   500 THEN 11000  -- 실버 1.10×
    WHEN COALESCE(total_points, 0) >=   100 THEN 10500  -- 브론즈 1.05×
    ELSE 10000                                          -- 새싹 1.00×
  END
  FROM profiles WHERE id = user_id_in
  UNION ALL SELECT 10000  -- profile 없는 fallback
  LIMIT 1;
$$;

GRANT EXECUTE ON FUNCTION public.user_level_multiplier_bps(uuid) TO authenticated;

-- 2. grant_coin 업데이트 — multiplier 적용 + 단발 한도 200으로 확장
CREATE OR REPLACE FUNCTION public.grant_coin(
  user_id_in   uuid,
  delta_in     integer,
  reason_in    text,
  source_id_in text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  caller_uid       uuid := auth.uid();
  today_date       date := (now() AT TIME ZONE 'Asia/Seoul')::date;
  today_sum        integer;
  new_balance      integer;
  mult_bps         integer := 10000;
  effective_delta  integer;
BEGIN
  IF caller_uid IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'auth_required');
  END IF;
  IF caller_uid <> user_id_in AND NOT public.is_admin() THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'forbidden');
  END IF;
  IF delta_in = 0 THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'zero_delta');
  END IF;
  IF reason_in IS NULL OR length(trim(reason_in)) = 0 THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'reason_required');
  END IF;
  -- 단발 절대값 한도 ±200 (multiplier 적용 후도 안전)
  IF delta_in > 200 OR delta_in < -200 THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'delta_out_of_range');
  END IF;

  -- 양수 적립만 등급 배수 적용
  IF delta_in > 0 THEN
    SELECT public.user_level_multiplier_bps(user_id_in) INTO mult_bps;
    effective_delta := (delta_in::bigint * mult_bps / 10000)::integer;
    -- 일일 캡 +500 (effective 기준)
    SELECT COALESCE(sum(delta), 0) INTO today_sum
      FROM coin_ledger
     WHERE user_id = user_id_in
       AND day_date = today_date
       AND delta > 0;
    IF today_sum + effective_delta > 500 THEN
      RETURN jsonb_build_object(
        'ok', false, 'reason', 'daily_cap_reached',
        'today_sum', today_sum, 'cap', 500
      );
    END IF;
  ELSE
    effective_delta := delta_in;
  END IF;

  UPDATE profiles
     SET coin_balance = coin_balance + effective_delta
   WHERE id = user_id_in
     AND coin_balance + effective_delta >= 0
   RETURNING coin_balance INTO new_balance;

  IF new_balance IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'insufficient_balance');
  END IF;

  INSERT INTO coin_ledger (user_id, delta, reason, source_id, balance_after)
  VALUES (user_id_in, effective_delta, reason_in, source_id_in, new_balance);

  RETURN jsonb_build_object(
    'ok', true,
    'balance', new_balance,
    'base_delta', delta_in,
    'effective_delta', effective_delta,
    'multiplier_bps', mult_bps,
    'reason', reason_in
  );
END;
$$;

REVOKE EXECUTE ON FUNCTION public.grant_coin(uuid, integer, text, text) FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION public.grant_coin(uuid, integer, text, text) TO authenticated;

-- 3. grant_coin_admin 업데이트 — 동일 multiplier + cap 200
CREATE OR REPLACE FUNCTION public.grant_coin_admin(
  user_id_in   uuid,
  delta_in     integer,
  reason_in    text,
  source_id_in text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  today_date       date := (now() AT TIME ZONE 'Asia/Seoul')::date;
  today_sum        integer;
  new_balance      integer;
  mult_bps         integer := 10000;
  effective_delta  integer;
BEGIN
  IF delta_in = 0 THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'zero_delta');
  END IF;
  IF delta_in > 200 OR delta_in < -200 THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'delta_out_of_range');
  END IF;
  IF reason_in IS NULL OR length(trim(reason_in)) = 0 THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'reason_required');
  END IF;
  IF user_id_in IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'user_required');
  END IF;

  IF delta_in > 0 THEN
    SELECT public.user_level_multiplier_bps(user_id_in) INTO mult_bps;
    effective_delta := (delta_in::bigint * mult_bps / 10000)::integer;
    SELECT COALESCE(sum(delta), 0) INTO today_sum
      FROM coin_ledger
     WHERE user_id = user_id_in
       AND day_date = today_date
       AND delta > 0;
    IF today_sum + effective_delta > 500 THEN
      RETURN jsonb_build_object(
        'ok', false, 'reason', 'daily_cap_reached',
        'today_sum', today_sum, 'cap', 500
      );
    END IF;
  ELSE
    effective_delta := delta_in;
  END IF;

  UPDATE profiles
     SET coin_balance = coin_balance + effective_delta
   WHERE id = user_id_in
     AND coin_balance + effective_delta >= 0
   RETURNING coin_balance INTO new_balance;

  IF new_balance IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'insufficient_balance');
  END IF;

  INSERT INTO coin_ledger (user_id, delta, reason, source_id, balance_after)
  VALUES (user_id_in, effective_delta, reason_in, source_id_in, new_balance);

  RETURN jsonb_build_object(
    'ok', true,
    'balance', new_balance,
    'base_delta', delta_in,
    'effective_delta', effective_delta,
    'multiplier_bps', mult_bps,
    'reason', reason_in
  );
END;
$$;

REVOKE ALL ON FUNCTION public.grant_coin_admin(uuid, integer, text, text)
  FROM PUBLIC, anon, authenticated;
