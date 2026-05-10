# RunClue - AI Assistant Context

## Project Overview

RunClue is a location-based mission marketplace Flutter app. Three-sided platform:
Explorers (play missions), Creators (design missions), Business owners (sponsor missions).

## Architecture

- **Flutter 3.2+** with Dart, dark-first design
- **Supabase** backend (Postgres + Auth + Realtime + Storage)
- **Riverpod** for state management (providers in `app/lib/providers/`)
- **Freezed** for immutable data models (in `app/lib/models/`)
- **GoRouter** with StatefulShellRoute for 5-tab bottom navigation
- All Supabase calls go through service classes in `app/lib/services/`

## Working Directory

The Flutter app lives in `app/`. Always `cd app/` before running flutter commands.

## Commands

```bash
# Install dependencies
cd app && flutter pub get

# Run (UI preview mode, no Supabase)
cd app && flutter run

# Run with Supabase
cd app && flutter run --dart-define-from-file=.env

# Analyze
cd app && flutter analyze

# Test (36 tests)
cd app && flutter test

# Build runner (after model changes)
cd app && dart run build_runner build --delete-conflicting-outputs
```

## Conventions

- Korean for user-facing strings, English for code identifiers
- Dark theme is primary (`AppColors`, `AppTextStyles` in `config/theme.dart`)
- Brand colors: Yellow #FACC15, Blue #38BDF8, Green #10B981, Red #EF4444
- Font: Black Han Sans for headlines, Noto Sans KR for body
- All new screens go in `screens/{feature}/` directory
- All reusable widgets go in `widgets/{category}/`
- Use `safeClient` from `config/supabase_safe.dart` for Supabase calls (graceful degradation)
- Services should catch errors and provide meaningful user-facing messages

## Key Files

- `app/lib/config/router.dart` - All routes, MainShell bottom nav
- `app/lib/config/theme.dart` - Colors, typography, shadows, gradients, spacing
- `app/lib/screens/main_shell.dart` - Bottom navigation (5 tabs)
- `app/lib/config/supabase_safe.dart` - Safe Supabase client accessor

## Testing

- Service tests in `app/test/services/` (validation, evidence, deep link)
- Widget smoke test in `app/test/widget_test.dart`
- Run `flutter test test/services/` for reliable service tests
