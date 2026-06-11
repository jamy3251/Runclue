import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../services/partner_application_service.dart';

/// Screen 07 — 사장님 랜딩 (BizLanding) — 명세 v2.0 §4.7
/// B2B 사장님 설득 + 자동 제휴 신청 폼
class BizLandingScreen extends ConsumerWidget {
  const BizLandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: Row(
          children: [
            Text('RUNCLUE',
                style: GoogleFonts.blackHanSans(
                    fontSize: 18, color: AppColors.textPrimary,),),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.brandOrange.withValues(alpha: 0.15),
                border: Border.all(
                    color: AppColors.brandOrange.withValues(alpha: 0.3),),
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.store,
                      size: 12, color: AppColors.brandOrange,),
                  const SizedBox(width: 4),
                  Text(
                    '사장님 모드',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 11,
                      color: AppColors.brandOrange,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHero(context),
            _buildMetrics(),
            _buildHowItWorks(),
            _buildSocialProof(),
            _buildSignupSection(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ─────────────── Hero ───────────────
  Widget _buildHero(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.bgHero,
            AppColors.brandOrange.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: GoogleFonts.blackHanSans(fontSize: 36, height: 1.15),
              children: const [
                TextSpan(
                    text: '광고비 ',
                    style: TextStyle(color: AppColors.textPrimary),),
                TextSpan(
                    text: '0원으로\n',
                    style: TextStyle(color: AppColors.brandYellow),),
                TextSpan(
                    text: '방학에도 손님이\n직접 찾아오게',
                    style: TextStyle(color: AppColors.textPrimary),),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '시립대 캠퍼스타운 매장 무상 베타 신청',
            style: GoogleFonts.notoSansKr(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _heroChip(Icons.local_offer, '메뉴 할인'),
              const SizedBox(width: 6),
              _heroChip(Icons.card_giftcard, '기프티콘'),
              const SizedBox(width: 6),
              _heroChip(Icons.payments, '캐시 (예정)'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.brandYellow),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.notoSansKr(
              fontSize: 11,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────── 임팩트 지표 ───────────────
  Widget _buildMetrics() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Row(
        children: [
          _metric('1/8', '학기 대비 방학 매출'),
          _divider(),
          _metric('₩0', '베타 매장 광고비'),
          _divider(),
          _metric('10+', '시립대 베타 매장 모집'),
        ],
      ),
    );
  }

  Widget _metric(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.blackHanSans(
              fontSize: 22,
              color: AppColors.brandYellow,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansKr(
              fontSize: 11,
              color: AppColors.textMuted,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 36,
        color: AppColors.borderDefault,
        margin: const EdgeInsets.symmetric(horizontal: 4),
      );

  // ─────────────── 작동 방식 ───────────────
  Widget _buildHowItWorks() {
    const steps = [
      (1, '퀘스트 등록', '메뉴 할인·기프티콘 보상으로 매장 방문 미션 등록 (5분)',
          Icons.edit_note, AppColors.brandYellow),
      (2, '탐험가 방문', 'AR 퀘스트를 풀러 캠퍼스타운 학생들이 매장 방문',
          Icons.directions_walk, AppColors.brandBlue),
      (3, '매출 확인', '대시보드에서 방문률·재방문율·체류시간 실시간 확인',
          Icons.trending_up, AppColors.brandGreen),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '3단계 온보딩',
            style: GoogleFonts.blackHanSans(
              fontSize: 22,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...steps.map((s) {
            final isLast = s.$1 == steps.length;
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: s.$5,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${s.$1}',
                          style: GoogleFonts.notoSansKr(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: AppColors.borderDefault,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.bgSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderDefault),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(s.$4, color: s.$5, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  s.$2,
                                  style: GoogleFonts.notoSansKr(
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              s.$3,
                              style: GoogleFonts.notoSansKr(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─────────────── 사회증명 ───────────────
  Widget _buildSocialProof() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.brandPurple.withValues(alpha: 0.08),
              AppColors.brandBlue.withValues(alpha: 0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(
                5,
                (_) => const Icon(Icons.star,
                    color: AppColors.brandYellow, size: 16,),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '"방학에도 학생들이 매장에 찾아오는 게 신기해요. 광고비 한 푼 안 들이고 신규 손님이 늘었습니다."',
              style: GoogleFonts.notoSansKr(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.6,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '— 회기동 카페 사장님 (베타 1기)',
              style: GoogleFonts.notoSansKr(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────── 신청 폼 ───────────────
  Widget _buildSignupSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '무료 베타 신청',
            style: GoogleFonts.blackHanSans(
              fontSize: 26,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '신용카드 불필요 · 즉시 시작 · 전담 담당자 배정',
            style: GoogleFonts.notoSansKr(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppGradients.ctaYellow,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [AppShadows.ctaYellow],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _openSignupSheet(context),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.bolt, color: Colors.black, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          '1분만에 신청하기',
                          style: GoogleFonts.notoSansKr(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _showDemoDialog(context),
            icon: const Icon(Icons.play_circle_outline, size: 18),
            label: const Text('데모 보기'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }

  void _openSignupSheet(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _PartnerSignupSheet(),
    );
  }

  void _showDemoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('데모 영상'),
        content: const Text(
          '곧 1분 데모 영상이 공개됩니다.\n그 전에 베타 신청하시면 직접 시연을 해드려요!',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _openSignupSheet(context);
            },
            child: const Text('베타 신청'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 파트너 신청 시트
// ─────────────────────────────────────────────────────────────

class _PartnerSignupSheet extends StatefulWidget {
  const _PartnerSignupSheet();

  @override
  State<_PartnerSignupSheet> createState() => _PartnerSignupSheetState();
}

class _PartnerSignupSheetState extends State<_PartnerSignupSheet> {
  final _formKey = GlobalKey<FormState>();
  final _storeC = TextEditingController();
  final _ownerC = TextEditingController();
  final _phoneC = TextEditingController();
  final _addressC = TextEditingController();
  final _descC = TextEditingController();
  final _instaC = TextEditingController();
  String _category = '카페';
  bool _isSubmitting = false;

  static const _categories = [
    '카페',
    '음식점',
    '디저트·베이커리',
    '주점·바',
    '스터디카페',
    '소품·잡화',
    '서비스',
    '기타',
  ];

  @override
  void dispose() {
    _storeC.dispose();
    _ownerC.dispose();
    _phoneC.dispose();
    _addressC.dispose();
    _descC.dispose();
    _instaC.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      await PartnerApplicationService().submit(
        storeName: _storeC.text.trim(),
        ownerName: _ownerC.text.trim(),
        phone: _phoneC.text.trim(),
        address: _addressC.text.trim(),
        category: _category,
        description: _descC.text.trim().isNotEmpty ? _descC.text.trim() : null,
        instagramUrl: _instaC.text.trim().isNotEmpty ? _instaC.text.trim() : null,
      );

      if (!mounted) return;
      Navigator.pop(context);
      _showSuccess();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('신청 실패: $e'),
          backgroundColor: AppColors.brandRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccess() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.brandGreen),
            const SizedBox(width: 8),
            Text('신청 완료!',
                style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w900),),
          ],
        ),
        content: Text(
          '베타 매장 신청이 접수되었습니다.\n영업일 1~3일 안에 연락드릴게요.',
          style: GoogleFonts.notoSansKr(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('베타 매장 신청',
                  style: GoogleFonts.blackHanSans(
                      fontSize: 24, color: AppColors.textPrimary,),),
              const SizedBox(height: 4),
              Text(
                '필수 항목만 입력하시면 됩니다',
                style: GoogleFonts.notoSansKr(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 20),
              _label('매장명 *'),
              _input(
                _storeC,
                hint: '예: 카페 RUNCLUE',
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? '매장명을 입력해주세요' : null,
              ),
              const SizedBox(height: 12),
              _label('대표자명 *'),
              _input(
                _ownerC,
                hint: '홍길동',
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? '대표자명을 입력해주세요' : null,
              ),
              const SizedBox(height: 12),
              _label('연락처 *'),
              _input(
                _phoneC,
                hint: '010-1234-5678',
                keyboard: TextInputType.phone,
                validator: (v) =>
                    (v ?? '').trim().length < 9 ? '연락처를 정확히 입력해주세요' : null,
              ),
              const SizedBox(height: 12),
              _label('매장 주소 *'),
              _input(
                _addressC,
                hint: '서울 동대문구 회기로 12',
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? '주소를 입력해주세요' : null,
              ),
              const SizedBox(height: 12),
              _label('카테고리 *'),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _categories.map((cat) {
                  final selected = _category == cat;
                  return GestureDetector(
                    onTap: () => setState(() => _category = cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8,),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.brandOrange.withValues(alpha: 0.15)
                            : AppColors.bgSurface,
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(
                          color: selected
                              ? AppColors.brandOrange
                              : AppColors.borderDefault,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: GoogleFonts.notoSansKr(
                          fontSize: 12,
                          color: selected
                              ? AppColors.brandOrange
                              : AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              _label('인스타그램 (선택)'),
              _input(
                _instaC,
                hint: '@your_store',
              ),
              const SizedBox(height: 12),
              _label('하고 싶은 말 (선택)'),
              _input(
                _descC,
                hint: '예: 방학에 매출이 줄어 고민이에요',
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient:
                        _isSubmitting ? null : AppGradients.ctaYellow,
                    color: _isSubmitting ? AppColors.bgSurface : null,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow:
                        _isSubmitting ? null : const [AppShadows.ctaYellow],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: _isSubmitting ? null : _submit,
                      child: Center(
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : Text(
                                '신청 제출',
                                style: GoogleFonts.notoSansKr(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '제출 즉시 RunClue 운영진에게 자동 전달됩니다',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansKr(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: GoogleFonts.notoSansKr(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      );

  Widget _input(
    TextEditingController controller, {
    required String hint,
    int maxLines = 1,
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboard,
      validator: validator,
      style: GoogleFonts.notoSansKr(
        fontSize: 14,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.notoSansKr(
          fontSize: 14,
          color: AppColors.textDisabled,
        ),
        filled: true,
        fillColor: AppColors.bgSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderDefault),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderDefault),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.brandOrange),
        ),
      ),
    );
  }
}
