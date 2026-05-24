# RunClue — 운영자(사용자) 액션 체크리스트

마지막 갱신: 2026-05-24
관련 플랜: `~/.claude/plans/wobbly-mixing-stroustrup.md`

지금까지 코드·DB·인프라는 진행됐지만, **현실 세계의 가입·등록·운영 작업**은 사용자(jamy)가 직접 해야 합니다. 우선순위 순.

---

## P0 — 출시 전 필수

### 1. 토스페이먼츠 가맹점 가입 (Step 6~8 release 전제)

**가입 단계 (1인 사장도 무료, 5~10분)**

1. **사업자등록** (없으면)
   - 토스페이먼츠 홈페이지 → [사업 시작] → [사업자등록 바로신청]
   - 통신판매업 준비 중인 개인사업자만 간이 신청 가능. 사업자등록번호 발급까지 ~3일 소요 (국세청 안내 문자).
   - 이미 있으면 skip.

2. **통신판매업 신고** (필수 — 기프티콘 발급 근거)
   - 토스페이먼츠 → [사업 시작] → [통신판매업 바로신청] (5분, 무료)
   - 구매안전서비스 이용확인증 자동 발급
   - 입력: 사업자등록번호 / 이메일 / 사업자등록증 사본 / 상호 / 사업장 주소 / 개업일 / 대표자 정보 / 정산 계좌 / 거주지 주소

3. **토스 비즈니스 가입** → **토스페이 가맹점 신청**
   - 신청 후 ~1~2 영업일 심사
   - 가맹점 ID + 클라이언트키(테스트/운영) + 시크릿키(테스트/운영) 발급
   - 클라이언트 키 (`TOSS_CLIENT_KEY`) — Flutter 앱에 `.env`로 주입
   - 시크릿 키 (`TOSS_SECRET_KEY`) — **Supabase Edge Function env에만** 저장 (절대 git에 X)

4. **Supabase Edge Function deploy**
   ```bash
   # toss-confirm (Step 6, 결제 승인 검증)
   supabase functions deploy toss-confirm
   supabase secrets set TOSS_SECRET_KEY=<your-secret-key>

   # toss-webhook (Phase 2, 환불·취소 처리) — 보안 강화 완료
   supabase functions deploy toss-webhook
   ```

5. **토스 콘솔 webhook URL 등록**
   - 토스 → 개발자센터 → webhook 설정
   - URL: `https://<project>.functions.supabase.co/toss-webhook`
   - 구독 이벤트: `PAYMENT_STATUS_CHANGED` (결제 상태 변경, 취소·환불)

**참고 링크**
- 토스페이먼츠 사업자등록 바로신청: https://www.tosspayments.com/blog/business-registration
- 통신판매업 신고 가이드 (2025): https://www.tosspayments.com/blog/articles/sales-registration
- 토스페이 가맹점 가입 단계: https://www.tosspayments.com

검증: 클루 생성 → 1000원 테스트 결제 → `wallet_topups.status='approved'` + `clues.reward_pool_net=850` 확인

### 2. 약관/개인정보처리방침 업데이트
- [ ] 약관에 명시적으로 추가:
  > "코인·다이아는 게임 내 가상 재화이며, **현금 환급이 불가**합니다. 다이아는 운영자가 정한 카탈로그(기프티콘·가게 메뉴) 내에서만 사용 가능합니다."
- [ ] 사장 측 약관:
  > "충전금은 보상 풀로 사용되며 환불·환금 불가. 플랫폼 수수료 15% 차감."
- [ ] 통신판매업 신고증 사본 보관 (기프티콘 발급 근거)
- [ ] 약관 화면 `/settings/terms`에 위 내용 반영 (`app/lib/config/router.dart` 380행대)

### 3. 환경 변수 (.env) 정리
- [ ] `app/.env`에 추가 (gitignore 확인 — `.env`는 .gitignore에 있음):
  ```env
  # 기존
  SUPABASE_URL=
  SUPABASE_ANON_KEY=
  GOOGLE_MAPS_API_KEY=

  # 신규 (Step 6~11)
  TOSS_CLIENT_KEY=
  GMA_APP_ID_ANDROID=ca-app-pub-XXXXXXXX~XXXXXXXXXX
  GMA_APP_ID_IOS=ca-app-pub-XXXXXXXX~XXXXXXXXXX
  GMA_REWARDED_AD_UNIT_ANDROID=ca-app-pub-XXXXXXXX/XXXXXXXXXX
  GMA_REWARDED_AD_UNIT_IOS=ca-app-pub-XXXXXXXX/XXXXXXXXXX
  ```
- [ ] `.env.example` 파일 생성하여 빈 키 템플릿 공유 (다른 환경 셋업용)

---

## P1 — 광고·헬스 운영 모드 활성화

### 4. Google AdMob 가입 (Step 11 release)
- [ ] [admob.google.com](https://admob.google.com) 가입 → 사이트/앱 등록 (RunClue Android + iOS)
- [ ] 앱 ID + 보상형 비디오 광고 단위 ID 발급
- [ ] Android `AndroidManifest.xml` 24:25행의 메타데이터를 운영 ID로 교체 (현재 테스트 ID)
  - 또는 `build.gradle.kts`에서 manifestPlaceholders로 `.env` 값 주입
- [ ] iOS `Info.plist`의 `GADApplicationIdentifier`를 운영 ID로 교체
- [ ] Flutter 빌드 시 `--dart-define-from-file=.env`로 광고 단위 ID 주입 (이미 APK 빌드 파이프라인에 포함됨, commit 820b445)

검증: 빌드 후 광고 시청 → coin_ledger에 reason='ad' row 생성 + 코인 +20

### 5. iOS HealthKit Capability 활성화 (Step 13 release)
- [ ] Mac/Xcode에서 `ios/Runner.xcworkspace` 열기
- [ ] Runner target → Signing & Capabilities → "+ Capability" → HealthKit 추가
- [ ] 자동으로 `Runner.entitlements` 파일 생성됨 (커밋)
- [ ] Apple Developer 계정의 App ID에서 HealthKit 활성화 (Provisioning Profile 갱신)

검증: iOS 빌드 → 권한 다이얼로그 표시 → 걸음수 카드에 오늘 걸음수 표시

### 6. Android Health Connect 안내 (Step 13)
- [ ] Health Connect 앱이 사용자 디바이스에 없으면 권한 요청이 실패. 권장 사항을 안내 UI에 추가 (낮은 우선순위 — 권한 거부 시 자동 안내 메시지로 충분할 수 있음)

---

## P2 — 콘텐츠/데이터 운영

### 7. 기프티콘 카탈로그 등록 (Step 15)
운영 도구 없이 SQL로 직접 INSERT:

```sql
INSERT INTO gifticons (partner_brand, name, value_krw, diamond_cost, image_url, stock, display_order, active) VALUES
  ('스타벅스', '아메리카노 Tall', 4500, 450, 'https://...', 50, 10, true),
  ('이디야', '아메리카노', 3000, 300, 'https://...', 50, 20, true),
  ('CU',     '편의점 5천원권', 5000, 500, 'https://...', 30, 30, true);
```

- [ ] 첫 5~10개 기프티콘 등록 (대학가 친화: 카페·편의점·치킨)
- [ ] 외부 기프티콘 도매처 또는 큐레이션 (수동 발급 — 사용자 redeem 요청 시 운영자가 수동으로 발송 + redemptions.coupon_code UPDATE + status='issued')
- [ ] 자동 발급 API 연동은 Phase 2 (예: 기프티스타, 스마일콘 등)

운영 SQL — pending 발급 처리:
```sql
UPDATE redemptions
   SET coupon_code = 'XXXX-XXXX-XXXX',
       status = 'issued',
       issued_at = now(),
       expires_at = now() + interval '90 days'
 WHERE id = '<redemption_id>'::uuid;
```

### 8. Storage 버킷 이미지 업로드
- [ ] `gifticons` 이미지: Supabase Storage → public 버킷에 PNG 업로드 (`clues/` 또는 신규 `gifticons/`)
- [ ] `store_menus` 이미지: 사장이 메뉴 등록 시 카메라/갤러리로 업로드 — 화면 구현 시 자동 처리

### 9. 사장 측 가게 메뉴 관리 (Step 16)
**현재 UI 미완성** — 진행 보류 상태. 다음 세션에 이어서:
- `app/lib/screens/store/menu_manage_screen.dart` (사장 본인 메뉴 CRUD)
- `app/lib/screens/store/store_menu_list_screen.dart` (다른 사용자가 가게 메뉴 보고 결제)
- `app/lib/screens/store/qr_redeem_screen.dart` (사장이 QR 스캔)
- `app/lib/screens/profile/my_purchases_screen.dart` (구매한 메뉴 + QR 표시)

DB·RPC는 모두 적용됨 (마이그레이션 023). RPC 단위 테스트는 가능:
```sql
SELECT purchase_store_menu('<menu-uuid>');
SELECT redeem_store_purchase('<qr-token>');
```

### 10. Supabase Storage 버킷 확인
- [ ] 003 마이그레이션에서 생성된 `clues`, `evidence`, `profiles` 버킷 그대로 사용
- [ ] `gifticons` 이미지용 별도 버킷이 필요하면 SQL로 추가 (또는 `clues` 버킷 재활용)

---

## P3 — 사업자/법무 (전문가 자문 권장)

### 11. 사업자 등록 & 세무
- [ ] 개인사업자 등록 (홈택스) — 대학가 1인 사장 대상으로 매출 시작 전
- [ ] 통신판매업 신고 (해당 시군구)
- [ ] 세무사 자문 — 수수료 매출의 부가세·소득세 처리

### 12. 한국 전자금융업 검토 (먼 미래 — 사용자 다이아 충전 활성화 시)
- [ ] MVP는 사용자 다이아 충전 비활성 (사장만 토스 충전). 사용자 P2P 송금도 없음 → 선불업 라이선스 미해당.
- [ ] 향후 환금/사용자 다이아 충전 도입 시 금감원 전자금융업자 등록 검토 (자본금 ~20억).
- [ ] 변호사 자문 — 약관·환금 정책 검토.

### 13. App Store / Google Play 심사 대비
- [ ] iOS 심사 리젝 대비: 토스 결제는 **사장 B2B 마케팅 광고비 충전**으로 포지셔닝 (Uber Eats / 배달의민족 동일 패턴)
- [ ] 토스 결제 화면은 외부 브라우저(`url_launcher`)로 — 인앱 WebView는 리젝 위험 ↑
- [ ] 사용자 다이아 충전 자체는 일단 disable (iOS IAP 30% 회피)
- [ ] AdMob — 광고 정책 위반 사유 확인 (gambling/incentive 정책)

---

## P4 — 모니터링 & 운영 대시보드

### 14. 운영 통계 SQL
정기 점검용 (Supabase SQL editor에서 수동 실행):

```sql
-- 일별 플랫폼 매출 (수수료)
SELECT * FROM platform_revenue_v1 LIMIT 30;

-- 일별 코인 인플레이션 (전체 사용자)
SELECT day_date, sum(delta) AS coin_minted
FROM coin_ledger
WHERE delta > 0
GROUP BY day_date ORDER BY day_date DESC LIMIT 30;

-- 다이아 발행 (사장 매출 vs 사용자 사용)
SELECT source, sum(delta) AS total
FROM diamond_ledger
GROUP BY source ORDER BY abs(sum(delta)) DESC;

-- 기프티콘 pending 누적 (운영자 발급 백로그)
SELECT count(*), sum(diamond_cost)
FROM redemptions WHERE status = 'pending';

-- coop 클루 현황
SELECT id, title, coop_state, min_participants, current_participants, lobby_started_at
FROM clues WHERE game_mode = 'coop'
ORDER BY created_at DESC LIMIT 20;
```

### 15. Supabase advisor 정기 점검
- [ ] 마이그레이션 추가 시마다 `mcp__supabase__get_advisors security` 실행 (대화 중 Claude에게 부탁)
- [ ] ERROR 레벨만 즉시 대응 (WARN/INFO는 정책 결정)

---

## P5 — 진행 보류된 코드 작업

### 16. Step 16 Flutter UI (가게 커머스)
DB·RPC는 모두 적용됨. 다음 세션에 이어서:
- 사장 메뉴 관리 (CRUD)
- 사용자 메뉴 결제 + QR 발급
- 사용자 QR 표시 + 사장 QR 스캔

### 17. Phase 2 광고 SSV ✅ 코드 완료, deploy 대기
Edge Function `admob-ssv` 작성 완료 — Google ECDSA-P256 서명 검증 + grant_coin_admin 호출.

운영 활성화 단계:
1. **Edge Function deploy**
   ```bash
   supabase functions deploy admob-ssv
   ```
2. **AdMob 콘솔 → 광고 단위 → 보상 설정 → 서버측 인증 URL**
   ```
   https://<project>.functions.supabase.co/admob-ssv
   ```
3. **Flutter 빌드 시 SSV 모드 활성화**
   ```bash
   flutter build apk --release \
     --dart-define=ADMOB_USE_SSV=true \
     --dart-define-from-file=.env
   ```
4. 검증: 광고 시청 → 우리 Edge Function 로그에 `ok: true` → `ad_views` row 생성 → 코인 +20

활성화 안 한 상태 (MVP) — 클라이언트가 `claim_ad_reward` RPC 직접 호출. 어뷰 위험은 일일 캡 5회·일일 +500 코인으로 완화.

### 18. Phase 2 토스 webhook ✅ 코드 완료, deploy 대기
Edge Function `toss-webhook` 작성 완료 — HMAC-SHA256 서명 검증 + 결제 취소 시 풀 자동 차감 (committed 이상은 보호).

운영 활성화는 위 1번 항목의 4~5 단계 참조.

### 19. Step 18 Lobby 타임아웃
`pg_cron`으로 30분 초과 recruiting 클루 자동 취소 + 풀 복원.

---

## 우선순위 요약

| 우선순위 | 항목 | 막힘 |
|---|---|---|
| P0 | 토스 가맹점 + 약관 + .env 정리 | release 불가 |
| P1 | AdMob 운영 ID + iOS HealthKit Capability | 광고/걸음수 운영 불가 |
| P2 | 기프티콘 카탈로그 + 사장 메뉴 UI | 다이아 사용처 활성화 |
| P3 | 사업자등록·통신판매업·법무 | 출시 후 보완 가능 |
| P4 | 운영 통계·advisor 정기 점검 | 운영 안정성 |
| P5 | 진행 보류 코드 + Phase 2 | 다음 코딩 사이클 |
