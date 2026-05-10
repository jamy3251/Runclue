# RunClue 골든패스 5분 테스트 시나리오

> 새 빌드 설치 후 이 문서대로 따라가면 클루 만들기 → 참여 → 완료 → 보상 흐름이 5분 안에 검증됩니다.

---

## STEP 0 (1회만): Supabase 백엔드 정합성 SQL

새로 추가된 컬럼이 모두 존재하는지 확실히 하려면 한 번만 실행. **이미 돌렸으면 skip**.

https://supabase.com/dashboard/project/cwhhekrtqkwaaabztmrq/sql/new

```sql
-- clues 테이블
ALTER TABLE clues
  ADD COLUMN IF NOT EXISTS lat double precision,
  ADD COLUMN IF NOT EXISTS lng double precision,
  ADD COLUMN IF NOT EXISTS address text,
  ADD COLUMN IF NOT EXISTS reward_label text,
  ADD COLUMN IF NOT EXISTS distribution_mode text DEFAULT 'first_come',
  ADD COLUMN IF NOT EXISTS current_participants integer DEFAULT 0;

-- steps 테이블
ALTER TABLE steps
  ADD COLUMN IF NOT EXISTS target_lat double precision,
  ADD COLUMN IF NOT EXISTS target_lng double precision,
  ADD COLUMN IF NOT EXISTS reference_image_url text;

-- participations 테이블 (랭킹·보상 결과 저장용)
ALTER TABLE participations
  ADD COLUMN IF NOT EXISTS rank integer,
  ADD COLUMN IF NOT EXISTS total_points_earned integer DEFAULT 0,
  ADD COLUMN IF NOT EXISTS reward_status text DEFAULT 'pending';

-- RLS 끄기 (이미 한 상태일 가능성 높음)
ALTER TABLE clues DISABLE ROW LEVEL SECURITY;
ALTER TABLE steps DISABLE ROW LEVEL SECURITY;
ALTER TABLE participations DISABLE ROW LEVEL SECURITY;
ALTER TABLE evidences DISABLE ROW LEVEL SECURITY;
```

성공하면 다음 검증:
```sql
SELECT column_name FROM information_schema.columns
WHERE table_name = 'participations' AND column_name IN ('rank','total_points_earned','reward_status');
-- 3개 모두 보여야 함
```

---

## STEP 1: 테스트용 빠른 클루 만들기 (선택지 A 또는 B)

### 옵션 A — 앱에서 직접 만들기 (실제 사용자 경험 검증)

1. 폰에서 RunClue 실행 → 로그인
2. 탐색 탭 → FAB(+ 노란 버튼) 탭 → 클루 만들기
3. **Step 1 기본정보**:
   - 썸네일: 생략 OK
   - 제목: `골든패스 테스트`
   - 카테고리: `퀴즈`
   - 소개: `OX 퀴즈로 빠른 테스트입니다. 답은 O입니다.` (10자 이상)
   - 다음
4. **Step 2 매장·위치**:
   - 매장명: `테스트 매장`
   - 주소: `서울 동대문구 회기로 12`
   - 인증 반경: `9999` (반경 매우 크게 → GPS 어디서든 통과)
   - 다음
5. **Step 3 단계 추가**:
   - "단계 추가" 탭
   - 유형: **OX 퀴즈** 선택
   - 단계 제목: `간단 OX`
   - 안내: `이 클루는 테스트용입니다. O를 선택하세요.`
   - OX 정답: `O (예)`
   - "단계 추가"
   - 다음
6. **Step 4 보상·분배**:
   - 보상 종류: **메뉴 할인**
   - 보상 내용: `아메리카노 무료`
   - 보상 가치: `4500`
   - 분배 방식: **전원 지급** (가장 단순한 검증)
   - 다음
7. **Step 5 미리보기 → 제출하기**
8. "자동 승인 완료" 다이얼로그 뜨면 → "탐색에서 확인"

### 옵션 B — SQL로 직접 삽입 (앱 등록이 안 될 때 우회)

```sql
WITH new_clue AS (
  INSERT INTO clues (title, description, category, status, creator_id, reward_value, reward_label, reward_type, distribution_mode, current_participants, lat, lng)
  VALUES (
    '골든패스 SQL 테스트',
    'SQL Editor로 직접 만든 OX 퀴즈',
    '퀴즈',
    'active',
    (SELECT id FROM auth.users LIMIT 1),
    4500,
    '아메리카노 무료',
    'menu_discount',
    'all',
    0,
    37.5836,
    127.0588
  )
  RETURNING id
)
INSERT INTO steps (clue_id, order_index, type, title, instruction, quiz_correct_answer, validation_type, target_lat, target_lng, location_radius_meters)
SELECT id, 0, 'OX_QUIZ', 'O를 선택', '이 테스트는 O가 정답입니다', true, 'auto', 37.5836, 127.0588, 9999
FROM new_clue
RETURNING clue_id, type;
```

---

## STEP 2: 탐색 → 클루 발견 → 참여

1. 탐색 탭으로 이동
2. 만든 클루(`골든패스 테스트`)가 리스트에 보이는지 확인
   - 안 보이면: 화면 끌어내려 새로고침 (pull-to-refresh)
3. 카드 탭 → ClueDetail 진입
4. 통계 카드(상금/참여중/마감), 단계 타임라인 확인
5. 하단 **"지금 참여하기"** 탭

**검증 포인트**: Supabase에서
```sql
SELECT id, status, current_step_index, user_id FROM participations
WHERE clue_id = '<위에서 만든 클루 ID>'
ORDER BY created_at DESC LIMIT 1;
```
→ 1 row 보이면 OK. `status='in_progress'`, `current_step_index=0`.

---

## STEP 3: 단계 풀기 → 완료

1. CluePlay 화면 진입
2. OX 단계 표시
3. **O** 버튼 탭 → 선택됨 (파란색 음영)
4. 화면 아래 **"완료하기"** (마지막 단계) 탭
5. evidence 제출 → 자동 검증 → 클루 완료

**예상 흐름**:
- evidence_service가 evidence INSERT
- completeParticipation:
  - 본인보다 먼저 완료한 사람 0명 → rank=1
  - distribution_mode='all' → 전원 지급 → earnedPoints=4500
  - reward_status='eligible'
- Result 화면으로 navigation

---

## STEP 4: Result 화면 검증

화면에 보여야 할 것:
- 풀스크린 컨페티 + "MISSION CLEAR!" + 트로피
- 미션 제목 표시
- "₩4500 적립 완료" 초록 배지

화면 탭 → 결과 상세 패널 슬라이드업:
- **보상 카드 (초록 강조)**: "보상 획득! / 아메리카노 무료 (₩4500 상당) / 완료자 전원 지급"
- 최종 순위: 🏆 1위
- 분배 방식: 전원 지급
- 완료 시간: ~몇 초 / 분
- "공유" / "다음 미션" 버튼

---

## STEP 5: DB 최종 검증

Supabase SQL Editor:
```sql
SELECT 
  p.id,
  p.status,
  p.rank,
  p.total_points_earned,
  p.reward_status,
  p.completed_at,
  c.title,
  c.distribution_mode
FROM participations p
JOIN clues c ON c.id = p.clue_id
WHERE p.user_id = (SELECT id FROM auth.users LIMIT 1)
ORDER BY p.completed_at DESC
LIMIT 5;
```

기대값:
| 컬럼 | 값 |
|---|---|
| status | `completed` |
| rank | `1` |
| total_points_earned | `4500` |
| reward_status | `eligible` |
| completed_at | (방금 시간) |
| title | `골든패스 테스트` |
| distribution_mode | `all` |

세 줄(`rank`, `total_points_earned`, `reward_status`)이 채워져 있으면 **end-to-end 통과**.

---

## 다른 분배 방식 검증 (선택)

- **선착순 1명** 테스트: `distribution_mode='first_come'`, `max_participants=1` → 두 번째 사용자는 reward=0
- **등수별** 테스트: `distribution_mode='rank'`, `max_participants=3` → 1등 4500원, 2등 3000원, 3등 1500원
- **랜덤** 테스트: `distribution_mode='random'` → 완료 직후엔 `pending_lottery`, 추첨 배치 후 결정 (현재 MVP 미구현)

---

## 트러블슈팅

| 증상 | 원인·픽스 |
|---|---|
| 클루 제출 시 "INSERT 실패 [code=PGRST204]" | STEP 0의 ALTER TABLE 미실행 — SQL 다시 돌리기 |
| 탐색에 클루 안 보임 | trendingCluesProvider 캐시 — 화면 끌어내려 새로고침 |
| "참여 등록 실패" | RLS 활성화 상태 — STEP 0의 DISABLE ROW LEVEL SECURITY 실행 |
| 완료 후 Result 화면 보상 0 | DB 컬럼 누락 — STEP 0 SQL 실행 |
| 완료 후 빈 Result | 새 빌드 미설치 — 최신 APK(2026-05-11 03:38) 재설치 |
| 같은 계정으로 재참여 시 처음부터 시작 안 됨 | 의도된 동작 (중복 join 방지) — 다른 계정으로 테스트 |

---

## 다음 검증 (Wave 2)

- 두 디바이스에서 동시 완료 → rank 1과 2가 정확히 매겨지는지
- 등수별 분배에서 rank별 ratio 계산 확인
- 사진 유사도(PHOTO_SIM) 단계로 만들고 채점 시각화 확인
- 모션 유사도(MOTION_SIM) 정답지 업로드 후 따라하기
