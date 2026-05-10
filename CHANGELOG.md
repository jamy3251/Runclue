# Changelog

All notable changes to RunClue will be documented in this file.
Format based on [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

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
