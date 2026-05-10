-- ============================================================================
-- RunClue Initial Schema Migration
-- ============================================================================
-- Comprehensive PostgreSQL schema with PostGIS support for the RunClue app.
-- Includes tables, indexes, RLS policies, triggers, and utility functions.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Extensions
-- ---------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ---------------------------------------------------------------------------
-- Helper function: auto-update updated_at timestamp
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 1. profiles (extends auth.users)
-- ============================================================================
CREATE TABLE profiles (
  id          uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  nickname    varchar(30) UNIQUE NOT NULL,
  avatar_url  text,
  bio         varchar(200),
  total_points    integer DEFAULT 0,
  badge_count     integer DEFAULT 0,
  clues_created   integer DEFAULT 0,
  clues_completed integer DEFAULT 0,
  is_creator  boolean DEFAULT false,
  role        varchar(10) DEFAULT 'user'
              CHECK (role IN ('user', 'creator', 'admin')),
  created_at  timestamptz DEFAULT now(),
  updated_at  timestamptz DEFAULT now()
);

CREATE TRIGGER profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================================
-- 2. clues
-- ============================================================================
CREATE TABLE clues (
  id                   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id           uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title                varchar(100) NOT NULL,
  description          text,
  category             varchar(20)
                       CHECK (category IN (
                         'adventure', 'quiz', 'education', 'life_help',
                         'promotion', 'workshop', 'broadcast'
                       )),
  status               varchar(20) DEFAULT 'draft'
                       CHECK (status IN (
                         'draft', 'pending_approval', 'approved', 'active',
                         'completed', 'rejected', 'suspended'
                       )),
  is_public            boolean DEFAULT true,
  max_participants     integer,
  current_participants integer DEFAULT 0,
  start_time           timestamptz,
  end_time             timestamptz,
  time_limit_minutes   integer,
  location             geography(Point, 4326),
  radius_meters        integer,
  address              text,
  thumbnail_url        text,
  reward_type          varchar(10)
                       CHECK (reward_type IN (
                         'points', 'badge', 'coupon', 'prize', 'raffle'
                       )),
  reward_value         integer,
  requires_approval    boolean DEFAULT false,
  is_prize_type        boolean DEFAULT false,
  is_broadcast_type    boolean DEFAULT false,
  min_age              integer,
  tags                 text[],
  view_count           integer DEFAULT 0,
  like_count           integer DEFAULT 0,
  created_at           timestamptz DEFAULT now(),
  updated_at           timestamptz DEFAULT now()
);

CREATE TRIGGER clues_updated_at
  BEFORE UPDATE ON clues
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================================
-- 3. steps
-- ============================================================================
CREATE TABLE steps (
  id                      uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  clue_id                 uuid NOT NULL REFERENCES clues(id) ON DELETE CASCADE,
  order_index             integer NOT NULL,
  type                    varchar(20) NOT NULL
                          CHECK (type IN (
                            'CHECKPOINT', 'SNAPSHOT', 'QUEST', 'OX_QUIZ',
                            'LIST', 'BOARD', 'PANORAMA', 'FACIAL'
                          )),
  title                   varchar(100) NOT NULL,
  description             text,
  instruction             text,
  -- CHECKPOINT
  target_location         geography(Point, 4326),
  location_radius_meters  integer DEFAULT 50,
  -- SNAPSHOT
  reference_image_url     text,
  -- QUEST
  quest_question          text,
  quest_answer            text,
  quest_answer_type       varchar(10)
                          CHECK (quest_answer_type IN ('exact', 'contains', 'free_text')),
  -- OX_QUIZ
  quiz_correct_answer     boolean,
  quiz_explanation        text,
  quiz_time_limit_seconds integer DEFAULT 30,
  -- LIST
  checklist_items         jsonb,
  -- Common
  validation_type         varchar(10) DEFAULT 'auto'
                          CHECK (validation_type IN ('auto', 'delayed', 'manual')),
  points                  integer DEFAULT 0,
  is_required             boolean DEFAULT true,
  time_limit_seconds      integer,
  hint                    text,
  created_at              timestamptz DEFAULT now(),
  updated_at              timestamptz DEFAULT now(),

  UNIQUE (clue_id, order_index)
);

CREATE TRIGGER steps_updated_at
  BEFORE UPDATE ON steps
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================================
-- 6. clans  (created before participations because participations references it)
-- ============================================================================
CREATE TABLE clans (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name          varchar(50) UNIQUE NOT NULL,
  description   varchar(200),
  avatar_url    text,
  leader_id     uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  member_count  integer DEFAULT 1,
  total_points  integer DEFAULT 0,
  is_public     boolean DEFAULT true,
  max_members   integer DEFAULT 50,
  created_at    timestamptz DEFAULT now(),
  updated_at    timestamptz DEFAULT now()
);

CREATE TRIGGER clans_updated_at
  BEFORE UPDATE ON clans
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================================
-- 4. participations
-- ============================================================================
CREATE TABLE participations (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  clue_id             uuid NOT NULL REFERENCES clues(id) ON DELETE CASCADE,
  user_id             uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  clan_id             uuid REFERENCES clans(id) ON DELETE SET NULL,
  status              varchar(20) DEFAULT 'joined'
                      CHECK (status IN (
                        'joined', 'in_progress', 'completed',
                        'abandoned', 'disqualified'
                      )),
  current_step_index  integer DEFAULT 0,
  started_at          timestamptz,
  completed_at        timestamptz,
  total_points_earned integer DEFAULT 0,
  rank                integer,
  created_at          timestamptz DEFAULT now(),
  updated_at          timestamptz DEFAULT now(),

  UNIQUE (clue_id, user_id)
);

CREATE TRIGGER participations_updated_at
  BEFORE UPDATE ON participations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================================
-- 5. evidences
-- ============================================================================
CREATE TABLE evidences (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  step_id             uuid NOT NULL REFERENCES steps(id) ON DELETE CASCADE,
  participation_id    uuid NOT NULL REFERENCES participations(id) ON DELETE CASCADE,
  user_id             uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  type                varchar(15) NOT NULL
                      CHECK (type IN (
                        'photo', 'location', 'video', 'qr_scan',
                        'text_answer', 'ox_answer', 'checklist'
                      )),
  -- Content
  media_url           text,
  text_content        text,
  boolean_answer      boolean,
  checklist_state     jsonb,
  submitted_location  geography(Point, 4326),
  -- Validation
  status              varchar(15) DEFAULT 'pending'
                      CHECK (status IN (
                        'pending', 'approved', 'rejected',
                        'auto_approved', 'auto_rejected'
                      )),
  validated_at        timestamptz,
  validated_by        uuid REFERENCES profiles(id) ON DELETE SET NULL,
  rejection_reason    text,
  -- Meta
  device_info         jsonb,
  submitted_at        timestamptz DEFAULT now(),
  created_at          timestamptz DEFAULT now(),
  updated_at          timestamptz DEFAULT now()
);

CREATE TRIGGER evidences_updated_at
  BEFORE UPDATE ON evidences
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================================
-- 7. clan_members
-- ============================================================================
CREATE TABLE clan_members (
  id        uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  clan_id   uuid NOT NULL REFERENCES clans(id) ON DELETE CASCADE,
  user_id   uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  role      varchar(10) DEFAULT 'member'
            CHECK (role IN ('leader', 'admin', 'member')),
  joined_at timestamptz DEFAULT now(),

  UNIQUE (clan_id, user_id)
);

-- ============================================================================
-- 8. rewards
-- ============================================================================
CREATE TABLE rewards (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  clue_id          uuid NOT NULL REFERENCES clues(id) ON DELETE CASCADE,
  participation_id uuid NOT NULL REFERENCES participations(id) ON DELETE CASCADE,
  type             varchar(10) NOT NULL
                   CHECK (type IN ('points', 'badge', 'coupon', 'prize', 'raffle')),
  value            integer,
  badge_name       varchar(50),
  badge_icon_url   text,
  coupon_code      varchar(50),
  is_claimed       boolean DEFAULT false,
  claimed_at       timestamptz,
  expires_at       timestamptz,
  created_at       timestamptz DEFAULT now()
);

-- ============================================================================
-- 9. reports
-- ============================================================================
CREATE TABLE reports (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id     uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  target_type     varchar(20) NOT NULL
                  CHECK (target_type IN ('clue', 'user', 'evidence', 'community_post')),
  target_id       uuid NOT NULL,
  reason          varchar(15) NOT NULL
                  CHECK (reason IN (
                    'inappropriate', 'spam', 'fraud', 'safety',
                    'harassment', 'copyright', 'other'
                  )),
  description     text,
  status          varchar(15) DEFAULT 'pending'
                  CHECK (status IN ('pending', 'reviewing', 'resolved', 'dismissed')),
  resolved_by     uuid REFERENCES profiles(id) ON DELETE SET NULL,
  resolved_at     timestamptz,
  resolution_note text,
  created_at      timestamptz DEFAULT now()
);

-- ============================================================================
-- 10. notifications
-- ============================================================================
CREATE TABLE notifications (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  type       varchar(20) NOT NULL
             CHECK (type IN (
               'clue_approved', 'clue_rejected', 'evidence_approved',
               'evidence_rejected', 'clue_started', 'clue_ended',
               'reward_earned', 'clan_invite', 'report_resolved', 'system'
             )),
  title      varchar(100),
  body       text,
  data       jsonb,
  is_read    boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- ============================================================================
-- 11. community_posts
-- ============================================================================
CREATE TABLE community_posts (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  author_id     uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  clue_id       uuid REFERENCES clues(id) ON DELETE SET NULL,
  type          varchar(10)
                CHECK (type IN ('review', 'tip', 'photo', 'question', 'general')),
  title         varchar(100),
  content       text NOT NULL,
  media_urls    text[],
  like_count    integer DEFAULT 0,
  comment_count integer DEFAULT 0,
  is_pinned     boolean DEFAULT false,
  created_at    timestamptz DEFAULT now(),
  updated_at    timestamptz DEFAULT now()
);

CREATE TRIGGER community_posts_updated_at
  BEFORE UPDATE ON community_posts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================================
-- 12. post_comments
-- ============================================================================
CREATE TABLE post_comments (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id    uuid NOT NULL REFERENCES community_posts(id) ON DELETE CASCADE,
  author_id  uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  content    text NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TRIGGER post_comments_updated_at
  BEFORE UPDATE ON post_comments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================================
-- 13. likes
-- ============================================================================
CREATE TABLE likes (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  target_type varchar(10) NOT NULL
              CHECK (target_type IN ('clue', 'post', 'comment')),
  target_id   uuid NOT NULL,
  created_at  timestamptz DEFAULT now(),

  UNIQUE (user_id, target_type, target_id)
);

-- ============================================================================
-- 14. blocks
-- ============================================================================
CREATE TABLE blocks (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  blocker_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  blocked_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),

  UNIQUE (blocker_id, blocked_id)
);


-- ============================================================================
-- INDEXES
-- ============================================================================

-- Spatial indexes (GiST)
CREATE INDEX idx_clues_location
  ON clues USING GIST (location);

CREATE INDEX idx_steps_target_location
  ON steps USING GIST (target_location);

CREATE INDEX idx_evidences_submitted_location
  ON evidences USING GIST (submitted_location);

-- clues
CREATE INDEX idx_clues_status_category_created
  ON clues (status, category, created_at DESC);

CREATE INDEX idx_clues_creator_id
  ON clues (creator_id);

-- steps
CREATE INDEX idx_steps_clue_id
  ON steps (clue_id, order_index);

-- participations
CREATE INDEX idx_participations_user_id_clue_id
  ON participations (user_id, clue_id);

CREATE INDEX idx_participations_clue_id
  ON participations (clue_id);

-- evidences
CREATE INDEX idx_evidences_participation_step
  ON evidences (participation_id, step_id);

CREATE INDEX idx_evidences_user_id
  ON evidences (user_id);

-- clan_members
CREATE INDEX idx_clan_members_user_id
  ON clan_members (user_id);

-- rewards
CREATE INDEX idx_rewards_user_id
  ON rewards (user_id);

-- notifications
CREATE INDEX idx_notifications_user_read
  ON notifications (user_id, is_read, created_at DESC);

-- community_posts
CREATE INDEX idx_community_posts_type_created
  ON community_posts (type, created_at DESC);

CREATE INDEX idx_community_posts_author
  ON community_posts (author_id);

-- post_comments
CREATE INDEX idx_post_comments_post_id
  ON post_comments (post_id, created_at);

-- likes
CREATE INDEX idx_likes_target
  ON likes (target_type, target_id);

-- reports
CREATE INDEX idx_reports_status
  ON reports (status, created_at DESC);

-- blocks
CREATE INDEX idx_blocks_blocker
  ON blocks (blocker_id);

CREATE INDEX idx_blocks_blocked
  ON blocks (blocked_id);


-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE profiles        ENABLE ROW LEVEL SECURITY;
ALTER TABLE clues           ENABLE ROW LEVEL SECURITY;
ALTER TABLE steps           ENABLE ROW LEVEL SECURITY;
ALTER TABLE participations  ENABLE ROW LEVEL SECURITY;
ALTER TABLE evidences       ENABLE ROW LEVEL SECURITY;
ALTER TABLE clans           ENABLE ROW LEVEL SECURITY;
ALTER TABLE clan_members    ENABLE ROW LEVEL SECURITY;
ALTER TABLE rewards         ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports         ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications   ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_comments   ENABLE ROW LEVEL SECURITY;
ALTER TABLE likes           ENABLE ROW LEVEL SECURITY;
ALTER TABLE blocks          ENABLE ROW LEVEL SECURITY;

-- ---------------------------------------------------------------------------
-- profiles policies
-- ---------------------------------------------------------------------------
CREATE POLICY "profiles_select_all"
  ON profiles FOR SELECT
  USING (true);

CREATE POLICY "profiles_insert_own"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

CREATE POLICY "profiles_update_own"
  ON profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- ---------------------------------------------------------------------------
-- clues policies
-- ---------------------------------------------------------------------------
CREATE POLICY "clues_select_public"
  ON clues FOR SELECT
  USING (
    status IN ('approved', 'active', 'completed')
    OR creator_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "clues_insert_own"
  ON clues FOR INSERT
  WITH CHECK (creator_id = auth.uid());

CREATE POLICY "clues_update_own"
  ON clues FOR UPDATE
  USING (
    creator_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
    )
  )
  WITH CHECK (
    creator_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "clues_delete_own"
  ON clues FOR DELETE
  USING (
    creator_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ---------------------------------------------------------------------------
-- steps policies
-- ---------------------------------------------------------------------------
CREATE POLICY "steps_select"
  ON steps FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM clues
      WHERE clues.id = steps.clue_id
        AND (
          clues.status IN ('approved', 'active', 'completed')
          OR clues.creator_id = auth.uid()
          OR EXISTS (
            SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
          )
        )
    )
  );

CREATE POLICY "steps_insert_creator"
  ON steps FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM clues
      WHERE clues.id = steps.clue_id
        AND clues.creator_id = auth.uid()
    )
  );

CREATE POLICY "steps_update_creator"
  ON steps FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM clues
      WHERE clues.id = steps.clue_id
        AND clues.creator_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM clues
      WHERE clues.id = steps.clue_id
        AND clues.creator_id = auth.uid()
    )
  );

CREATE POLICY "steps_delete_creator"
  ON steps FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM clues
      WHERE clues.id = steps.clue_id
        AND clues.creator_id = auth.uid()
    )
  );

-- ---------------------------------------------------------------------------
-- participations policies
-- ---------------------------------------------------------------------------
CREATE POLICY "participations_select_own"
  ON participations FOR SELECT
  USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM clues
      WHERE clues.id = participations.clue_id
        AND clues.creator_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "participations_insert_own"
  ON participations FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "participations_update_own"
  ON participations FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- evidences policies
-- ---------------------------------------------------------------------------
CREATE POLICY "evidences_select"
  ON evidences FOR SELECT
  USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM steps
      JOIN clues ON clues.id = steps.clue_id
      WHERE steps.id = evidences.step_id
        AND clues.creator_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "evidences_insert_own"
  ON evidences FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "evidences_update_creator_or_admin"
  ON evidences FOR UPDATE
  USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM steps
      JOIN clues ON clues.id = steps.clue_id
      WHERE steps.id = evidences.step_id
        AND clues.creator_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
    )
  )
  WITH CHECK (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM steps
      JOIN clues ON clues.id = steps.clue_id
      WHERE steps.id = evidences.step_id
        AND clues.creator_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ---------------------------------------------------------------------------
-- clans policies
-- ---------------------------------------------------------------------------
CREATE POLICY "clans_select_public"
  ON clans FOR SELECT
  USING (
    is_public = true
    OR leader_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM clan_members
      WHERE clan_members.clan_id = clans.id
        AND clan_members.user_id = auth.uid()
    )
  );

CREATE POLICY "clans_insert"
  ON clans FOR INSERT
  WITH CHECK (leader_id = auth.uid());

CREATE POLICY "clans_update_leader_admin"
  ON clans FOR UPDATE
  USING (
    leader_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM clan_members
      WHERE clan_members.clan_id = clans.id
        AND clan_members.user_id = auth.uid()
        AND clan_members.role IN ('leader', 'admin')
    )
  )
  WITH CHECK (
    leader_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM clan_members
      WHERE clan_members.clan_id = clans.id
        AND clan_members.user_id = auth.uid()
        AND clan_members.role IN ('leader', 'admin')
    )
  );

CREATE POLICY "clans_delete_leader"
  ON clans FOR DELETE
  USING (leader_id = auth.uid());

-- ---------------------------------------------------------------------------
-- clan_members policies
-- ---------------------------------------------------------------------------
CREATE POLICY "clan_members_select"
  ON clan_members FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM clans
      WHERE clans.id = clan_members.clan_id
        AND (
          clans.is_public = true
          OR clans.leader_id = auth.uid()
          OR EXISTS (
            SELECT 1 FROM clan_members cm2
            WHERE cm2.clan_id = clans.id
              AND cm2.user_id = auth.uid()
          )
        )
    )
  );

CREATE POLICY "clan_members_insert"
  ON clan_members FOR INSERT
  WITH CHECK (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM clans
      WHERE clans.id = clan_members.clan_id
        AND clans.leader_id = auth.uid()
    )
  );

CREATE POLICY "clan_members_delete"
  ON clan_members FOR DELETE
  USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM clans
      WHERE clans.id = clan_members.clan_id
        AND clans.leader_id = auth.uid()
    )
  );

-- ---------------------------------------------------------------------------
-- rewards policies
-- ---------------------------------------------------------------------------
CREATE POLICY "rewards_select_own"
  ON rewards FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "rewards_update_own"
  ON rewards FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- reports policies
-- ---------------------------------------------------------------------------
CREATE POLICY "reports_insert_own"
  ON reports FOR INSERT
  WITH CHECK (reporter_id = auth.uid());

CREATE POLICY "reports_select_own_or_admin"
  ON reports FOR SELECT
  USING (
    reporter_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "reports_update_admin"
  ON reports FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ---------------------------------------------------------------------------
-- notifications policies
-- ---------------------------------------------------------------------------
CREATE POLICY "notifications_select_own"
  ON notifications FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "notifications_update_own"
  ON notifications FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- community_posts policies
-- ---------------------------------------------------------------------------
CREATE POLICY "community_posts_select_all"
  ON community_posts FOR SELECT
  USING (true);

CREATE POLICY "community_posts_insert_own"
  ON community_posts FOR INSERT
  WITH CHECK (author_id = auth.uid());

CREATE POLICY "community_posts_update_own"
  ON community_posts FOR UPDATE
  USING (author_id = auth.uid())
  WITH CHECK (author_id = auth.uid());

CREATE POLICY "community_posts_delete_own"
  ON community_posts FOR DELETE
  USING (
    author_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ---------------------------------------------------------------------------
-- post_comments policies
-- ---------------------------------------------------------------------------
CREATE POLICY "post_comments_select_all"
  ON post_comments FOR SELECT
  USING (true);

CREATE POLICY "post_comments_insert_own"
  ON post_comments FOR INSERT
  WITH CHECK (author_id = auth.uid());

CREATE POLICY "post_comments_update_own"
  ON post_comments FOR UPDATE
  USING (author_id = auth.uid())
  WITH CHECK (author_id = auth.uid());

CREATE POLICY "post_comments_delete_own"
  ON post_comments FOR DELETE
  USING (
    author_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ---------------------------------------------------------------------------
-- likes policies
-- ---------------------------------------------------------------------------
CREATE POLICY "likes_select_all"
  ON likes FOR SELECT
  USING (true);

CREATE POLICY "likes_insert_own"
  ON likes FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "likes_delete_own"
  ON likes FOR DELETE
  USING (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- blocks policies
-- ---------------------------------------------------------------------------
CREATE POLICY "blocks_select_own"
  ON blocks FOR SELECT
  USING (blocker_id = auth.uid());

CREATE POLICY "blocks_insert_own"
  ON blocks FOR INSERT
  WITH CHECK (blocker_id = auth.uid());

CREATE POLICY "blocks_delete_own"
  ON blocks FOR DELETE
  USING (blocker_id = auth.uid());


-- ============================================================================
-- FUNCTIONS & TRIGGERS
-- ============================================================================

-- ---------------------------------------------------------------------------
-- handle_new_user: auto-create profile on auth.users insert
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, nickname, avatar_url)
  VALUES (
    NEW.id,
    COALESCE(
      NEW.raw_user_meta_data ->> 'nickname',
      'user_' || substr(NEW.id::text, 1, 8)
    ),
    NEW.raw_user_meta_data ->> 'avatar_url'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ---------------------------------------------------------------------------
-- increment_participant_count: update clues.current_participants on join
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION increment_participant_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE clues
    SET current_participants = current_participants + 1
    WHERE id = NEW.clue_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE clues
    SET current_participants = GREATEST(current_participants - 1, 0)
    WHERE id = OLD.clue_id;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_participation_change
  AFTER INSERT OR DELETE ON participations
  FOR EACH ROW EXECUTE FUNCTION increment_participant_count();

-- ---------------------------------------------------------------------------
-- nearby_clues: find active clues within a given radius using PostGIS
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION nearby_clues(
  lat double precision,
  lng double precision,
  radius_km double precision DEFAULT 10
)
RETURNS SETOF clues AS $$
BEGIN
  RETURN QUERY
  SELECT *
  FROM clues
  WHERE status IN ('approved', 'active')
    AND location IS NOT NULL
    AND ST_DWithin(
      location,
      ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography,
      radius_km * 1000  -- convert km to meters
    )
  ORDER BY
    ST_Distance(
      location,
      ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography
    ) ASC;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;
