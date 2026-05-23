-- ============================================================================
-- 004 · steps.type CHECK 확장 — 대소문자 + PHOTO_SIM/MOTION_SIM 허용
-- ============================================================================
-- 배경:
--   003까지 적용했지만 steps.type 이 소문자만 허용 (checkpoint, snapshot, ...)
--   인데 앱은 'CHECKPOINT', 'PHOTO_SIM' 등 대문자로 INSERT → 23514 (CHECK 위반)
--   에러로 모든 step 저장 silently 실패. step_service의 retry/매핑은 이 케이스를
--   못 잡아서 12회 재시도 후 throw. 결과: 클루는 만들어지는데 step이 0개.
--   참여하면 "데이터 못 불러옴" 에러로 사용자 경험 깨짐.
--
-- 적용 방법:
--   Supabase Dashboard → SQL Editor → 본 파일 전체 RUN. 멱등.
-- ============================================================================

ALTER TABLE steps DROP CONSTRAINT IF EXISTS steps_type_check;
ALTER TABLE steps ADD CONSTRAINT steps_type_check
  CHECK (type = ANY (ARRAY[
    -- lowercase (legacy + freezed model)
    'checkpoint','snapshot','quest','ox_quiz','list','board','panorama','facial',
    -- uppercase (current app code)
    'CHECKPOINT','SNAPSHOT','QUEST','OX_QUIZ','LIST','BOARD','PANORAMA','FACIAL',
    -- 신규 SIM 타입
    'PHOTO_SIM','MOTION_SIM','photo_sim','motion_sim'
  ]));
