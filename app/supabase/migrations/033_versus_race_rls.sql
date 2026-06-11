-- ============================================================================
-- 033 · versus/coop 레이스 — 참가자 간 진행률 상호 조회 RLS
-- ============================================================================
-- 문제: participations SELECT 정책이 본인/생성자/admin 한정이라
--       versus 실시간 경쟁 UI(누가 몇 스텝까지 갔는지)를 만들 수 없음.
--
-- 해법: coop/versus 클루에 한해, 같은 클루 참가자끼리 서로의 행 조회 허용.
--       solo 클루는 기존 정책 그대로 (프라이버시 유지).
--
-- 주의: 정책 안에서 participations를 직접 서브쿼리하면 RLS 무한 재귀 →
--       SECURITY DEFINER 헬퍼 함수로 우회 (RLS 미적용 조회).
-- ============================================================================

CREATE OR REPLACE FUNCTION public.is_clue_participant(clue_id_in uuid)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM participations
    WHERE clue_id = clue_id_in AND user_id = auth.uid()
  );
$$;

REVOKE ALL ON FUNCTION public.is_clue_participant(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.is_clue_participant(uuid) TO authenticated;

DROP POLICY IF EXISTS "participations_select_race" ON public.participations;
CREATE POLICY "participations_select_race" ON public.participations
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM clues c
      WHERE c.id = participations.clue_id
        AND c.game_mode IN ('coop','versus')
    )
    AND public.is_clue_participant(participations.clue_id)
  );
