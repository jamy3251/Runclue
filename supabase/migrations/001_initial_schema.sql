-- RunClue 초기 스키마
-- Supabase SQL Editor에서 실행하세요

-- ============================================================
-- 1. PROFILES (auth.users 트리거로 자동 생성)
-- ============================================================
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  nickname text not null default 'guest_' || substr(gen_random_uuid()::text, 1, 6),
  avatar_url text,
  bio text,
  total_points integer not null default 0,
  badge_count integer not null default 0,
  clues_created integer not null default 0,
  clues_completed integer not null default 0,
  completed_clues integer not null default 0,
  is_creator boolean not null default false,
  role text not null default 'user' check (role in ('user', 'moderator', 'admin')),
  notification_settings jsonb default '{}',
  privacy_settings jsonb default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 회원가입 시 자동 프로필 생성 트리거
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, nickname)
  values (new.id, 'guest_' || substr(new.id::text, 1, 6));
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ============================================================
-- 2. CLANS
-- ============================================================
create table if not exists public.clans (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  avatar_url text,
  leader_id uuid not null references public.profiles(id) on delete cascade,
  member_count integer not null default 1,
  total_points integer not null default 0,
  is_public boolean not null default true,
  max_members integer not null default 50,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.clan_members (
  clan_id uuid not null references public.clans(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role text not null default 'member' check (role in ('member', 'officer', 'leader')),
  joined_at timestamptz not null default now(),
  primary key (clan_id, user_id)
);

-- ============================================================
-- 3. CLUES
-- ============================================================
create table if not exists public.clues (
  id uuid primary key default gen_random_uuid(),
  creator_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  description text,
  category text not null default 'adventure',
  status text not null default 'draft' check (status in ('draft','pending_approval','approved','active','completed','rejected','suspended')),
  is_public boolean not null default true,
  max_participants integer,
  current_participants integer not null default 0,
  start_time timestamptz,
  end_time timestamptz,
  time_limit_minutes integer,
  center_latitude double precision,
  center_longitude double precision,
  center_address text,
  radius_meters double precision,
  address text,
  thumbnail_url text,
  reward_type text check (reward_type in ('points','badge','coupon','prize','certificate')),
  reward_value text,
  requires_approval boolean not null default false,
  tags text[] default '{}',
  view_count integer not null default 0,
  like_count integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_clues_creator on public.clues(creator_id);
create index idx_clues_status on public.clues(status);
create index idx_clues_category on public.clues(category);
create index idx_clues_location on public.clues(center_latitude, center_longitude) where center_latitude is not null;

-- ============================================================
-- 4. STEPS
-- ============================================================
create table if not exists public.steps (
  id uuid primary key default gen_random_uuid(),
  clue_id uuid not null references public.clues(id) on delete cascade,
  order_index integer not null default 0,
  type text not null check (type in ('checkpoint','snapshot','quest','ox_quiz','list','board','panorama','facial')),
  title text,
  description text,
  instruction text,
  target_latitude double precision,
  target_longitude double precision,
  location_radius_meters double precision,
  reference_image_url text,
  quest_question text,
  quest_answer text,
  quest_answer_type text,
  quiz_correct_answer boolean,
  quiz_explanation text,
  quiz_time_limit_seconds integer,
  checklist_items jsonb,
  validation_type text not null default 'auto' check (validation_type in ('auto','delayed','manual')),
  points integer not null default 0,
  is_required boolean not null default true,
  time_limit_seconds integer,
  hint text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_steps_clue on public.steps(clue_id, order_index);

-- ============================================================
-- 5. PARTICIPATIONS
-- ============================================================
create table if not exists public.participations (
  id uuid primary key default gen_random_uuid(),
  clue_id uuid not null references public.clues(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  clan_id uuid references public.clans(id),
  status text not null default 'joined' check (status in ('joined','in_progress','completed','abandoned','disqualified')),
  current_step_index integer not null default 0,
  started_at timestamptz,
  completed_at timestamptz,
  total_points_earned integer not null default 0,
  rank integer,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(clue_id, user_id)
);

create index idx_participations_user on public.participations(user_id);
create index idx_participations_clue on public.participations(clue_id);

-- ============================================================
-- 6. EVIDENCES
-- ============================================================
create table if not exists public.evidences (
  id uuid primary key default gen_random_uuid(),
  step_id uuid not null references public.steps(id) on delete cascade,
  participation_id uuid not null references public.participations(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  type text not null check (type in ('photo','location','video','qr_scan','text_answer','ox_answer','checklist')),
  media_url text,
  text_content text,
  boolean_answer boolean,
  checklist_state jsonb,
  submitted_latitude double precision,
  submitted_longitude double precision,
  status text not null default 'pending' check (status in ('pending','approved','rejected','auto_approved','auto_rejected')),
  validated_at timestamptz,
  validated_by uuid references public.profiles(id),
  rejection_reason text,
  submitted_at timestamptz default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_evidences_participation on public.evidences(participation_id);
create index idx_evidences_step on public.evidences(step_id);

-- ============================================================
-- 7. REWARDS
-- ============================================================
create table if not exists public.rewards (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  clue_id uuid not null references public.clues(id) on delete cascade,
  participation_id uuid not null references public.participations(id) on delete cascade,
  type text not null check (type in ('points','badge','coupon','prize','certificate')),
  value text,
  badge_name text,
  badge_icon_url text,
  coupon_code text,
  is_claimed boolean not null default false,
  claimed_at timestamptz,
  expires_at timestamptz,
  created_at timestamptz not null default now()
);

create index idx_rewards_user on public.rewards(user_id);

-- ============================================================
-- 8. COMMUNITY
-- ============================================================
create table if not exists public.community_posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles(id) on delete cascade,
  clue_id uuid references public.clues(id),
  type text not null default 'general' check (type in ('review','tip','photo','question','general')),
  title text,
  content text not null,
  media_urls text[] default '{}',
  like_count integer not null default 0,
  comment_count integer not null default 0,
  is_pinned boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_posts_author on public.community_posts(author_id);

create table if not exists public.post_comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.community_posts(id) on delete cascade,
  author_id uuid not null references public.profiles(id) on delete cascade,
  content text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.likes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  target_type text not null check (target_type in ('clue','post')),
  target_id uuid not null,
  created_at timestamptz not null default now(),
  unique(user_id, target_type, target_id)
);

-- ============================================================
-- 9. NOTIFICATIONS
-- ============================================================
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  type text not null,
  title text not null,
  body text not null,
  data jsonb default '{}',
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create index idx_notifications_user on public.notifications(user_id, is_read);

-- ============================================================
-- 10. REPORTS
-- ============================================================
create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  target_type text not null check (target_type in ('clue','user','evidence','community_post')),
  target_id uuid not null,
  reason text not null check (reason in ('inappropriate','spam','fraud','safety','harassment','copyright','other')),
  description text,
  created_at timestamptz not null default now()
);

-- ============================================================
-- 11. BLOCKS
-- ============================================================
create table if not exists public.blocks (
  id uuid primary key default gen_random_uuid(),
  blocker_user_id uuid not null references public.profiles(id) on delete cascade,
  blocked_user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique(blocker_user_id, blocked_user_id)
);

-- ============================================================
-- RPC FUNCTIONS
-- ============================================================

-- 근처 클루 검색 (PostGIS 없이 위도/경도 거리 계산)
create or replace function public.nearby_clues(
  user_lat double precision,
  user_lng double precision,
  radius_km double precision default 10
)
returns setof public.clues as $$
begin
  return query
    select *
    from public.clues
    where status = 'active'
      and center_latitude is not null
      and center_longitude is not null
      and (
        6371 * acos(
          cos(radians(user_lat)) * cos(radians(center_latitude))
          * cos(radians(center_longitude) - radians(user_lng))
          + sin(radians(user_lat)) * sin(radians(center_latitude))
        )
      ) <= radius_km
    order by (
      6371 * acos(
        cos(radians(user_lat)) * cos(radians(center_latitude))
        * cos(radians(center_longitude) - radians(user_lng))
        + sin(radians(user_lat)) * sin(radians(center_latitude))
      )
    )
    limit 50;
end;
$$ language plpgsql stable;

-- 플랫폼 통계
create or replace function public.get_platform_stats()
returns json as $$
declare
  result json;
begin
  select json_build_object(
    'total_participants', (select count(*) from public.profiles),
    'cumulative_earnings', (select coalesce(sum(total_points), 0) from public.profiles),
    'active_missions', (select count(*) from public.clues where status = 'active')
  ) into result;
  return result;
end;
$$ language plpgsql stable;

-- 조회수 증가
create or replace function public.increment_view_count(p_clue_id uuid)
returns void as $$
begin
  update public.clues set view_count = view_count + 1 where id = p_clue_id;
end;
$$ language plpgsql;

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================
alter table public.profiles enable row level security;
alter table public.clues enable row level security;
alter table public.steps enable row level security;
alter table public.participations enable row level security;
alter table public.evidences enable row level security;
alter table public.rewards enable row level security;
alter table public.clans enable row level security;
alter table public.clan_members enable row level security;
alter table public.community_posts enable row level security;
alter table public.post_comments enable row level security;
alter table public.likes enable row level security;
alter table public.notifications enable row level security;
alter table public.reports enable row level security;
alter table public.blocks enable row level security;

-- Profiles: 누구나 읽기, 본인만 수정
create policy "profiles_select" on public.profiles for select using (true);
create policy "profiles_update" on public.profiles for update using (auth.uid() = id);
create policy "profiles_insert" on public.profiles for insert with check (auth.uid() = id);

-- Clues: 누구나 읽기, 크리에이터만 수정/삭제
create policy "clues_select" on public.clues for select using (true);
create policy "clues_insert" on public.clues for insert with check (auth.uid() = creator_id);
create policy "clues_update" on public.clues for update using (auth.uid() = creator_id);
create policy "clues_delete" on public.clues for delete using (auth.uid() = creator_id);

-- Steps: 클루와 동일 정책
create policy "steps_select" on public.steps for select using (true);
create policy "steps_insert" on public.steps for insert with check (
  exists (select 1 from public.clues where id = clue_id and creator_id = auth.uid())
);
create policy "steps_update" on public.steps for update using (
  exists (select 1 from public.clues where id = clue_id and creator_id = auth.uid())
);
create policy "steps_delete" on public.steps for delete using (
  exists (select 1 from public.clues where id = clue_id and creator_id = auth.uid())
);

-- Participations: 본인만 읽기/생성, 클루 크리에이터도 읽기 가능
create policy "participations_select" on public.participations for select using (
  auth.uid() = user_id or
  exists (select 1 from public.clues where id = clue_id and creator_id = auth.uid())
);
create policy "participations_insert" on public.participations for insert with check (auth.uid() = user_id);
create policy "participations_update" on public.participations for update using (auth.uid() = user_id);

-- Evidences: 참여자 + 클루 크리에이터
create policy "evidences_select" on public.evidences for select using (
  auth.uid() = user_id or
  exists (select 1 from public.clues c join public.steps s on c.id = s.clue_id where s.id = step_id and c.creator_id = auth.uid())
);
create policy "evidences_insert" on public.evidences for insert with check (auth.uid() = user_id);
create policy "evidences_update" on public.evidences for update using (
  auth.uid() = user_id or
  exists (select 1 from public.clues c join public.steps s on c.id = s.clue_id where s.id = step_id and c.creator_id = auth.uid())
);

-- Rewards: 본인만
create policy "rewards_select" on public.rewards for select using (auth.uid() = user_id);
create policy "rewards_insert" on public.rewards for insert with check (auth.uid() = user_id);

-- Clans: 누구나 읽기
create policy "clans_select" on public.clans for select using (true);
create policy "clans_insert" on public.clans for insert with check (auth.uid() = leader_id);
create policy "clans_update" on public.clans for update using (auth.uid() = leader_id);

-- Clan Members
create policy "clan_members_select" on public.clan_members for select using (true);
create policy "clan_members_insert" on public.clan_members for insert with check (auth.uid() = user_id);
create policy "clan_members_delete" on public.clan_members for delete using (
  auth.uid() = user_id or
  exists (select 1 from public.clans where id = clan_id and leader_id = auth.uid())
);

-- Community: 누구나 읽기, 본인 작성/수정/삭제
create policy "posts_select" on public.community_posts for select using (true);
create policy "posts_insert" on public.community_posts for insert with check (auth.uid() = author_id);
create policy "posts_update" on public.community_posts for update using (auth.uid() = author_id);
create policy "posts_delete" on public.community_posts for delete using (auth.uid() = author_id);

create policy "comments_select" on public.post_comments for select using (true);
create policy "comments_insert" on public.post_comments for insert with check (auth.uid() = author_id);
create policy "comments_delete" on public.post_comments for delete using (auth.uid() = author_id);

-- Likes
create policy "likes_select" on public.likes for select using (true);
create policy "likes_insert" on public.likes for insert with check (auth.uid() = user_id);
create policy "likes_delete" on public.likes for delete using (auth.uid() = user_id);

-- Notifications: 본인만
create policy "notifications_select" on public.notifications for select using (auth.uid() = user_id);
create policy "notifications_update" on public.notifications for update using (auth.uid() = user_id);
create policy "notifications_delete" on public.notifications for delete using (auth.uid() = user_id);

-- Reports: 본인이 생성한 것만 읽기
create policy "reports_select" on public.reports for select using (auth.uid() = reporter_id);
create policy "reports_insert" on public.reports for insert with check (auth.uid() = reporter_id);

-- Blocks: 본인 차단 목록만
create policy "blocks_select" on public.blocks for select using (auth.uid() = blocker_user_id);
create policy "blocks_insert" on public.blocks for insert with check (auth.uid() = blocker_user_id);
create policy "blocks_delete" on public.blocks for delete using (auth.uid() = blocker_user_id);

-- ============================================================
-- STORAGE BUCKETS
-- ============================================================
-- Supabase 대시보드에서 수동 생성 필요:
-- 1. evidence (public: false)
-- 2. profiles (public: true)
-- 3. clues (public: true)
--
-- Storage Policy 예시 (대시보드 > Storage > Policies):
-- evidence: authenticated users can upload to own path
-- profiles: authenticated users can upload to own path, public read
-- clues: authenticated users can upload to own clue path, public read

-- ============================================================
-- updated_at 자동 갱신 트리거
-- ============================================================
create or replace function public.update_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger profiles_updated_at before update on public.profiles
  for each row execute function public.update_updated_at();
create trigger clues_updated_at before update on public.clues
  for each row execute function public.update_updated_at();
create trigger steps_updated_at before update on public.steps
  for each row execute function public.update_updated_at();
create trigger participations_updated_at before update on public.participations
  for each row execute function public.update_updated_at();
create trigger evidences_updated_at before update on public.evidences
  for each row execute function public.update_updated_at();
create trigger posts_updated_at before update on public.community_posts
  for each row execute function public.update_updated_at();
create trigger comments_updated_at before update on public.post_comments
  for each row execute function public.update_updated_at();
