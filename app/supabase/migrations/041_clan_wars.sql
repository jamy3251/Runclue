-- ============================================================================
-- 041 · 클랜 대항전 — 학교/동아리 팀 주간 경쟁
-- ============================================================================
-- 기존 clans/clan_members 테이블 활용. 추가:
--   1) create_clan / join_clan / leave_clan RPC (1인 1클랜)
--   2) 미션 완료 시 클랜 주간 점수 자동 적립 트리거 (+10점/완료)
--   3) 주간 대항전 리더보드 뷰 (KST 주 단위)
-- 학교 대항 = 클랜 이름을 학교/학과/동아리로 만들면 그대로 대항전이 된다.
-- ============================================================================

-- 주간 클랜 점수 ledger
CREATE TABLE IF NOT EXISTS public.clan_war_scores (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  clan_id     uuid NOT NULL REFERENCES public.clans(id) ON DELETE CASCADE,
  user_id     uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  points      integer NOT NULL CHECK (points > 0),
  source      text NOT NULL DEFAULT 'clue_complete',
  week_start  date NOT NULL,
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS clan_war_scores_week_idx
  ON public.clan_war_scores (week_start, clan_id);

ALTER TABLE public.clan_war_scores ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "clan_war_scores_read" ON public.clan_war_scores;
CREATE POLICY "clan_war_scores_read" ON public.clan_war_scores
  FOR SELECT TO authenticated USING (true);  -- 리더보드는 공개

-- ── 미션 완료 → 클랜 점수 적립 트리거 ──
CREATE OR REPLACE FUNCTION public.tg_clan_war_score()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  my_clan uuid;
  wk date := (date_trunc('week', now() AT TIME ZONE 'Asia/Seoul'))::date;
BEGIN
  IF NEW.status = 'completed' AND COALESCE(OLD.status, '') <> 'completed' THEN
    SELECT clan_id INTO my_clan FROM clan_members
     WHERE user_id = NEW.user_id ORDER BY joined_at ASC LIMIT 1;
    IF my_clan IS NOT NULL THEN
      INSERT INTO clan_war_scores (clan_id, user_id, points, week_start)
      VALUES (my_clan, NEW.user_id, 10, wk);
      UPDATE clans SET total_points = total_points + 10 WHERE id = my_clan;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_clan_war_score ON public.participations;
CREATE TRIGGER trg_clan_war_score
  AFTER UPDATE ON public.participations
  FOR EACH ROW EXECUTE FUNCTION public.tg_clan_war_score();

-- ── 주간 대항전 리더보드 뷰 ──
CREATE OR REPLACE VIEW public.clan_weekly_leaderboard
WITH (security_invoker = true) AS
SELECT
  c.id          AS clan_id,
  c.name,
  c.avatar_url,
  c.member_count,
  COALESCE(sum(s.points), 0)::integer AS week_points,
  count(DISTINCT s.user_id)::integer  AS active_members
FROM clans c
LEFT JOIN clan_war_scores s
  ON s.clan_id = c.id
 AND s.week_start = (date_trunc('week', now() AT TIME ZONE 'Asia/Seoul'))::date
GROUP BY c.id, c.name, c.avatar_url, c.member_count
ORDER BY week_points DESC, c.member_count DESC;

-- ── 클랜 생성/가입/탈퇴 RPC (1인 1클랜) ──
CREATE OR REPLACE FUNCTION public.create_clan(name_in text, description_in text DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  uid uuid := auth.uid();
  new_id uuid;
BEGIN
  IF uid IS NULL THEN RETURN jsonb_build_object('ok', false, 'reason', 'auth_required'); END IF;
  IF length(trim(name_in)) < 2 OR length(trim(name_in)) > 20 THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'invalid_name');
  END IF;
  IF EXISTS (SELECT 1 FROM clan_members WHERE user_id = uid) THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'already_in_clan');
  END IF;
  IF EXISTS (SELECT 1 FROM clans WHERE lower(name) = lower(trim(name_in))) THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'name_taken');
  END IF;

  INSERT INTO clans (name, description, leader_id, member_count, is_public)
  VALUES (trim(name_in), description_in, uid, 1, true)
  RETURNING id INTO new_id;
  INSERT INTO clan_members (clan_id, user_id, role) VALUES (new_id, uid, 'leader');

  RETURN jsonb_build_object('ok', true, 'clan_id', new_id);
END;
$$;

CREATE OR REPLACE FUNCTION public.join_clan(clan_id_in uuid)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  uid uuid := auth.uid();
  c clans%ROWTYPE;
BEGIN
  IF uid IS NULL THEN RETURN jsonb_build_object('ok', false, 'reason', 'auth_required'); END IF;
  IF EXISTS (SELECT 1 FROM clan_members WHERE user_id = uid) THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'already_in_clan');
  END IF;
  SELECT * INTO c FROM clans WHERE id = clan_id_in FOR UPDATE;
  IF NOT FOUND THEN RETURN jsonb_build_object('ok', false, 'reason', 'clan_not_found'); END IF;
  IF NOT c.is_public THEN RETURN jsonb_build_object('ok', false, 'reason', 'private_clan'); END IF;
  IF c.member_count >= COALESCE(c.max_members, 50) THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'clan_full');
  END IF;

  INSERT INTO clan_members (clan_id, user_id, role) VALUES (clan_id_in, uid, 'member');
  UPDATE clans SET member_count = member_count + 1 WHERE id = clan_id_in;
  RETURN jsonb_build_object('ok', true, 'clan_id', clan_id_in);
END;
$$;

CREATE OR REPLACE FUNCTION public.leave_clan()
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  uid uuid := auth.uid();
  m clan_members%ROWTYPE;
BEGIN
  IF uid IS NULL THEN RETURN jsonb_build_object('ok', false, 'reason', 'auth_required'); END IF;
  SELECT * INTO m FROM clan_members WHERE user_id = uid LIMIT 1;
  IF NOT FOUND THEN RETURN jsonb_build_object('ok', false, 'reason', 'not_in_clan'); END IF;
  IF m.role = 'leader' THEN
    -- 리더는 멤버가 본인뿐일 때만 탈퇴(=해산)
    IF (SELECT count(*) FROM clan_members WHERE clan_id = m.clan_id) > 1 THEN
      RETURN jsonb_build_object('ok', false, 'reason', 'leader_must_disband_last');
    END IF;
    DELETE FROM clan_members WHERE clan_id = m.clan_id;
    DELETE FROM clans WHERE id = m.clan_id;
    RETURN jsonb_build_object('ok', true, 'disbanded', true);
  END IF;
  DELETE FROM clan_members WHERE user_id = uid;
  UPDATE clans SET member_count = greatest(member_count - 1, 0) WHERE id = m.clan_id;
  RETURN jsonb_build_object('ok', true);
END;
$$;

REVOKE EXECUTE ON FUNCTION public.create_clan(text, text) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.join_clan(uuid) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.leave_clan() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.create_clan(text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.join_clan(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.leave_clan() TO authenticated;
