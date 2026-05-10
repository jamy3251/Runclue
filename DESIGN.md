# Design System — RunClue

## Product Context
- **What this is:** 위치기반 게임 미션 마켓플레이스. "뛰자, 풀자, 벌자."
- **Who it's for:** 탐험가(미션 수행), 크리에이터(미션 제작), 사장님(광고/집객)
- **Space/industry:** 게이밍 x 위치기반 x 마켓플레이스
- **Project type:** 모바일 앱 (Flutter, iOS/Android)
- **기준 해상도:** 390 x 844px (iPhone 14 Pro), 최소 360 x 780px

## Aesthetic Direction
- **Direction:** Dark Gaming Marketplace — 밤의 도시를 달리는 탐험가의 에너지
- **Decoration level:** Intentional — 레이더 링, 글로우 오브, 서틀 그라디언트
- **Mood:** 긴장감 있는 다크 UI에 노란색 네온이 터지는 느낌. 게임 로비처럼 몰입감 있되, 마켓플레이스의 명확한 정보 전달 유지.
- **Reference:** 배틀그라운드 로비, 카카오게임 대시보드, Uber 다크 모드

## Typography

### Font Family
| 용도 | 폰트 | 적용 범위 |
|------|------|----------|
| 디스플레이/헤드라인 | **Black Han Sans** | 화면 제목, 히어로 카피, 슬로건, 숫자 강조 |
| 본문/UI | **Noto Sans KR** | 설명 텍스트, 레이블, 데이터, 버튼 |

### Font Scale
| 토큰 | 사이즈 | Weight | Line-Height | 용도 |
|------|--------|--------|-------------|------|
| display-xl | 44px | 900 (BHS) | 1.0 | 결과 화면 "MISSION CLEAR!" |
| display-lg | 38-42px | 900 (BHS) | 1.05 | 로그인 슬로건, 랜딩 헤드라인 |
| display-md | 32-36px | 900 (BHS) | 1.1 | 화면 제목 (홈, 클루리스트) |
| heading-lg | 22-26px | 700 (NSK) | 1.3 | 섹션 제목, 카드 제목 |
| heading-md | 18-20px | 700 (NSK) | 1.4 | 서브 섹션, 미션 명 |
| body-lg | 16px | 400-500 | 1.6 | 본문 설명 |
| body-md | 14px | 400 | 1.6 | 일반 UI 텍스트, 레이블 |
| body-sm | 12px | 400 | 1.5 | 보조 정보, 날짜, 거리 |
| caption | 10-11px | 400 | 1.4 | 배지 내 텍스트, 아이콘 레이블 |

### Loading
- Google Fonts CDN: `google_fonts` Flutter 패키지
- Black Han Sans: `GoogleFonts.blackHanSans()`
- Noto Sans KR: `GoogleFonts.notoSansKr()`

## Color

### Approach: Expressive Dark
어두운 배경 위에 노란색/파란색/녹색이 강하게 터지는 컬러 시스템.

### Background Hierarchy
| 토큰 | 헥스 | 용도 |
|------|------|------|
| bg-hero | `#07070E` | 로그인, 결과 등 임팩트 풀스크린 |
| bg-base | `#111115` | 앱 기본 배경 |
| bg-surface | `#1C1C22` | 카드, 리스트 아이템 배경 |
| bg-elevated | `#262626` | 모달, 드롭다운, 헤더 배경 |

### Brand Colors
| 토큰 | 헥스 | 용도 |
|------|------|------|
| brand-yellow-primary | `#FACC15` | CTA 버튼, 활성 상태, 강조 수치 |
| brand-yellow-deep | `#F59E0B` | 버튼 그라디언트 끝색, 호버 |
| brand-blue | `#38BDF8` | 보조 액션, 정보성 요소, 탐험가 태그 |
| brand-green | `#10B981` | 완료 상태, 수익/보상, 사회증명 |
| brand-orange | `#F97316` | 경고, 사장님 태그, HOT 배지 |
| brand-red | `#EF4444` | 긴급, LIVE 배지, 오류 |
| brand-purple | `#A78BFA` | 크리에이터 태그, 보조 정보 |

### Text Colors
| 토큰 | 헥스 | 용도 |
|------|------|------|
| text-primary | `#EBEBEB` | 제목, 본문 핵심 텍스트 |
| text-secondary | `#A0A0A0` | 서브 설명, 레이블 |
| text-muted | `#696969` | 날짜, 단위, 비활성 |
| text-disabled | `#555555` | 비활성 placeholder |

### Border & Overlay
| 토큰 | 값 | 용도 |
|------|------|------|
| border-default | `rgba(255,255,255,0.07)` | 카드, 입력 필드 기본 보더 |
| border-subtle | `rgba(255,255,255,0.04)` | 탭, 구분선 |
| glow-yellow | `rgba(250,204,21,0.15)` | 활성 요소 배경 틴트 |
| glow-blue | `rgba(56,189,248,0.10)` | 파란 강조 배경 틴트 |

### Semantic
- Success: `#10B981` (brand-green)
- Warning: `#F97316` (brand-orange)
- Error: `#EF4444` (brand-red)
- Info: `#38BDF8` (brand-blue)

### Dark Mode
다크 모드가 기본. 라이트 모드는 Phase 2에서 지원.

## Spacing

### Base Unit: 4px
| 토큰 | 값 | 용도 |
|------|------|------|
| space-xs | 4px | 아이콘-텍스트 사이 |
| space-sm | 8px | 인라인 요소 간격 |
| space-md | 12px | 컴포넌트 내부 패딩 |
| space-lg | 16px | 컴포넌트 간 마진 |
| space-xl | 20-24px | 섹션 패딩 |
| space-2xl | 32px | 섹션 간 여백 |
| screen-padding-h | 16px | 화면 좌우 기본 패딩 |
| screen-padding-v | 20px | 화면 상하 기본 패딩 |

### Density: Comfortable
게이밍 앱이지만 마켓플레이스 정보를 명확히 전달해야 하므로 적당한 밀도.

## Layout
- **Approach:** Grid-disciplined (앱 UI 표준)
- **Grid:** Single column mobile-first
- **Max content width:** 390px (기준), 반응형 확장
- **Safe Area:** 상단 44px, 하단 34px (Home Indicator)

### Border Radius
| 토큰 | 값 | 용도 |
|------|------|------|
| radius-sm | 6px | 배지, 소형 pill |
| radius-md | 10-12px | 입력 필드, 소형 카드, 버튼 |
| radius-lg | 16px | 일반 카드 |
| radius-xl | 20px | 히어로 카드, 모달 |
| radius-full | 9999px | 아바타, 원형 버튼, 태그 |

### Shadow & Glow
| 토큰 | 값 | 용도 |
|------|------|------|
| shadow-card | `0 4px 24px rgba(0,0,0,0.6)` | 일반 카드 |
| shadow-modal | `0 24px 80px rgba(0,0,0,0.9)` | 모달, 오버레이 |
| glow-cta-yellow | `0 4px 20px rgba(250,204,21,0.4)` | CTA 버튼 |
| glow-result | `0 0 80px rgba(250,204,21,0.12)` | 미션 클리어 화면 |
| glow-live | `0 0 12px rgba(16,185,129,0.5)` | LIVE 배지 배경 |

## Motion
- **Approach:** Intentional — 모든 애니메이션은 의미가 있어야 함
- **Easing:** enter(ease-out), exit(ease-in), move(ease-in-out)
- **Duration:** micro(50-100ms), short(150-250ms), medium(250-400ms), long(400-700ms)

### Key Animations
| 요소 | 애니메이션 | Duration |
|------|----------|----------|
| CTA 버튼 shimmer | 좌→우 광택 이동 | 3초 주기 반복 |
| 로그인 레이더 링 | 확장하며 사라짐 + 스윕 라인 | 4초 주기 반복 |
| 아이콘 glow pulse | 노란색 글로우 밝기 변화 | 2초 주기 반복 |
| 미션 완료 축하 | 컨페티 파티클 + 스케일 바운스 | 3초 1회 |
| 카드 진입 | 슬라이드 업 + 페이드 인 | 300ms |

## Component Patterns

### CTA 버튼 (Primary Yellow)
```
background: linear-gradient(135deg, #FACC15, #F59E0B)
color: #000000
font-weight: 900
font-size: 16px
border-radius: 12px
height: 52px
box-shadow: 0 4px 20px rgba(250,204,21,0.4)
shimmer: 3초 주기 좌→우 광택
```

### Ghost 버튼 (Secondary)
```
background: transparent
border: 1px solid rgba(255,255,255,0.15)
color: #EBEBEB
font-weight: 700
border-radius: 12px
height: 52px
```

### 입력 필드
```
background: rgba(255,255,255,0.04)
border: 1px solid rgba(255,255,255,0.08)
border-radius: 10px
focus: border rgba(250,204,21,0.5) + glow
```

### 배지/Pill
| 배지 | 색상 | 배경 |
|------|------|------|
| LIVE | #EF4444 | rgba(239,68,68,0.15) |
| HOT | #F97316 | rgba(249,115,22,0.15) |
| NEW | #10B981 | rgba(16,185,129,0.15) |
| ACTIVE | #38BDF8 | rgba(56,189,248,0.15) |

### 바텀 네비게이션
- 4탭: HOME(Flame) / EXPLORE(Search) / RANK(Trophy) / MY XP(Star)
- 활성: `#FACC15` + drop-shadow glow
- 비활성: `#555555`
- 배경: bg-base + blur(12px)
- 높이: 64px + Safe Area Bottom

### 미션 카드
```
background: #1C1C22
border: 1px solid rgba(255,255,255,0.07)
border-radius: 16px
padding: 16px
구조: [타입아이콘 + 배지] → [제목 2줄] → [위치·시간·참여자] → [진행도 바] → [크리에이터 + 금액]
```

## Navigation (4탭)
| 탭 | 아이콘 | 레이블 | 화면 |
|------|--------|--------|------|
| HOME | Flame | HOME | 홈 대시보드 |
| EXPLORE | Search | EXPLORE | 클루 마켓플레이스 |
| RANK | Trophy | RANK | 나의 진행도/랭킹 |
| MY XP | Star | MY XP | 프로필/XP |

## 11 Screens
1. Login — 히어로 배경 + 레이더 링 + 슬로건 + 소셜 로그인
2. Home — 플랫폼 스탯 + 역할 탭 + LIVE 히어로 + 미션 카드 리스트
3. ClueList — 검색 + 카테고리 탭 + 정렬 + 미션 카드 + FAB
4. CreateClue — 6단계 위저드 + 템플릿 선택
5. MyProgress — 랭킹 + 스트릭 + AI 도발 배너
6. ClueDetail — 미션 상세 + 스텝 미리보기 + 참여 CTA
7. BizLanding — 사장님 전용 랜딩
8. StepPlay — 미션 진행 + GPS + 카메라 + 타이머
9. Result — MISSION CLEAR + 보상 + 공유
10. Community — 소통 광장
11. WhyRunClue — 앱 소개/온보딩

## Decisions Log
| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-04-05 | Initial design system from PDF spec v2.0 | docs/Presentation-Design-Plus.pdf + docs/runclue-ui-ux-spec.md 기반 |
| 2026-04-05 | Dark mode as default | 게이밍 마켓플레이스 컨벤션 + PDF 스펙 일치 |
| 2026-04-05 | Yellow (#FACC15) as primary CTA | PDF 스펙 + 카테고리 차별화 (대부분 파란/보라 사용) |
| 2026-04-05 | Black Han Sans + Noto Sans KR | 한글 가독성 + 임팩트 디스플레이 |
| 2026-04-05 | 4탭 네비 (HOME/EXPLORE/RANK/MY XP) | PDF 스펙 Section 3.1 |
