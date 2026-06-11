import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme.dart';

/// AR 보물찾기 — 카메라 프리뷰 위에 나침반 기반 방향 화살표 + 거리 HUD.
/// 목표 반경 안에 들어오면 화면에 보물이 떠오르고, 탭하면 도착 처리(pop true).
///
/// ARCore/ARKit 없이 카메라+나침반+GPS만 사용 — 전 기기 호환, 가벼움.
/// (3D 평면인식 AR은 P3 — 마스코트 IP와 함께)
class ArTreasureScreen extends StatefulWidget {
  const ArTreasureScreen({
    super.key,
    required this.targetLat,
    required this.targetLng,
    this.radiusM = 30,
    this.title = '보물을 찾아라!',
  });

  final double targetLat;
  final double targetLng;
  final double radiusM;
  final String title;

  @override
  State<ArTreasureScreen> createState() => _ArTreasureScreenState();
}

class _ArTreasureScreenState extends State<ArTreasureScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _camera;
  String? _cameraError;
  StreamSubscription<Position>? _posSub;
  StreamSubscription<CompassEvent>? _compassSub;
  late final AnimationController _pulse;

  double? _heading; // 기기가 향하는 방위 (0=북)
  double? _bearing; // 현재 위치 → 목표 방위
  double? _distanceM;
  bool _captured = false;

  bool get _arrived => _distanceM != null && _distanceM! <= widget.radiusM;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _initCamera();
    _initSensors();
  }

  Future<void> _initCamera() async {
    try {
      final cams = await availableCameras();
      final back = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cams.first,
      );
      final ctrl = CameraController(
        back,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await ctrl.initialize();
      if (!mounted) {
        ctrl.dispose();
        return;
      }
      setState(() => _camera = ctrl);
    } catch (e) {
      if (mounted) setState(() => _cameraError = '카메라를 열 수 없습니다');
    }
  }

  void _initSensors() {
    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2,
      ),
    ).listen((pos) {
      if (!mounted) return;
      setState(() {
        _distanceM = Geolocator.distanceBetween(
            pos.latitude, pos.longitude, widget.targetLat, widget.targetLng,);
        _bearing = Geolocator.bearingBetween(
            pos.latitude, pos.longitude, widget.targetLat, widget.targetLng,);
      });
    });
    _compassSub = FlutterCompass.events?.listen((event) {
      if (!mounted || event.heading == null) return;
      setState(() => _heading = event.heading);
    });
  }

  void _onTreasureTap() {
    if (_captured || !_arrived) return;
    _captured = true;
    HapticFeedback.heavyImpact();
    Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    _posSub?.cancel();
    _compassSub?.cancel();
    _camera?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 화살표 회전각: 목표 방위 − 기기 방위
    final double? relative = (_bearing != null && _heading != null)
        ? ((_bearing! - _heading!) * math.pi / 180.0)
        : null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 카메라 프리뷰 (실패 시 다크 배경 유지)
          if (_camera != null && _camera!.value.isInitialized)
            CameraPreview(_camera!)
          else
            Container(
              color: Colors.black,
              alignment: Alignment.center,
              child: Text(
                _cameraError ?? '카메라 준비 중...',
                style: GoogleFonts.notoSansKr(
                    color: AppColors.textMuted, fontSize: 13,),
              ),
            ),

          // 어두운 비네트 (HUD 가독성)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.55),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.55),
                ],
              ),
            ),
          ),

          // 상단 HUD: 제목 + 거리
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                      Expanded(
                        child: Text(widget.title,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.blackHanSans(
                                fontSize: 16, color: Colors.white,),),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: (_arrived
                                ? AppColors.brandGreen
                                : AppColors.brandYellow)
                            .withValues(alpha: 0.6),),
                  ),
                  child: Text(
                    _distanceM == null
                        ? 'GPS 수신 중...'
                        : _arrived
                            ? '🎯 도착! 보물을 탭하세요'
                            : '${_distanceM!.round()}m 남음',
                    style: GoogleFonts.notoSansKr(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: _arrived
                            ? AppColors.brandGreen
                            : AppColors.brandYellow,),
                  ),
                ),
              ],
            ),
          ),

          // 중앙: 도착 전 = 방향 화살표 / 도착 = 보물
          Center(
            child: _arrived
                ? GestureDetector(
                    onTap: _onTreasureTap,
                    child: AnimatedBuilder(
                      animation: _pulse,
                      builder: (context, child) {
                        final scale = 1.0 + _pulse.value * 0.18;
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(colors: [
                                AppColors.brandYellow
                                    .withValues(alpha: 0.55),
                                AppColors.brandYellow
                                    .withValues(alpha: 0.08),
                              ],),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.brandYellow
                                      .withValues(alpha: 0.5),
                                  blurRadius: 40,
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: const Text('💎',
                                style: TextStyle(fontSize: 64),),
                          ),
                        );
                      },
                    ),
                  )
                : relative == null
                    ? Text('나침반 보정 중...\n폰을 8자로 흔들어 주세요',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.notoSansKr(
                            color: Colors.white70, fontSize: 13,),)
                    : Transform.rotate(
                        angle: relative,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.navigation,
                                size: 96,
                                color: AppColors.brandYellow
                                    .withValues(alpha: 0.95),
                                shadows: const [
                                  Shadow(
                                      color: Colors.black54, blurRadius: 12,),
                                ],),
                          ],
                        ),
                      ),
          ),

          // 하단 안내
          if (!_arrived)
            Positioned(
              left: 0,
              right: 0,
              bottom: 40,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10,),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '화살표 방향으로 이동하세요 — ${widget.radiusM.round()}m 안에서 보물이 나타납니다',
                    style: GoogleFonts.notoSansKr(
                        fontSize: 12, color: Colors.white,),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
