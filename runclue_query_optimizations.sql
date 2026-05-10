-- RunClue query optimization addendum

-- 1) clues nearby search support
ALTER TABLE clues
  ADD COLUMN IF NOT EXISTS geo_lat NUMERIC(9,6),
  ADD COLUMN IF NOT EXISTS geo_lng NUMERIC(9,6),
  ADD COLUMN IF NOT EXISTS geohash6 TEXT,
  ADD COLUMN IF NOT EXISTS reward_total_krw BIGINT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS popularity_score BIGINT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS is_featured BOOLEAN DEFAULT false;

CREATE INDEX IF NOT EXISTS idx_clues_live_public
  ON clues (status, visibility, start_at, end_at);

CREATE INDEX IF NOT EXISTS idx_clues_geohash6_live
  ON clues (geohash6, start_at DESC)
  WHERE status = 'PUBLISHED';

CREATE INDEX IF NOT EXISTS idx_clues_category_live
  ON clues (category, start_at DESC)
  WHERE status = 'PUBLISHED';

-- 2) user progress
CREATE INDEX IF NOT EXISTS idx_participations_user_active
  ON participations (user_id, status, joined_at DESC)
  WHERE status IN ('JOINED', 'IN_PROGRESS');

CREATE INDEX IF NOT EXISTS idx_clue_steps_clue_order
  ON clue_steps (clue_id, order_no);

-- 3) JSONB config filtering
CREATE INDEX IF NOT EXISTS idx_clue_steps_config_gin
  ON clue_steps USING GIN (config jsonb_path_ops);

CREATE INDEX IF NOT EXISTS idx_clue_steps_type
  ON clue_steps (type);

-- 4) evidence / append-heavy tables
CREATE INDEX IF NOT EXISTS idx_evidences_attempt_id
  ON evidences (attempt_id);

CREATE INDEX IF NOT EXISTS idx_evidences_created_at_brin
  ON evidences USING BRIN (created_at);

-- 5) weekly reports
CREATE INDEX IF NOT EXISTS idx_weekly_reports_user_recent
  ON weekly_reports_materialized (user_id, week_key DESC);

-- Nearby clue query
WITH candidate AS (
  SELECT
    c.id,
    c.title,
    c.category,
    c.reward_total_krw,
    c.geo_lat,
    c.geo_lng,
    c.popularity_score,
    c.is_featured,
    (
      6371000 * acos(
        cos(radians($1)) * cos(radians(c.geo_lat)) *
        cos(radians(c.geo_lng) - radians($2)) +
        sin(radians($1)) * sin(radians(c.geo_lat))
      )
    ) AS distance_m
  FROM clues c
  WHERE c.status = 'PUBLISHED'
    AND c.visibility IN ('PUBLIC', 'UNLISTED_DISCOVERABLE')
    AND c.geohash6 = ANY($3)
    AND now() BETWEEN c.start_at AND c.end_at
)
SELECT *
FROM candidate
WHERE distance_m <= $4
ORDER BY is_featured DESC, distance_m ASC, popularity_score DESC
LIMIT $5 OFFSET $6;

-- Active participations
SELECT
  p.id,
  p.clue_id,
  p.status,
  p.current_step_order,
  c.title,
  c.end_at,
  s.id AS current_step_id,
  s.type AS current_step_type,
  s.config
FROM participations p
JOIN clues c
  ON c.id = p.clue_id
LEFT JOIN clue_steps s
  ON s.clue_id = p.clue_id
 AND s.order_no = p.current_step_order
WHERE p.user_id = $1
  AND p.status IN ('JOINED', 'IN_PROGRESS')
ORDER BY p.joined_at DESC
LIMIT 20;

-- Snapshot filter example
SELECT DISTINCT c.id, c.title
FROM clues c
JOIN clue_steps s ON s.clue_id = c.id
WHERE c.status = 'PUBLISHED'
  AND s.type = 'SNAPSHOT'
  AND s.config @> '{"privacy":{"visibility":"operator_only"}}'::jsonb;