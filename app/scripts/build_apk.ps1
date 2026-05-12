#requires -Version 5.1
<#
.SYNOPSIS
  RunClue APK 빌드 스크립트. .env 누락 시 명확히 실패.

.DESCRIPTION
  과거에 --dart-define-from-file=.env 없이 빌드한 APK가 Supabase URL/KEY 없이
  배포되어 회원가입/로그인이 모두 실패했던 사고가 있었음. 이 스크립트는:
    1. .env 파일 존재 확인
    2. SUPABASE_URL / SUPABASE_ANON_KEY 키 확인
    3. flutter clean (옵션 -Clean)
    4. flutter pub get
    5. --dart-define-from-file=.env 포함해서 빌드
    6. 산출 APK 목록 출력

.PARAMETER Clean
  flutter clean 먼저 실행 (의존성 변경 후 권장)

.PARAMETER NoSplit
  --split-per-abi 제외 — 단일 universal APK (배포용)

.EXAMPLE
  .\scripts\build_apk.ps1
  .\scripts\build_apk.ps1 -Clean
  .\scripts\build_apk.ps1 -NoSplit
#>
[CmdletBinding()]
param(
  [switch]$Clean,
  [switch]$NoSplit
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot

Push-Location $repoRoot
try {
  # ─────────────────────────────────────────────────────────────
  # 1) .env 존재 & 내용 검증
  # ─────────────────────────────────────────────────────────────
  $envPath = Join-Path $repoRoot '.env'
  if (-not (Test-Path $envPath)) {
    Write-Host '✘ .env 파일 없음.' -ForegroundColor Red
    Write-Host '  app/ 디렉토리에 .env 가 있어야 합니다.' -ForegroundColor Yellow
    Write-Host '  형식:' -ForegroundColor Yellow
    Write-Host '    SUPABASE_URL=https://xxx.supabase.co'
    Write-Host '    SUPABASE_ANON_KEY=eyJ...'
    Write-Host '    GOOGLE_MAPS_API_KEY=AIza...'
    exit 1
  }

  $envContent = Get-Content $envPath -Raw
  $requiredKeys = @('SUPABASE_URL', 'SUPABASE_ANON_KEY')
  $missing = @()
  foreach ($k in $requiredKeys) {
    if ($envContent -notmatch "(?m)^\s*$k\s*=\s*\S+") {
      $missing += $k
    }
  }
  if ($envContent -match 'your-project\.supabase\.co') {
    $missing += 'SUPABASE_URL (placeholder 그대로)'
  }
  if ($missing.Count -gt 0) {
    Write-Host "✘ .env에 누락/placeholder 항목: $($missing -join ', ')" -ForegroundColor Red
    exit 1
  }

  Write-Host '✓ .env 검증 통과' -ForegroundColor Green

  # ─────────────────────────────────────────────────────────────
  # 2) flutter clean (옵션)
  # ─────────────────────────────────────────────────────────────
  if ($Clean) {
    Write-Host '→ flutter clean' -ForegroundColor Cyan
    flutter clean
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  }

  # ─────────────────────────────────────────────────────────────
  # 3) flutter pub get
  # ─────────────────────────────────────────────────────────────
  Write-Host '→ flutter pub get' -ForegroundColor Cyan
  flutter pub get
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

  # ─────────────────────────────────────────────────────────────
  # 4) 빌드
  # ─────────────────────────────────────────────────────────────
  $buildArgs = @('build', 'apk', '--release', '--dart-define-from-file=.env')
  if (-not $NoSplit) { $buildArgs += '--split-per-abi' }

  Write-Host "→ flutter $($buildArgs -join ' ')" -ForegroundColor Cyan
  $started = Get-Date
  flutter @buildArgs
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  $elapsed = (Get-Date) - $started

  # ─────────────────────────────────────────────────────────────
  # 5) 결과 요약
  # ─────────────────────────────────────────────────────────────
  $apkDir = Join-Path $repoRoot 'build\app\outputs\flutter-apk'
  $apks = Get-ChildItem -Path $apkDir -Filter 'app-*.apk' -ErrorAction SilentlyContinue
  Write-Host ''
  Write-Host "✓ 빌드 완료 ($([int]$elapsed.TotalSeconds)초)" -ForegroundColor Green
  foreach ($apk in $apks) {
    $size = [math]::Round($apk.Length / 1MB, 1)
    Write-Host "  $($apk.Name)  ${size} MB"
  }
  Write-Host ''
  Write-Host '설치:' -ForegroundColor Cyan
  Write-Host '  adb install -r build\app\outputs\flutter-apk\app-arm64-v8a-release.apk'
}
finally {
  Pop-Location
}
