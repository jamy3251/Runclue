# RunClue 출시 가이드 (Play Store + App Store)

> 두 스토어 모두 본인이 직접 계정 등록 + 결제가 필요합니다. 이 문서는 단계·체크리스트.

---

## 0. 공통 사전 준비 (양 스토어 공통)

| 항목 | 비고 |
|---|---|
| 앱 아이콘 (1024×1024) | `app/assets/images/app_icon.png` 있음 — Play Store/App Store용으로 1024px PNG 필요 |
| 스크린샷 (각 스토어 요건) | 폰·태블릿 화면, 5~8개 |
| 짧은 설명 (80자 이내) | "방학에도 손님이 찾아오게 하는 AR 캠퍼스타운 리워드 플랫폼" |
| 긴 설명 (4000자 이내) | `MVP_GUIDE.md` 1장 기반 |
| 개인정보처리방침 URL | 공개 URL 필수 (랜딩페이지에 추가) |
| 서비스 약관 URL | 동일 |
| 개발사 연락 이메일 | jamy3251@gmail.com |
| 카테고리 | 라이프스타일 / 음식 및 음료 |

---

## 1. Google Play Store 출시 절차

### 1.1 계정·결제
1. https://play.google.com/console 접속
2. **개발자 계정 등록** ($25 1회)
   - 본인 정보, 신용카드 결제
   - 이메일·전화번호 인증
3. 결제 프로필 등록 (앱 내 결제 안 쓰면 생략 가능)

### 1.2 앱 등록
1. Play Console → "앱 만들기"
2. 앱 정보:
   - 이름: **RunClue**
   - 기본 언어: 한국어
   - 앱·게임: **앱**
   - 무료·유료: **무료**
3. 정책 검토 — 모두 동의 (콘텐츠 가이드라인, 미국 수출법 등)

### 1.3 스토어 등록정보
- **스토어 등록정보** 섹션
- 짧은 설명, 자세한 설명 (위 §0 참고)
- 그래픽 자료: 앱 아이콘 (512×512), 기능 그래픽 (1024×500), 스크린샷 (폰 최소 2개, 1080×1920)
- 카테고리: **라이프스타일** 또는 **음식 및 음료**
- 콘텐츠 등급 설문 (위치 기반·참여형 미션 → 전체이용가)
- 개인정보처리방침 URL (필수)

### 1.4 앱 콘텐츠
- **데이터 보호**: 위치, 이메일, 사진 수집 명시
- **광고 포함 여부**: 없음
- **앱 액세스**: 모든 사용자 가능 (단, 베타 매장 등록 후)

### 1.5 Release용 Android App Bundle (AAB) 빌드

```bash
cd app

# 1) MY_SECRETS.local에 기재된 keystore가 실제로 있는지 확인
ls C:\Users\User\runclue-release.jks

# 2) 없으면 새로 생성 (한 번만)
keytool -genkey -v \
  -keystore C:\Users\User\runclue-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias runclue
# 입력: storePassword, keyPassword (MY_SECRETS.local에 저장된 값과 일치시키기)

# 3) build.gradle에서 minifyEnabled 다시 true로 (출시 전 검증 끝나면)
# ← 현재는 false. release 안정화되면 true로 + ProGuard rules 검증

# 4) AAB 빌드 (Play Store는 APK 대신 AAB 권장)
flutter build appbundle --release \
  --dart-define-from-file=.env

# 결과: build/app/outputs/bundle/release/app-release.aab
```

### 1.6 내부 테스트 → 비공개 테스트 → 공개

**내부 테스트 (10분)**:
1. Play Console → 출시 → 테스트 → 내부 테스트
2. AAB 업로드
3. 테스터 추가 (이메일 목록)
4. 내부 테스트 트랙 시작
5. 테스터에게 옵트인 링크 전송 → 그들이 Play Store에서 설치

**비공개 테스트 (베타 매장 사장님 + 시립대 학생)**:
- 같은 흐름이지만 더 많은 테스터 포함 가능
- 콘텐츠 등급, 정책 동의 모두 완료해야 함

**프로덕션 출시**:
- 사전 검토 1~3일 (Google 심사)
- 승인 후 Play Store에 노출

### 1.7 체크리스트
- [ ] 개발자 계정 등록 + $25 결제
- [ ] 앱 만들기
- [ ] 스토어 등록정보 작성
- [ ] 그래픽 자료 업로드 (아이콘, 기능 그래픽, 스크린샷 4+)
- [ ] 개인정보처리방침 공개 URL
- [ ] 콘텐츠 등급 설문
- [ ] 데이터 보호 신고 (위치/이메일/사진)
- [ ] keystore 생성 + key.properties 셋업
- [ ] `flutter build appbundle --release`
- [ ] 내부 테스트 트랙 업로드
- [ ] 테스터 옵트인 → 실기 검증
- [ ] 프로덕션 트랙 출시

---

## 2. Apple App Store 출시 절차 (Mac 필요)

### 2.1 계정·결제
1. **Apple Developer Program 가입** ($99/년)
2. https://developer.apple.com 에서 등록
3. 본인 인증 (한국 사업자 또는 개인) — 약 1~3일

### 2.2 App Store Connect 등록
1. https://appstoreconnect.apple.com 접속
2. **My Apps** → **+ New App**
3. 정보:
   - 플랫폼: iOS
   - 이름: **RunClue**
   - 기본 언어: 한국어
   - 번들 ID: **com.runclue.app**
   - SKU: runclue-001
   - 사용자 액세스: 전체

### 2.3 앱 정보 작성
- 이름·부제·키워드·설명
- 카테고리: **라이프스타일** + 보조 **음식 및 음료**
- 스크린샷: iPhone 6.7" (1290×2796), 6.5" 호환
- 앱 아이콘: 1024×1024 PNG (투명도·라운드코너 X)
- 등급: 4+ (장소 검색·참여형 미션은 일반 등급)
- 개인정보처리방침 URL

### 2.4 빌드 (Mac에서)

```bash
git clone https://github.com/jamy3251/Runclue.git
cd Runclue

# MY_SECRETS.local 받아서 루트에 두기
bash apply_secrets.sh

cd app/ios && pod install && cd ..

# Xcode 열기
open ios/Runner.xcworkspace
```

Xcode에서:
1. **Signing & Capabilities**:
   - Team: Apple Developer 계정
   - Bundle ID: `com.runclue.app` (App Store Connect와 일치)
   - Automatically manage signing: ✓
2. **Product → Archive**
3. Organizer → **Distribute App** → **App Store Connect** → Upload
4. 잠시 기다리면 App Store Connect에 빌드가 나타남

### 2.5 TestFlight (베타 테스트)
1. App Store Connect → My Apps → RunClue → TestFlight
2. 업로드된 빌드 선택 → 테스트 정보 입력
3. **내부 테스터** 100명까지 즉시 가능 (App Store Connect 멤버)
4. **외부 테스터** 10,000명 — Apple 심사 필요 (약 24시간)
5. 테스터에게 TestFlight 앱 설치 안내

### 2.6 App Store 심사
- App Information 모두 작성
- 빌드 선택 → "Submit for Review"
- 심사 기간: 평균 1~3일
- 거절 시 사유 확인 후 수정 → 재제출

### 2.7 체크리스트
- [ ] Apple Developer Program 가입 + $99 결제
- [ ] 본인 인증 완료
- [ ] App Store Connect에 앱 만들기 (Bundle ID `com.runclue.app`)
- [ ] 앱 정보·스크린샷 업로드
- [ ] 개인정보처리방침 URL
- [ ] iOS bundle id용 Google Maps API key 추가 발급 (Cloud Console)
- [ ] Xcode Signing 설정
- [ ] Archive → Upload to App Store Connect
- [ ] TestFlight 내부 테스트
- [ ] App Store 심사 제출

---

## 3. 출시 전 필수 작업 (앱 자체)

### 3.1 ProGuard/R8 다시 활성화 (현재 disabled)
출시 전 검증 끝나면:

```gradle
// app/android/app/build.gradle
buildTypes {
  release {
    minifyEnabled true        // ← false에서 true로
    shrinkResources true       // ← false에서 true로
    proguardFiles ...
  }
}
```

### 3.2 디버그 모드 OFF 확인
- `app/lib/app.dart`: `debugShowCheckedModeBanner: false` ✓
- 디버그 print 제거 (`debugPrint` 호출 일부 제거 권장)

### 3.3 Supabase RLS 강화
현재 MVP에서 RLS 비활성화되어 있음. 출시 전 모두 켜고 정책 작성:
```sql
ALTER TABLE clues ENABLE ROW LEVEL SECURITY;
CREATE POLICY "anyone reads active clues" ON clues
  FOR SELECT USING (status = 'active');
CREATE POLICY "creator updates own clues" ON clues
  FOR UPDATE USING (creator_id = auth.uid());
-- 등...
```

### 3.4 자동 confirm 트리거 제거
이메일 인증 다시 켜고:
```sql
DROP TRIGGER IF EXISTS auto_confirm_email_trigger ON auth.users;
DROP FUNCTION IF EXISTS public.auto_confirm_email();
```

### 3.5 클루 자동 승인 → 검수 큐로 변경
`create_clue_screen.dart`의 `'status': 'active'` → `'status': 'pending'`로 변경하고 운영자 승인 페이지 추가.

### 3.6 개인정보처리방침 페이지 공개
- `landing/privacy.html` 작성
- GitHub Pages 또는 Netlify로 공개 URL 확보
- 양 스토어 등록 시 입력

---

## 4. 출시 일정 (예상)

| 마일스톤 | 기간 | 비고 |
|---|---|---|
| 베타 매장 10곳 등록 | 2주 | 시립대 캠퍼스타운 영업 |
| 내부 테스트 (10명) | 1주 | Play Console 내부 트랙 |
| Closed Beta (100명) | 2주 | TestFlight + Play Beta |
| 출시 정책 검토·심사 | 1주 | Google 1~3일, Apple 1~3일 |
| **공개 출시** | 4~6주 후 | |

---

## 5. 비용

| 항목 | 비용 |
|---|---|
| Google Play Developer | $25 (1회) |
| Apple Developer Program | $99 (연 1회) |
| Supabase | $0 (free tier 충분, 사용자 50K+ 시 $25/mo) |
| Google Maps API | $0~ (월 $200 크레딧, 작은 사용량은 무료) |
| 도메인 (선택, 랜딩용) | ~$15/년 |
| **합계 1년차** | ~$140 |

---

## 6. 다음 단계 추천

1. **이번 주**: Google Play Developer 계정 등록 ($25)
2. **이번 주말까지**: 앱 아이콘·스크린샷 6장 준비
3. **다음 주**: 개인정보처리방침 공개 (`landing/privacy.html`)
4. **2주 후**: AAB 빌드 + Play Console 내부 테스트 트랙 업로드
5. **3주 후**: 베타 매장과 함께 비공개 테스트
6. **Mac 팀원 합류 후**: Apple Developer 등록 + iOS TestFlight 준비
