import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 인증 사진에 RunClue 워터마크를 합성하는 서비스.
/// Isolate에서 처리하여 UI 스레드 블로킹 방지 (Eng Review #5 결정).
///
/// 워터마크 내용: "RunClue" 로고 + 타임스탬프 + GPS 좌표(선택)
/// 위치: 하단 우측, 반투명
/// 사용자 설정: ON/OFF (기본 OFF)
class WatermarkService {
  /// 이미지 파일에 워터마크를 합성하고 새 바이트를 반환한다.
  /// Isolate에서 실행되므로 UI가 멈추지 않음.
  static Future<Uint8List> applyWatermark({
    required File imageFile,
    required DateTime timestamp,
    double? latitude,
    double? longitude,
    String? clueTitle,
  }) async {
    final imageBytes = await imageFile.readAsBytes();

    // Isolate에서 워터마크 합성
    return compute(_processWatermark, _WatermarkParams(
      imageBytes: imageBytes,
      timestamp: timestamp,
      latitude: latitude,
      longitude: longitude,
      clueTitle: clueTitle,
    ));
  }

  /// Isolate에서 실행되는 워터마크 처리 함수
  static Future<Uint8List> _processWatermark(_WatermarkParams params) async {
    // 이미지 디코딩
    final codec = await ui.instantiateImageCodec(params.imageBytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final width = image.width.toDouble();
    final height = image.height.toDouble();

    // 캔버스에 원본 이미지 그리기
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.drawImage(image, Offset.zero, Paint());

    // 워터마크 텍스트 구성
    final lines = <String>['RunClue'];

    final ts = params.timestamp;
    lines.add(
      '${ts.year}.${ts.month.toString().padLeft(2, '0')}.${ts.day.toString().padLeft(2, '0')} '
      '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}',
    );

    if (params.latitude != null && params.longitude != null) {
      lines.add(
        '${params.latitude!.toStringAsFixed(4)}, ${params.longitude!.toStringAsFixed(4)}',
      );
    }

    if (params.clueTitle != null) {
      lines.add(params.clueTitle!);
    }

    // 워터마크 배경
    final fontSize = width * 0.025;
    final padding = width * 0.015;
    final lineHeight = fontSize * 1.4;
    final blockHeight = lines.length * lineHeight + padding * 2;
    final blockWidth = width * 0.4;

    final bgPaint = Paint()
      ..color = const Color(0x88000000); // 반투명 검정

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          width - blockWidth - padding,
          height - blockHeight - padding,
          blockWidth,
          blockHeight,
        ),
        const Radius.circular(8),
      ),
      bgPaint,
    );

    // 텍스트 그리기
    for (var i = 0; i < lines.length; i++) {
      final builder = ui.ParagraphBuilder(ui.ParagraphStyle(
        textAlign: TextAlign.right,
        fontSize: fontSize,
      ))
        ..pushStyle(ui.TextStyle(color: const Color(0xCCFFFFFF)))
        ..addText(lines[i]);

      final paragraph = builder.build()
        ..layout(ui.ParagraphConstraints(width: blockWidth - padding * 2));

      canvas.drawParagraph(
        paragraph,
        Offset(
          width - blockWidth - padding + padding,
          height - blockHeight - padding + padding + i * lineHeight,
        ),
      );
    }

    // PNG로 인코딩
    final picture = recorder.endRecording();
    final resultImage = await picture.toImage(width.round(), height.round());
    final byteData = await resultImage.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }
}

class _WatermarkParams {
  final Uint8List imageBytes;
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;
  final String? clueTitle;

  _WatermarkParams({
    required this.imageBytes,
    required this.timestamp,
    this.latitude,
    this.longitude,
    this.clueTitle,
  });
}
