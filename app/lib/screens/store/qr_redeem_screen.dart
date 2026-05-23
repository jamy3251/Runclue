import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../config/theme.dart';
import '../../providers/store_provider.dart';

/// 사장이 손님 QR을 스캔하여 주문을 redeem.
/// 같은 QR은 1회만 사용 가능 (DB 가드).
class QrRedeemScreen extends ConsumerStatefulWidget {
  const QrRedeemScreen({super.key});

  @override
  ConsumerState<QrRedeemScreen> createState() => _QrRedeemScreenState();
}

class _QrRedeemScreenState extends ConsumerState<QrRedeemScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _busy = false;
  String? _lastToken;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || code.isEmpty) return;
    if (code == _lastToken) return; // 같은 토큰 연속 인식 방지
    _lastToken = code;

    HapticFeedback.mediumImpact();
    setState(() => _busy = true);
    try {
      final res = await ref.read(storeServiceProvider).redeem(code);
      if (!mounted) return;
      if (res['ok'] == true) {
        HapticFeedback.heavyImpact();
        ref.invalidate(myStoreOrdersProvider);
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('주문 확인 완료'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle,
                    color: AppColors.brandGreen, size: 56),
                const SizedBox(height: 12),
                Text(
                  res['menu_name']?.toString() ?? '',
                  style: GoogleFonts.notoSansKr(
                      fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text('${res['diamond_cost']} 다이아 받음',
                    style: GoogleFonts.notoSansKr(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brandBlue)),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _lastToken = null; // 다음 스캔 허용
                },
                child: const Text('다음 손님'),
              ),
            ],
          ),
        );
      } else {
        final msg = _reasonMessage(res);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(msg),
              backgroundColor: AppColors.brandRed,
              duration: const Duration(seconds: 2)),
        );
        // 일정 시간 후 같은 토큰 재인식 허용
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) _lastToken = null;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static String _reasonMessage(Map<String, dynamic> res) {
    final reason = res['reason']?.toString() ?? 'unknown';
    switch (reason) {
      case 'qr_not_found':
        return '유효하지 않은 QR 코드입니다';
      case 'not_owner':
        return '다른 가게의 QR입니다';
      case 'already_redeemed':
        return '이미 사용된 QR입니다';
      case 'expired':
        return '만료된 QR입니다';
      case 'auth_required':
        return '로그인이 필요합니다';
      default:
        return '실패: $reason';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('손님 QR 스캔'),
        actions: [
          IconButton(
            tooltip: '플래시 토글',
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          // 가이드 박스
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.brandYellow, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          // 하단 안내
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _busy
                    ? '확인 중...'
                    : '손님 휴대폰의 QR을 가이드 박스 안에 맞춰주세요',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansKr(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension on List<Barcode> {
  Barcode? get firstOrNull => isEmpty ? null : first;
}
