-- ============================================================================
-- 038 · 단체전 인증 스텝 타입 — GROUP_PHOTO / PARTY_MISSION
-- ============================================================================
-- 용도: MT 시즌 보물찾기, 학교/동아리 단체전, 파티 게임 등.
--   GROUP_PHOTO   : 단체 인증샷 — 지정 인원과 함께 찍기 (예: "조원 4명 모두")
--   PARTY_MISSION : 파티 미션 인증 — 호스트가 지정한 미션 수행 사진
--                   (예: 응원구호 외치기, 벌칙 수행, 조별 포즈)
-- 검증: 사진 제출 (validation_type='manual' — 호스트/참가자 상호 확인).
-- 인원수 자동 검출(얼굴 인식)은 P2.
-- ============================================================================

ALTER TABLE steps DROP CONSTRAINT IF EXISTS steps_type_check;
ALTER TABLE steps ADD CONSTRAINT steps_type_check
  CHECK (type = ANY (ARRAY[
    'checkpoint','snapshot','quest','ox_quiz','list','board','panorama','facial',
    'CHECKPOINT','SNAPSHOT','QUEST','OX_QUIZ','LIST','BOARD','PANORAMA','FACIAL',
    'PHOTO_SIM','MOTION_SIM','photo_sim','motion_sim',
    'GROUP_PHOTO','PARTY_MISSION','group_photo','party_mission'
  ]));
