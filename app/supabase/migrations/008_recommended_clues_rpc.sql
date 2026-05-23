-- ============================================================================
-- 008 · 위치 기반 + 개인화 클루 추천 RPC
-- ============================================================================
-- 함수 2개:
--   1. recommended_clues(user_lat, user_lng, user_id, radius_km, max)
--      → 사용자 위치 기준 점수 정렬 추천. 점수 가중합:
--         0.40 거리 + 0.20 보상가치(log) + 0.15 인기 + 0.10 신선도 + 0.15 미참여
--      만료/시작전/비활성 제외.
--   2. same_district_clues(origin_clue_id, radius_km, max)
--      → 특정 클루 주변 상권 (같은 동네) 다른 클루.
--
-- 인덱스: clues(lat, lng) 추가 권장 (대량 데이터에서). MVP 단계에선 생략.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.recommended_clues(
  user_lat   double precision,
  user_lng   double precision,
  user_id_in uuid,
  radius_km  double precision DEFAULT 5.0,
  max_results int DEFAULT 20
)
RETURNS TABLE (
  id                   uuid,
  title                text,
  description          text,
  category             text,
  location_name        text,
  address              text,
  lat                  double precision,
  lng                  double precision,
  thumbnail_url        text,
  reward_type          text,
  reward_value         text,
  reward_label         text,
  current_participants integer,
  status               text,
  starts_at            timestamptz,
  ends_at              timestamptz,
  creator_id           uuid,
  created_at           timestamptz,
  distance_m           double precision,
  recommendation_score double precision
)
LANGUAGE sql STABLE AS $$
  WITH nearby AS (
    SELECT c.*,
      111320 * sqrt(
        power((c.lat - user_lat) * cos(radians(user_lat)), 2) +
        power(c.lng - user_lng, 2)
      ) AS distance_m
    FROM public.clues c
    WHERE c.lat IS NOT NULL AND c.lng IS NOT NULL
      AND c.status = 'active'
      AND (c.ends_at IS NULL OR c.ends_at > now())
      AND (c.starts_at IS NULL OR c.starts_at <= now())
  ),
  scored AS (
    SELECT n.*,
      (
        0.40 * GREATEST(0, 1 - n.distance_m / (radius_km * 1000))
        + 0.20 * LEAST(1.0,
            ln(1 + COALESCE(NULLIF(n.reward_value, '')::numeric, 0)) / 10.0
          )
        + 0.15 * LEAST(1.0, COALESCE(n.current_participants, 0) / 50.0)
        + 0.10 * GREATEST(0, 1 - EXTRACT(EPOCH FROM (now() - n.created_at)) / (7 * 86400))
        + CASE
            WHEN NOT EXISTS (
              SELECT 1 FROM public.participations p
              WHERE p.clue_id = n.id AND p.user_id = user_id_in
            ) THEN 0.15
            ELSE 0.0
          END
      ) AS recommendation_score
    FROM nearby n
    WHERE n.distance_m <= radius_km * 1000
  )
  SELECT
    s.id, s.title, s.description, s.category, s.location_name, s.address,
    s.lat, s.lng, s.thumbnail_url, s.reward_type, s.reward_value, s.reward_label,
    s.current_participants, s.status, s.starts_at, s.ends_at, s.creator_id, s.created_at,
    s.distance_m, s.recommendation_score
  FROM scored s
  ORDER BY s.recommendation_score DESC, s.distance_m ASC
  LIMIT max_results;
$$;

GRANT EXECUTE ON FUNCTION public.recommended_clues TO anon, authenticated;

CREATE OR REPLACE FUNCTION public.same_district_clues(
  origin_clue_id uuid,
  radius_km      double precision DEFAULT 1.0,
  max_results    int DEFAULT 6
)
RETURNS TABLE (
  id                   uuid,
  title                text,
  category             text,
  location_name        text,
  thumbnail_url        text,
  reward_value         text,
  current_participants integer,
  distance_m           double precision
)
LANGUAGE sql STABLE AS $$
  WITH origin AS (
    SELECT lat, lng FROM public.clues WHERE id = origin_clue_id
  )
  SELECT c.id, c.title, c.category, c.location_name, c.thumbnail_url,
         c.reward_value, c.current_participants,
         111320 * sqrt(
           power((c.lat - o.lat) * cos(radians(o.lat)), 2) +
           power(c.lng - o.lng, 2)
         ) AS distance_m
  FROM public.clues c, origin o
  WHERE c.id != origin_clue_id
    AND c.lat IS NOT NULL AND c.lng IS NOT NULL
    AND c.status = 'active'
    AND (c.ends_at IS NULL OR c.ends_at > now())
    AND 111320 * sqrt(
          power((c.lat - o.lat) * cos(radians(o.lat)), 2) +
          power(c.lng - o.lng, 2)
        ) <= radius_km * 1000
  ORDER BY distance_m ASC
  LIMIT max_results;
$$;

GRANT EXECUTE ON FUNCTION public.same_district_clues TO anon, authenticated;
