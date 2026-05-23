-- ============================================================================
-- 007 · clues 테이블 기간 컬럼 추가 (starts_at / ends_at)
-- ============================================================================
-- 배경:
--   사장님이 "이번 주말 한정 미션", "런칭 이벤트 3일" 같은 시간제한 클루 만들고
--   싶어함. 만료된 클루를 자동으로 탐색에서 숨기는 것도 필요.
--
-- 컬럼:
--   - starts_at: 미션 시작 (null 이면 즉시 시작)
--   - ends_at: 미션 종료 (null 이면 무기한)
--
-- 인덱스: ends_at 순 정렬 + active 상태 + 미만료 필터링용 부분 인덱스.
-- ============================================================================

ALTER TABLE public.clues
  ADD COLUMN IF NOT EXISTS starts_at timestamptz,
  ADD COLUMN IF NOT EXISTS ends_at   timestamptz;

CREATE INDEX IF NOT EXISTS clues_ends_at_idx ON public.clues (ends_at);
CREATE INDEX IF NOT EXISTS clues_active_period_idx
  ON public.clues (status, ends_at) WHERE status = 'active';
