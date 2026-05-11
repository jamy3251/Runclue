-- ============================================================================
-- 002 · rewards / notifications INSERT RLS 정책 보충
-- ============================================================================
-- 배경:
--   001에서 rewards / notifications 테이블은 SELECT/UPDATE 정책만 정의됨.
--   RLS가 ENABLE된 상태에서 INSERT 정책이 없으면 anon/authenticated 역할의
--   모든 INSERT가 거부됨. → 클루 완료 시 보상 발급(_issueReward)이 항상 실패.
--
-- 적용 방법:
--   Supabase Dashboard → SQL Editor → 본 파일 전체 내용 붙여넣기 후 RUN.
--   IF NOT EXISTS / DROP POLICY IF EXISTS 패턴이라 멱등하게 여러 번 실행 가능.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- rewards: 본인 user_id로만 INSERT 허용
-- ---------------------------------------------------------------------------
-- 클루를 완료한 본인이 자신의 보상을 INSERT (앱 로직: completeParticipation).
-- 향후 서버측 자동 발급으로 옮기면 SECURITY DEFINER 함수로 재설계 권장.
DROP POLICY IF EXISTS "rewards_insert_own" ON rewards;
CREATE POLICY "rewards_insert_own"
  ON rewards FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- notifications: 본인이 자신의 알림 INSERT/DELETE 허용
-- ---------------------------------------------------------------------------
-- 호스트가 참여자에게 알림 보내는 케이스는 별도 SECURITY DEFINER 함수가 필요.
-- 우선 본인 → 본인 알림(읽음 처리, 클라이언트측 임시 알림) 만 허용.
DROP POLICY IF EXISTS "notifications_insert_own" ON notifications;
CREATE POLICY "notifications_insert_own"
  ON notifications FOR INSERT
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "notifications_delete_own" ON notifications;
CREATE POLICY "notifications_delete_own"
  ON notifications FOR DELETE
  USING (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- 검증 쿼리 — 실행 후 결과를 보면 정책 적용 확인 가능
-- ---------------------------------------------------------------------------
-- SELECT tablename, policyname, cmd
--   FROM pg_policies
--  WHERE schemaname = 'public'
--    AND tablename IN ('rewards', 'notifications')
--  ORDER BY tablename, cmd;
--
-- 기대 결과:
--   notifications | notifications_delete_own  | DELETE
--   notifications | notifications_insert_own  | INSERT
--   notifications | notifications_select_own  | SELECT
--   notifications | notifications_update_own  | UPDATE
--   rewards       | rewards_insert_own        | INSERT
--   rewards       | rewards_select_own        | SELECT
--   rewards       | rewards_update_own        | UPDATE
