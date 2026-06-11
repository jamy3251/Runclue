import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// 미션 완료 시 공유용 승리 카드 이미지를 생성하는 서비스.
///
/// Canvas API로 카드를 그리고, PNG로 내보내서 카톡/인스타 공유.
/// 내용: 클루명, 순위, 점수, 소요시간, 날짜, RunClue 로고
class VictoryCardService {
  /// GlobalKey로 지정된 위젯을 캡처해서 PNG 바이트로 반환
  static Future<Uint8List?> captureWidget(GlobalKey key) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  /// 승리 카드를 캡처하고 시스템 공유 시트로 공유
  static Future<void> shareVictoryCard(GlobalKey cardKey) async {
    final bytes = await captureWidget(cardKey);
    if (bytes == null) return;

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/runclue_victory_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: '🏆 RunClue 미션 완료! #RunClue',
    );
  }
}

/// 승리 카드 위젯. RepaintBoundary로 감싸서 캡처 가능하게.
class VictoryCard extends StatelessWidget {
  final GlobalKey cardKey;
  final String clueTitle;
  final int rank;
  final int points;
  final Duration elapsed;
  final DateTime completedAt;

  const VictoryCard({
    super.key,
    required this.cardKey,
    required this.clueTitle,
    required this.rank,
    required this.points,
    required this.elapsed,
    required this.completedAt,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: cardKey,
      child: Container(
        width: 340,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // RunClue 로고
            const Text(
              'RunClue',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),

            // 트로피
            Text(
              rank == 1 ? '🥇' : rank == 2 ? '🥈' : rank == 3 ? '🥉' : '🏆',
              style: const TextStyle(fontSize: 56),
            ),
            const SizedBox(height: 12),

            // 클루 제목
            Text(
              clueTitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            // 통계
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatColumn(label: '순위', value: '$rank위'),
                _StatColumn(label: '점수', value: '$points'),
                _StatColumn(
                  label: '소요시간',
                  value: _formatDuration(elapsed),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 날짜
            Text(
              '${completedAt.year}.${completedAt.month.toString().padLeft(2, '0')}.${completedAt.day.toString().padLeft(2, '0')}',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;

  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white60),
        ),
      ],
    );
  }
}
