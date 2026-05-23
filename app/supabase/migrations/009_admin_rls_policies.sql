-- ============================================================================
-- 009 · 어드민 RLS 정책 + helper 함수
-- ============================================================================
-- 배경:
--   관리자(profiles.role='admin')는 모든 클루/보상/참여/신고 데이터를 조회·
--   수정·삭제할 수 있어야 운영 모더레이션 가능. 기존 정책은 본인 데이터만
--   접근 허용이라 어드민 우회 정책 추가.
--
-- 패턴:
--   - is_admin() helper (SECURITY DEFINER로 RLS 통해도 호출 가능)
--   - 각 테이블에 admin permissive 정책 추가 (기존 정책과 OR로 결합됨)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.is_admin() RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  );
$$;

GRANT EXECUTE ON FUNCTION public.is_admin TO anon, authenticated;

-- clues / evidences / participations / rewards / profiles / reports
-- 각 테이블에 admin SELECT/UPDATE/DELETE 정책. INSERT는 일반 사용자 정책으로 충분.
DROP POLICY IF EXISTS "clues_admin_select" ON public.clues;
CREATE POLICY "clues_admin_select" ON public.clues FOR SELECT TO authenticated USING (public.is_admin());
DROP POLICY IF EXISTS "clues_admin_update" ON public.clues;
CREATE POLICY "clues_admin_update" ON public.clues FOR UPDATE TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());
DROP POLICY IF EXISTS "clues_admin_delete" ON public.clues;
CREATE POLICY "clues_admin_delete" ON public.clues FOR DELETE TO authenticated USING (public.is_admin());

DROP POLICY IF EXISTS "evidences_admin_select" ON public.evidences;
CREATE POLICY "evidences_admin_select" ON public.evidences FOR SELECT TO authenticated USING (public.is_admin());
DROP POLICY IF EXISTS "evidences_admin_update" ON public.evidences;
CREATE POLICY "evidences_admin_update" ON public.evidences FOR UPDATE TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());
DROP POLICY IF EXISTS "evidences_admin_delete" ON public.evidences;
CREATE POLICY "evidences_admin_delete" ON public.evidences FOR DELETE TO authenticated USING (public.is_admin());

DROP POLICY IF EXISTS "participations_admin_select" ON public.participations;
CREATE POLICY "participations_admin_select" ON public.participations FOR SELECT TO authenticated USING (public.is_admin());
DROP POLICY IF EXISTS "participations_admin_delete" ON public.participations;
CREATE POLICY "participations_admin_delete" ON public.participations FOR DELETE TO authenticated USING (public.is_admin());

DROP POLICY IF EXISTS "rewards_admin_select" ON public.rewards;
CREATE POLICY "rewards_admin_select" ON public.rewards FOR SELECT TO authenticated USING (public.is_admin());
DROP POLICY IF EXISTS "rewards_admin_update" ON public.rewards;
CREATE POLICY "rewards_admin_update" ON public.rewards FOR UPDATE TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "profiles_admin_update" ON public.profiles;
CREATE POLICY "profiles_admin_update" ON public.profiles FOR UPDATE TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "reports_admin_select" ON public.reports;
CREATE POLICY "reports_admin_select" ON public.reports FOR SELECT TO authenticated USING (public.is_admin());
DROP POLICY IF EXISTS "reports_admin_update" ON public.reports;
CREATE POLICY "reports_admin_update" ON public.reports FOR UPDATE TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());
