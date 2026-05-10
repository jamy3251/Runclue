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

Write-Host ""
Write-Host "다음 단계:" -ForegroundColor Cyan
Write-Host "  cd app" -ForegroundColor White
Write-Host "  flutter pub get" -ForegroundColor White
Write-Host "  flutter run --dart-define-from-file=.env" -ForegroundColor White
