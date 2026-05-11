-- ============================================================================
-- 003 · Storage 버킷 + RLS 정책
-- ============================================================================
-- 배경:
--   storage_service.dart는 3개 버킷을 사용하는데 (clues / evidence / profiles)
--   001 마이그레이션이 storage 설정을 다루지 않아서 버킷이 존재하지 않음.
--   결과: clue 썸네일 / 증거 사진 / 프로필 아바타 업로드가 모두 silently 실패.
--
-- 적용 방법:
--   Supabase Dashboard → SQL Editor → 본 파일 전체 붙여넣기 후 RUN.
--   ON CONFLICT DO NOTHING / IF NOT EXISTS 패턴이라 멱등.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. 버킷 생성 (public read, owner write)
-- ---------------------------------------------------------------------------
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  ('clues',    'clues',    true,  10485760, ARRAY['image/jpeg','image/png','image/webp']),
  ('evidence', 'evidence', true,  20971520, ARRAY['image/jpeg','image/png','image/webp']),
  ('profiles', 'profiles', true,   5242880, ARRAY['image/jpeg','image/png','image/webp'])
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- ---------------------------------------------------------------------------
-- 2. clues 버킷 정책 — 누구나 read, 로그인 사용자만 write
-- ---------------------------------------------------------------------------
-- clue 썸네일은 탐색에서 모두에게 노출되므로 public read.
-- write는 일단 인증된 사용자 누구나 — clue 생성 RLS가 이미 creator만 허용하므로
-- 사이드 효과 없음.
DROP POLICY IF EXISTS "clues_storage_read" ON storage.objects;
CREATE POLICY "clues_storage_read"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'clues');

DROP POLICY IF EXISTS "clues_storage_write" ON storage.objects;
CREATE POLICY "clues_storage_write"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'clues' AND auth.role() = 'authenticated');

DROP POLICY IF EXISTS "clues_storage_update" ON storage.objects;
CREATE POLICY "clues_storage_update"
  ON storage.objects FOR UPDATE
  USING (bucket_id = 'clues' AND auth.role() = 'authenticated');

-- ---------------------------------------------------------------------------
-- 3. evidence 버킷 정책 — public read (호스트가 확인), 인증 write
-- ---------------------------------------------------------------------------
-- evidence 사진은 일반적으로는 본인만 봐야 하지만, host가 검수해야 하므로
-- public read로 단순화. (Wave 2에서 signed URL + 호스트만 검수로 강화 권장)
DROP POLICY IF EXISTS "evidence_storage_read" ON storage.objects;
CREATE POLICY "evidence_storage_read"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'evidence');

DROP POLICY IF EXISTS "evidence_storage_write" ON storage.objects;
CREATE POLICY "evidence_storage_write"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'evidence' AND auth.role() = 'authenticated');

DROP POLICY IF EXISTS "evidence_storage_update" ON storage.objects;
CREATE POLICY "evidence_storage_update"
  ON storage.objects FOR UPDATE
  USING (bucket_id = 'evidence' AND auth.role() = 'authenticated');

-- ---------------------------------------------------------------------------
-- 4. profiles 버킷 정책 — public read, 본인만 write
-- ---------------------------------------------------------------------------
-- 아바타는 공개. 본인 폴더(첫 segment가 user_id)에만 write 허용.
DROP POLICY IF EXISTS "profiles_storage_read" ON storage.objects;
CREATE POLICY "profiles_storage_read"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'profiles');

DROP POLICY IF EXISTS "profiles_storage_write" ON storage.objects;
CREATE POLICY "profiles_storage_write"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'profiles'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

DROP POLICY IF EXISTS "profiles_storage_update" ON storage.objects;
CREATE POLICY "profiles_storage_update"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'profiles'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

DROP POLICY IF EXISTS "profiles_storage_delete" ON storage.objects;
CREATE POLICY "profiles_storage_delete"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'profiles'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- ---------------------------------------------------------------------------
-- 검증
-- ---------------------------------------------------------------------------
-- SELECT id, name, public, file_size_limit FROM storage.buckets ORDER BY id;
-- SELECT policyname, cmd FROM pg_policies WHERE schemaname='storage' AND tablename='objects' ORDER BY policyname;
