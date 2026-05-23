import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/points_provider.dart';
import '../../providers/routine_provider.dart';
import '../../services/location_service.dart';
import '../../widgets/common/location_picker_modal.dart';

/// 루틴 인증 — 매일 가는 곳 등록 → 1일 1회 체크인 → streak.
/// 인터뷰 3/3 "일회성" 우려 해결용 retention 핵심 기능.
class RoutinesScreen extends ConsumerWidget {
  const RoutinesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routinesAsync = ref.watch(myRoutinesProvider);
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.bgElevated,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          '루틴 인증',
          style: GoogleFonts.notoSansKr(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.brandYellow,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('루틴 추가'),
        onPressed: () => _showCreateSheet(context, ref),
      ),
      body: routinesAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.brandYellow)),
        error: (e, _) => Center(
            child: Text('오류: $e', style: TextStyle(color: AppColors.error))),
        data: (routines) {
          if (routines.isEmpty) return _emptyState();
          return RefreshIndicator(
            color: AppColors.brandYellow,
            onRefresh: () async => ref.invalidate(myRoutinesProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: routines.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) =>
                  _RoutineCard(routine: routines[i], onChanged: () {
                ref.invalidate(myRoutinesProvider);
              }),
            ),
          );
        },
      ),
    );
  }

  Widget _emptyState() {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 80),
        const Icon(Icons.repeat,
            size: 64, color: AppColors.textMuted),
        const SizedBox(height: 16),
        Text(
          '루틴을 등록해보세요',
          textAlign: TextAlign.center,
          style: GoogleFonts.notoSansKr(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          '매일 가는 곳(학교/회사/단골 카페)을 등록하면\n방문할 때마다 streak가 쌓이고 보상으로 이어져요.',
          textAlign: TextAlign.center,
          style: GoogleFonts.notoSansKr(
              fontSize: 13, color: AppColors.textSecondary, height: 1.5),
        ),
      ],
    );
  }

  void _showCreateSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _CreateRoutineSheet(onCreated: () {
        ref.invalidate(myRoutinesProvider);
      }),
    );
  }
}

class _RoutineCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> routine;
  final VoidCallback onChanged;
  const _RoutineCard({required this.routine, required this.onChanged});

  @override
  ConsumerState<_RoutineCard> createState() => _RoutineCardState();
}

class _RoutineCardState extends ConsumerState<_RoutineCard> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.routine;
    final streak = r['current_streak'] ?? 0;
    final longest = r['longest_streak'] ?? 0;
    final last = r['last_checkin_at'] != null
        ? DateTime.tryParse(r['last_checkin_at'].toString())?.toLocal()
        : null;
    final today = DateTime.now();
    final didToday = last != null &&
        last.year == today.year &&
        last.month == today.month &&
        last.day == today.day;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: didToday
                ? AppColors.brandGreen.withValues(alpha: 0.4)
                : AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  r['name']?.toString() ?? '',
                  style: GoogleFonts.notoSansKr(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: AppColors.textMuted, size: 20),
                onPressed: () async {
                  final ok = await _confirmDelete(context);
                  if (ok != true) return;
                  await ref
                      .read(routineServiceProvider)
                      .deleteRoutine(r['id'] as String);
                  widget.onChanged();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _streakBadge('🔥 $streak일', AppColors.brandRed),
              const SizedBox(width: 8),
              _streakBadge('최장 $longest일', AppColors.brandPurple),
              const Spacer(),
              Text(
                '반경 ${r['radius_m']}m',
                style: GoogleFonts.notoSansKr(
                    fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: (didToday || _busy) ? null : _doCheckin,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    didToday ? AppColors.brandGreen : AppColors.brandYellow,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black))
                  : Icon(didToday ? Icons.check : Icons.location_on,
                      size: 18),
              label: Text(
                didToday ? '오늘 인증 완료' : '지금 체크인',
                style: GoogleFonts.notoSansKr(
                    fontWeight: FontWeight.w900, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _doCheckin() async {
    setState(() => _busy = true);
    try {
      final svc = LocationService();
      await svc.requestPermission();
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );
      final res = await ref.read(routineServiceProvider).checkin(
            routineId: widget.routine['id'] as String,
            lat: pos.latitude,
            lng: pos.longitude,
          );
      if (!mounted) return;
      if (res['ok'] == true) {
        HapticFeedback.heavyImpact();
        // streak 마일스톤 포인트 — 매일 +2p, 7일 streak +10p 보너스, 30일 +50p
        final streak = (res['streak'] as num?)?.toInt() ?? 1;
        int reward = 2;
        if (streak == 7) reward += 10;
        if (streak == 30) reward += 50;
        final uid = ref.read(currentUserIdProvider);
        if (uid != null) {
          await ref.read(pointsServiceProvider).add(
                userId: uid,
                delta: reward,
                reason: 'routine:streak:$streak',
              );
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🔥 streak ${streak}일! +${reward}p'),
            backgroundColor: AppColors.brandGreen,
          ),
        );
        widget.onChanged();
      } else {
        final reason = res['reason']?.toString() ?? 'unknown';
        final msg = switch (reason) {
          'too_far' =>
            '너무 멀어요 (${(res['distance_m'] as num?)?.toInt()}m). 반경 안에서 다시 시도.',
          'already_today' => '오늘은 이미 인증했어요',
          'routine_not_found' => '루틴을 찾을 수 없습니다',
          _ => '실패: $reason',
        };
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('체크인 오류: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _streakBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: GoogleFonts.notoSansKr(
              fontSize: 11, color: color, fontWeight: FontWeight.w900)),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgElevated,
        title: const Text('루틴 삭제',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('streak 기록도 함께 사라집니다.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('삭제',
                  style: TextStyle(color: AppColors.brandRed))),
        ],
      ),
    );
  }
}

class _CreateRoutineSheet extends ConsumerStatefulWidget {
  final VoidCallback onCreated;
  const _CreateRoutineSheet({required this.onCreated});
  @override
  ConsumerState<_CreateRoutineSheet> createState() => _CreateRoutineSheetState();
}

class _CreateRoutineSheetState extends ConsumerState<_CreateRoutineSheet> {
  final _name = TextEditingController();
  double? _lat;
  double? _lng;
  String? _addr;
  int _radius = 100;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + viewInsets),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.borderDefault,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text('루틴 추가',
              style: GoogleFonts.notoSansKr(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text('매일 가는 곳을 등록하세요. 1일 1회 체크인이 가능해요.',
              style: GoogleFonts.notoSansKr(
                  fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 20),
          _label('이름'),
          TextField(
            controller: _name,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: '예: 학교 등교, 단골 카페',
              hintStyle: TextStyle(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.bgSurface,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          _label('위치'),
          GestureDetector(
            onTap: () async {
              final r = await LocationPickerModal.show(context);
              if (r != null) {
                setState(() {
                  _lat = r.latitude;
                  _lng = r.longitude;
                  _addr = r.address;
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: _lat != null
                        ? AppColors.brandYellow.withValues(alpha: 0.4)
                        : AppColors.borderDefault),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on,
                      color: _lat != null
                          ? AppColors.brandYellow
                          : AppColors.textMuted,
                      size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _lat != null
                          ? (_addr ?? '${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}')
                          : '지도에서 위치 선택',
                      style: TextStyle(
                          color: _lat != null
                              ? AppColors.textPrimary
                              : AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _label('인증 반경'),
          Row(
            children: [
              Expanded(
                child: Slider(
                  min: 30,
                  max: 500,
                  divisions: 47,
                  value: _radius.toDouble(),
                  activeColor: AppColors.brandYellow,
                  inactiveColor: AppColors.borderDefault,
                  onChanged: (v) => setState(() => _radius = v.round()),
                ),
              ),
              SizedBox(
                width: 60,
                child: Text('${_radius}m',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.notoSansKr(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brandYellow)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandYellow,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _canSubmit() && !_busy ? _submit : null,
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black))
                  : Text('등록',
                      style: GoogleFonts.notoSansKr(
                          fontSize: 16, fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }

  bool _canSubmit() => _name.text.trim().isNotEmpty && _lat != null;

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인이 필요합니다')),
        );
        return;
      }
      await ref.read(routineServiceProvider).createRoutine(
            userId: userId,
            name: _name.text.trim(),
            lat: _lat!,
            lng: _lng!,
            radiusM: _radius,
          );
      if (mounted) {
        widget.onCreated();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('등록 실패: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _label(String s) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(s,
            style: GoogleFonts.notoSansKr(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700)),
      );
}
