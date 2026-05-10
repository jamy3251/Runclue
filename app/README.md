# RunClue

위치기반 미션 마켓플레이스 앱. 크리에이터가 실제 장소에 미션(클루)을 만들고, 참여자가 현장에서 풀며 보상을 받는 3자 플랫폼.

## Quick Start

```bash
# 1. Prerequisites
# Flutter SDK >= 3.2.0 (https://docs.flutter.dev/get-started/install)
# Android Studio or Xcode (platform tools)

# 2. Clone & install
git clone https://github.com/jamy3251/git-remote-repo.git
cd App/RunClue/app
flutter pub get

# 3. Configure environment
cp .env.example .env
# Edit .env with your Supabase project URL and anon key

# 4. Run
flutter run --dart-define-from-file=.env

# Or run in UI preview mode (no Supabase needed):
flutter run
```

## Project Structure

```
app/lib/
  config/      # Theme, router, Supabase config
  models/      # Freezed data models (clue, profile, participation, etc.)
  providers/   # Riverpod state providers
  screens/     # Screen widgets organized by feature
  services/    # Business logic & Supabase API calls
  widgets/     # Reusable UI components
```

## Tech Stack

| Layer | Choice |
|-------|--------|
| Framework | Flutter 3.2+ (Dart) |
| Backend | Supabase (Postgres + Auth + Realtime + Storage) |
| State | Riverpod + Freezed |
| Routing | GoRouter (StatefulShellRoute) |
| Maps | Google Maps Flutter |
| Design | Dark-first, brand colors (#FACC15 yellow, #38BDF8 blue) |

## Testing

```bash
# Run all tests (36 pass)
flutter test

# Run specific test suite
flutter test test/services/validation_orchestrator_test.dart
```

## Key Features

- **5-step mission types**: GPS checkpoint, photo snapshot, text quest, OX quiz, checklist
- **Real-time**: Live location tracking, participation feed, earnings notifications
- **Verification**: Auto-validation (GPS proximity, quiz answers) + host manual review
- **Gamification**: XP points, streak calendar, AI provocation banners, leaderboards
- **3-sided marketplace**: Explorers (play), Creators (design), Business owners (sponsor)

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `SUPABASE_URL` | Yes | Supabase project URL |
| `SUPABASE_ANON_KEY` | Yes | Supabase anonymous API key |
| `GOOGLE_MAPS_API_KEY` | No | Google Maps (falls back to placeholder) |

## Docs

Detailed specs live in `/docs/`:
- `01_UI_UX_화면설계서.md` - Screen design spec
- `02_서비스_명세서.md` - Service specification
- `04_PRD.md` - Product requirements
- `09_기능설명서.md` - Feature descriptions
