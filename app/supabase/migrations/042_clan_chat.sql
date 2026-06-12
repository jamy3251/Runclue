-- ============================================================================
-- 042 · 클랜 채팅 — 멤버 전용 실시간 채팅
-- ============================================================================
-- clan_messages + RLS(멤버만 읽기/쓰기) + Realtime publication 등록.
-- 앱은 supabase_flutter의 .stream() API로 초기 로드+실시간 수신을 한 번에 처리.
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.clan_messages (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  clan_id     uuid NOT NULL REFERENCES public.clans(id) ON DELETE CASCADE,
  user_id     uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  nickname    text NOT NULL DEFAULT '',   -- 표시용 스냅샷 (join 없이 렌더)
  content     text NOT NULL CHECK (length(content) BETWEEN 1 AND 500),
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS clan_messages_clan_idx
  ON public.clan_messages (clan_id, created_at DESC);

ALTER TABLE public.clan_messages ENABLE ROW LEVEL SECURITY;

-- 멤버만 읽기
DROP POLICY IF EXISTS "clan_messages_member_select" ON public.clan_messages;
CREATE POLICY "clan_messages_member_select" ON public.clan_messages
  FOR SELECT TO authenticated
  USING (
    EXISTS (SELECT 1 FROM clan_members m
            WHERE m.clan_id = clan_messages.clan_id
              AND m.user_id = auth.uid())
  );

-- 멤버만 쓰기 (본인 명의)
DROP POLICY IF EXISTS "clan_messages_member_insert" ON public.clan_messages;
CREATE POLICY "clan_messages_member_insert" ON public.clan_messages
  FOR INSERT TO authenticated
  WITH CHECK (
    user_id = auth.uid()
    AND EXISTS (SELECT 1 FROM clan_members m
                WHERE m.clan_id = clan_messages.clan_id
                  AND m.user_id = auth.uid())
  );

-- 본인 메시지 삭제
DROP POLICY IF EXISTS "clan_messages_own_delete" ON public.clan_messages;
CREATE POLICY "clan_messages_own_delete" ON public.clan_messages
  FOR DELETE TO authenticated USING (user_id = auth.uid());

-- Realtime 활성화
DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.clan_messages;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
