import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// 사진/모션 유사도 계산.
///
/// MVP 알고리즘: Average Hash (aHash) 64-bit perceptual hash
/// 1. 8x8 리사이즈 + 그레이스케일
/// 2. 평균 픽셀 값 기준으로 각 픽셀이 평균 위/아래인지 64비트 해시 생성
/// 3. 두 해시의 Hamming distance로 유사도 점수 계산 (0~100)
///
/// 한계:
/// - 회전·반전·심한 색조 변화에는 약함
/// - Wave 3에서 ML Kit Pose Detection 또는 ARCore Body Tracking으로 교체 예정
class SimilarityService {
  /// 이미지 파일에서 64비트 perceptual hash 생성.
  /// 실패 시 null 반환.
  static int? hashFromFile(File file) {
    try {
      final bytes = file.readAsBytesSync();
      return hashFromBytes(bytes);
    } catch (_) {
      return null;
    }
  }

  static int? hashFromBytes(Uint8List bytes) {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      // 8x8로 리사이즈 + 그레이스케일
      final small = img.copyResize(image, width: 8, height: 8);
      final gray = img.grayscale(small);

      // 평균 픽셀 값 계산
      final pixels = <int>[];
      for (int y = 0; y < 8; y++) {
        for (int x = 0; x < 8; x++) {
          final pixel = gray.getPixel(x, y);
          // image 4.x: pixel.r/g/b는 num
          pixels.add(pixel.r.toInt());
        }
      }
      final avg = pixels.reduce((a, b) => a + b) ~/ pixels.length;

      // 64비트 해시 생성
      int hash = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (pixels[i] > avg) {
          hash |= (1 << i);
        }
      }
      return hash;
    } catch (_) {
      return null;
    }
  }

  /// Hamming distance — 두 해시에서 다른 비트 수
  static int hammingDistance(int a, int b) {
    int xor = a ^ b;
    int count = 0;
    while (xor != 0) {
      count += xor & 1;
      xor >>= 1;
    }
    return count;
  }

  /// 두 이미지 해시의 유사도를 0~100점으로 환산.
  /// 100 = 동일, 0 = 완전 다름.
  static double similarityScore(int hashA, int hashB) {
    final dist = hammingDistance(hashA, hashB);
    return ((64 - dist) / 64.0 * 100).clamp(0, 100);
  }

  /// 두 이미지 파일을 비교한 점수.
  /// 이미지 디코딩 실패 시 0 반환.
  static double compareFiles(File a, File b) {
    final ha = hashFromFile(a);
    final hb = hashFromFile(b);
    if (ha == null || hb == null) return 0;
    return similarityScore(ha, hb);
  }

  /// 사용자 사진 vs 정답 사진(URL bytes) 비교.
  static double compareUserToReference({
    required Uint8List userBytes,
    required Uint8List referenceBytes,
  }) {
    final ha = hashFromBytes(userBytes);
    final hb = hashFromBytes(referenceBytes);
    if (ha == null || hb == null) return 0;
    return similarityScore(ha, hb);
  }

  /// 점수 → 사용자 친화적 등급
  static String gradeOf(double score) {
    if (score >= 90) return 'PERFECT';
    if (score >= 80) return 'EXCELLENT';
    if (score >= 70) return 'GREAT';
    if (score >= 60) return 'GOOD';
    if (score >= 50) return 'OK';
    return 'TRY AGAIN';
  }
}
