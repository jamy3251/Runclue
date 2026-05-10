# RunClue UI/UX 요구사항 명세서
**버전**: v2.0 | **작성일**: 2026.04 | **플랫폼**: iOS/Android (모바일 퍼스트)

---

## 목차

1. [프로젝트 개요](#1-프로젝트-개요)
2. [디자인 시스템](#2-디자인-시스템)
3. [글로벌 컴포넌트 명세](#3-글로벌-컴포넌트-명세)
4. [화면별 UX 명세 (11 Screens)](#4-화면별-ux-명세)
5. [인터랙션 & 애니메이션 명세](#5-인터랙션--애니메이션-명세)
6. [상태 관리 명세](#6-상태-관리-명세)
7. [접근성 요구사항](#7-접근성-요구사항)

---

## 1. 프로젝트 개요

### 1.1 서비스 정의
RunClue(런클루)는 **위치기반 게임 미션 마켓플레이스**이다. 슬로건은 "뛰자, 풀자, 벌자."로, 탐험가가 실제 오프라인 공간을 이동하며 미션을 수행하고 현금 보상을 받는 구조이다.

### 1.2 3자 생태계 (Multi-sided Marketplace)

| 역할 | 한글명 | 목적 | 아이콘 |
|---|---|---|---|
| Explorer | 탐험가 | 미션 수행 → 현금 보상 | Compass |
| Creator | 크리에이터 | 미션 제작 → 수익 배분 | Pen |
| Business | 사장님 | 미션 등록 → 고객 유입 | Store |

### 1.3 핵심 플라이휠 구조
```
탐험가 증가
    ↓
크리에이터 수익 증가 → 미션 품질/다양성 증가
    ↓
사장님 광고 효과 증가 → 사장님 참여 증가
    ↓
상금 풀 증가 → 탐험가 증가 (순환)
```

### 1.4 지원 뷰포트
- **기준 해상도**: 390 × 844 px (iPhone 14 Pro 기준)
- **최소 지원**: 360 × 780 px
- **Safe Area**: 상단 44px, 하단 34px (Home Indicator)

---

## 2. 디자인 시스템

### 2.1 컬러 팔레트

#### 배경 계층 시스템 (Background Hierarchy)

| 토큰명 | 헥스코드 | 용도 |
|---|---|---|
| `bg-hero` | `#07070E` | 로그인·결과 등 임팩트 풀스크린 배경 |
| `bg-base` | `#111115` | 앱 기본 배경 |
| `bg-surface` | `#1C1C22` | 카드·리스트 아이템 배경 |
| `bg-elevated` | `#262626` | 모달·드롭다운·헤더 배경 |

#### 브랜드 컬러 시스템 (Brand Colors)

| 토큰명 | 헥스코드 | 용도 |
|---|---|---|
| `brand-yellow-primary` | `#FACC15` | CTA 버튼, 활성 상태, 강조 수치 |
| `brand-yellow-deep` | `#F59E0B` | 버튼 그레이디언트 끝색, 호버 |
| `brand-blue` | `#38BDF8` | 보조 액션, 정보성 요소, 탐험가 태그 |
| `brand-green` | `#10B981` | 완료 상태, 수익·보상, 사회증명 |
| `brand-orange` | `#F97316` | 경고성 정보, 사장님 태그, HOT 배지 |
| `brand-red` | `#EF4444` | 긴급·LIVE 배지, 오류, AI 도발 배너 |
| `brand-purple` | `#A78BFA` | 크리에이터 태그, 보조 정보 |

#### 텍스트 컬러 시스템

| 토큰명 | 헥스코드 | 용도 |
|---|---|---|
| `text-primary` | `#EBEBEB` | 제목, 본문 핵심 텍스트 |
| `text-secondary` | `#A0A0A0` | 서브 설명, 레이블 |
| `text-muted` | `#696969` | 날짜, 단위, 비활성 |
| `text-disabled` | `#555555` | 비활성 입력 placeholder |

#### 보더 & 오버레이 시스템

| 토큰명 | 값 | 용도 |
|---|---|---|
| `border-default` | `rgba(255,255,255,0.07)` | 카드, 입력 필드 기본 보더 |
| `border-subtle` | `rgba(255,255,255,0.04)` | 탭, 구분선 |
| `overlay-dark` | `rgba(0,0,0,0.85)` | 이미지 위 텍스트 오버레이 |
| `glow-yellow` | `rgba(250,204,21,0.15)` | 활성 요소 배경 틴트 |
| `glow-blue` | `rgba(56,189,248,0.10)` | 파란 강조 배경 틴트 |

---

### 2.2 타이포그래피 시스템

#### 폰트 패밀리

| 용도 | 폰트 | 적용 범위 |
|---|---|---|
| 디스플레이/헤드라인 | Black Han Sans | 화면 제목, 히어로 카피, 슬로건 |
| 본문/UI | Noto Sans KR | 설명 텍스트, 레이블, 데이터 |

#### 폰트 스케일

| 토큰명 | 사이즈 | Weight | Line-Height | 용도 |
|---|---|---|---|---|
| `display-xl` | 44px | 900 (Black Han Sans) | 1.0 | 결과 화면 "MISSION CLEAR!" |
| `display-lg` | 38–42px | 900 (Black Han Sans) | 1.05 | 로그인 슬로건, 랜딩 헤드라인 |
| `display-md` | 32–36px | 900 (Black Han Sans) | 1.1 | 화면 제목 (홈, 클루리스트 등) |
| `heading-lg` | 22–26px | 700 (Noto Sans KR) | 1.3 | 섹션 제목, 카드 제목 |
| `heading-md` | 18–20px | 700 | 1.4 | 서브 섹션, 미션 명 |
| `body-lg` | 16px | 400–500 | 1.6 | 본문 설명 |
| `body-md` | 14px | 400 | 1.6 | 일반 UI 텍스트, 레이블 |
| `body-sm` | 12px | 400 | 1.5 | 보조 정보, 날짜, 거리 |
| `caption` | 10–11px | 400 | 1.4 | 배지 내 텍스트, 아이콘 레이블 |

---

### 2.3 간격 (Spacing) 시스템

| 토큰명 | 값 | 용도 |
|---|---|---|
| `space-xs` | 4px | 아이콘-텍스트 사이 |
| `space-sm` | 8px | 인라인 요소 간격 |
| `space-md` | 12px | 컴포넌트 내부 패딩 |
| `space-lg` | 16px | 컴포넌트 간 마진 |
| `space-xl` | 20–24px | 섹션 패딩 |
| `space-2xl` | 32px | 섹션 간 여백 |
| `screen-padding-h` | 16px | 화면 좌우 기본 패딩 |
| `screen-padding-v` | 20px | 화면 상하 기본 패딩 |

---

### 2.4 Border Radius 시스템

| 토큰명 | 값 | 용도 |
|---|---|---|
| `radius-sm` | 6px | 배지, 소형 pill |
| `radius-md` | 10–12px | 입력 필드, 소형 카드 |
| `radius-lg` | 16px | 일반 카드 |
| `radius-xl` | 20px | 히어로 카드, 모달 |
| `radius-full` | 9999px | 아바타, 원형 버튼, 태그 |

---

### 2.5 그림자(Shadow) & Glow 시스템

| 토큰명 | 값 | 용도 |
|---|---|---|
| `shadow-card` | `0 4px 24px rgba(0,0,0,0.6)` | 일반 카드 |
| `shadow-modal` | `0 24px 80px rgba(0,0,0,0.9)` | 모달, 오버레이 |
| `glow-cta-yellow` | `0 4px 20px rgba(250,204,21,0.4)` | CTA 버튼 |
| `glow-result` | `0 0 80px rgba(250,204,21,0.12)` | 미션 클리어 화면 |
| `glow-live` | `0 0 12px rgba(16,185,129,0.5)` | LIVE 배지 배경 |

---

## 3. 글로벌 컴포넌트 명세

### 3.1 바텀 네비게이션 (BottomNav)

**구조**: 4탭 고정, 화면 하단 Safe Area 위 위치

| 탭 | 아이콘 (Lucide) | 레이블 | 링크 |
|---|---|---|---|
| HOME | `Flame` | HOME | 홈 화면 |
| EXPLORE | `Search` | EXPLORE | 클루 마켓플레이스 |
| RANK | `Trophy` | RANK | 나의 진행도 (랭킹) |
| MY XP | `Star` | MY XP | 내 프로필/XP |

**스타일 명세**:
- 배경: `linear-gradient(to top, #111115 70%, transparent)` + `backdrop-filter: blur(12px)`
- 높이: 64px + Safe Area Bottom (34px)
- 아이콘 크기: 22px
- 레이블 크기: 10px, letter-spacing 0.08em
- **활성 상태**: 아이콘 색상 `#FACC15` + `drop-shadow(0 0 8px rgba(250,204,21,0.6))` + 레이블 `#FACC15`
- **비활성 상태**: 아이콘 색상 `#555` + 레이블 `#555`

---

### 3.2 CTA 버튼 시스템

#### Primary Button (Yellow Gradient)
```
background: linear-gradient(135deg, #FACC15, #F59E0B)
color: #000000
font-weight: 900
font-size: 16px
border-radius: 12px
padding: 16px 24px
box-shadow: 0 4px 20px rgba(250,204,21,0.4)
height: 52px
```
**shimmer 애니메이션**: 3초 주기로 좌→우 광택 이동

#### Secondary Button (Ghost/Outline)
```
background: transparent
border: 1px solid rgba(255,255,255,0.15)
color: #EBEBEB
font-weight: 700
font-size: 16px
border-radius: 12px
padding: 16px 24px
height: 52px
```

#### Cyan CTA (탐험가 전용)
```
background: linear-gradient(135deg, #38BDF8, #0EA5E9)
color: #000000
font-weight: 900
box-shadow: 0 4px 20px rgba(56,189,248,0.3)
```

#### 비활성(Disabled) 상태
```
background: rgba(255,255,255,0.08)
color: rgba(255,255,255,0.3)
pointer-events: none
box-shadow: none
```

---

### 3.3 입력 필드 (Input Field)

```
배경: rgba(255,255,255,0.04)
보더: 1px solid rgba(255,255,255,0.08)
보더반지름: 10px
패딩: 14px 16px
폰트: 16px Noto Sans KR #EBEBEB
placeholder: #555555

포커스 상태:
  border: 1px solid rgba(250,204,21,0.5)
  box-shadow: 0 0 0 3px rgba(250,204,21,0.1)

오류 상태:
  border: 1px solid rgba(239,68,68,0.6)
  box-shadow: 0 0 0 3px rgba(239,68,68,0.1)
```

---

### 3.4 배지(Badge) & 상태 Pill 시스템

| 배지 | 색상 | 배경 | 용도 |
|---|---|---|---|
| LIVE | `#EF4444` | `rgba(239,68,68,0.15)` | 실시간 진행 중 미션 |
| HOT | `#F97316` | `rgba(249,115,22,0.15)` | 인기 미션 |
| NEW | `#10B981` | `rgba(16,185,129,0.15)` | 신규 등록 미션 |
| ACTIVE | `#38BDF8` | `rgba(56,189,248,0.15)` | 진행 가능 상태 |
| CLOSED | `#696969` | `rgba(255,255,255,0.06)` | 마감 완료 |
| 탐험가 | `#FACC15` | `rgba(250,204,21,0.12)` | 역할 배지 |
| 크리에이터 | `#A78BFA` | `rgba(167,139,250,0.12)` | 역할 배지 |
| 사장님 | `#F97316` | `rgba(249,115,22,0.12)` | 역할 배지 |

**공통 스타일**: `border-radius: 9999px`, `padding: 3px 10px`, `font-size: 11px`, `font-weight: 700`

---

### 3.5 진행도 바 (Progress Bar)

```
배경: rgba(255,255,255,0.08)
높이: 6px (기본), 4px (소형)
border-radius: 9999px

색상 구간:
  0%–50%:  #38BDF8 (파랑)
  50%–80%: #FACC15 (노랑)
  80%–100%: #EF4444 (빨강)

구현: background: linear-gradient(to right,
  #38BDF8 0%, #FACC15 50%, #EF4444 100%)
  clip 방식으로 완료율 표현
```

---

### 3.6 미션 카드 (Mission Card)

```
구조:
  ┌─────────────────────────────────────┐
  │ [타입아이콘] [LIVE/HOT/NEW 배지]      │
  │ 미션 제목 (2줄 clamp)                │
  │ 📍 위치 · ⏱ 시간 · 👤 N명 참여      │
  │ ────────────────────────────── 72% │
  │ 크리에이터 아바타 + 이름   ₩30,000  │
  └─────────────────────────────────────┘

스타일:
  background: #1C1C22
  border: 1px solid rgba(255,255,255,0.07)
  border-radius: 16px
  padding: 16px
  box-shadow: 0 4px 24px rgba(0,0,0,0.6)
```

---

### 3.7 FAB 버튼 (Floating Action Button)

```
위치: 하단 우측, bottom: 80px (BottomNav 위), right: 16px
크기: 56px × 56px
border-radius: 9999px
background: linear-gradient(135deg, #FACC15, #F59E0B)
box-shadow: 0 4px 20px rgba(250,204,21,0.4)
아이콘: Plus (Lucide), 24px, color: #000000
```

---

## 4. 화면별 UX 명세

---

### Screen 01 · 로그인 (Login)

**파일**: `Login.tsx`  
**접근 경로**: 앱 최초 진입 / 로그아웃 후  
**역할**: 브랜드 인식 + 사회적 증명 + 로그인 진입

#### 4.1.1 화면 레이아웃 구조

```
[Safe Area Top]
┌──────────────────────────────────────┐
│  RUNCLUE 로고 + 슬로건 영역            │  (50vh)
│  ─────────────────────────────────  │
│  사회증명 배너 (실시간 크루)            │
│  ─────────────────────────────────  │
│  이메일 입력 필드                      │
│  비밀번호 입력 필드                    │  (30vh)
│  [크루 합류하기] CTA                  │
│  아이디 찾기 | 비밀번호 찾기 | 회원가입  │
│  ─────────────────────────────────  │
│  소셜 로그인 (카카오 / 네이버 / Google) │  (20vh)
└──────────────────────────────────────┘
[Safe Area Bottom]
```

#### 4.1.2 컴포넌트별 상세 명세

**A. 히어로 배경 레이어**
- 기본 배경색: `#07070E`
- 레이어 1: SVG 레이더 링 애니메이션 (동심원 3개, opacity 0.08)
- 레이어 2: 중앙 하단 radial glow `rgba(250,204,21,0.06)`
- 레이어 3: 우상단 오브 글로우 `rgba(56,189,248,0.04)`

**B. 브랜드 슬로건 영역**
- 폰트: Black Han Sans, 42px
- 색상: `#EBEBEB`
- 텍스트: "뛰자,\n풀자,\n벌자." (3행 분리)
- line-height: 1.05
- 좌상단 정렬, padding-left: 24px

**C. 실시간 사회증명 배너**
- 구성: 5개 아바타 pill + "N명 지금 활동 중"
- LIVE 녹색 도트 (6px, `#10B981`, pulse 애니메이션)
- 아바타: 각각 다른 색상의 이니셜 원형 (24px)
- 닉네임 표시: "준서(8)", "지수(17)" 등 이름+나이 형태
- 업데이트 주기: 30초

**D. 이메일/비밀번호 입력 필드**
- 스타일: Section 3.3 입력 필드 명세 적용
- 비밀번호: Eye/EyeOff Lucide 아이콘 토글
- 자동완성: `autocomplete="email"`, `autocomplete="current-password"`
- 키보드: 이메일 필드 `keyboard-type="email-address"`, 비밀번호 `secureTextEntry`

**E. 메인 CTA 버튼 - "크루 합류하기"**
- 스타일: Section 3.2 Primary Button 명세 적용
- 너비: 100% (양측 24px 패딩 내)
- 로딩 상태: 버튼 내 SpinnerIcon 애니메이션, 텍스트 "로그인 중..."
- 성공 시: 0.3s fade → 홈 화면 전환

**F. 소셜 로그인 버튼**

| 버튼 | 배경 | 텍스트색 | 아이콘 |
|---|---|---|---|
| 카카오 | `#FAE100` | `#000000` | 카카오 로고 SVG |
| 네이버 | `#03C75A` | `#FFFFFF` | 네이버 로고 SVG |
| Google | `#FFFFFF` | `#000000` | Google 로고 SVG |

- 버튼 높이: 48px
- border-radius: 12px
- 배치: 3열 균등 (각 버튼 너비 자동)

#### 4.1.3 상태 명세

| 상태 | 트리거 | UI 변화 |
|---|---|---|
| Default | 진입 시 | 기본 화면 |
| Field Focus | 필드 탭 | 키보드 올라옴, 히어로 영역 50% 축소 |
| Loading | 로그인 버튼 탭 | CTA 로딩 스피너 |
| Error | 로그인 실패 | 필드 빨간 border, 오류 메시지 표시 |
| Success | 로그인 완료 | 0.3s fade-out → 홈 화면 |

#### 4.1.4 UX 요구사항
- REQ-L01: 앱 최초 진입 시 로딩 스피너 없이 즉시 렌더링되어야 한다.
- REQ-L02: 소셜 로그인 버튼은 각 플랫폼 브랜드 가이드라인을 준수해야 한다.
- REQ-L03: 비밀번호 오류 3회 시 30초 잠금 안내 텍스트를 표시한다.
- REQ-L04: 로그인 성공 후 이전 방문 화면으로 deep-link 복귀한다.
- REQ-L05: 사회증명 배너는 실제 활성 유저 데이터를 기반으로 한다 (가상 데이터 금지).

---

### Screen 02 · 홈 / 플랫폼 대시보드 (Home)

**파일**: `Home.tsx`  
**접근 경로**: 로그인 후 기본 화면 / 바텀네비 HOME 탭  
**역할**: 플랫폼 현황 + 역할 탭 + LIVE 미션 + 개인 추천

#### 4.2.1 화면 레이아웃 구조

```
[Header: RUNCLUE 로고 + 검색 + 알림]
[플랫폼 스탯 바: 참여자수 | 누적수익 | 활성미션]
[역할 탭: 탐험가 | 크리에이터 | 사장님]
─────────────────────────────────────
[지금 LIVE 섹션 헤더]
[LIVE 히어로 카드 - 풀 width]
[LIVE 소형 카드 목록 - 가로 스크롤]
─────────────────────────────────────
[이런 분들이 씁니다 섹션 헤더]
[페르소나 추천 카드 - 가로 스크롤]
─────────────────────────────────────
[BottomNav]
```

#### 4.2.2 컴포넌트별 상세 명세

**A. 플랫폼 스탯 바**
- 3열 균등 분할 (flex: 1)
- 배경: `rgba(255,255,255,0.04)`, border: `1px solid rgba(255,255,255,0.07)`
- 수치 스타일: `#FACC15`, font-weight: 900, font-size: 20px
- 레이블: `#A0A0A0`, font-size: 11px
- 데이터: 참여자수(명) | 누적수익(₩) | 활성미션수
- 업데이트: 실시간 (WebSocket 또는 30초 polling)
- 수치 애니메이션: counter-up 1.2s ease-out

**B. 역할 탭 스위처**
- 탭 항목: 탐험가(Compass) / 크리에이터(Pen) / 사장님(Store)
- 아이콘: Lucide 아이콘 16px + 한글 텍스트 12px
- **활성 탭**: `border: 1.5px solid #FACC15`, `color: #FACC15`, `background: rgba(250,204,21,0.08)`
- **비활성 탭**: `background: rgba(255,255,255,0.04)`, `color: #696969`
- border-radius: 10px, padding: 8px 16px
- 탭 전환 시 콘텐츠 영역 fade 0.2s

**C. LIVE 히어로 카드**
- 너비: 100% (좌우 16px 패딩 내)
- 높이: 200px
- 배경: 미션 대표 이미지 + `linear-gradient(to top, rgba(0,0,0,0.85) 0%, transparent 50%)` 오버레이
- 상단 좌측: LIVE 배지 (붉은 점 + "LIVE" 텍스트) + 타이머 (HH:MM:SS)
- 상단 우측: "N명 참여 중" (Users 아이콘)
- 하단: 미션 제목 (Black Han Sans 22px) + 상금 (Yellow 28px font-900) + "참여 →" 버튼
- 전환: 없으면 "현재 LIVE 미션이 없습니다" 대체 UI

**D. LIVE 소형 카드 목록 (가로 스크롤)**
- 카드 너비: 160px, 높이: 100px
- snap-scroll, 첫 카드에서 snap-align: start
- 각 카드: 미션명 + 배지(LIVE/HOT) + 거리 + 금액
- 오른쪽 끝: "전체 보기" 버튼

**E. 페르소나 추천 카드 (가로 스크롤)**
구성요소:
```
┌──────────────────────┐
│  [색상 원형 아이콘]    │  ← 각 페르소나마다 고유 색상
│  이름 (이름 + 나이)    │
│  역할 레이블           │
│  월 수익 (Yellow bold) │
│  공감 카피 텍스트       │  ← 1–2줄, 말줄임
└──────────────────────┘
```
- 카드 너비: 150px
- 탭 시: 해당 페르소나 유형 미션 필터링된 ClueList로 이동

#### 4.2.3 UX 요구사항
- REQ-H01: 앱 진입 시 기본 탭은 '탐험가' 탭으로 고정한다.
- REQ-H02: LIVE 카드가 없을 경우 "오늘 첫 번째 미션을 만들어보세요" 안내와 함께 CreateClue 바로가기 제공.
- REQ-H03: 알림 아이콘에 미읽은 알림 수 배지(최대 99+)를 표시한다.
- REQ-H04: 플랫폼 스탯 수치는 사용자가 직접 확인할 수 있는 실제 데이터여야 한다.
- REQ-H05: 역할 탭 전환 시 콘텐츠 로딩은 200ms 이내에 완료되어야 한다 (캐시 우선).

---

### Screen 03 · 클루 마켓플레이스 (ClueList)

**파일**: `ClueList.tsx`  
**접근 경로**: 바텀네비 EXPLORE 탭 / 홈 '전체 보기'  
**역할**: 미션 탐색 + 검색 + 필터링 + 참여 진입

#### 4.3.1 화면 레이아웃 구조

```
[긴급 수익 알림 배너 - sticky top]
[글로벌 검색 바]
[카테고리 탭 스크롤]
[정렬 필터 탭]
─────────────────────────────────────
[미션 카드 리스트 - 무한 스크롤]
─────────────────────────────────────
[FAB 버튼 - + 클루 만들기]
[BottomNav]
```

#### 4.3.2 컴포넌트별 상세 명세

**A. 긴급 수익 알림 배너**
```
배경: rgba(16,185,129,0.08), border-bottom: 1px solid rgba(16,185,129,0.2)
아이콘: Flame (Lucide), 14px, #10B981
텍스트: "[이름]님 방금 ₩[금액] 획득" (#EBEBEB, 13px)
높이: 36px
sticky: top: 0, z-index: 50
업데이트: 실시간 (최근 획득 이벤트 push)
```

**B. 글로벌 검색 바**
```
배경: #1C1C22
border: 1px solid rgba(255,255,255,0.07)
border-radius: 12px
높이: 44px
좌측: Search Lucide 아이콘 (#696969, 18px)
우측: SlidersHorizontal Lucide 아이콘 (#696969, 18px) → 필터 모달 진입
placeholder: "어디서 뭘 하고 싶으세요?"
포커스 시: border yellow, 키보드 올라옴
```

**C. 카테고리 탭 스크롤**

| 탭 | 아이콘 | 필터 기준 |
|---|---|---|
| 전체 | Flame | 필터 없음 |
| 실시간 | Radio | LIVE 상태 |
| 탐험 | Compass | 체크포인트·숨바꼭질 유형 |
| 퀴즈 | HelpCircle | OX퀴즈·설문 유형 |
| 카페·맛집 | Coffee | 사장님 등록 미션 |
| 근처 | MapPin | 현재위치 기준 1km 이내 |

- 활성: `background: #FACC15`, `color: #000000`, `font-weight: 700`
- 비활성: `background: rgba(255,255,255,0.06)`, `color: #696969`
- 높이: 34px, border-radius: 9999px, padding: 6px 14px
- 가로 스크롤, 스크롤바 숨김

**D. 정렬 필터 탭**
- 항목: 인기순 | 거리순 | 상금순 | 마감순
- 활성: `color: #FACC15`, `border-bottom: 2px solid #FACC15`
- 비활성: `color: #555555`
- 하단 구분선: `1px solid rgba(255,255,255,0.06)`

**E. 미션 카드 상세 구조**
```
┌─────────────────────────────────────────┐
│ [타입아이콘 16px]  [LIVE배지] [크리에이터아바타]│
│                                          │
│ 미션 제목 (font-weight:700, 16px, 2줄clamp)│
│ 📍 홍대입구역 3번 출구 · 0.3km            │
│                                          │
│ ████████████░░░░ 72%     ⏱ 23분 남음     │
│                                          │
│ @creator_name     ₩30,000               │
│ 선착순 15명 남음                           │
└─────────────────────────────────────────┘
```

**F. 무한 스크롤 & 로딩**
- 페이지네이션: cursor-based (last item ID 기준)
- 한 페이지 아이템 수: 10개
- 하단 진입 시 (Intersection Observer) 다음 페이지 fetch
- 로딩 중: 스켈레톤 UI 카드 2개 표시 (shimmer 애니메이션)
- 빈 결과: "해당하는 클루가 없어요. 새로 만들어보세요!" + FAB 하이라이트

#### 4.3.3 UX 요구사항
- REQ-CL01: 검색은 제목, 위치명, 크리에이터명 기준으로 실시간 검색 (debounce 300ms).
- REQ-CL02: 위치 권한 미허용 시 거리 정보를 "위치 설정 필요"로 대체 표시.
- REQ-CL03: 마감된 미션은 리스트 최하단에 표시하고 overlay 처리(opacity 0.5 + "마감" 표시).
- REQ-CL04: FAB 버튼은 탐험가 역할 유저에게는 숨김, 크리에이터/사장님 유저에게만 표시.
- REQ-CL05: 카드 탭 시 진동 피드백(haptic) 적용.

---

### Screen 04 · 클루 만들기 (CreateClue)

**파일**: `CreateClue.tsx`  
**접근 경로**: FAB 버튼 / 크리에이터·사장님 전용  
**역할**: 6단계 위저드를 통한 미션 제작

#### 4.4.1 6단계 위저드 구조

| 단계 | 제목 | 주요 입력 |
|---|---|---|
| Step 1 | 클루 유형 선택 | 템플릿 6종 선택 |
| Step 2 | 기본 정보 | 미션명, 설명, 카테고리 |
| Step 3 | 위치 설정 | 지도에서 체크포인트 지정 |
| Step 4 | 보상 설정 | 총 상금, 선착순 인원, 수수료 |
| Step 5 | 검증 방법 | GPS/QR/카메라/AI 선택 |
| Step 6 | 미리보기 & 출시 | 최종 확인 후 발행 |

#### 4.4.2 컴포넌트별 상세 명세

**A. 단계 프로그레스 헤더**
```
배경: #262626 (bg-elevated), sticky top
높이: 56px
좌측: ChevronLeft (뒤로가기)
중앙: "달릿팟 N/6" (#EBEBEB, font-weight 700)
우측: 6개 도트 인디케이터
  - 완료: filled #FACC15 (8px)
  - 현재: filled #FFFFFF (8px)
  - 미진행: filled #333333 (8px)
  - 간격: 6px
```

**B. 템플릿 카드 그리드 (Step 1)**

| 템플릿 | 아이콘 | 설명 | 서브타입 |
|---|---|---|---|
| 보물찾기 | EyeOff | 특정 장소 발견 | 위치인증 |
| 체크포인트 | MapPin | 여러 지점 통과 | GPS인증 |
| 인증샷 | Camera | 특정 사물 촬영 | 카메라인증 |
| OX 퀴즈 | HelpCircle | 장소 기반 문제 | 정답입력 |
| 음식 미션 | UtensilsCrossed | 메뉴 주문 인증 | QR인증 |
| 설문 미션 | ClipboardList | 현장 설문 참여 | 텍스트입력 |

**카드 스타일**:
```
기본 상태:
  background: #1C1C22
  border: 1px solid rgba(255,255,255,0.07)
  border-radius: 16px

선택 상태:
  border: 2px solid #FACC15
  background: rgba(250,204,21,0.08)
  우상단: CheckCircle2 아이콘 (#FACC15, 18px)
```

**C. 하단 CTA 패널**
```
배경: linear-gradient(to top, #111115 80%, transparent)
height: 80px
"다음 단계 >" 버튼: Section 3.2 Primary Button
비활성(선택 안 했을 때): Section 3.2 Disabled 스타일
```

#### 4.4.3 UX 요구사항
- REQ-CC01: 각 단계에서 필수 입력을 완료하지 않으면 다음 단계로 진입 불가.
- REQ-CC02: 단계 이탈 시 "작업 중인 내용이 있습니다. 계속 진행하시겠습니까?" 확인 다이얼로그 표시.
- REQ-CC03: Step 3 지도에서 체크포인트 지정 시 GPS 권한을 요청하고, 거부 시 주소 검색으로 대체 제공.
- REQ-CC04: 보상 설정 시 플랫폼 수수료(15%)를 실시간으로 계산하여 투명하게 표시.
- REQ-CC05: Step 6 미리보기는 탐험가 입장에서 보이는 카드 형태로 렌더링한다.

---

### Screen 05 · 나의 클루 진행도 (MyProgress)

**파일**: `MyProgress.tsx`  
**접근 경로**: 바텀네비 RANK 탭  
**역할**: 크루 랭킹 + 개인 기록 + 스트릭 + 성취 배지

#### 4.5.1 화면 레이아웃 구조

```
[헤더: 나의 진행도]
[탭 스위처: 크루(Users) | 나의 기록(Star)]

─── 크루 탭 ─────────────────────────────
[AI 도발 배너]
[랭킹 리스트]
─────────────────────────────────────────

─── 나의 기록 탭 ────────────────────────
[스트릭 캘린더 (7일)]
[누적 통계 4개]
[획득 배지 그리드]
─────────────────────────────────────────
[BottomNav]
```

#### 4.5.2 컴포넌트별 상세 명세

**A. 탭 스위처**
```
전체 너비, height: 44px
activated tab: background #FACC15, color #000000, font-weight 900
deactivated tab: background rgba(255,255,255,0.04), color #696969
border-radius: 10px (각 탭)
전환 애니메이션: 0.2s ease
```

**B. AI 도발 배너**
```
배경: linear-gradient(135deg, rgba(239,68,68,0.15), rgba(249,115,22,0.15))
border: 1px solid rgba(239,68,68,0.2)
border-radius: 12px
padding: 12px 16px
아이콘: Flame (Lucide, #EF4444, 18px)
텍스트: "[닉네임]님보다 [N]개 뒤져있어요. 오늘 따라잡을 수 있을까요?"
폰트: #EBEBEB, 14px, font-weight 700
```
- 메시지는 서버에서 personalized AI 메시지 생성
- 본인이 1위인 경우: "1위를 지키세요! 추격자가 [N]명 있습니다." 로 변경

**C. 랭킹 리스트**

| 순위 | 아이콘 | 색상 |
|---|---|---|
| 1위 | Trophy | `#FACC15` (gold) |
| 2위 | Star | `#E5E5E5` (silver) |
| 3위 | Zap | `#CD7F32` (bronze) |
| 4위+ | Moon | `#696969` |

본인 행 강조:
```
border: 1.5px solid #FACC15
background: rgba(250,204,21,0.06)
"나" 배지: background #FACC15, color #000000, 6px 8px, border-radius 9999px
```

**D. 스트릭 캘린더 (7일)**
```
요일: 월~일 7칸 균등 분할
완료 날짜: filled #FACC15 원형 + Check 아이콘 (#000000)
오늘 미완료: dashed border #FACC15, 텍스트 #FACC15
그 외 미완료: border #333, 텍스트 #555
연속 N일: Flame 아이콘 (#EF4444) + "N일 연속!" 텍스트
```

**E. 펀 통계 배지 4개**

| 배지 | 아이콘 | 내용 |
|---|---|---|
| 총 이동거리 | Footprints | Nkm |
| 총 수익 | Banknote | ₩N |
| 방문 장소 | MapPin | N곳 |
| 참여 시간 | Clock | N시간 |

```
배지 스타일:
  배경: #1C1C22, border: 1px solid rgba(255,255,255,0.07)
  아이콘 원형 배경: 각 고유 색상 rgba(X,X,X,0.15)
  수치: #FACC15, font-weight: 900, font-size: 18px
  레이블: #696969, font-size: 11px
```

#### 4.5.3 UX 요구사항
- REQ-MP01: 랭킹은 같은 '크루'(팀) 내에서만 표시하고, 전체 랭킹은 별도 접근 경로 제공.
- REQ-MP02: AI 도발 메시지는 사용자가 불쾌감을 느끼지 않도록 격려형 어조를 유지한다.
- REQ-MP03: 스트릭은 00:00 KST 기준으로 리셋된다.
- REQ-MP04: 배지는 달성 순간 화면 전체 팝업 애니메이션으로 축하 연출한다.
- REQ-MP05: 랭킹 데이터 새로고침은 당겨서 새로고침(pull-to-refresh)으로 트리거한다.

---

### Screen 06 · 클루 상세 (ClueDetail)

**파일**: `ClueDetail.tsx`  
**접근 경로**: 미션 카드 탭 → 상세 페이지  
**역할**: 미션 전체 정보 + 참여 진입점

#### 4.6.1 화면 레이아웃 구조

```
[히어로 헤더 - 타입배지 + 제목 + 크리에이터]
[3탭: 미션 구성 | 지도 보기 | 리뷰]
─────────────────────────────────────────
[미션 통계 3개 카드]
[전체 진행도 바 + 순위]
[단계별 타임라인]
─────────────────────────────────────────
[하단 CTA: "지금 참여하기"]
```

#### 4.6.2 컴포넌트별 상세 명세

**A. 히어로 헤더**
```
배경: bg-surface #1C1C22
패딩: 20px 16px
상단: [타입 배지] [ACTIVE/CLOSED 상태]
제목: Black Han Sans, 24px, #EBEBEB
크리에이터: 아바타 24px + @닉네임 (#A0A0A0, 13px)
```

**B. 3탭 네비게이션 (Tab Sticky)**
```
sticky: top: 0
배경: #111115 + blur(12px)
각 탭 아이콘 + 한글명
활성: color #FACC15, border-bottom: 2px solid #FACC15
비활성: color #555
탭 간 전환: 콘텐츠 slide (0.2s)
```

**C. 미션 통계 카드 (3개)**

| 카드 | 아이콘 | 값 |
|---|---|---|
| 총 상금 | Banknote | ₩N |
| 참여 중 | Users | N명 |
| 마감 | Clock | N일 N시간 |

```
배경: #1C1C22, border: 1px solid rgba(255,255,255,0.07)
border-radius: 12px, padding: 14px
수치: #FACC15, font-weight 900, font-size 18px
레이블: #696969, font-size 11px
```

**D. 단계별 타임라인**
```
단계별 구성:
  - 세로 선 (2px, #333) 연결
  - 완료: CheckCircle2 (#10B981, 24px, filled)
  - 진행 중: Circle with pulse animation (#38BDF8)
  - 미진행: Circle (#333)
  
각 단계 오른쪽:
  - 단계명 (font-weight 700, #EBEBEB)
  - 검증방법 pill (작은 배지)
  - 힌트 텍스트 (#A0A0A0, 13px)
```

**E. 전체 진행도 바 + 순위**
```
레이블: "전체 진행도" (좌) + "현재 N위 / 전체 M명" (우)
바: 6px 높이, gradient blue→yellow→red, 완료율 clip
아래: "상위 X%에 속합니다" 격려 텍스트
```

**F. 하단 참여 CTA**
```
배경: linear-gradient(to top, #111115, transparent)
높이: 100px (Safe Area 포함)
버튼: "지금 참여하기" + MapPin 아이콘
스타일: Cyan CTA (Section 3.2)
남은 선착순 표시: "선착순 N자리 남음" (버튼 위 경고 텍스트 #EF4444)
마감 시: 버튼 비활성 + "이미 마감된 미션입니다"
```

#### 4.6.3 UX 요구사항
- REQ-CD01: 이미 참여 중인 미션의 경우 CTA를 "계속하기 →"로 변경하고 현재 진행 단계를 강조한다.
- REQ-CD02: 리뷰 탭에는 인증샷 포함 완료 후기를 우선 표시한다.
- REQ-CD03: 지도 탭에서 체크포인트 위치는 실제 참여 전까지 블러 처리 (Spoiler 방지).
- REQ-CD04: 공유 버튼으로 카카오톡/인스타그램 Deep Link 공유 지원.
- REQ-CD05: 마감 D-1 이내는 "긴급" 뱃지 + 진행도 바 빨간 pulse 애니메이션.

---

### Screen 07 · 사장님 랜딩 (BizLanding)

**파일**: `BizLanding.tsx`  
**접근 경로**: 홈 사장님 탭 / 랜딩 링크  
**역할**: B2B 사장님 설득 + 무료 온보딩 진입

#### 4.7.1 화면 레이아웃 구조

```
[헤더: RUNCLUE 로고 + "사장님 모드" 배지]
[히어로 섹션: 헤드라인 + 서브]
[3대 임팩트 지표]
─────────────────────────────────────────
[3단계 온보딩 타임라인]
─────────────────────────────────────────
[실적 증명 섹션 - 후기]
─────────────────────────────────────────
[이중 CTA: 무료 미션 올리기 | 데모 보기]
```

#### 4.7.2 컴포넌트별 상세 명세

**A. "사장님 모드" 배지**
```
위치: 헤더 우측
배경: rgba(249,115,22,0.15), border: 1px solid rgba(249,115,22,0.3)
아이콘: Store Lucide (#F97316, 12px)
텍스트: "사장님 모드" (#F97316, 11px, font-weight 700)
border-radius: 9999px, padding: 5px 10px
```

**B. 히어로 헤드라인**
```
폰트: Black Han Sans, 38px
색상: #EBEBEB (기본) + #FACC15 (강조 단어)
내용: "광고비 없이 / 손님이 직접 / 찾아오게 하는 법"
      "없이" → #FACC15 강조 처리
```

**C. 3대 임팩트 지표**

| 지표 | 값 | 설명 |
|---|---|---|
| 탐험가 | 19,120명 | 현재 활동 탐험가 |
| 재방문율 | 36% | 미션 완료 후 재방문 |
| 등록 사장님 | 623곳 | 누적 등록 매장 수 |

```
3열 균등 배치, background: #1C1C22, border: 1px solid rgba(255,255,255,0.07)
수치: #FACC15, font-weight 900, font-size 22px
레이블: #696969, font-size 11px
```

**D. 3단계 온보딩 타임라인**

| 단계 | 아이콘 | 내용 |
|---|---|---|
| 1. 미션 등록 | PenLine | 미션 내용과 상금을 설정 (5분) |
| 2. 탐험가 방문 | Footprints | 탐험가들이 미션 완료 위해 방문 |
| 3. 수익 확인 | Banknote | 대시보드에서 방문 효과 실시간 확인 |

```
세로 연결선: 2px solid rgba(255,255,255,0.1), height: 32px
번호 원형: #FACC15 filled, #000 텍스트, 28px
아이콘: Lucide 20px, #10B981
제목: #EBEBEB, font-weight 700, 16px
설명: #A0A0A0, font-size 13px
```

**E. 실적 증명 후기 카드**
```
섹션 제목: "믿지 않지만 실화예요"
카드: background #262626, border-radius 16px, padding 16px
  - 별점 5개 (Star, #FACC15, 14px)
  - 매장명 (#EBEBEB, font-weight 700)
  - 후기 텍스트 (#A0A0A0, 14px, italic)
  - 결과 수치 (예: "방문객 +280%")
가로 스크롤, 2개 카드 표시
```

**F. 이중 CTA**
```
상단: "무료로 미션 올리기" → Primary Button (yellow)
하단: "데모 보기" → Secondary Button (ghost)
간격: 12px
하단 텍스트: "신용카드 불필요 · 즉시 시작" (#696969, 12px)
```

#### 4.7.3 UX 요구사항
- REQ-BL01: 지표 수치는 실제 플랫폼 데이터와 연동하여 실시간 업데이트한다.
- REQ-BL02: "무료로 미션 올리기" 탭 시 사장님 여부 확인 후 CreateClue(사장님 모드)로 연결.
- REQ-BL03: 이 페이지는 로그인 없이 접근 가능한 공개 랜딩 페이지로도 동작한다.
- REQ-BL04: 사장님 등록 후기는 실제 사장님의 동의를 받은 내용만 표시한다.

---

### Screen 08 · 미션 진행 중 (StepPlay)

**파일**: `StepPlay.tsx`  
**접근 경로**: ClueDetail → "지금 참여하기"  
**역할**: 실시간 미션 진행 + GPS 인증 + 힌트 제공

#### 4.8.1 화면 레이아웃 구조

```
[미션 헤더 - sticky]
[전체 진행 바]
─────────────────────────────────────────
[현재 스텝 배지]
[지도 미니맵]
[힌트 카드]
─────────────────────────────────────────
[GPS 확인 버튼]
[다음 스텝 버튼 (비활성)]
```

#### 4.8.2 컴포넌트별 상세 명세

**A. 미션 헤더 (Sticky)**
```
배경: #262626, height: 52px
좌측: ChevronLeft (탭: 포기 확인 다이얼로그)
중앙: 미션 제목 (14px, truncate 1줄)
우측: "N/M 스텝" (12px, #FACC15)
```

**B. 전체 진행 바 (상단 thin bar)**
```
position: sticky, top: 52px
높이: 4px
배경: rgba(255,255,255,0.08)
완료 구간: linear-gradient(to right, #38BDF8, #FACC15)
우측: Clock 아이콘 + "예상 N분 남음" (12px, #A0A0A0)
```

**C. 현재 스텝 배지**
```
"STEP N · [유형명]"
아이콘: 유형별 Lucide 아이콘 (MapPin, Camera, HelpCircle 등)
배경: rgba(56,189,248,0.08), border: 1px solid rgba(56,189,248,0.2)
STEP N: #FACC15, font-weight 900, font-size 14px
유형명: #A0A0A0, font-size 13px
```

**D. 지도 미니맵**
```
높이: 220px
배경: 다크 그리드 지도 (또는 MapBox/카카오맵 다크 테마)
현재 위치: 파란 pulse 원 (12px + 30px pulse ring)
목표 핀: MapPin (#FACC15, 32px)
"목표까지 N미터" 거리 오버레이:
  배경: rgba(0,0,0,0.7), border-radius 20px, padding 6px 12px
  텍스트: #EBEBEB, font-weight 700
탭: 전체 화면 지도 모달 확장
```

**E. 힌트 카드**
```
배경: rgba(250,204,21,0.06), border: 1px solid rgba(250,204,21,0.15)
border-radius: 12px, padding: 14px 16px
좌측: Lightbulb Lucide (#FACC15, 18px)
힌트 텍스트: #FACC15, font-size 14px, font-weight 500
우측 하단: "힌트 더 보기 (+N개)" 링크 (#A0A0A0, underline)
힌트 추가 잠금: 첫 힌트 무료, 이후 XP 소모
```

**F. GPS 확인 CTA**
```
"GPS 위치 확인하기"
아이콘: Navigation Lucide + "현재 위치 인증"
스타일: Cyan CTA (Section 3.2)
상태:
  - 범위 밖: 비활성 gray + "목표 지점에 더 가까이 이동하세요"
  - 범위 내 (50m): 활성 cyan + pulse glow 애니메이션
  - 인증 중: 로딩 스피너
  - 인증 성공: 초록 체크 + "다음 Step >" 버튼 활성화
  - 인증 실패: 붉은 × + "재시도" 버튼
```

#### 4.8.3 UX 요구사항
- REQ-SP01: GPS 위치는 5초 간격으로 polling하고, 정확도 20m 미만의 값만 사용한다.
- REQ-SP02: 백그라운드 상태에서도 위치 추적을 유지하고, 범위 진입 시 push 알림 발송.
- REQ-SP03: GPS 신호가 불량한 경우 (정확도 > 100m) 사용자에게 안내 메시지 표시.
- REQ-SP04: 미션 포기 버튼은 탭 2회 확인 방식으로 구현 (실수 방지).
- REQ-SP05: 이전 스텝 완료 기록은 서버에 저장되어 앱 강제 종료 후 재진입 시 복원된다.

---

### Screen 09 · 미션 결과 (Result)

**파일**: `Result.tsx`  
**접근 경로**: StepPlay 마지막 스텝 인증 성공 후 자동 전환  
**역할**: 클리어 세리머니 + 보상 확인 + 다음 행동 유도

#### 4.9.1 화면 레이아웃 구조

```
[풀스크린 다크 배경 + 컨페티 파티클]
[MISSION CLEAR! 텍스트]
[골드 트로피 아이콘]
[미션명 + 달성 내용]
[획득 금액 + 적립 완료]
[순위 정보]
─────────────────────────────────────────
["탭해서 결과 보기 →" CTA]
```

#### 4.9.2 컴포넌트별 상세 명세

**A. 풀스크린 배경**
```
배경: #07070E (bg-hero)
컨페티 파티클: 20개 이상의 소형 사각형/원형 파티클
  - 색상: #FACC15, #FFFFFF, #38BDF8
  - 상단에서 중력으로 낙하 애니메이션 (3초)
중심 radial glow: rgba(250,204,21,0.15), 반지름 200px
```

**B. "MISSION CLEAR!" 텍스트**
```
폰트: Black Han Sans, 44px
색상: #FACC15
text-shadow: 0 0 30px rgba(250,204,21,0.8), 0 0 60px rgba(250,204,21,0.4)
상하 장식선: "✦ ─── ✦" 형태 (SVG 또는 border)
진입 애니메이션: scale 0.5 → 1.0, 0.6s spring
```

**C. 골드 트로피 아이콘**
```
Trophy Lucide, 72px, 색상 #FACC15
원형 배경:
  width/height: 120px
  background: rgba(250,204,21,0.15)
  border: 2px solid rgba(250,204,21,0.4)
  border-radius: 9999px
  box-shadow: 0 0 40px rgba(250,204,21,0.3), 0 0 80px rgba(250,204,21,0.15)
진입 애니메이션: 위로 bounce (0.8s)
```

**D. 획득 금액 표시**
```
Banknote Lucide (24px, #10B981) + "₩N" (36px, #10B981, font-weight 900)
"적립 완료" 배지: background rgba(16,185,129,0.15), border rgba(16,185,129,0.3)
```

**E. "탭해서 결과 보기" CTA**
```
텍스트: #EBEBEB, font-size 16px
ChevronRight Lucide + 우측으로 slide 애니메이션 (0.8s loop)
전체 화면 탭 가능 영역으로 구현
탭 시: 결과 상세 패널 slide-up 애니메이션 (0.4s)
```

#### 4.9.3 결과 상세 패널 (탭 후 표시)

```
┌─────────────────────────────────────────┐
│ 최종 순위: 🏆 [N위 / M명 중]            │
│ 획득 금액: ₩N                           │
│ 완료 시간: N분 N초                      │
│ ─────────────────────────────────────  │
│ [커뮤니티 공유] [다음 미션 찾기]          │
└─────────────────────────────────────────┘
```

#### 4.9.4 UX 요구사항
- REQ-R01: 결과 화면 진입 시 haptic feedback (성공 패턴) 발동.
- REQ-R02: 컨페티 애니메이션은 accessibility 설정에서 '동작 줄이기' 선택 시 비활성화.
- REQ-R03: 결과 공유 시 미션명, 순위, 획득금액이 포함된 이미지 자동 생성.
- REQ-R04: 마감 순위에서 상금을 받지 못한 경우 위로 메시지와 함께 "다음에는 꼭!" 카피 표시.

---

### Screen 10 · 소통 광장 (Community)

**파일**: `Community.tsx`  
**접근 경로**: 홈 하단 배너 / 결과 화면 "공유" 버튼  
**역할**: 인증 공유 + 수익 자랑 + 커뮤니티 형성

#### 4.10.1 화면 레이아웃 구조

```
[헤더: 소통 광장 + Search + Bell + PenSquare]
[4탭: 피드 | 동네 | 챌린지 | 거래]
[실시간 인증 배너]
[카테고리 필터 탭]
─────────────────────────────────────────
[게시물 피드 (무한 스크롤)]
─────────────────────────────────────────
[FAB: + 글쓰기]
[BottomNav]
```

#### 4.10.2 컴포넌트별 상세 명세

**A. 4탭 네비게이션**

| 탭 | 아이콘 | 콘텐츠 |
|---|---|---|
| 피드 | Home | 전체 활동 피드 |
| 동네 | MapPin | 현재 위치 기반 근처 글 |
| 챌린지 | Zap | 진행 중 챌린지 랭킹 |
| 거래 | Repeat | 클루 팁·거래 게시판 |

**B. 실시간 인증 배너**
```
배경: rgba(16,185,129,0.08), border-bottom: 1px solid rgba(16,185,129,0.15)
Flame 아이콘 (#10B981, 14px) + "지금 핫한 인증" + 최신 인증자 이름
height: 36px, sticky top (탭 바 바로 아래)
3초마다 최신 인증 데이터로 교체 (slide-left 애니메이션)
```

**C. 카테고리 필터 탭**
- 전체 / 수익인증 / 인증샷 / 실패담 / 꿀팁
- pill 스타일, 가로 스크롤
- 활성: yellow filled, 비활성: bg-surface

**D. 게시물 카드**
```
┌─────────────────────────────────────────┐
│ [아바타 36px] [이름] [역할배지] [시간]   │
│ 텍스트 내용 (3줄 clamp)                  │
│ [인증샷 이미지 그리드 1–4장]              │
│ ─────────────────────────────────────  │
│ [❤ N] [💬 N] [공유]    [획득금액 표시] │
└─────────────────────────────────────────┘
```

- 역할 배지: Section 3.4 배지 시스템
- 획득금액 (수익인증 글만): Banknote 아이콘 + ₩N, 초록색

**E. 반응 시스템**
```
좋아요 (Heart):
  기본: Heart Lucide, #696969, 크기 18px
  탭 시: Heart filled, #EF4444 + bounce 애니메이션 + haptic
이모지 반응: 길게 누르면 이모지 팝업 (5가지 반응)
댓글 (MessageCircle): 댓글 모달 슬라이드업
공유 (Share2): OS 공유 시트
```

#### 4.10.3 UX 요구사항
- REQ-CM01: 게시물 작성 시 관련 미션 태그 기능을 제공한다.
- REQ-CM02: 수익인증 글은 실제 획득 데이터와 연동하여 인증 마크를 표시한다 (허위 인증 방지).
- REQ-CM03: 신고 기능: 게시물 우측 상단 점 3개 메뉴 → 신고 → 사유 선택.
- REQ-CM04: 동네 탭은 위치 권한이 없을 경우 권한 요청 화면을 표시한다.

---

### Screen 11 · 런클루만의 이유 (WhyRunClue)

**파일**: `WhyRunClue.tsx`  
**접근 경로**: 홈 하단 / 사장님 랜딩 링크 / 온보딩  
**역할**: 경쟁 우위 설명 + 플라이휠 구조 시각화 + 전환 유도

#### 4.11.1 화면 레이아웃 구조

```
["ONLY RUNCLUE" 배지]
[임팩트 헤드라인]
[3대 차별 지표]
─────────────────────────────────────────
[플라이휠 삼각 다이어그램]
[네트워크 효과 표]
─────────────────────────────────────────
[비교 대조 표 (vs 경쟁사)]
[CTA: 지금 시작하기]
```

#### 4.11.2 컴포넌트별 상세 명세

**A. 3대 차별 지표**

| 지표 | 값 | 설명 |
|---|---|---|
| 월 최대 수익 | ₩2.3M | 상위 탐험가 기준 |
| 경쟁사 대비 수익 | 60× | 캐쉬워크 동일 시간 대비 |
| 광고비 | ₩0 | 사장님 기준 마케팅 비용 |

**B. 플라이휠 삼각 다이어그램**
```
정삼각형 SVG (300 × 260px)
꼭짓점:
  상단: 탐험가 (#FACC15 원형 아이콘 + 텍스트)
  좌하: 크리에이터 (#38BDF8)
  우하: 사장님 (#F97316)
변 위: 화살표 + 상호작용 설명 텍스트
중앙: "플라이휠" 텍스트 (#696969, 12px)
화살표: 순환 방향으로 rotate 애니메이션 (10s loop)
```

**C. 비교 대조 표 (vs 경쟁사)**

| 항목 | 캐쉬워크 | 런클루 |
|---|---|---|
| 시간당 수익 | ₩300 | ₩18,000+ |
| 오프라인 연계 | X | O |
| 상금 투명성 | 불명확 | 100% 공개 |
| 크리에이터 수익 | 없음 | 최대 40% |
| 사장님 광고비 | 고정 | 성과 기반 |

```
런클루 열: background rgba(250,204,21,0.06), border: 1px solid rgba(250,204,21,0.2)
런클루 O: CheckCircle2 (#10B981, 16px)
경쟁사 X: XCircle (#EF4444, 16px)
헤더행: "RUNCLUE" yellow bold
```

---

## 5. 인터랙션 & 애니메이션 명세

### 5.1 화면 전환 (Screen Transitions)

| 전환 | 방향 | 지속시간 | 이징 |
|---|---|---|---|
| 앞으로 이동 (push) | 우→좌 slide | 300ms | ease-in-out |
| 뒤로 이동 (pop) | 좌→우 slide | 250ms | ease-out |
| 모달 진입 | 하→상 slide-up | 350ms | spring(damping:30) |
| 모달 닫기 | 상→하 slide-down | 250ms | ease-in |
| 탭 전환 | fade | 200ms | linear |
| 결과 화면 | fade-in | 400ms | ease-out |

### 5.2 마이크로 인터랙션

| 요소 | 인터랙션 | 상세 |
|---|---|---|
| 버튼 탭 | scale-down 0.96 | 100ms, ease-out |
| 카드 탭 | scale-down 0.98 | 80ms |
| 좋아요 | Heart bounce | scale 1→1.3→1.0, 300ms, spring |
| 배지 달성 | 전체화면 팝업 | scale 0→1.1→1.0, 600ms + confetti |
| 배너 업데이트 | slide-left | 300ms, ease-in-out |
| 스탯 수치 | counter-up | 1200ms, ease-out |
| 진행도 바 | width 확장 | 800ms, ease-out |

### 5.3 로딩 상태

| 상황 | 방식 |
|---|---|
| 리스트 최초 로딩 | 스켈레톤 카드 3개 (shimmer 2s loop) |
| 더 불러오기 | 하단 SpinnerIcon (#FACC15) |
| 버튼 액션 | 버튼 내 SpinnerIcon, 텍스트 유지 |
| 이미지 로딩 | blur-up placeholder |
| 지도 로딩 | 다크 skeleton |

### 5.4 Haptic Feedback 명세

| 이벤트 | 햅틱 패턴 |
|---|---|
| 카드 탭 | light impact |
| CTA 버튼 탭 | medium impact |
| 좋아요 | light impact |
| 미션 인증 성공 | success notification |
| 배지 달성 | heavy impact × 2 |
| 오류 발생 | error notification |
| 당겨서 새로고침 | light impact |

---

## 6. 상태 관리 명세

### 6.1 전역 상태 (Global State)

| 상태 | 내용 |
|---|---|
| `user.role` | 현재 활성 역할 (explorer/creator/business) |
| `user.profile` | 이름, 아바타, XP, 보유 금액 |
| `missions.active` | 현재 참여 중인 미션 ID 목록 |
| `missions.step` | 각 미션별 현재 스텝 진행 상태 |
| `location.current` | 현재 GPS 위치 (5초 갱신) |
| `notifications.unread` | 미읽은 알림 수 |
| `streak.current` | 현재 연속 참여 일수 |

### 6.2 에러 핸들링

| 에러 | UI 처리 |
|---|---|
| 네트워크 오류 | 토스트: "인터넷 연결을 확인해주세요" + 재시도 버튼 |
| GPS 신호 없음 | 배너: "GPS 신호를 찾는 중..." + 스피너 |
| 서버 에러 (5xx) | 전체 화면: "잠시 후 다시 시도해주세요" |
| 만료된 세션 | 자동 로그아웃 + 로그인 화면 이동 + 딥링크 보존 |
| 결제/환전 실패 | 모달: 상세 오류 코드 + 고객센터 링크 |

---

## 7. 접근성 요구사항

### 7.1 색상 대비 (Contrast Ratio)

| 요소 | 전경 | 배경 | 비율 | 요구사항 |
|---|---|---|---|---|
| 기본 텍스트 | `#EBEBEB` | `#111115` | 15:1+ | WCAG AA 통과 |
| 노란 강조 | `#FACC15` | `#111115` | 9:1 | WCAG AA 통과 |
| 비활성 텍스트 | `#555555` | `#111115` | 4.6:1 | WCAG AA 최소 기준 충족 |

### 7.2 터치 타겟

- 모든 인터랙티브 요소: 최소 44 × 44px (Apple HIG 기준)
- 바텀 네비 아이콘: 44px × 64px 탭 영역
- 목록 아이템: 최소 56px 높이

### 7.3 스크린 리더 (VoiceOver / TalkBack)

- 모든 아이콘에 `accessibilityLabel` 필수 지정
- 미션 카드: "홍대 보물찾기, ₩30,000 상금, LIVE, 3위 이내 달성 가능"
- 진행도 바: `accessibilityValue: {min: 0, max: 100, now: 72}` + "72% 완료"
- 역할 탭: "탐험가 탭, 현재 선택됨, 3개 중 1번"

### 7.4 다이나믹 타입 (Dynamic Type)

- 텍스트는 시스템 텍스트 크기 설정에 따라 ±20% 범위 내 자동 조정
- 최대 확대 시에도 레이아웃 깨짐 없도록 `flexWrap` 및 `minimumFontScale` 설정

### 7.5 모션 접근성

- iOS "동작 줄이기" / Android "애니메이션 사용 안 함" 활성화 시:
  - 컨페티 파티클 비활성화
  - 화면 전환: slide → fade로 대체
  - 모든 loop 애니메이션 정지

---

## 부록 A. 아이콘 참조 (Lucide Icons)

| 아이콘명 | 용도 |
|---|---|
| `Flame` | 바텀네비 HOME, AI 도발, 인기 배너 |
| `Search` | 바텀네비 EXPLORE, 검색 바 |
| `Trophy` | 바텀네비 RANK, 1위 랭킹, 결과 화면 |
| `Star` | 바텀네비 MY XP, 2위 랭킹, 즐겨찾기 |
| `MapPin` | 위치, 체크포인트, 클루 상세 3탭 |
| `Camera` | 인증샷 미션 유형 |
| `HelpCircle` | 퀴즈 미션 유형 |
| `EyeOff` | 숨바꼭질 미션 유형 |
| `Compass` | 탐험가 탭, 탐험 카테고리 |
| `Pen` | 크리에이터 탭 |
| `Store` | 사장님 탭/배지 |
| `Navigation` | GPS 확인 버튼 |
| `Lightbulb` | 힌트 카드 |
| `CheckCircle2` | 완료 상태, 카드 선택 |
| `Banknote` | 금액, 수익 |
| `Footprints` | 이동거리 통계 |
| `Clock` | 타이머, 시간 통계 |
| `Users` | 참여 인원 |
| `Share2` | 공유 |
| `Heart` | 좋아요 |
| `MessageCircle` | 댓글 |
| `Zap` | 3위 랭킹, 챌린지 탭 |
| `Moon` | 4위+ 랭킹 |
| `Radio` | 실시간 카테고리 |
| `Coffee` | 카페/맛집 카테고리 |
| `PenLine` | 1단계 온보딩 아이콘 |
| `ClipboardList` | 설문 미션 유형 |
| `UtensilsCrossed` | 음식 미션 유형 |
| `Bell` | 알림 |
| `Plus` | FAB 버튼 |
| `SlidersHorizontal` | 필터 |
| `ChevronLeft` | 뒤로가기 |
| `ChevronRight` | 다음/화살표 |

---

## 부록 B. API 엔드포인트 의존성 (UI 관련)

| 화면 | 필요 데이터 | 엔드포인트 (예시) |
|---|---|---|
| 홈 | 플랫폼 스탯, LIVE 미션, 페르소나 | `GET /api/home/dashboard` |
| 클루리스트 | 미션 목록 (필터/정렬/페이지네이션) | `GET /api/missions?filter&sort&cursor` |
| 미션 상세 | 미션 전체 정보 + 현재 참여 상태 | `GET /api/missions/:id` |
| GPS 인증 | 현재 위치 → 인증 요청 | `POST /api/missions/:id/steps/:step/verify` |
| 결과 | 완료 결과 + 순위 + 획득금액 | `GET /api/missions/:id/result` |
| 커뮤니티 | 게시물 피드 | `GET /api/community/feed?tab&filter&cursor` |
| 랭킹 | 크루 랭킹 + 나의 기록 | `GET /api/users/me/progress` |

---

*RunClue UI/UX 요구사항 명세서 v2.0 | 2026.04 | Internal Use Only*
