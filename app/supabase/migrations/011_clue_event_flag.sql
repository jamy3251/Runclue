-- ============================================================================
-- 011 · 단기 이벤트 클루 플래그
-- ============================================================================
-- 인터뷰 (CTO) — "술집·축제·세미나 같은 단기간 관심 급증, 특정 가능 타겟"
-- 일반 클루와 구분되는 "이벤트 클루" 마킹 (24h 만료 + 풀스크린 강조용).
-- ends_at은 이미 007에서 추가됨. 이 마이그레이션은 분류 플래그만.
-- ============================================================================

ALTER TABLE public.clues
  ADD COLUMN IF NOT EXISTS is_event boolean NOT NULL DEFAULT false;

CREATE INDEX IF NOT EXISTS clues_is_event_idx
  ON public.clues (is_event, ends_at) WHERE is_event = true;
