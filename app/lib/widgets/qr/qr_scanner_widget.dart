import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// QR 코드 스캔 위젯. CHECKPOINT 스텝의 대체 검증 방식.
///
/// 사용: QrScannerWidget.show(context) → Future<String?> (스캔된 값)
/// 또는 인라인 위젯으로 배치.
class QrScannerWidget extends StatefulWidget {
  final void Function(String value) onScanned;

  const QrScannerWidget({super.key, required this.onScanned});

  /// 모달로 QR 스캐너를 열고 스캔 결과를 반환
  static Future<String?> show(BuildContext context) async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              // 핸들바
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'QR 코드를 스캔하세요',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: QrScannerWidget(
                    onScanned: (value) => Navigator.pop(context, value),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        '취소',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  State<QrScannerWidget> createState() => _QrScannerWidgetState();
}

class _QrScannerWidgetState extends State<QrScannerWidget> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _scanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: (capture) {
            if (_scanned) return;
            final barcodes = capture.barcodes;
            if (barcodes.isEmpty) return;

            final value = barcodes.first.rawValue;
            if (value == null || value.isEmpty) return;

            setState(() => _scanned = true);
            widget.onScanned(value);
          },
        ),
        // 스캔 가이드 오버레이
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        // 플래시 토글
        Positioned(
          bottom: 16,
          right: 16,
          child: IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.white),
            onPressed: () => _controller.toggleTorch(),
          ),
        ),
      ],
    );
  }
}
