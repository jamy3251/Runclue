-- ============================================================================
-- 005 · CRITICAL — 5개 테이블 RLS 활성화
-- ============================================================================
-- 배경:
--   001 마이그레이션에서 정책(POLICY)은 작성됐으나 ALTER TABLE ... ENABLE
--   ROW LEVEL SECURITY 가 빠져 있어서 정책이 무시됨. anon key (APK + public repo
--   배포)만 있으면 모든 사용자 데이터 읽기/쓰기/삭제 가능한 상태였음.
--
-- 영향:
--   - clues, evidences, participations, profiles, steps 5개 테이블
--   - 정책은 이미 작성돼 있으므로 ENABLE만으로 즉시 보호됨 (코드 변경 불필요)
--
-- 검증:
--   SELECT c.relname, c.relrowsecurity FROM pg_class c
--   JOIN pg_namespace n ON c.relnamespace = n.oid
--   WHERE n.nspname='public' AND c.relkind='r'
--     AND c.relname IN ('clues','evidences','participations','profiles','steps');
--   → 5행 모두 relrowsecurity = true 여야 함
-- ============================================================================

ALTER TABLE public.clues          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.evidences      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.participations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.steps          ENABLE ROW LEVEL SECURITY;
