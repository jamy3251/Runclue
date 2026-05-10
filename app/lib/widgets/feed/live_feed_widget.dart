import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../providers/realtime_feed_provider.dart';

/// 미션 진행 중 실시간 이벤트를 표시하는 오버레이 위젯.
/// CluePlayScreen이나 HostDashboard 상단에 배치.
///
/// 표시 예시:
///   "참여자A가 Step 2를 완료했습니다" (2분 전)
///   "새 인증이 제출되었습니다" (방금)
class LiveFeedWidget extends ConsumerStatefulWidget {
  final String clueId;
  final int maxEvents;

  const LiveFeedWidget({
    super.key,
    required this.clueId,
    this.maxEvents = 5,
  });

  @override
  ConsumerState<LiveFeedWidget> createState() => _LiveFeedWidgetState();
}

class _LiveFeedWidgetState extends ConsumerState<LiveFeedWidget> {
  final List<FeedEvent> _events = [];

  @override
  Widget build(BuildContext context) {
    // 실시간 이벤트 수신
    ref.listen<AsyncValue<FeedEvent>>(
      realtimeFeedProvider(widget.clueId),
      (prev, next) {
        next.whenData((event) {
          setState(() {
            _events.insert(0, event);
            if (_events.length > widget.maxEvents) {
              _events.removeLast();
            }
          });
        });
      },
    );

    if (_events.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      child: ListView.builder(
        shrinkWrap: true,
        reverse: false,
        itemCount: _events.length,
        itemBuilder: (context, index) {
          final event = _events[index];
          return _FeedEventTile(event: event);
        },
      ),
    );
  }
}

class _FeedEventTile extends StatelessWidget {
  final FeedEvent event;
  const _FeedEventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final isEvidence = event.type == FeedEventType.evidenceSubmitted;
    final status = event.data['status'] as String? ?? '';

    String message;
    IconData icon;
    Color color;

    if (isEvidence) {
      if (status == 'auto_approved' || status == 'approved') {
        message = '인증이 승인되었습니다';
        icon = Icons.check_circle;
        color = Colors.green;
      } else if (status == 'auto_rejected' || status == 'rejected') {
        message = '인증이 반려되었습니다';
        icon = Icons.cancel;
        color = Colors.red;
      } else {
        message = '새 인증이 제출되었습니다';
        icon = Icons.camera_alt;
        color = Colors.blue;
      }
    } else {
      final participationStatus = event.data['status'] as String? ?? '';
      if (participationStatus == 'completed') {
        message = '미션을 완료했습니다!';
        icon = Icons.emoji_events;
        color = Colors.amber;
      } else {
        final stepIndex = event.data['current_step_index'] as int? ?? 0;
        message = 'Step ${stepIndex + 1} 진행 중';
        icon = Icons.directions_run;
        color = Colors.blue;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Text(
            timeago.format(event.timestamp, locale: 'ko'),
            style: TextStyle(fontSize: 11, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}
