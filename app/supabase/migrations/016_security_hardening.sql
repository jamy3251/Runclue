-- ============================================================================
-- 016 · 보안 hardening — advisor 권고 반영
-- ============================================================================
-- 014/015에서 생성된 객체에 대한 supabase database linter 권고 적용:
--
-- 1. platform_revenue_v1 뷰: SECURITY DEFINER 기본 → SECURITY INVOKER로 강제
--    (호출자 권한으로 뷰 실행 → RLS 우회 방지)
--
-- 2. join_coop_clue / topup_clue_pool 함수: PUBLIC EXECUTE 회수
--    (authenticated만 호출 가능, anon은 거부)
--
-- 3. wallet_topups: anon 접근 명시적 차단 (RLS 정책으로도 막혀있지만 schema 레벨에서도)
-- ============================================================================

-- 1. platform_revenue_v1 — security_invoker
ALTER VIEW public.platform_revenue_v1 SET (security_invoker = true);

-- 2. join_coop_clue — PUBLIC/anon EXECUTE 차단
REVOKE EXECUTE ON FUNCTION public.join_coop_clue(uuid) FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION public.join_coop_clue(uuid) TO authenticated;

-- 3. wallet_topups schema-level — anon SELECT 명시적 차단
REVOKE ALL ON public.wallet_topups FROM anon;
-- (authenticated은 RLS 정책에서 본인 row만 가능)
