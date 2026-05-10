# RunClue MVP 사용 설명서

> **버전**: MVP v1.0 — 캠퍼스타운 베타 피벗
> **작성일**: 2026.05
> **슬로건**: 방문하자, 풀자, 벌자.

---

## 1. 피벗 배경 (Why)

### 1.1 발견한 문제
대학교 주변 상권은 **방학 기간 매출이 학기 대비 1/8 수준**까지 위축됩니다. 서비스 러닝 수업으로 시립대 캠퍼스타운 매장을 컨설팅하면서 직접 확인한 수치입니다.

특히 서울시립대 주변은 다른 대학 상권과 다음 면에서 차별점이 있습니다:
- 고연령층 거주 비율이 높음
- 타 대학생/외국인 방문이 활성화되지 못함
- 방학 시 학생 유동인구 급감 → 매장 매출 직격탄

### 1.2 해법 가설
**AR 기반 지역사회 상생 리워드형 중개 플랫폼**으로 방문 동기를 만들면, 광고비 없이도 매장 방문률을 지속할 수 있다.

| 역할 | 행동 | 보상 |
|---|---|---|
| 탐험가 | 가게 방문 + AR 퀘스트 수행 | 메뉴 할인 / 기프티콘 (추후 캐시 리워드) |
| 크리에이터 | 매장별 퀘스트 설계 | 방문 수익 배분 |
| 사장님 | 매장에 퀘스트 등록 | 광고비 0원으로 방문률 지속 |

### 1.3 기존 컨셉과의 차이
| | 이전 (RUNCLUE v1) | 현재 (캠퍼스타운 피벗) |
|---|---|---|
| 슬로건 | 뛰자, 풀자, 벌자 | **방문하자**, 풀자, 벌자 |
| 핵심 동기 | 운동·탐험 | **매장 방문 + 상생** |
| 인증 방식 | GPS·카메라·OX | + **AR 모션 인식** |
| 보상 | 상금 | 메뉴 할인·기프티콘 → 캐시 |
| 타깃 시장 | 일반 위치기반 게임 | **시립대 캠퍼스타운 베타** |

---

## 2. MVP 범위 (What)

### 2.1 이번 빌드에 포함된 화면 (5개 + 셸)

| Screen | 파일 | 역할 |
|---|---|---|
| 01 Login | `app/lib/screens/auth/login_screen.dart` | 히어로 슬로건 + 사회증명 + 이메일/카카오/네이버/Google 로그인 |
| 02 Home | `app/lib/screens/home/home_screen.dart` | 플랫폼 스탯 + 역할 탭 + LIVE 카드 + 캠퍼스타운 페르소나 |
| 03 Explore | `app/lib/screens/explore/explore_screen.dart` | 매장 퀘스트 탐색, 검색·카테고리·정렬, 무한 스크롤, FAB |
| 06 Detail | `app/lib/screens/clue/detail/clue_detail_screen.dart` | 매장 퀘스트 상세, 3탭(구성/지도/리뷰), 단계 타임라인 |
| 08+09 Play→Result | `app/lib/screens/clue/play/clue_play_screen.dart`, `clue_result_screen.dart` | 퀘스트 진행 + 클리어 컨페티 + 보상 패널 |

### 2.2 바텀 네비게이션 (4탭 한글)
| 라우트 | 라벨 | 진입 화면 |
|---|---|---|
| `/home` | 홈 | HomeScreen |
| `/explore` | 탐색 | ExploreScreen |
| `/rank` | 랭킹 | MyProgressScreen |
| `/my-xp` | 내 정보 | ProfileScreen |

`/create` (퀘스트 만들기), `/community`, `/participate`는 셸 외부로 빠져 FAB·배너로 진입합니다.

### 2.3 후속 Wave (이번 MVP 범위 밖)
- Screen 04 CreateClue 6단계 위저드 (현재는 기본 화면만)
- Screen 05 MyProgress 폴리싱 (랭킹 + 스트릭 + 배지)
- Screen 07 BizLanding 사장님 랜딩
- Screen 10 Community 소통 광장
- Screen 11 WhyRunClue 경쟁 우위
- AR 모션 인식 SDK 연동 (현재는 GPS·카메라·OX·체크리스트만 동작)

---

## 3. 실행 방법 (How to run)

### 3.1 사전 준비
```bash
# Flutter 3.2+ 설치 확인
flutter --version

# 프로젝트 의존성 설치
cd app
flutter pub get
```

### 3.2 환경 변수
`.env` 파일이 이미 있으며 다음 키가 필요합니다:
```
SUPABASE_URL=https://cwhhekrtqkwaaabztmrq.supabase.co
SUPABASE_ANON_KEY=...
GOOGLE_MAPS_API_KEY=AIzaSy...
```

> ⚠️ Maps API key는 `build.gradle`이 `.env`에서 자동으로 읽어 `manifestPlaceholders`로 주입합니다 (이전 placeholder 크래시 픽스).

### 3.3 디버그 실행
```bash
cd app
flutter run --dart-define-from-file=.env
```

### 3.4 릴리스 APK 빌드
```bash
cd app
flutter build apk --release --dart-define-from-file=.env
# → build/app/outputs/flutter-apk/app-release.apk
```

### 3.5 분석 및 테스트
```bash
flutter analyze       # 0 errors (lint info만 남음)
flutter test test/services/   # 36/36 pass
```

---

## 4. 골든 패스 데모 시나리오

### 4.1 탐험가 흐름 (사장님 미팅·발표용)
1. 앱 시작 → **스플래시** (방문하자, 풀자, 벌자)
2. **로그인** → 카카오 또는 이메일 로그인
3. **홈** 진입
   - 플랫폼 스탯 확인 (베타 매장 N개, 누적 리워드, 활성 퀘스트)
   - 역할 탭 = 탐험가 고정
   - LIVE 카드 또는 페르소나 카드 탭
4. **탐색 (Explore)**
   - 검색바: "어떤 가게를 방문해볼까요?"
   - 카테고리 → 카페·맛집 / 근처 선택
   - 카드 탭
5. **클루 상세**
   - 미션 구성 탭 → 단계 타임라인 확인
   - 지도 탭 → 매장 위치 확인 (참여 전엔 블러)
   - "지금 참여하기" 탭
6. **StepPlay**
   - 미니맵·힌트 카드·GPS 인증 또는 카메라 인증
   - 마지막 스텝 제출
7. **Result**
   - 풀스크린 컨페티 + "MISSION CLEAR!" + 트로피
   - 화면 탭 → 결과 상세 패널 (순위·획득 금액·완료 시간)
   - 공유 또는 다음 미션 버튼

### 4.2 사장님 흐름 (오프라인 영업용)
1. 로그인 → 홈 → 사장님 탭
2. (현재 MVP는 BizLanding 미완 — 사장님 모드는 후속 Wave에서 본격화)
3. 임시: FAB → CreateClue 진입으로 퀘스트 등록 가능

---

## 5. 베타 10개 매장 운영 가이드

### 5.1 매장 선정 기준
- 시립대 캠퍼스타운 입주 기업 / 시립대 주변 도보 10분 상권
- **이미 마케팅(인스타·전단지·리뷰 이벤트) 진행 중인 매장 우선**
  - 도입 전후 비교 데이터 수집이 가능
- 카테고리 다양성: 카페 / 음식점 / 디저트 / 소품샵 / 스터디카페 등 골고루

### 5.2 도입 전 베이스라인 측정
다음 항목을 매장 사장님 인터뷰 + 방문 카운터로 측정:
| 지표 | 측정 방법 |
|---|---|
| 평일 방문률 | 시간대별 도어카운터 또는 POS |
| 평균 체류시간 | 매장 직접 관찰 (평균 30분 등) |
| 재방문율 | 단골 식별 / POS 회원 데이터 |
| 매출 | 학기 대비 방학 비율 |

### 5.3 RunClue 도입 후 4주 측정
- 1주차: 퀘스트 등록 + 매장 안내문 부착 ("RunClue로 메뉴 할인 받으세요")
- 2주차: 첫 탐험가 유입 데이터 수집
- 3주차: 퀘스트 난이도/보상 조정
- 4주차: 도입 전 데이터와 비교 리포트 작성

### 5.4 사장님 인터뷰 질문 (피드백 수집)
1. 어떤 형태의 퀘스트가 참여율이 가장 높았나요? (방문 인증 / 메뉴 사진 / AR 모션)
2. 어떤 리워드가 실제 방문 전환으로 이어졌나요? (메뉴 할인 / 기프티콘 / 스탬프)
3. 사용자 이탈 구간은 어디였나요? (앱 진입 / 검색 / 상세 / 인증)
4. 매장 운영자로서 추가하고 싶은 기능은?

---

## 6. 숏폼 바이럴 전략 (탐험가 10명+ 확보)

### 6.1 콘텐츠 컨셉 4가지
| 컨셉 | 예시 카피 | 타깃 플랫폼 |
|---|---|---|
| 현실 탐험 퀘스트 | "방학에 시립대 근처 숨겨진 카페 찾기" | TikTok, IG Reels |
| 숨겨진 장소 찾기 | "캠퍼스타운 비밀 메뉴 찾기 챌린지" | YouTube Shorts |
| 미션 수행형 리워드 | "AR 퀘스트 깨고 아메리카노 무료로 받기" | TikTok |
| 지역 기반 보물찾기 | "시립대 주변 5km 보물지도 도전" | IG Reels |

### 6.2 30초 영상 템플릿
- 0~3초: "방학에 학교 와봤어요?" (후크)
- 3~10초: 실제 매장 방문 + AR 퀘스트 수행 장면
- 10~20초: 보상 받는 순간 (메뉴 할인 결제 화면)
- 20~30초: "지금 RunClue 다운받기" CTA + 앱스토어 QR

### 6.3 측정 지표
- 영상 노출 → 앱 다운로드 전환율
- 다운로드 → 첫 퀘스트 완료율
- 첫 퀘스트 완료 → 7일 재참여율

---

## 7. 크래시 안정화 (이번 빌드에서 해결)

### 7.1 해결한 5건
1. **Maps API key**: AndroidManifest의 `YOUR_GOOGLE_MAPS_API_KEY` placeholder → `.env`의 실제 키 자동 주입
2. **clue_play_screen force unwrap**: `_capturedImage!`, `_distanceToTarget!` 5개 위치 null-safe 패턴 적용
3. **realtime_location_provider 채널**: `_channel!` 직접 참조 → try/catch + `isSupabaseReady` 가드
4. **realtime_feed_provider**: 같은 패턴으로 graceful degradation
5. **Splash race condition**: `Future.delayed` 후 `context.go` → `addPostFrameCallback` + `_navigated` 플래그
6. **ProGuard rules**: Freezed/Supabase/Geolocator/MLKit/Gson reflection 보호 규칙

### 7.2 검증 결과
- `flutter analyze`: **0 errors**
- `flutter test test/services/`: **36/36 pass**

---

## 8. 디자인 시스템 (다크 퍼스트)

### 8.1 컬러 토큰
- 배경 4단계: `bg-hero #07070E` / `bg-base #111115` / `bg-surface #1C1C22` / `bg-elevated #262626`
- 브랜드 옐로: `#FACC15` (CTA / 활성)
- 브랜드 블루: `#38BDF8` (탐험가 / 정보)
- 브랜드 그린: `#10B981` (완료 / 수익)
- 브랜드 오렌지: `#F97316` (사장님 / 경고)
- 브랜드 퍼플: `#A78BFA` (크리에이터)

### 8.2 폰트
- 디스플레이: **Black Han Sans** (슬로건, 결과 화면, 화면 제목)
- 본문/UI: **Noto Sans KR**

---

## 9. 다음 스프린트 우선순위

### 9.1 Wave 2 (2주)
1. **CreateClue 6단계 위저드** — 사장님이 직접 퀘스트 등록 가능하게
2. **BizLanding** — 사장님 무료 베타 신청 페이지
3. **MyProgress 폴리싱** — 랭킹·스트릭·배지

### 9.2 Wave 3 (4주)
1. **AR 모션 인식 SDK 연동** — ARCore/ARKit 기반 모션 퀘스트 (이번 피벗의 핵심 차별 요소)
2. **캐시 리워드 결제 연동** — 메뉴 할인 → 결제 대용 캐시 전환
3. **Community 활성화** — 인증샷 공유 + 매장 후기

### 9.3 베타 10개 매장 출시 → 1개월 검증 → 데이터 기반 확장 결정

---

## 10. 참고 자료
- 명세 v2.0: 채팅 기록 / `RunClue_통합기획패키지_최종.docx`
- 디자인 시스템: `app/lib/config/theme.dart`
- 라우터: `app/lib/config/router.dart` (4탭 + 외부 라우트)
- 크래시 픽스 디테일: `C:\Users\User\.claude\plans\runclue-ui-ux-sleepy-sloth.md`

---

**문의**: 개발 / 베타 매장 신청은 GitHub Issues 또는 직접 연락
