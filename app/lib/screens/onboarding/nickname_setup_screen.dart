import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';

/// 첫 로그인 닉네임 설정 — 소셜/익명 가입자는 'guest_xxxxxx'로 시작하므로
/// 탐험가 이름을 정하고 들어가게 한다. (이메일 가입자는 가입 시 입력 → skip)
class NicknameSetupScreen extends ConsumerStatefulWidget {
  const NicknameSetupScreen({super.key});

  @override
  ConsumerState<NicknameSetupScreen> createState() =>
      _NicknameSetupScreenState();
}

class _NicknameSetupScreenState extends ConsumerState<NicknameSetupScreen> {
  final _controller = TextEditingController();
  bool _busy = false;
  String? _error;

  static const _adjectives = [
    '날쌘', '용감한', '엉뚱한', '재빠른', '느긋한', '수상한', '빛나는', '집요한',
    '명랑한', '진지한', '몰래온', '전설의',
  ];
  static const _nouns = [
    '탐험가', '러너', '추적자', '보물꾼', '해결사', '미식가', '순찰자', '모험왕',
    '관찰자', '수집가',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _suggest() {
    HapticFeedback.selectionClick();
    final rng = Random();
    final name = '${_adjectives[rng.nextInt(_adjectives.length)]}'
        '${_nouns[rng.nextInt(_nouns.length)]}'
        '${rng.nextInt(90) + 10}';
    setState(() {
      _controller.text = name;
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (_busy) return;
    final nickname = _controller.text.trim();
    if (nickname.length < 2 || nickname.length > 12) {
      setState(() => _error = '닉네임은 2~12자로 입력해 주세요');
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) {
        if (mounted) context.go('/auth');
        return;
      }
      await ref
          .read(profileServiceProvider)
          .updateProfile(userId, {'nickname': nickname});
      ref.invalidate(currentProfileProvider);
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() => _error = '저장 실패: 잠시 후 다시 시도해 주세요');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgHero,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),
              Text('🏃', style: const TextStyle(fontSize: 44)),
              const SizedBox(height: 16),
              Text('탐험가 이름을\n정해주세요',
                  style: GoogleFonts.blackHanSans(
                      fontSize: 34,
                      color: AppColors.textPrimary,
                      height: 1.25)),
              const SizedBox(height: 10),
              Text('랭킹·배틀·시즌 보드에 이 이름으로 표시됩니다.\n언제든 프로필에서 바꿀 수 있어요.',
                  style: GoogleFonts.notoSansKr(
                      fontSize: 13,
                      color: AppColors.textMuted,
                      height: 1.5)),
              const SizedBox(height: 28),
              TextField(
                controller: _controller,
                maxLength: 12,
                autofocus: true,
                style: GoogleFonts.notoSansKr(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: '예: 날쌘탐험가42',
                  counterText: '',
                  errorText: _error,
                  prefixIcon: const Icon(Icons.badge_outlined,
                      color: AppColors.brandYellow),
                  suffixIcon: IconButton(
                    tooltip: '랜덤 추천',
                    icon: const Icon(Icons.casino_outlined,
                        color: AppColors.textMuted),
                    onPressed: _suggest,
                  ),
                ),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _busy ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandYellow,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black))
                      : Text('탐험 시작하기',
                          style: GoogleFonts.notoSansKr(
                              fontSize: 16, fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _busy ? null : () => context.go('/home'),
                  child: Text('나중에 정할게요',
                      style: GoogleFonts.notoSansKr(
                          fontSize: 12, color: AppColors.textDisabled)),
                ),
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
