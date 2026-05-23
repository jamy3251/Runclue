-- ============================================================================
-- 006 · post_comments → community_posts.comment_count 자동 동기화 트리거
-- ============================================================================
-- 배경:
--   댓글 추가/삭제 시 community_posts.comment_count가 갱신 안 돼서
--   리스트 카드에 카운트가 stale. 클라이언트에서 invalidate로 막을 수도 있지만
--   DB 트리거가 더 견고 (다른 클라이언트/관리자 직접 INSERT 케이스도 커버).
-- 멱등: CREATE OR REPLACE + DROP TRIGGER IF EXISTS.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.tg_update_comment_count()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.community_posts
       SET comment_count = comment_count + 1
     WHERE id = NEW.post_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.community_posts
       SET comment_count = GREATEST(comment_count - 1, 0)
     WHERE id = OLD.post_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS post_comments_count_sync ON public.post_comments;
CREATE TRIGGER post_comments_count_sync
  AFTER INSERT OR DELETE ON public.post_comments
  FOR EACH ROW EXECUTE FUNCTION public.tg_update_comment_count();

-- 기존 데이터 카운트 정정 (한 번만)
UPDATE public.community_posts cp
   SET comment_count = (SELECT count(*) FROM public.post_comments pc WHERE pc.post_id = cp.id);
