import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/theme.dart';
import '../../providers/currency_provider.dart';
import '../../providers/diamond_topup_provider.dart';

/// 다이아 충전 상점 (032) — 토스 결제로 다이아 패키지 구매.
///
/// 결제는 외부 브라우저(pay.html)에서 진행 — 인앱 WebView는 앱스토어 리젝 위험.
/// iOS는 IAP 정책상 기본 비활성 (--dart-define=ENABLE_IOS_DIAMOND_TOPUP=true로 오픈).
class DiamondShopScreen extends ConsumerStatefulWidget {
  const DiamondShopScreen({super.key});

  @override
  ConsumerState<DiamondShopScreen> createState() => _DiamondShopScreenState();
}

class _DiamondShopScreenState extends ConsumerState<DiamondShopScreen>
    with WidgetsBindingObserver {
  static const _tossClientKey = String.fromEnvironment('TOSS_CLIENT_KEY');
  static const _payBaseUrl = String.fromEnvironment(
    'PAY_PAGE_URL',
    defaultValue: 'https://runclue.app/pay.html',
  );
  static const _iosEnabled =
      bool.fromEnvironment('ENABLE_IOS_DIAMOND_TOPUP', defaultValue: false);

  bool _busy = false;
  bool _awaitingPayment = false;

  bool get _purchasable =>
      _tossClientKey.isNotEmpty && (kIsWeb || !Platform.isIOS || _iosEnabled);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 외부 브라우저 결제 후 앱 복귀 → 잔액/내역 갱신
    if (state == AppLifecycleState.resumed && _awaitingPayment) {
      _awaitingPayment = false;
      ref.invalidate(balancesProvider);
      ref.invalidate(myDiamondTopupsProvider);
    }
  }

  Future<void> _onBuy(Map<String, dynamic> pkg) async {
    if (_busy || !_purchasable) return;
    HapticFeedback.mediumImpact();
    setState(() => _busy = true);
    try {
      final res = await ref
          .read(diamondTopupServiceProvider)
          .createOrder(pkg['id'] as String);
      if (!mounted) return;
      if (res['ok'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('주문 생성 실패: ${res['reason']}')),
        );
        return;
      }
      final uri = Uri.parse(_payBaseUrl).replace(queryParameters: {
        'clientKey': _tossClientKey,
        'orderId': res['order_id'] as String,
        'amount': '${res['amount']}',
        'orderName': res['order_name'] as String,
      },);
      _awaitingPayment = true;
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        _awaitingPayment = false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('결제 페이지를 열 수 없습니다')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final balances = ref.watch(balancesProvider).valueOrNull;
    final packages = ref.watch(diamondPackagesProvider);
    final topups = ref.watch(myDiamondTopupsProvider).valueOrNull ?? const [];

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.bgElevated,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text('다이아 충전',
            style: GoogleFonts.notoSansKr(
                fontWeight: FontWeight.w900, color: AppColors.textPrimary,),),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(balancesProvider);
          ref.invalidate(myDiamondTopupsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 잔액 헤더
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppColors.brandBlue.withValues(alpha: 0.16),
                  AppColors.brandPurple.withValues(alpha: 0.10),
                ],),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.diamond,
                      color: AppColors.brandBlue, size: 28,),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('보유 다이아',
                          style: GoogleFonts.notoSansKr(
                              fontSize: 11, color: AppColors.textMuted,),),
                      Text('${balances?.diamond ?? 0}',
                          style: GoogleFonts.notoSansKr(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.brandBlue,),),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (!_purchasable) _disabledNotice(),
            const SizedBox(height: 8),
            Text('패키지',
                style: GoogleFonts.notoSansKr(
                    fontSize: 14, fontWeight: FontWeight.w900,),),
            const SizedBox(height: 8),
            packages.when(
              loading: () => const Center(
                  child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: AppColors.brandBlue),
              ),),
              error: (e, _) => Text('패키지 로드 실패: $e',
                  style: GoogleFonts.notoSansKr(
                      fontSize: 12, color: AppColors.brandRed,),),
              data: (list) => Column(
                children: list.map(_packageCard).toList(),
              ),
            ),
            const SizedBox(height: 20),
            Text('이용 안내',
                style: GoogleFonts.notoSansKr(
                    fontSize: 12, fontWeight: FontWeight.w800,),),
            const SizedBox(height: 4),
            Text(
              '· 다이아는 게임 내 가상 재화로 현금 환급이 불가합니다.\n'
              '· 기프티콘 교환·가게 메뉴 결제에 사용할 수 있습니다.\n'
              '· 결제는 토스페이먼츠 보안 결제창(외부 브라우저)에서 진행됩니다.',
              style: GoogleFonts.notoSansKr(
                  fontSize: 11, color: AppColors.textMuted, height: 1.6,),
            ),
            if (topups.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('충전 내역',
                  style: GoogleFonts.notoSansKr(
                      fontSize: 14, fontWeight: FontWeight.w900,),),
              const SizedBox(height: 8),
              ...topups.map(_topupRow),
            ],
          ],
        ),
      ),
    );
  }

  Widget _disabledNotice() {
    final isIosBlocked =
        !kIsWeb && Platform.isIOS && !_iosEnabled && _tossClientKey.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.brandYellow.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: AppColors.brandYellow.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.hourglass_top,
              color: AppColors.brandYellow, size: 18,),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isIosBlocked
                  ? 'iOS에서는 곧 충전이 오픈됩니다'
                  : '결제 준비 중 — 가맹점 심사 완료 후 오픈됩니다',
              style: GoogleFonts.notoSansKr(
                  fontSize: 12, color: AppColors.brandYellow,),
            ),
          ),
        ],
      ),
    );
  }

  Widget _packageCard(Map<String, dynamic> pkg) {
    final diamonds = pkg['diamond_amount'] as int? ?? 0;
    final price = pkg['price_krw'] as int? ?? 0;
    final bonus = pkg['bonus_label'] as String?;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: _purchasable && !_busy ? () => _onBuy(pkg) : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.brandBlue.withValues(alpha: 0.25),),
            ),
            child: Row(
              children: [
                const Icon(Icons.diamond,
                    color: AppColors.brandBlue, size: 22,),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('$diamonds 다이아',
                              style: GoogleFonts.notoSansKr(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,),),
                          if (bonus != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2,),
                              decoration: BoxDecoration(
                                color: AppColors.brandGreen
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(bonus,
                                  style: GoogleFonts.notoSansKr(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.brandGreen,),),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8,),
                  decoration: BoxDecoration(
                    color: _purchasable
                        ? AppColors.brandBlue
                        : AppColors.textMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${_formatKrw(price)}원',
                      style: GoogleFonts.notoSansKr(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,),),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topupRow(Map<String, dynamic> t) {
    final status = t['status'] as String? ?? '';
    final (label, color) = switch (status) {
      'approved' => ('충전 완료', AppColors.brandGreen),
      'pending' => ('결제 대기', AppColors.brandYellow),
      'failed' => ('실패', AppColors.brandRed),
      _ => ('취소', AppColors.textMuted),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.diamond, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
                '${t['diamond_amount']} 다이아 · ${_formatKrw(t['price_krw'] as int? ?? 0)}원',
                style: GoogleFonts.notoSansKr(
                    fontSize: 12, color: AppColors.textPrimary,),),
          ),
          Text(label,
              style: GoogleFonts.notoSansKr(
                  fontSize: 11, fontWeight: FontWeight.w800, color: color,),),
        ],
      ),
    );
  }

  static String _formatKrw(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
