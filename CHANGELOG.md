# Changelog

All notable changes to RunClue will be documented in this file.
Format based on [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

### Added (2026-06-11 — 게임 IP 완성 + 정식 서비스화 배치)
- **미니게임 PvP 배틀 확장 (#24)**: tap(서로 때리기)·coin_grab(동전 줍기) 베팅 대전 합류
  - 마이그레이션 031: game_type 확장 + 점수 판정 + CPU 경쟁 점수 (경제 보호)
  - 배틀 로비 게임 선택 UI, 게임별 라운드 화면 (BattleTapRound/BattleCoinRound)
- **versus 실시간 레이스 UI (#23 완성)**: 참가자별 진행률 경쟁 바 (4초 폴링)
  - 마이그레이션 033: coop/versus 한정 참가자 상호 조회 RLS
- **사용자 다이아 충전 (토스 결제)**: 패키지 4종 + 외부 브라우저 결제 + 멱등 승인
  - 마이그레이션 032, Edge Function toss-diamond-confirm, landing/pay*.html
- **소셜 로그인 재정립**: 카카오/Google/Apple OAuth 실연동 (네이버 제거 — Supabase 미지원)
  - 첫 로그인 닉네임 설정 화면 (guest_* 게이트), OAuth 딥링크 복귀 자동 라우팅
  - 가짜 "1,247명 활동 중" → 실DB 통계 (0명 시 얼리액세스 카피)
- **AR 보물찾기**: 카메라+나침반+GPS — 방향 화살표 HUD, 반경 진입 시 보물 탭 = 도착 인증
- **IA 재정비**: 5탭 구조 (홈/탐색/**플레이**/랭킹/내정보) — 플레이 허브에 게임 기능 통합
- **Edge Function 4종 배포**: toss-confirm/toss-webhook/admob-ssv/toss-diamond-confirm (ACTIVE)
- 컴백 캠페인 스크립트 (scripts/comeback_campaign.sql) — 웰컴백 100코인 + 인앱 알림
- 문서: IAP_GUIDE.md(스토어 결제 준비), STRATEGY_NEEDS_2026-06.md, PROJECT_STATUS

### Fixed (2026-06-11)
- 운영자 계정 프로필 부재 → 모든 재화 RPC 실패 (마이그레이션 030 backfill + 트리거 강화)
- 이메일 가입 닉네임이 무시되고 guest_로 저장되던 트리거 버그 (마이그레이션 034)
- 배틀 결과 폴링 시 승자가 항상 'opponent'로 표시되던 버그
- OAuth 인증 완료 전에 /home으로 이동하던 버그
- Android 빌드 불가 상태 해결: AGP 8.3.2 + core desugaring + minSdk 26
- 보안 위생 (마이그레이션 035): diamond 테이블 anon 노출 + 트리거 함수 RPC 노출 차단

### Verified (2026-06-11)
- 재화 E2E 실주행: grant_coin → 배틀 베팅 → CPU전 승리 배당까지 coin_ledger 정합 확인

### Added
- 배포 직전 갭 분석 + 구현
  - SearchScreen: 키워드 검색, 최근검색어 (SharedPreferences), 인기검색어, 디바운스, 결과 리스트
  - NotificationCenterScreen: 날짜 그룹, 스와이프 삭제, 모두읽음, 딥링크 네비게이션
  - LocationPickerModal: Google Maps 위치 선택, 역지오코딩, 현재위치, 수동입력 폴백
  - NotificationService 완성: Supabase 연동 (조회, 읽음, 삭제, 미읽음 카운트)
  - ExploreScreen 하드코딩 제거: 수익배너/LIVE 히어로/검색/알림 아이콘 동적 데이터 바인딩
  - MyProgressScreen 실데이터: 랭킹 Supabase 연동, 스트릭 자동계산, 배지 실데이터
  - CreateClueScreen 맵 위치 피커 연결
  - Auth 리다이렉트 활성화 (비로그인시 /auth로 리다이렉트, 공개페이지 예외)
  - 프로필 화면 배지/클랜 네비게이션 스텁 제거, 실제 라우트 연결
  - Router: /search, /notifications 라우트 추가

- Phase B-E: CEO/Design review implementation
  - Design system: shadows, gradients, glows, spacing tokens, animation durations
  - Common widgets: ShimmerEffect, HapticButton, GradientButton, CategoryFilterTabs
  - ClueCard full redesign (dark theme, status badges, progress bar, creator avatar)
  - CelebrationOverlay redesign (confetti, trophy glow, pulsing text)
  - New widgets: AIProvocationBanner, StreakCalendar, FunStatsGrid, EarningsNotificationBanner, PersonaCard
  - New screens: MyProgressScreen, BizLandingScreen, WhyRunClueScreen
  - MainShell bottom nav: spec-aligned icons (HOME/EXPLORE/CREATE/RANK/MY XP) + haptic
  - Settings screens: Supabase DB save/load for notifications, privacy, block management
  - PushNotificationService: deep link navigation on tap
  - PlatformStatsService: real-time stats from Supabase RPC
  - ExploreScreen: live platform stats binding, persona cards, category filters

### Fixed
- CelebrationOverlay return type error
- MyProgressScreen duplicate BoxDecoration color argument
- widget_test.dart referencing non-existent MyApp class
- Dead ScaffoldWithBottomNav code removed from router.dart

## [1.0.0] - 2026-04-03

### Added
- Phase 1 complete build
  - Authentication: Supabase Auth with email/social login
  - 5 mission step types: CHECKPOINT, SNAPSHOT, QUEST, OX_QUIZ, LIST
  - Clue CRUD: create, browse, detail, participate, play, result
  - Real-time location tracking and participation feed
  - Evidence submission with photo/text verification
  - Validation orchestrator: auto-approve GPS/quiz, host review for photos
  - Push notifications (local)
  - Deep link sharing (/join/:id)
  - Host dashboard for mission management
  - Community feed with posts and comments
  - Profile with badges and clan support
  - Onboarding flow
  - Dark theme with Black Han Sans + Noto Sans KR typography
  - 36 passing tests (validation, evidence, deep link)
  - 12 spec documents in /docs/
