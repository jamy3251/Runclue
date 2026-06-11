-- ============================================================================
-- 035 · 보안 위생 — advisor WARN 정리 (2026-06-11 스캔 기준)
-- ============================================================================
-- 실위험은 아님 (RLS가 행 보호 중) — GraphQL/REST 스키마 노출 표면 축소.
--
-- 1) diamond_topups / diamond_packages: anon SELECT REVOKE
--    (정책이 TO authenticated 전용이라 anon은 어차피 0행 — 스키마 발견만 차단)
-- 2) handle_new_user: 트리거 전용 함수인데 RPC로 노출 → EXECUTE 전부 REVOKE
--    (트리거 실행은 소유자 권한이라 영향 없음)
-- ============================================================================

REVOKE SELECT ON public.diamond_topups FROM anon;
REVOKE SELECT ON public.diamond_packages FROM anon;

REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM PUBLIC, anon, authenticated;
