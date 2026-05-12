#requires -Version 5.1
<#
.SYNOPSIS
  RunClue 릴리즈 파이프라인 — APK 빌드 → GitHub Release 업로드 → QR 생성

.DESCRIPTION
  1. scripts\build_apk.ps1 호출 (.env 검증 + APK 빌드)
  2. pubspec.yaml에서 version 추출
  3. GitHub Release 생성 (gh CLI 사용)
  4. APK 자산 업로드
  5. install 페이지 URL용 QR PNG 생성 (api.qrserver.com)
  6. dist\install.html 갱신 (랜딩 페이지)

.PARAMETER Tag
  릴리즈 태그. 기본은 pubspec version 기반 (v1.0.0+1 → v1.0.0-1).
  같은 태그가 이미 있으면 -Replace 필요.

.PARAMETER Replace
  같은 태그 release 있으면 삭제 후 재생성

.PARAMETER SkipBuild
  이미 빌드된 APK 사용 (debug용)

.EXAMPLE
  .\scripts\release.ps1
  .\scripts\release.ps1 -Tag v0.1.0
  .\scripts\release.ps1 -Replace
#>
[CmdletBinding()]
param(
  [string]$Tag,
  [switch]$Replace,
  [switch]$SkipBuild
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot

Push-Location $repoRoot
try {
  # ─────────────────────────────────────────────────────────────
  # 0) gh CLI 존재 & 로그인 확인
  # ─────────────────────────────────────────────────────────────
  if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host '✘ GitHub CLI(gh) 미설치.' -ForegroundColor Red
    Write-Host '  https://cli.github.com/ 에서 설치 후 `gh auth login`' -ForegroundColor Yellow
    exit 1
  }
  $authStatus = gh auth status 2>&1
  if ($LASTEXITCODE -ne 0) {
    Write-Host '✘ gh 로그인 필요: `gh auth login`' -ForegroundColor Red
    exit 1
  }
  Write-Host '✓ gh 로그인 확인' -ForegroundColor Green

  # ─────────────────────────────────────────────────────────────
  # 1) 버전 / 태그 결정
  # ─────────────────────────────────────────────────────────────
  $pubspec = Get-Content (Join-Path $repoRoot 'pubspec.yaml') -Raw
  if ($pubspec -notmatch '(?m)^version:\s*(\S+)') {
    Write-Host '✘ pubspec.yaml에서 version 추출 실패' -ForegroundColor Red
    exit 1
  }
  $version = $Matches[1]
  if (-not $Tag) {
    $Tag = 'v' + ($version -replace '\+', '-')
  }
  Write-Host "→ 릴리즈 태그: $Tag (pubspec version=$version)"

  # ─────────────────────────────────────────────────────────────
  # 2) 빌드
  # ─────────────────────────────────────────────────────────────
  if (-not $SkipBuild) {
    Write-Host '→ APK 빌드' -ForegroundColor Cyan
    & (Join-Path $PSScriptRoot 'build_apk.ps1') -NoSplit
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  }

  $apkDir = Join-Path $repoRoot 'build\app\outputs\flutter-apk'
  # universal APK 우선, 없으면 arm64
  $apk = Get-ChildItem -Path $apkDir -Filter 'app-release.apk' -ErrorAction SilentlyContinue | Select-Object -First 1
  if (-not $apk) {
    $apk = Get-ChildItem -Path $apkDir -Filter 'app-arm64-v8a-release.apk' | Select-Object -First 1
  }
  if (-not $apk) {
    Write-Host '✘ 빌드된 APK 없음' -ForegroundColor Red
    exit 1
  }
  Write-Host "✓ APK: $($apk.Name) ($([math]::Round($apk.Length / 1MB, 1)) MB)" -ForegroundColor Green

  # ─────────────────────────────────────────────────────────────
  # 3) 같은 태그 release 처리
  # PS 5.1이 native stderr를 에러로 취급하므로 ErrorAction을 격리
  # ─────────────────────────────────────────────────────────────
  $prevEAP = $ErrorActionPreference
  $ErrorActionPreference = 'SilentlyContinue'
  $null = gh release view $Tag 2>&1
  $exists = ($LASTEXITCODE -eq 0)
  $ErrorActionPreference = $prevEAP

  if ($exists) {
    if ($Replace) {
      Write-Host "→ 기존 release ($Tag) 삭제 (-Replace)" -ForegroundColor Yellow
      gh release delete $Tag --yes --cleanup-tag
    }
    else {
      Write-Host "✘ release $Tag 이미 존재. -Replace 옵션 사용." -ForegroundColor Red
      exit 1
    }
  }

  # ─────────────────────────────────────────────────────────────
  # 4) Release 생성 + APK 업로드
  # PS 5.1이 한국어를 native arg로 전달 시 인코딩이 깨지므로
  # notes는 UTF-8 파일로 작성 후 --notes-file로 전달
  # title도 ASCII만 사용
  # ─────────────────────────────────────────────────────────────
  $notesPath = Join-Path $env:TEMP "runclue_release_notes_$([guid]::NewGuid().ToString('N')).md"
  $notes = @"
## RunClue $Tag

Scan QR to install on Android.
APK is universal (ARM64 / ARMv7 / x86_64).

### Install (Android)
1. Scan QR or click APK link
2. Enable "Install unknown apps" (Settings → Security)
3. Install
"@
  [System.IO.File]::WriteAllText($notesPath, $notes, [System.Text.UTF8Encoding]::new($false))

  Write-Host "→ gh release create $Tag" -ForegroundColor Cyan
  gh release create $Tag $apk.FullName --title "RunClue $Tag" --notes-file $notesPath
  $createExit = $LASTEXITCODE
  Remove-Item $notesPath -ErrorAction SilentlyContinue
  if ($createExit -ne 0) { exit $createExit }

  # ─────────────────────────────────────────────────────────────
  # 5) 다운로드 URL + QR 생성
  # ─────────────────────────────────────────────────────────────
  $repo = gh repo view --json nameWithOwner -q '.nameWithOwner'
  # GitHub은 release asset에 대해 latest 링크를 제공
  $apkUrl = "https://github.com/$repo/releases/download/$Tag/$($apk.Name)"
  Write-Host "✓ APK URL: $apkUrl" -ForegroundColor Green

  $distDir = Join-Path $repoRoot 'dist'
  if (-not (Test-Path $distDir)) {
    New-Item -ItemType Directory -Path $distDir | Out-Null
  }

  # QR PNG — qrserver.com 무료 API
  $qrUrl = "https://api.qrserver.com/v1/create-qr-code/?size=600x600&margin=20&data=$([Uri]::EscapeDataString($apkUrl))"
  $qrPath = Join-Path $distDir "qr_$Tag.png"
  Write-Host "→ QR 생성: $qrPath" -ForegroundColor Cyan
  Invoke-WebRequest -Uri $qrUrl -OutFile $qrPath -UseBasicParsing
  Write-Host "✓ QR: $qrPath" -ForegroundColor Green

  # ─────────────────────────────────────────────────────────────
  # 6) install.html 갱신 — QR + 안드로이드 자동 다운로드
  # ─────────────────────────────────────────────────────────────
  $htmlPath = Join-Path $distDir 'install.html'
  $html = @"
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>RunClue $Tag — 설치</title>
<style>
  :root { color-scheme: dark; }
  * { box-sizing: border-box; }
  body {
    margin: 0; min-height: 100vh; background: #07070E;
    color: #EBEBEB;
    font-family: -apple-system, BlinkMacSystemFont, 'Noto Sans KR', sans-serif;
    display: flex; align-items: center; justify-content: center;
    padding: 24px;
  }
  .card {
    max-width: 420px; width: 100%; background: #1C1C22;
    border: 1px solid rgba(255,255,255,.07); border-radius: 24px;
    padding: 32px; text-align: center;
  }
  h1 { margin: 0 0 8px; font-size: 28px; color: #FACC15; }
  .ver { color: #A0A0A0; font-size: 14px; margin-bottom: 24px; }
  .qr { background: #fff; padding: 12px; border-radius: 16px; display: inline-block; }
  .qr img { display: block; width: 240px; height: 240px; }
  .btn {
    display: inline-block; margin-top: 24px; padding: 14px 28px;
    background: #FACC15; color: #000; text-decoration: none;
    border-radius: 12px; font-weight: 900; font-size: 16px;
  }
  .hint { margin-top: 20px; font-size: 12px; color: #696969; line-height: 1.6; }
</style>
</head>
<body>
<div class="card">
  <h1>RunClue</h1>
  <div class="ver">$Tag · $([math]::Round($apk.Length / 1MB, 1)) MB</div>
  <div class="qr">
    <img src="$qrUrl" alt="QR 코드">
  </div>
  <a class="btn" href="$apkUrl">📥 APK 다운로드</a>
  <div class="hint">
    안드로이드 폰에서 카메라로 QR을 스캔하거나<br>
    위 버튼을 누르면 APK가 다운로드 돼요.<br><br>
    설정 → 보안에서 "알 수 없는 출처 허용" 켜야 설치 가능합니다.
  </div>
</div>
<script>
  // 안드로이드 사용자 자동 다운로드 시작 (선택)
  if (/android/i.test(navigator.userAgent)) {
    setTimeout(function(){ window.location.href = "$apkUrl"; }, 1500);
  }
</script>
</body>
</html>
"@
  Set-Content -Path $htmlPath -Value $html -Encoding utf8
  Write-Host "✓ install.html: $htmlPath" -ForegroundColor Green

  # ─────────────────────────────────────────────────────────────
  # 7) 요약
  # ─────────────────────────────────────────────────────────────
  Write-Host ''
  Write-Host '════════════════════════════════════════' -ForegroundColor Cyan
  Write-Host '  배포 완료!' -ForegroundColor Green
  Write-Host '════════════════════════════════════════' -ForegroundColor Cyan
  Write-Host "  태그:     $Tag"
  Write-Host "  APK URL:  $apkUrl"
  Write-Host "  QR PNG:   $qrPath"
  Write-Host "  랜딩:     $htmlPath"
  Write-Host ''
  Write-Host '다음 단계:' -ForegroundColor Yellow
  Write-Host "  • QR 이미지를 열어서 친구 폰에서 스캔: explorer $qrPath"
  Write-Host '  • 또는 install.html을 GitHub Pages / Vercel에 호스팅'
}
finally {
  Pop-Location
}
