-- ============================================================================
-- 040 · 전환율 뷰 보안 수정 — security_invoker
-- ============================================================================
-- 039의 clue_purchase_conversion_v1은 기본(owner 권한) 뷰라 RLS를 우회 —
-- 아무 인증 사용자나 모든 클루의 전환 데이터를 볼 수 있었음.
-- security_invoker=true로 호출자 RLS 적용: 생성자는 자기 클루의
-- participations(생성자 정책)와 evidences만 보임.
-- ============================================================================

ALTER VIEW public.clue_purchase_conversion_v1 SET (security_invoker = true);
