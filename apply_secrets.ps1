# RunClue 비밀 자동 배포 스크립트
# 사용: PowerShell에서 .\apply_secrets.ps1 실행
# 동작: MY_SECRETS.local → app/.env + app/android/key.properties 생성

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Definition
$secretFile = Join-Path $root 'MY_SECRETS.local'

if (-not (Test-Path $secretFile)) {
    Write-Host "[ERROR] MY_SECRETS.local 파일을 찾을 수 없습니다." -ForegroundColor Red
    Write-Host "  경로: $secretFile" -ForegroundColor Yellow
    exit 1
}

# Parse KEY=VALUE pairs (주석/빈줄 무시)
$secrets = @{}
Get-Content $secretFile | ForEach-Object {
    $line = $_.Trim()
    if ($line -and -not $line.StartsWith('#')) {
        $parts = $line -split '=', 2
        if ($parts.Length -eq 2) {
            $secrets[$parts[0].Trim()] = $parts[1].Trim()
        }
    }
}

Write-Host "[OK] $($secrets.Count) 개 비밀 파싱 완료" -ForegroundColor Green

# ─── 1) app/.env ───
$envPath = Join-Path $root 'app\.env'
$envContent = @"
# Auto-generated from MY_SECRETS.local. DO NOT EDIT (regenerate via apply_secrets.ps1)
SUPABASE_URL=$($secrets['SUPABASE_URL'])
SUPABASE_ANON_KEY=$($secrets['SUPABASE_ANON_KEY'])
GOOGLE_MAPS_API_KEY=$($secrets['GOOGLE_MAPS_API_KEY'])
"@
Set-Content -Path $envPath -Value $envContent -Encoding utf8
Write-Host "[OK] $envPath 생성" -ForegroundColor Green

# ─── 2) app/android/key.properties ───
$keyPropsPath = Join-Path $root 'app\android\key.properties'
$keyPropsContent = @"
storePassword=$($secrets['KEYSTORE_PASSWORD'])
keyPassword=$($secrets['KEY_PASSWORD'])
keyAlias=$($secrets['KEY_ALIAS'])
storeFile=$($secrets['KEYSTORE_PATH'])
"@
Set-Content -Path $keyPropsPath -Value $keyPropsContent -Encoding utf8
Write-Host "[OK] $keyPropsPath 생성" -ForegroundColor Green

# ─── 3) iOS Secrets.xcconfig (iOS 폴더가 있을 때만) ───
$iosFlutterDir = Join-Path $root 'app\ios\Flutter'
if (Test-Path $iosFlutterDir) {
    $xcconfigPath = Join-Path $iosFlutterDir 'Secrets.xcconfig'
    $xcconfigContent = @"
// Auto-generated. DO NOT EDIT.
GOOGLE_MAPS_API_KEY=$($secrets['GOOGLE_MAPS_API_KEY'])
SUPABASE_URL=$($secrets['SUPABASE_URL'])
SUPABASE_ANON_KEY=$($secrets['SUPABASE_ANON_KEY'])
"@
    Set-Content -Path $xcconfigPath -Value $xcconfigContent -Encoding utf8
    Write-Host "[OK] $xcconfigPath 생성" -ForegroundColor Green

    # Debug/Release.xcconfig에 include 추가
    foreach ($cfgName in @('Debug.xcconfig', 'Release.xcconfig')) {
        $cfgPath = Join-Path $iosFlutterDir $cfgName
        if (Test-Path $cfgPath) {
            $content = Get-Content $cfgPath -Raw
            if ($content -notmatch 'Secrets\.xcconfig') {
                Add-Content -Path $cfgPath -Value "`n#include `"Secrets.xcconfig`""
                Write-Host "[OK] $cfgPath에 Secrets.xcconfig include 추가" -ForegroundColor Green
            }
        }
    }
}

Write-Host ""
Write-Host "다음 단계:" -ForegroundColor Cyan
Write-Host "  cd app" -ForegroundColor White
Write-Host "  flutter pub get" -ForegroundColor White
Write-Host "  flutter run --dart-define-from-file=.env" -ForegroundColor White
Write-Host ""
Write-Host "  # Mac에서 iOS 빌드:" -ForegroundColor Cyan
Write-Host "  cd app/ios && pod install && cd .." -ForegroundColor White
Write-Host "  flutter run -d <iphone_id> --dart-define-from-file=.env" -ForegroundColor White
