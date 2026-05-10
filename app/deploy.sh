#!/bin/bash
# RunClue 배포 스크립트
# 사용법: ./deploy.sh <SUPABASE_URL> <SUPABASE_ANON_KEY>

set -e

SUPABASE_URL=${1:-"https://your-project.supabase.co"}
SUPABASE_ANON_KEY=${2:-"your-anon-key"}

echo "=== RunClue 빌드 & 배포 ==="
echo "Supabase URL: $SUPABASE_URL"

export PATH="/c/flutter/bin:$PATH"

# Web 빌드
echo ""
echo "[1/2] Web 빌드 중..."
flutter build web \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
  --release

echo "✓ Web 빌드 완료: build/web/"

# Android APK 빌드
echo ""
echo "[2/2] Android APK 빌드 중..."
flutter build apk \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
  --release

echo "✓ APK 빌드 완료: build/app/outputs/flutter-apk/app-release.apk"

echo ""
echo "=== 배포 옵션 ==="
echo ""
echo "1. 로컬 테스트:"
echo "   npx serve build/web"
echo ""
echo "2. Surge.sh 배포 (무료):"
echo "   surge build/web runclue.surge.sh"
echo ""
echo "3. Vercel 배포 (무료):"
echo "   npx vercel build/web"
echo ""
echo "4. Firebase Hosting:"
echo "   firebase deploy --only hosting"
