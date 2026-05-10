#!/usr/bin/env bash
# RunClue 비밀 자동 배포 스크립트 (macOS / Linux)
# 사용: bash apply_secrets.sh
# 동작: MY_SECRETS.local → app/.env + app/android/key.properties + app/ios/Flutter/Secrets.xcconfig 생성

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SECRET_FILE="$ROOT/MY_SECRETS.local"

if [ ! -f "$SECRET_FILE" ]; then
  echo "[ERROR] MY_SECRETS.local 파일을 찾을 수 없습니다." >&2
  echo "        경로: $SECRET_FILE" >&2
  exit 1
fi

# Parse KEY=VALUE pairs (주석/빈줄 무시)
declare -A SECRETS
while IFS='=' read -r key value; do
  # 주석 또는 빈 줄 skip
  [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue
  # 양 끝 공백 제거
  key="$(echo "$key" | xargs)"
  value="$(echo "$value" | xargs)"
  [[ -z "$key" || -z "$value" ]] && continue
  SECRETS["$key"]="$value"
done < "$SECRET_FILE"

echo "[OK] ${#SECRETS[@]} 개 비밀 파싱 완료"

# ─── 1) app/.env ───
ENV_PATH="$ROOT/app/.env"
cat > "$ENV_PATH" <<EOF
# Auto-generated from MY_SECRETS.local. DO NOT EDIT (regenerate via apply_secrets.sh)
SUPABASE_URL=${SECRETS[SUPABASE_URL]}
SUPABASE_ANON_KEY=${SECRETS[SUPABASE_ANON_KEY]}
GOOGLE_MAPS_API_KEY=${SECRETS[GOOGLE_MAPS_API_KEY]}
EOF
echo "[OK] $ENV_PATH 생성"

# ─── 2) app/android/key.properties ───
KEY_PROPS_PATH="$ROOT/app/android/key.properties"
mkdir -p "$ROOT/app/android"
cat > "$KEY_PROPS_PATH" <<EOF
storePassword=${SECRETS[KEYSTORE_PASSWORD]}
keyPassword=${SECRETS[KEY_PASSWORD]}
keyAlias=${SECRETS[KEY_ALIAS]}
storeFile=${SECRETS[KEYSTORE_PATH]}
EOF
echo "[OK] $KEY_PROPS_PATH 생성"

# ─── 3) app/ios/Flutter/Secrets.xcconfig (iOS 빌드 시 Info.plist의 \$(GOOGLE_MAPS_API_KEY) 치환용) ───
IOS_XCCONFIG_DIR="$ROOT/app/ios/Flutter"
if [ -d "$IOS_XCCONFIG_DIR" ]; then
  IOS_XCCONFIG_PATH="$IOS_XCCONFIG_DIR/Secrets.xcconfig"
  cat > "$IOS_XCCONFIG_PATH" <<EOF
// Auto-generated. DO NOT EDIT.
GOOGLE_MAPS_API_KEY=${SECRETS[GOOGLE_MAPS_API_KEY]}
SUPABASE_URL=${SECRETS[SUPABASE_URL]}
SUPABASE_ANON_KEY=${SECRETS[SUPABASE_ANON_KEY]}
EOF
  echo "[OK] $IOS_XCCONFIG_PATH 생성"

  # Debug.xcconfig / Release.xcconfig가 Secrets.xcconfig를 include하도록
  for cfg in Debug.xcconfig Release.xcconfig; do
    XCFG="$IOS_XCCONFIG_DIR/$cfg"
    if [ -f "$XCFG" ] && ! grep -q "Secrets.xcconfig" "$XCFG"; then
      echo "#include \"Secrets.xcconfig\"" >> "$XCFG"
      echo "[OK] $XCFG에 Secrets.xcconfig include 추가"
    fi
  done
else
  echo "[WARN] $IOS_XCCONFIG_DIR 가 없습니다. 'flutter create --platforms=ios .' 먼저 실행하세요."
fi

echo ""
echo "다음 단계:"
echo "  cd app"
echo "  flutter pub get"
echo ""
echo "  # Android 빌드"
echo "  flutter run --dart-define-from-file=.env"
echo ""
echo "  # iOS 빌드 (Mac 전용)"
echo "  cd ios && pod install && cd .."
echo "  flutter run -d <iphone_id> --dart-define-from-file=.env"
