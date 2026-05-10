"""
RunClue 기능설명서 PDF 생성 스크립트
시각화 다이어그램 + 테이블 + 아키텍처 포함
"""
import os
from fpdf import FPDF

class RunCluePDF(FPDF):
    # 브랜드 컬러
    YELLOW = (250, 204, 21)
    DARK_BG = (17, 17, 21)
    SURFACE = (28, 28, 34)
    TEXT_PRIMARY = (235, 235, 235)
    TEXT_SECONDARY = (160, 160, 160)
    BLUE = (56, 189, 248)
    GREEN = (16, 185, 129)
    RED = (239, 68, 68)
    ORANGE = (249, 115, 22)
    PURPLE = (167, 139, 250)

    def __init__(self):
        super().__init__()
        self.set_auto_page_break(auto=True, margin=20)
        # 한글 폰트 등록
        font_path = "C:/Windows/Fonts"
        self.add_font("NotoKR", "", os.path.join(font_path, "malgun.ttf"), uni=True)
        self.add_font("NotoKR", "B", os.path.join(font_path, "malgunbd.ttf"), uni=True)

    def dark_page(self):
        """다크 배경 페이지"""
        self.add_page()
        self.set_fill_color(*self.DARK_BG)
        self.rect(0, 0, 210, 297, 'F')

    def title_page(self):
        """표지"""
        self.dark_page()
        # 로고 배경 글로우
        self.set_fill_color(250, 204, 21)
        self.set_draw_color(250, 204, 21)
        # 노란색 원
        self.ellipse(85, 60, 40, 40, 'F')
        # R 텍스트
        self.set_font("NotoKR", "B", 28)
        self.set_text_color(17, 17, 21)
        self.set_xy(95, 68)
        self.cell(20, 20, "R", align="C")

        # 타이틀
        self.set_font("NotoKR", "B", 36)
        self.set_text_color(*self.TEXT_PRIMARY)
        self.set_xy(0, 110)
        self.cell(210, 15, "RUNCLUE", align="C")

        self.set_font("NotoKR", "B", 18)
        self.set_text_color(*self.YELLOW)
        self.set_xy(0, 130)
        self.cell(210, 12, "기능설명서 v1.0", align="C")

        self.set_font("NotoKR", "", 12)
        self.set_text_color(*self.TEXT_SECONDARY)
        self.set_xy(0, 148)
        self.cell(210, 8, "위치기반 게임 미션 마켓플레이스", align="C")
        self.set_xy(0, 158)
        self.cell(210, 8, '"뛰자, 풀자, 벌자."', align="C")

        # 하단 정보
        self.set_font("NotoKR", "", 10)
        self.set_text_color(*self.TEXT_SECONDARY)
        self.set_xy(0, 250)
        self.cell(210, 6, "2026.04 | Flutter + Supabase | 36 Tests Passing", align="C")
        self.set_xy(0, 258)
        self.cell(210, 6, "3자 생태계: 탐험가 · 크리에이터 · 사장님", align="C")

    def section_title(self, num, title):
        """섹션 제목"""
        self.set_font("NotoKR", "B", 18)
        self.set_text_color(*self.YELLOW)
        self.cell(0, 12, f"{num}. {title}", new_x="LMARGIN", new_y="NEXT")
        # 밑줄
        y = self.get_y()
        self.set_draw_color(*self.YELLOW)
        self.set_line_width(0.8)
        self.line(10, y, 80, y)
        self.ln(6)

    def sub_title(self, title):
        """소제목"""
        self.set_font("NotoKR", "B", 13)
        self.set_text_color(*self.BLUE)
        self.cell(0, 10, title, new_x="LMARGIN", new_y="NEXT")

    def body_text(self, text):
        """본문"""
        self.set_font("NotoKR", "", 10)
        self.set_text_color(*self.TEXT_PRIMARY)
        self.multi_cell(0, 6, text)
        self.ln(2)

    def colored_box(self, text, color, w=60, h=20):
        """컬러 박스"""
        self.set_fill_color(*color)
        x, y = self.get_x(), self.get_y()
        self.rect(x, y, w, h, 'F')
        self.set_font("NotoKR", "B", 9)
        self.set_text_color(0, 0, 0) if color == self.YELLOW else self.set_text_color(*self.TEXT_PRIMARY)
        self.set_xy(x, y + 4)
        self.cell(w, h - 8, text, align="C")
        return x, y

    def table(self, headers, rows, col_widths=None):
        """테이블"""
        if col_widths is None:
            col_widths = [190 / len(headers)] * len(headers)

        # 헤더
        self.set_font("NotoKR", "B", 9)
        self.set_fill_color(*self.SURFACE)
        self.set_text_color(*self.YELLOW)
        for i, h in enumerate(headers):
            self.cell(col_widths[i], 8, h, border=0, fill=True, align="C")
        self.ln()

        # 행
        self.set_font("NotoKR", "", 9)
        self.set_text_color(*self.TEXT_PRIMARY)
        for row in rows:
            # 페이지 넘김 체크
            if self.get_y() > 270:
                self.dark_page()
            self.set_fill_color(22, 22, 28)
            for i, cell in enumerate(row):
                self.cell(col_widths[i], 7, str(cell), border=0, fill=True, align="C")
            self.ln()
        self.ln(4)

    def architecture_diagram(self):
        """아키텍처 다이어그램"""
        y_start = self.get_y() + 2
        x_start = 20
        box_h = 18
        box_w = 34
        gap = 2

        # Flutter App 레이어
        self.set_fill_color(*self.SURFACE)
        self.rect(x_start, y_start, 170, box_h, 'F')
        self.set_font("NotoKR", "B", 10)
        self.set_text_color(*self.TEXT_PRIMARY)
        self.set_xy(x_start, y_start + 4)
        self.cell(170, 10, "Flutter App (Screens + Widgets + Animations)", align="C")

        # Providers 레이어
        y2 = y_start + box_h + gap
        self.set_fill_color(40, 40, 50)
        self.rect(x_start, y2, 170, box_h, 'F')
        self.set_text_color(*self.BLUE)
        self.set_xy(x_start, y2 + 4)
        self.cell(170, 10, "Providers (Riverpod) — 상태관리", align="C")

        # Services 레이어
        y3 = y2 + box_h + gap
        self.set_fill_color(50, 50, 60)
        self.rect(x_start, y3, 170, box_h, 'F')
        self.set_text_color(*self.GREEN)
        self.set_xy(x_start, y3 + 4)
        self.cell(170, 10, "Services (16개) — 비즈니스 로직", align="C")

        # Models 레이어
        y4 = y3 + box_h + gap
        self.set_fill_color(60, 60, 70)
        self.rect(x_start, y4, 170, box_h, 'F')
        self.set_text_color(*self.PURPLE)
        self.set_xy(x_start, y4 + 4)
        self.cell(170, 10, "Models (Freezed) — 데이터 모델 8개", align="C")

        # Supabase 레이어
        y5 = y4 + box_h + gap
        self.set_fill_color(*self.YELLOW)
        self.rect(x_start, y5, 170, box_h + 4, 'F')
        self.set_font("NotoKR", "B", 10)
        self.set_text_color(0, 0, 0)
        self.set_xy(x_start, y5 + 2)
        self.cell(170, 8, "Supabase Backend", align="C")
        self.set_font("NotoKR", "", 8)
        self.set_xy(x_start, y5 + 11)
        self.cell(170, 8, "14 Tables + RLS + PostGIS + Realtime + Storage + Edge Functions", align="C")

        # 화살표
        self.set_draw_color(*self.TEXT_SECONDARY)
        for y in [y_start + box_h, y2 + box_h, y3 + box_h, y4 + box_h]:
            self.line(105, y, 105, y + gap)

        self.set_y(y5 + box_h + 10)

    def flow_diagram(self):
        """미션 진행 플로우 다이어그램"""
        y = self.get_y() + 2
        x = 15
        steps = [
            ("미션 생성", self.YELLOW),
            ("링크 공유", self.BLUE),
            ("익명 참여", self.GREEN),
            ("스텝 수행", self.ORANGE),
            ("실시간 피드", self.PURPLE),
            ("완료/공유", self.RED),
        ]

        for i, (label, color) in enumerate(steps):
            bx = x + i * 30
            self.set_fill_color(*color)
            self.rect(bx, y, 28, 16, 'DF')
            self.set_font("NotoKR", "B", 7)
            self.set_text_color(0, 0, 0) if color in [self.YELLOW, self.GREEN] else self.set_text_color(255, 255, 255)
            self.set_xy(bx, y + 4)
            self.cell(28, 8, label, align="C")

            # 화살표
            if i < len(steps) - 1:
                self.set_draw_color(*self.TEXT_SECONDARY)
                self.line(bx + 28, y + 8, bx + 30, y + 8)

        self.set_y(y + 24)


def generate():
    pdf = RunCluePDF()

    # ─── 1. 표지 ───
    pdf.title_page()

    # ─── 2. 목차 ───
    pdf.dark_page()
    pdf.set_xy(10, 20)
    pdf.section_title("", "목차")
    toc = [
        "1. 아키텍처 개요",
        "2. 인증 모듈",
        "3. 미션(클루) 모듈",
        "4. 검증 모듈",
        "5. 실시간 모듈",
        "6. 공유 모듈",
        "7. 알림 모듈",
        "8. 디자인 시스템",
        "9. 데이터베이스 (14 테이블)",
        "10. 테스트 커버리지",
        "11. 기술 스택",
    ]
    for item in toc:
        pdf.set_font("NotoKR", "", 12)
        pdf.set_text_color(*pdf.TEXT_PRIMARY)
        pdf.cell(0, 10, f"  {item}", new_x="LMARGIN", new_y="NEXT")

    # ─── 3. 아키텍처 개요 ───
    pdf.dark_page()
    pdf.set_xy(10, 20)
    pdf.section_title("1", "아키텍처 개요")
    pdf.body_text("RunClue는 Flutter + Supabase 기반의 모바일 앱입니다.\n3자 생태계(탐험가/크리에이터/사장님)를 지원하며,\n실시간 미션 진행과 검증을 제공합니다.")
    pdf.ln(2)
    pdf.sub_title("시스템 아키텍처")
    pdf.architecture_diagram()
    pdf.ln(4)
    pdf.sub_title("미션 진행 플로우")
    pdf.flow_diagram()

    # ─── 4. 인증 모듈 ───
    pdf.dark_page()
    pdf.set_xy(10, 20)
    pdf.section_title("2", "인증 모듈")
    pdf.body_text("카카오/네이버/Google 소셜 로그인 + 이메일 로그인 + 딥링크 익명 참여를 지원합니다.")
    pdf.table(
        ["기능", "설명", "구현 파일"],
        [
            ["카카오 로그인", "Supabase OAuth", "auth_service.dart"],
            ["네이버 로그인", "Supabase OAuth", "auth_service.dart"],
            ["Google 로그인", "Supabase OAuth", "auth_service.dart"],
            ["이메일 가입", "이메일 + 비밀번호", "auth_service.dart"],
            ["익명 참여", "딥링크 → anonymous auth", "anonymous_auth_service.dart"],
            ["계정 전환", "익명 → 정식 업그레이드", "anonymous_auth_service.dart"],
        ],
        [40, 70, 80]
    )

    # ─── 5. 미션 모듈 ───
    pdf.dark_page()
    pdf.set_xy(10, 20)
    pdf.section_title("3", "미션(클루) 모듈")
    pdf.body_text("클루 생성, 스텝 관리, 검색, 좋아요 등 미션의 전체 생명주기를 관리합니다.")
    pdf.sub_title("스텝 타입 상세")
    pdf.table(
        ["타입", "Evidence", "검증 방식", "타임아웃"],
        [
            ["CHECKPOINT", "GPS 좌표", "자동 (Haversine 50m)", "없음"],
            ["SNAPSHOT", "사진 파일", "수동 (호스트 승인)", "10분→자동"],
            ["QUEST", "텍스트", "자동/수동", "10분(수동)"],
            ["OX_QUIZ", "O/X 선택", "자동 (정답 비교)", "없음"],
            ["LIST", "체크리스트", "자동 (전체 체크)", "없음"],
        ],
        [35, 40, 60, 55]
    )

    # ─── 6. 검증 모듈 ───
    pdf.dark_page()
    pdf.set_xy(10, 20)
    pdf.section_title("4", "검증 모듈")
    pdf.body_text("ValidationOrchestrator가 Evidence 제출 시 타입별로 자동/수동/지연 검증을 분기합니다.")
    pdf.sub_title("검증 알고리즘")
    pdf.table(
        ["검증", "알고리즘", "구현"],
        [
            ["GPS 근접", "Haversine 거리 ≤ radius", "autoValidateCheckpoint()"],
            ["퀴즈 정답", "trim + lowercase 비교", "autoValidateQuiz()"],
            ["체크리스트", "requiredItems.every()", "autoValidateChecklist()"],
        ],
        [40, 70, 80]
    )
    pdf.ln(4)
    pdf.sub_title("검증 흐름")
    pdf.body_text("자동 검증: Evidence 제출 → 즉시 판정 → auto_approved / auto_rejected\n수동 검증: Evidence 제출 → pending → 호스트 승인/반려\n지연 검증: Evidence 제출 → pending → 10분 타임아웃 → auto_approved")

    # ─── 7. 실시간 모듈 ───
    pdf.dark_page()
    pdf.set_xy(10, 20)
    pdf.section_title("5", "실시간 모듈")
    pdf.body_text("Supabase Realtime을 통해 미션 진행 상황, 참여자 위치, 알림을 실시간으로 전달합니다.")
    pdf.sub_title("채널 구조 (Eng Review: 2채널 통합)")
    pdf.table(
        ["채널", "이벤트", "용도"],
        [
            ["clue:{clueId}", "evidence INSERT/UPDATE", "미션 진행 피드"],
            ["location:{clueId}", "Broadcast (Presence)", "참여자 위치 공유"],
        ],
        [55, 60, 75]
    )
    pdf.sub_title("실시간 기능")
    pdf.table(
        ["기능", "구현", "설명"],
        [
            ["실시간 피드", "RealtimeFeedProvider", "Evidence/Participation 변경 감지"],
            ["실시간 맵", "RealtimeLocationProvider", "참여자 GPS 브로드캐스트"],
            ["라이브 위젯", "LiveFeedWidget", "이벤트 오버레이 표시"],
            ["실시간 알림", "NotificationService", "알림 INSERT 감지"],
        ],
        [40, 65, 85]
    )

    # ─── 8. 공유 모듈 ───
    pdf.dark_page()
    pdf.set_xy(10, 20)
    pdf.section_title("6", "공유 모듈")
    pdf.sub_title("딥링크 시스템")
    pdf.body_text("URL 형식: https://runclue.app/clue/{clueId}\n비회원도 링크 클릭으로 즉시 참여 가능")
    pdf.sub_title("확장 기능")
    pdf.table(
        ["기능", "구현", "설명"],
        [
            ["딥링크", "DeepLinkService", "URL 생성/파싱/검증/공유"],
            ["승리 카드", "VictoryCardService", "Canvas 캡처 → 이미지 공유"],
            ["워터마크", "WatermarkService", "Isolate에서 사진 합성"],
            ["하이라이트 릴", "HighlightReelScreen", "인증 사진 슬라이드쇼"],
            ["축하 애니메이션", "CelebrationOverlay", "컨페티 파티클 3초"],
        ],
        [45, 60, 85]
    )

    # ─── 9. 디자인 시스템 ───
    pdf.dark_page()
    pdf.set_xy(10, 20)
    pdf.section_title("8", "디자인 시스템")
    pdf.body_text("다크 게이밍 마켓플레이스 — 밤의 도시를 달리는 탐험가의 에너지\nBlack Han Sans (디스플레이) + Noto Sans KR (본문)")

    pdf.sub_title("컬러 팔레트")
    y = pdf.get_y() + 2
    colors = [
        ("bg-hero\n#07070E", (7, 7, 14)),
        ("bg-base\n#111115", (17, 17, 21)),
        ("bg-surface\n#1C1C22", (28, 28, 34)),
        ("Yellow\n#FACC15", (250, 204, 21)),
        ("Blue\n#38BDF8", (56, 189, 248)),
        ("Green\n#10B981", (16, 185, 129)),
    ]
    for i, (label, color) in enumerate(colors):
        x = 15 + i * 30
        pdf.set_fill_color(*color)
        pdf.rect(x, y, 28, 22, 'F')
        pdf.set_font("NotoKR", "", 6)
        tc = (0,0,0) if color == (250,204,21) else (235,235,235)
        pdf.set_text_color(*tc)
        pdf.set_xy(x, y + 6)
        pdf.cell(28, 5, label.split('\n')[0], align="C")
        pdf.set_xy(x, y + 12)
        pdf.cell(28, 5, label.split('\n')[1], align="C")

    pdf.set_y(y + 30)

    # ─── 10. DB 스키마 ───
    pdf.dark_page()
    pdf.set_xy(10, 20)
    pdf.section_title("9", "데이터베이스 (14 테이블)")
    pdf.table(
        ["테이블", "용도", "RLS"],
        [
            ["profiles", "사용자 프로필", "본인만 수정"],
            ["clues", "미션 정보", "creator만 수정"],
            ["steps", "미션 스텝", "creator만 수정"],
            ["participations", "참여 기록", "본인만 조회/수정"],
            ["evidences", "인증 증거", "본인 INSERT"],
            ["clans", "클랜(팀)", "leader만 수정"],
            ["clan_members", "클랜 멤버", "본인/leader"],
            ["rewards", "보상 기록", "본인만 조회"],
            ["reports", "신고", "본인 INSERT"],
            ["notifications", "알림", "본인만 조회"],
            ["community_posts", "커뮤니티 글", "전체 조회"],
            ["post_comments", "댓글", "전체 조회"],
            ["likes", "좋아요", "전체 조회"],
            ["blocks", "차단", "본인만 관리"],
        ],
        [45, 80, 65]
    )

    # ─── 11. 테스트 + 기술 스택 ───
    pdf.dark_page()
    pdf.set_xy(10, 20)
    pdf.section_title("10", "테스트 커버리지")
    pdf.table(
        ["영역", "테스트 수", "커버리지"],
        [
            ["자동 검증 (GPS/퀴즈/체크리스트)", "16", "100%"],
            ["검증 분기 로직", "11", "100%"],
            ["딥링크 파싱", "9", "100%"],
            ["합계", "36", "—"],
        ],
        [80, 50, 60]
    )

    pdf.section_title("11", "기술 스택")
    pdf.table(
        ["구분", "기술"],
        [
            ["프론트엔드", "Flutter 3.x (Dart)"],
            ["상태관리", "Riverpod"],
            ["라우팅", "GoRouter"],
            ["백엔드", "Supabase (PostgreSQL + PostGIS)"],
            ["인증", "Supabase Auth (OAuth + Anonymous)"],
            ["실시간", "Supabase Realtime (Broadcast)"],
            ["지도", "Google Maps Flutter"],
            ["위치", "Geolocator (Haversine)"],
            ["폰트", "Google Fonts (Black Han Sans + Noto Sans KR)"],
            ["테스트", "flutter_test (36개)"],
        ],
        [50, 140]
    )

    # 저장
    output_path = "D:/Projects/App/RunClue/docs/RunClue_기능설명서_v1.0.pdf"
    pdf.output(output_path)
    print(f"PDF saved: {output_path}")

if __name__ == "__main__":
    generate()
