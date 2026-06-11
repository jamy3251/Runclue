import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// 하이라이트 릴 Phase 2 — 인증 사진들을 GIF로 인코딩 (공유 바이럴용).
///
/// 인코딩은 CPU 집약적이라 compute() isolate에서 수행.
/// 프레임 0.8초, 폭 480px 리사이즈 (카톡 공유에 적당한 용량).
class GifExportService {
  /// 이미지 URL들을 다운로드 → GIF 파일 생성. 실패한 프레임은 건너뜀.
  /// 반환: 임시 디렉토리의 .gif 파일 (1장 이상 성공 시), 전부 실패면 null.
  Future<File?> buildGif(
    List<String> imageUrls, {
    void Function(int done, int total)? onProgress,
  }) async {
    final frames = <Uint8List>[];
    final client = HttpClient();
    try {
      for (var i = 0; i < imageUrls.length; i++) {
        try {
          final req = await client.getUrl(Uri.parse(imageUrls[i]));
          final res = await req.close();
          if (res.statusCode == 200) {
            final builder = BytesBuilder(copy: false);
            await for (final chunk in res) {
              builder.add(chunk);
            }
            frames.add(builder.takeBytes());
          }
        } catch (_) {/* 프레임 단위 실패 무시 */}
        onProgress?.call(i + 1, imageUrls.length);
      }
    } finally {
      client.close();
    }
    if (frames.isEmpty) return null;

    final gifBytes = await compute(_encodeGif, frames);
    if (gifBytes == null) return null;

    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/runclue_highlight_${DateTime.now().millisecondsSinceEpoch}.gif',);
    await file.writeAsBytes(gifBytes);
    return file;
  }
}

/// isolate 진입점 — 디코드 → 480px 리사이즈 → GIF 인코딩 (프레임 0.8초).
Uint8List? _encodeGif(List<Uint8List> rawFrames) {
  const maxWidth = 480;
  const frameDelayCs = 80; // 1/100초 단위 → 0.8초

  final encoder = img.GifEncoder(repeat: 0); // 무한 반복
  var added = 0;
  for (final raw in rawFrames) {
    try {
      var frame = img.decodeImage(raw);
      if (frame == null) continue;
      if (frame.width > maxWidth) {
        frame = img.copyResize(frame, width: maxWidth);
      }
      encoder.addFrame(frame, duration: frameDelayCs);
      added++;
    } catch (_) {/* 깨진 프레임 무시 */}
  }
  if (added == 0) return null;
  return encoder.finish();
}
