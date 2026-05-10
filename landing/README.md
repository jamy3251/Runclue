# RunClue 홍보 랜딩 페이지

`index.html` 단일 파일에 모두 들어있습니다. 의존성 없음.

## 미리보기 (로컬)

```bash
cd D:/Projects/App/RunClue/landing
python -m http.server 8000
# 또는
npx serve .
```

브라우저에서 http://localhost:8000 접속.

## 배포 옵션

### A) GitHub Pages (가장 간단)
1. 깃허브 저장소 만들기 → `landing/` 안의 `index.html`을 업로드
2. Settings → Pages → Source: main / root
3. `https://<유저>.github.io/<레포>/` 로 접속 가능

### B) Netlify Drop (드래그 1번)
1. https://app.netlify.com/drop 접속
2. `landing/` 폴더를 드래그
3. 즉시 https://random-name.netlify.app/ URL 발급

### C) Vercel
```bash
cd landing
vercel deploy --prod
```

## 사장님 자동 제휴 신청 동작

폼 제출 시 Supabase REST API로 직접 INSERT:
- 1차: `partner_applications` 테이블
- 2차 (1차 실패 시): `store_partners` 테이블

테이블이 없으면 실패 메시지가 떠서 사용자가 contact@runclue.app으로 연락하도록 안내합니다.

### Supabase 테이블 생성 SQL

```sql
create table if not exists partner_applications (
  id uuid default gen_random_uuid() primary key,
  store_name text not null,
  owner_name text not null,
  phone text not null,
  address text not null,
  category text not null,
  description text,
  instagram_url text,
  status text default 'pending',
  source text,
  created_at timestamptz default now()
);

-- 익명 사용자가 INSERT 가능하도록 RLS
alter table partner_applications enable row level security;
create policy "anon can insert" on partner_applications
  for insert with check (true);
```

## 카카오톡 공유

페이지 메타 태그(og:title / og:description)가 이미 설정되어 있어 카톡에 링크 붙여넣으면 미리보기가 깔끔하게 나옵니다.

## APK 배포 흐름 (현재)

1. 사장님이 폼 신청 → 운영진이 연락처로 카카오톡 → APK 파일 또는 다운로드 링크 전송
2. (Wave 2) Google Drive 또는 자체 호스팅에 APK 올리고 다운로드 버튼이 직접 가리키도록
3. (Wave 3) Play Store 정식 배포 후 버튼 → Play Store 링크
