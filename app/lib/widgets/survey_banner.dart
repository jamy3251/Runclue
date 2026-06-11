import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/theme.dart';

/// 공모전/설문조사 배너 위젯.
/// 홈 화면 상단에 배치하여 사용자 피드백 수집 + 공모전 참여 유도.
///
/// 디자인: 다크 카드 + 노란 border glow + 아이콘 + CTA
class SurveyBanner extends StatelessWidget {
  final String? surveyUrl;
  final VoidCallback? onDismiss;

  const SurveyBanner({
    super.key,
    this.surveyUrl,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.brandYellow.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandYellow.withValues(alpha: 0.06),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 아이콘
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.brandYellow.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.campaign_rounded,
                    color: AppColors.brandYellow,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // 텍스트
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.brandOrange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('HOT',
                              style: GoogleFonts.notoSansKr(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.brandOrange,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.brandGreen.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('NEW',
                              style: GoogleFonts.notoSansKr(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.brandGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('RunClue 사전 설문조사',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('여러분의 의견이 RunClue를 만듭니다!\n1분이면 충분해요. 참여자 전원 포인트 지급!',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                // 닫기 버튼
                if (onDismiss != null)
                  IconButton(
                    onPressed: onDismiss,
                    icon: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 하단: 참여자 수 + CTA 버튼
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                // 참여자 수
                const Icon(Icons.people_outline, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text('342명 참여',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 12, color: AppColors.textMuted,
                  ),
                ),
                const Spacer(),
                // CTA 버튼
                ElevatedButton(
                    onPressed: () async {
                      final url = surveyUrl ?? 'https://forms.gle/runclue-survey';
                      final uri = Uri.parse(url);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandYellow,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      minimumSize: const Size(0, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text('참여하기',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 13, fontWeight: FontWeight.w700,
                      ),
                    ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 공모전 배너 — 특별 이벤트/공모전용
class ContestBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final String prize;
  final String? contestUrl;

  const ContestBanner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.prize,
    this.contestUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.bgSurface,
            AppColors.bgElevated,
          ],
        ),
        border: Border.all(
          color: AppColors.brandBlue.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.brandBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.emoji_events, size: 14, color: AppColors.brandBlue),
                    const SizedBox(width: 4),
                    Text('공모전',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: AppColors.brandBlue,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.brandRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.brandRed,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('LIVE',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: AppColors.brandRed,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(title,
            style: GoogleFonts.blackHanSans(
              fontSize: 22, color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(subtitle,
            style: GoogleFonts.notoSansKr(
              fontSize: 13, color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // 상금
              Text(prize,
                style: GoogleFonts.blackHanSans(
                  fontSize: 20, color: AppColors.brandYellow,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                  onPressed: () async {
                    if (contestUrl != null) {
                      final uri = Uri.parse(contestUrl!);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandBlue,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    minimumSize: const Size(0, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text('도전하기',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 14, fontWeight: FontWeight.w900,
                    ),
                  ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
