-- ============================================================================
-- 039 · K2 다이아 경제 재설계 + K5 구매 영수증 인증 스텝
-- ============================================================================
-- [K2] 문제: 기존 시드 패키지의 +15%/+20% 보너스는 기프티콘 도매가율(~90%)을
--   초과 → 헤비유저 기준 역마진 (예: 30,000원 → 3,600다이아 → 정가 36,000원어치
--   기프티콘 = 도매 32,400원 지출 = 건당 -2,400원 적자).
--   재설계 룰: 보너스율 ≤ (1/도매가율 - 1) ≈ 11%. 보너스 = 사용자 효용(정가 대비
--   이득)이며 UI에 가시화한다. 추가 마진은 가게 메뉴 결제(사장 수수료 부담)에서.
--
-- [K5] 문제: 방문 ≠ 구매 — 사장 ROI를 증명할 측정 도구 부재.
--   해결: RECEIPT 스텝 타입 — 구매 영수증 사진 인증. 사장 리포트에서
--   "구매 인증 완료 수"를 셀 수 있는 최초의 전환 지표.
-- ============================================================================

-- [K2] 패키지 보너스 재조정 — 마진 안전선 5/8/10%
UPDATE public.diamond_packages SET diamond_amount = 100,  bonus_label = NULL
 WHERE price_krw = 1000;
UPDATE public.diamond_packages SET diamond_amount = 525,  bonus_label = '+5% 보너스'
 WHERE price_krw = 5000;
UPDATE public.diamond_packages SET diamond_amount = 1080, bonus_label = '+8% 보너스'
 WHERE price_krw = 10000;
UPDATE public.diamond_packages SET diamond_amount = 3300, bonus_label = '+10% 보너스'
 WHERE price_krw = 30000;

-- [K5] RECEIPT 스텝 타입 추가
ALTER TABLE steps DROP CONSTRAINT IF EXISTS steps_type_check;
ALTER TABLE steps ADD CONSTRAINT steps_type_check
  CHECK (type = ANY (ARRAY[
    'checkpoint','snapshot','quest','ox_quiz','list','board','panorama','facial',
    'CHECKPOINT','SNAPSHOT','QUEST','OX_QUIZ','LIST','BOARD','PANORAMA','FACIAL',
    'PHOTO_SIM','MOTION_SIM','photo_sim','motion_sim',
    'GROUP_PHOTO','PARTY_MISSION','group_photo','party_mission',
    'RECEIPT','receipt'
  ]));

-- [K5] 사장 리포트용 — 클루별 구매 인증 전환 뷰
-- (방문자 수 대비 영수증 인증 완료 수 = 방문→구매 전환율)
CREATE OR REPLACE VIEW public.clue_purchase_conversion_v1 AS
SELECT
  c.id              AS clue_id,
  c.title,
  c.creator_id,
  count(DISTINCT p.user_id)                            AS visitors,
  count(DISTINCT e.participation_id)                   AS purchase_proofs,
  CASE WHEN count(DISTINCT p.user_id) > 0
       THEN round(100.0 * count(DISTINCT e.participation_id)
            / count(DISTINCT p.user_id), 1)
       ELSE 0 END                                      AS conversion_pct
FROM clues c
JOIN participations p ON p.clue_id = c.id
  AND p.status IN ('in_progress','completed')
LEFT JOIN steps s ON s.clue_id = c.id AND upper(s.type) = 'RECEIPT'
LEFT JOIN evidences e ON e.step_id = s.id
GROUP BY c.id, c.title, c.creator_id;
