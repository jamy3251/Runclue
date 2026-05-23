-- ============================================================================
-- 013 · 그룹 미션 (#15) — coop 모드 MVP
-- ============================================================================
-- 배경:
--   CTO 인터뷰: "3명 모아라" — 모르는 사람과 새 경험. 일회성 우려 해결.
--   clue.game_mode = solo (기존, 기본) / coop (신규)
--   coop은 min_participants 도달 시 자동 시작 + 모든 in_lobby 참여자 일괄 in_progress.
--
-- 후속 마이그레이션:
--   014 · 풀 (reward_pool_net 등) — coop_split 분배 모드 기반
--   022 · pg_cron lobby 타임아웃 (보너스)
-- ============================================================================

ALTER TABLE public.clues
  ADD COLUMN IF NOT EXISTS game_mode             text        NOT NULL DEFAULT 'solo',
  ADD COLUMN IF NOT EXISTS min_participants      integer     NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS lobby_window_minutes  integer     NOT NULL DEFAULT 30,
  ADD COLUMN IF NOT EXISTS lobby_started_at      timestamptz,
  ADD COLUMN IF NOT EXISTS coop_state            text        NOT NULL DEFAULT 'idle';

-- CHECK 제약 (drop-and-add 패턴 — 멱등성)
ALTER TABLE public.clues DROP CONSTRAINT IF EXISTS clues_game_mode_check;
ALTER TABLE public.clues ADD  CONSTRAINT clues_game_mode_check
  CHECK (game_mode IN ('solo','coop'));

ALTER TABLE public.clues DROP CONSTRAINT IF EXISTS clues_coop_state_check;
ALTER TABLE public.clues ADD  CONSTRAINT clues_coop_state_check
  CHECK (coop_state IN ('idle','recruiting','started','cancelled'));

ALTER TABLE public.clues DROP CONSTRAINT IF EXISTS clues_min_participants_check;
ALTER TABLE public.clues ADD  CONSTRAINT clues_min_participants_check
  CHECK (min_participants BETWEEN 1 AND 50);

ALTER TABLE public.clues DROP CONSTRAINT IF EXISTS clues_lobby_window_check;
ALTER TABLE public.clues ADD  CONSTRAINT clues_lobby_window_check
  CHECK (lobby_window_minutes BETWEEN 5 AND 1440);

-- participations.status CHECK 확장 — 'in_lobby' 추가
ALTER TABLE public.participations DROP CONSTRAINT IF EXISTS participations_status_check;
ALTER TABLE public.participations ADD  CONSTRAINT participations_status_check
  CHECK (status IN ('in_lobby','joined','in_progress','completed','abandoned','disqualified'));

-- 부분 인덱스 — recruiting 상태 빠른 조회 (홈/탐색 화면 coop 위젯)
CREATE INDEX IF NOT EXISTS clues_coop_recruiting_idx
  ON public.clues (created_at DESC)
  WHERE coop_state = 'recruiting';
