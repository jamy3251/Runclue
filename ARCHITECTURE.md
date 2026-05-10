# RunClue 코드 구조 문서

> 모든 디렉토리·파일의 역할 + 의존 관계 정리. 새 개발자가 와서 이 문서 하나 읽으면 어디서 뭘 고쳐야 할지 알 수 있도록.

**버전**: 2026-05-10 기준 / **언어**: Flutter 3.2+ (Dart) + Android (Kotlin) + Supabase (Postgres)

---

## 1. 최상위 구조 (Project Root)

```
RunClue/
├─ app/                       ← Flutter 앱 본체 (대부분의 코드)
├─ landing/                   ← 홍보용 정적 HTML 페이지
├─ supabase/                  ← Supabase DB 마이그레이션
├─ docs/                      ← 기획·UX·약관·시나리오 문서 (10개 챕터)
├─ .github/workflows/         ← CI 설정
├─ ARCHITECTURE.md            ← (이 문서)
├─ MVP_GUIDE.md               ← MVP 사용 설명서 (피벗 배경, 골든패스, 베타 가이드)
├─ DESIGN.md                  ← 디자인 시스템 토큰 정의
├─ CLAUDE.md                  ← AI 어시스턴트 컨텍스트 (코드 컨벤션, 명령어)
├─ CHANGELOG.md               ← 버전별 변경사항
├─ MY_SECRETS.local           ← (gitignored) 모든 환경 비밀 마스터
├─ apply_secrets.ps1          ← MY_SECRETS.local → .env / key.properties 자동 배포
└─ runclue_*.{json,yaml,sql}  ← 운영 설정 (승인 규칙·쿼리 최적화 등)
```

**최상위 마크다운 4종 역할 구분**
- `ARCHITECTURE.md` (이 문서): 코드 어디에 뭐가 있는지
- `MVP_GUIDE.md`: 무엇을 왜 만들었는지 + 운영 가이드
- `DESIGN.md`: 디자인 시스템 (색·폰트·그림자 토큰)
- `CLAUDE.md`: 자동화 도구를 위한 코딩 컨벤션·명령어

---

## 2. Flutter 앱 (`app/`)

```
app/
├─ android/                   ← Android 네이티브 빌드 설정
├─ lib/                       ← 모든 Dart 코드
├─ test/                      ← 단위·위젯 테스트
├─ assets/images/             ← 앱 아이콘 등 정적 이미지
├─ pubspec.yaml               ← 의존성 + 자산 등록
├─ pubspec.lock               ← 의존성 lock
└─ analysis_options.yaml      ← Dart lint 규칙
```

### 2.1 Android 빌드 (`app/android/`)

| 파일 | 역할 |
|---|---|
| `app/build.gradle` | applicationId(com.runclue.app), minSdk 23, targetSdk, manifestPlaceholders 주입 (.env에서 GOOGLE_MAPS_API_KEY 읽음), 서명 설정 |
| `app/src/main/AndroidManifest.xml` | 권한(INTERNET, GPS, CAMERA), MainActivity 등록(`com.runclue.runclue.MainActivity` 풀패스), 딥링크(`runclue://`), Maps API key 주입(`${MAPS_API_KEY}`) |
| `app/src/main/kotlin/com/runclue/runclue/MainActivity.kt` | Flutter Activity 진입점 (단순 상속) |
| `app/proguard-rules.pro` | release 빌드 R8 보호 규칙 (Freezed, Supabase, MLKit, Geolocator, Gson) — 현재는 minifyEnabled=false라 미사용이지만 향후 활성화 시 사용 |
| `key.properties` (gitignored) | release keystore 비밀번호 |

### 2.2 코드 디렉토리 (`app/lib/`)

```
lib/
├─ main.dart                  ← 부트스트랩 (Supabase init, Maps Hybrid Composition, runApp)
├─ app.dart                   ← MaterialApp.router + 다크 테마 + ko_KR locale
├─ config/                    ← 전역 설정 (4 파일)
├─ models/                    ← Freezed 데이터 모델 (9종 + 자동생성 .freezed/.g.dart)
├─ services/                  ← Supabase·기기 API 래퍼 (20 파일)
├─ providers/                 ← Riverpod 상태/캐시 공급자 (9 파일)
├─ screens/                   ← 화면별 페이지 (24 파일, 디렉토리별 분리)
└─ widgets/                   ← 재사용 위젯 (8 카테고리)
```

---

## 3. `lib/config/` — 전역 설정

| 파일 | 역할 |
|---|---|
| `theme.dart` | **AppColors**(40개 토큰, 배경 4단계·브랜드 6색·텍스트 4색), **AppTextStyles**(Black Han Sans + Noto Sans KR), **AppShadows**, **AppGradients**, **AppSpacing**, **AppDurations**, **AppTheme** (light/dark ThemeData) |
| `router.dart` | GoRouter — 4탭 StatefulShellRoute(/home, /explore, /rank, /my-xp), 셸 외부 라우트(/create, /community, /participate, /clue/:id 계층 등 14개), redirect 로직(비로그인→/auth, 로그인 + /auth접근 → /home) |
| `supabase_config.dart` | `String.fromEnvironment`로 .env에서 SUPABASE_URL/ANON_KEY 읽기 (빌드 시 컴파일 상수) |
| `supabase_safe.dart` | **safeClient** getter — Supabase 미초기화 시 placeholder 클라이언트 반환 (UI 미리보기 모드), `isSupabaseReady` 헬퍼 |

---

## 4. `lib/models/` — Freezed 모델

각 도메인은 `.dart` (정의) + `.freezed.dart` + `.g.dart` (자동생성) 3개 파일로 구성.

| 모델 | 역할 |
|---|---|
| `clue` | 클루(미션) 본체 — title, description, category, status, lat/lng, reward, distribution_mode |
| `clue_step` | 클루의 단계 — type(CHECKPOINT/SNAPSHOT/QUEST/OX_QUIZ/LIST/PHOTO_SIM/MOTION_SIM), validation_type, target_lat/lng, reference_image_url |
| `evidence` | 탐험가가 단계 완료 시 제출하는 증거 — type(location/photo/text/ox/checklist/similarity), media_url, similarity_score |
| `participation` | 탐험가의 클루 참여 기록 — current_step_index, status, total_points_earned, started_at/completed_at |
| `profile` | 사용자 프로필 — nickname, avatar_url, bio, role, total_points, badges |
| `clan` | 크루(팀) — 사용자 그룹화, 랭킹 단위 |
| `reward` | 보상 인스턴스 |
| `community_post` | 소통 광장 게시물 |
| `notification_model` | 알림 |

`models.dart` — barrel export 파일 (`export 'clue.dart';` ...)

---

## 5. `lib/services/` — Supabase·기기 API 래퍼

| 서비스 | 역할 |
|---|---|
| **인증** ||
| `auth_service.dart` | Supabase Auth 래핑 — signUp/signIn/OAuth/resetPassword + **친화적 한국어 에러 변환** (Cloudflare 521, SocketException, Invalid credentials 등) |
| `anonymous_auth_service.dart` | 익명 가입 (게스트 사용자) |
| **클루 도메인** ||
| `clue_service.dart` | clues CRUD + getNearbyClues(RPC) + searchClues + **3단계 fallback 트렌딩** + **PGRST204 자동 컬럼 제거 재시도 + 사후 검증 SELECT** |
| `step_service.dart` | steps CRUD + reorder + **컬럼 제거 재시도** |
| `participation_service.dart` | 참여 시작/진행도 갱신/완료/취소 |
| `evidence_service.dart` | 증거 제출 + 검증 |
| **위치·검증** ||
| `location_service.dart` | Geolocator 래핑 — getCurrentPosition, **locationStream**(continuous), bearingBetween(방위각), calculateDistance(Haversine), isWithinRadius |
| `similarity_service.dart` | **PHOTO_SIM/MOTION_SIM 채점** — `image` 패키지로 8x8 grayscale + 64bit aHash → Hamming distance → 0~100점 + gradeOf(PERFECT/EXCELLENT/...) |
| `validation_orchestrator.dart` | 단계 유형별 자동 검증 분기 (CHECKPOINT 거리, OX 정답 비교, QUEST 텍스트, LIST 체크리스트) |
| **저장소·미디어** ||
| `storage_service.dart` | Supabase Storage 래핑 — uploadEvidence/Profile/ClueImage/uploadBytes + getSignedUrl |
| `victory_card_service.dart` | 결과 화면 공유 이미지 생성 |
| `watermark_service.dart` | 사진에 워터마크 |
| **커뮤니케이션** ||
| `community_service.dart` | 게시물 CRUD |
| `notification_service.dart` | 인앱 알림 |
| `push_notification_service.dart` | FCM 푸시 |
| `report_service.dart` | 신고 처리 |
| **기타** ||
| `profile_service.dart` | 프로필 CRUD + 배지 |
| `platform_stats_service.dart` | 홈 화면 스탯 바용 (참여자수/누적수익/활성미션) — RPC 또는 fallback count |
| `partner_application_service.dart` | **사장님 자동 제휴 신청** — `partner_applications` 테이블에 INSERT, fallback `store_partners` |
| `deep_link_service.dart` | 카카오톡 공유 deep link 생성 |

---

## 6. `lib/providers/` — Riverpod 상태

각 provider는 `services/`의 함수를 호출해서 캐시 가능한 상태로 노출.

| Provider | 종류 | 역할 |
|---|---|---|
| `auth_provider.dart` | StateNotifier | 현재 사용자, currentUserIdProvider, authServiceProvider |
| `clue_provider.dart` | FutureProvider.family | clueDetailProvider(id), trendingCluesProvider, myCluesProvider, clueSearchProvider(query), nearbyCluesProvider(lat/lng/radius), clueServiceProvider |
| `participation_provider.dart` | FutureProvider | currentParticipationProvider(clueId), myParticipationsProvider, leaderboardProvider, participationServiceProvider |
| `community_provider.dart` | FutureProvider | 게시물 피드 |
| `profile_provider.dart` | FutureProvider | myProfileProvider, myBadgesProvider, myClanProvider |
| `location_provider.dart` | StreamProvider | 현재 위치 스트림 |
| `realtime_feed_provider.dart` | StreamProvider.family | 클루별 실시간 evidence/participation 이벤트 (Supabase Realtime) |
| `realtime_location_provider.dart` | StateNotifier.family | 클루별 참여자 위치 broadcast (Presence) |
| `providers.dart` | barrel | 모든 provider re-export |

---

## 7. `lib/screens/` — 화면별 페이지

### 7.1 진입·셸

| 파일 | 역할 |
|---|---|
| `splash/splash_screen.dart` | 2초 후 세션 체크 → /home or /auth (race condition 방지: addPostFrameCallback + _navigated 플래그) |
| `main_shell.dart` | 4탭 바텀 네비 (홈/탐색/랭킹/내 정보) — Hybrid blur background, 한글 라벨 |
| `onboarding/onboarding_screen.dart` | 첫 방문자 온보딩 (현재 미사용) |

### 7.2 인증

| 파일 | 역할 |
|---|---|
| `auth/auth_screen.dart` | 슬로건 + 사회증명 + 카카오/네이버/Google 소셜 + "크루 합류하기" CTA (세션 있으면 /home, 없으면 /auth/login) |
| `auth/login_screen.dart` | 이메일/비번 폼 + 회원가입 토글 + **session 없으면 즉시 로그인 시도 (트리거 confirm 유저 자동 진입)** |

### 7.3 메인 4탭

| 라우트 | 파일 | 역할 |
|---|---|---|
| `/home` | `home/home_screen.dart` | 헤더(검색·알림) + 플랫폼 스탯 바 + 역할 탭 + LIVE 히어로/소형 카드 + 페르소나 추천 |
| `/explore` | `explore/explore_screen.dart` | 긴급 수익 sticky 배너 + 검색바(debounce 300ms) + 카테고리 탭 + **거리 필터 chips(전체/1/3/5/10km)** + 정렬(인기/거리/상금/마감) + 무한 스크롤 + FAB(/create) |
| `/rank` | `progress/my_progress_screen.dart` | 크루 랭킹 + 내 기록 (스트릭/배지/통계) |
| `/my-xp` | `profile/profile_screen.dart` | 프로필 헤더 + 스탯 + 배지 + 설정/로그아웃 |

### 7.4 클루 도메인

| 파일 | 역할 |
|---|---|
| `clue/detail/clue_detail_screen.dart` | 히어로 헤더 + 3탭(미션 구성/지도/리뷰) + 통계 카드 + 단계 타임라인 + sticky CTA "지금 참여하기" |
| `clue/play/clue_play_screen.dart` | 단계별 진행 — 미션 헤더, thin progress bar, 단계별 콘텐츠(`_buildCheckpointContent` 등 7종), **_GpsLiveCard 위젯** (실시간 거리·방향·정확도·도착 펄스), **_buildSimilarityContent** (PHOTO_SIM/MOTION_SIM 정답지 비교 + 채점 UI) |
| `clue/clue_result_screen.dart` | 풀스크린 컨페티 + "MISSION CLEAR!" + 트로피 + slide-up 결과 패널 + 공유/다음 미션 |

### 7.5 클루 만들기

| 파일 | 역할 |
|---|---|
| `create/create_clue_screen.dart` | **5단계 위저드** — Step1 기본정보(썸네일·제목·카테고리·소개), Step2 매장·위치(매장명·주소·**미니맵**·인증반경), Step3 단계 추가(`_AddStepSheet`로 7가지 유형 모달 + PHOTO_SIM/MOTION_SIM 정답지 업로드), Step4 보상·분배(4가지 분배 방식 + 비용 계산기), Step5 미리보기 + 제출 → Supabase + 자동 승인. 내부 위젯: `_MapPreview`(GoogleMap 4초 안에 안 뜨면 격자 카드 폴백), `_GridPainter`, `_StepDraft`, `_DarkInput` |

### 7.6 사장님·랜딩

| 파일 | 역할 |
|---|---|
| `biz/biz_landing_screen.dart` | Hero(광고비 0원으로 방학에도) + 임팩트 지표 + 3단계 온보딩 + 후기 + **_PartnerSignupSheet** (매장 자동 제휴 신청 슬라이드업 폼) |
| `landing/why_runclue_screen.dart` | 경쟁 우위 비교표 + 플라이휠 다이어그램 |

### 7.7 기타 화면

| 파일 | 역할 |
|---|---|
| `community/community_screen.dart` | 소통 광장 피드 |
| `community/post_detail_screen.dart` | 게시물 상세 |
| `mission/mission_map_screen.dart` | 호스트/참여자 실시간 위치 지도 |
| `host/host_dashboard_screen.dart` | 사장님 매장 대시보드 (방문 통계) |
| `join/join_via_link_screen.dart` | 카카오톡 deeplink로 진입한 비회원 참여 화면 |
| `notifications/notification_center_screen.dart` | 알림 센터 |
| `participate/participate_screen.dart` | 참여 진입점 |
| `profile/profile_edit_screen.dart` | 프로필 편집 |
| `profile/settings_screen.dart` | 알림/개인정보/차단/약관 설정 |
| `search/search_screen.dart` | 글로벌 검색 |
| `highlight/highlight_reel_screen.dart` | 인스타 스토리 형식 하이라이트 |

---

## 8. `lib/widgets/` — 재사용 위젯

| 카테고리 | 파일 | 역할 |
|---|---|---|
| **루트** ||
| | `clue_card.dart` | 미션 카드 (compact/full 두 모드) — 배지·진행도·크리에이터·보상·거리 표시. `_TapWrapper`로 scale + haptic |
| | `step_type_icon.dart` | 단계 유형별 아이콘 (CHECKPOINT/SNAPSHOT/QUEST/OX_QUIZ/LIST/PHOTO_SIM/MOTION_SIM 색상 매핑) |
| | `survey_banner.dart` | 설문/공모전 배너 |
| | `report_dialog.dart` | 신고 다이얼로그 |
| **cards/** | `persona_card.dart` | 페르소나 추천 카드 (홈 가로 스크롤 섹션) |
| **celebration/** | `celebration_overlay.dart` | 풀스크린 컨페티 + 트로피 모달 (Result 화면 진입 시 발동) |
| **common/** | `badge_chip.dart` | 작은 배지 (LIVE/HOT/NEW/카테고리) |
| | `category_filter_tabs.dart` | 가로 스크롤 카테고리 탭 (Explore에서 사용) |
| | `earnings_notification_banner.dart` | sticky 수익 알림 배너 (최근 N명 ₩N 획득) |
| | `empty_state_widget.dart` | 빈 결과 상태 |
| | `error_widget.dart` | 에러 상태 + 재시도 버튼 (`AppErrorWidget`) |
| | `gradient_scaffold.dart` | 다크 그라디언트 배경 Scaffold |
| | `haptic_button.dart` | 햅틱 피드백 포함 버튼 |
| | `loading_widget.dart` | 로딩 spinner |
| | `location_picker_modal.dart` | **풀스크린 GoogleMap 위치 선택** — 검색바, 다크 스타일, 중앙 핀, 역지오코딩, **4초 timeout 시 수동입력 모드 자동 폴백** |
| | `shimmer_loading.dart` | 스켈레톤 shimmer |
| **feed/** | `live_feed_widget.dart` | 클루 진행 중 실시간 이벤트 오버레이 (Realtime feed) |
| **qr/** | `qr_scanner_widget.dart` | mobile_scanner QR 스캔 |
| **stats/** | `ai_provocation_banner.dart` | AI 도발 메시지 (랭킹 자극용) |
| | `fun_stats_grid.dart` | 4개 펀 통계 (이동거리/수익/방문장소/시간) |
| | `streak_calendar.dart` | 7일 스트릭 캘린더 |
| **step_editors/** | `step_editor_fields.dart` | (구) 단계 유형별 입력 필드 — CheckpointFields/QuestFields/OxQuizFields/ListFields. 신규 CreateClue가 자체 시트 사용해서 일부 deprecated |

---

## 9. `lib/main.dart` 부트스트랩 흐름

```
main()
├─ runZonedGuarded(전역 에러 핸들링)
├─ WidgetsFlutterBinding.ensureInitialized()
├─ [Android만] Google Maps Hybrid Composition 강제
│    GoogleMapsFlutterPlatform.useAndroidViewSurface = true
├─ Supabase.initialize() — .env 값 있을 때만
│    실패해도 앱은 실행 (safeClient가 placeholder 사용)
└─ runApp(ProviderScope(RunClueApp))

RunClueApp (app.dart)
├─ MaterialApp.router
│    ├─ themeMode: dark
│    ├─ locale: ko_KR + flutter_localizations 델리게이트
│    └─ routerConfig: ref.watch(routerProvider) — config/router.dart
└─ → SplashScreen (2초) → /home or /auth
```

---

## 10. 테스트 (`app/test/`)

```
test/
├─ widget_test.dart           ← 앱 부팅 smoke
└─ services/
   ├─ evidence_service_test.dart    ← autoValidateCheckpoint/Quiz/Checklist
   ├─ validation_orchestrator_test.dart
   └─ deep_link_service_test.dart
```

총 36개 테스트. `flutter test test/services/` 로 실행.

---

## 11. `landing/` — 홍보 정적 페이지

| 파일 | 역할 |
|---|---|
| `index.html` | 단일 HTML — Hero, 스탯, 차별점, 7가지 단계, 3자 생태계, **사장님 자동 제휴 신청 폼** (Supabase REST API 직접 호출), APK 다운로드 CTA. CSS·JS 인라인, 의존성 0 |
| `README.md` | GitHub Pages·Netlify·Vercel 배포 가이드 + Supabase 테이블 SQL |

---

## 12. `supabase/migrations/` — 데이터베이스 스키마

| 파일 | 역할 |
|---|---|
| `001_initial_schema.sql` | 초기 테이블 생성 (clues/steps/participations/evidences/profiles/clans 등) |

추가 컬럼은 SQL Editor에서 직접 ALTER TABLE 하거나 새 마이그레이션 파일 추가 (예: lat/lng/reward_label/distribution_mode 등은 코드의 PGRST204 fallback이 자동 처리하므로 필수 아님).

---

## 13. 빌드·배포 워크플로

### 개발 실행
```bash
cd app
flutter pub get
flutter run --dart-define-from-file=.env
```

### Release APK (베타 매장 배포용)
```bash
cd app
flutter build apk --release \
  --dart-define-from-file=.env \
  --no-shrink \
  --split-per-abi \
  --target-platform=android-arm64
# → build/app/outputs/flutter-apk/app-arm64-v8a-release.apk (~32MB)
```

### 환경 비밀 셋업 (새 PC)
```powershell
# 1. MY_SECRETS.local 파일을 루트에 복사 (USB·패스워드 매니저 등)
# 2. 자동 배포
.\apply_secrets.ps1
# → app/.env + app/android/key.properties 생성
```

### 분석·테스트
```bash
cd app
flutter analyze              # 0 errors 기준
flutter test test/services/  # 36 tests
```

---

## 14. 의존성 (`pubspec.yaml` 핵심)

| 카테고리 | 패키지 | 용도 |
|---|---|---|
| **Backend** | `supabase_flutter ^2.3.0` | DB + Auth + Storage + Realtime |
| **State** | `flutter_riverpod ^2.4.9`, `riverpod_annotation ^2.3.3` | 상태 관리 |
| **Routing** | `go_router ^13.0.0` | 라우팅 + StatefulShellRoute |
| **Location** | `geolocator ^11.0.0`, `geocoding ^3.0.0` | GPS + 주소 변환 |
| **Maps** | `google_maps_flutter ^2.5.0` | 지도 (Hybrid Composition 모드) |
| **Camera** | `image_picker ^1.0.7`, `camera ^0.11.0` | 사진 촬영 |
| **QR** | `mobile_scanner ^4.0.0`, `qr_flutter ^4.1.0` | QR 인증 |
| **Image** | `image ^4.1.7`, `crypto ^3.0.3` | aHash 유사도 채점 (PHOTO_SIM/MOTION_SIM) |
| **UI** | `google_fonts ^6.1.0` (Black Han Sans, Noto Sans KR), `cached_network_image`, `shimmer`, `flutter_svg`, `lottie` | |
| **Localization** | `flutter_localizations` | ko_KR 지원 (Material 위젯 한국어 lookup) |
| **Misc** | `share_plus`, `flutter_local_notifications`, `permission_handler`, `dio`, `intl`, `uuid`, `freezed`, `json_serializable` | |

---

## 15. 흐름 요약 (핵심 시나리오 5개)

### A) 탐험가 골든패스
```
SplashScreen → AuthScreen("크루 합류하기") → LoginScreen → /home
→ HomeScreen LIVE 카드 탭 → ClueDetailScreen "지금 참여하기"
→ CluePlayScreen (단계별 _buildXContent → _handleSubmit → evidence_service)
→ ClueResultScreen (컨페티 + 결과 패널)
```

### B) 사장님 클루 등록
```
HomeScreen FAB → CreateClueScreen 5단계
→ Step5 _submit → clue_service.createClue (PGRST204 fallback)
→ step_service.createStep (각 단계, PHOTO_SIM/MOTION_SIM은 reference_image_url도 업로드)
→ status='active' 즉시 → trendingCluesProvider invalidate → 탐색에 노출
```

### C) PHOTO_SIM/MOTION_SIM 채점
```
CluePlayScreen _buildSimilarityContent
→ GPS 도착 확인 (LocationService 스트림)
→ 카메라 촬영 (image_picker)
→ similarity_service.compareUserToReference (사장님 정답지 + 사용자 사진 → aHash 비교)
→ 0~100점 + 등급 → evidence에 similarity_score 저장
```

### D) 사장님 자동 제휴 신청 (앱)
```
BizLandingScreen "1분만에 신청하기" → _PartnerSignupSheet 슬라이드업
→ 매장명/주소/카테고리 등 입력 → partner_application_service.submit
→ partner_applications 테이블 INSERT (없으면 store_partners fallback)
```

### E) 사장님 자동 제휴 신청 (웹)
```
landing/index.html "베타 신청 제출" → JS fetch
→ Supabase REST POST /rest/v1/partner_applications (anon key)
→ 같은 테이블에 저장
```

---

## 16. 문서 vs 코드 매핑

| 문서 | 다루는 코드 위치 |
|---|---|
| `docs/01_UI_UX_화면설계서.md` | `lib/screens/`, `lib/widgets/` |
| `docs/02_서비스_명세서.md` | `lib/services/` |
| `docs/04_PRD.md` | 전체 (요구사항) |
| `docs/05_모의흐름_시나리오.md` | 흐름 §15 참고 |
| `runclue_approval_rules.yaml` | (예정) `validation_orchestrator.dart`에 통합 |
| `runclue_clue_template_examples.json` | CreateClue 단계 템플릿 시드 데이터 |
| `runclue_query_optimizations.sql` | Supabase RPC `nearby_clues` 등 |

---

이 문서가 stale 되면 안 되니 큰 구조 변경(폴더 추가, 라우트 변경, 핵심 서비스 신설) 시 같이 업데이트해주세요.
