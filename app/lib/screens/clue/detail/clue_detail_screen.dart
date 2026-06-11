import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/supabase_safe.dart';
import '../../../config/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/clue_provider.dart';
import '../../../providers/participation_provider.dart';
import '../../../providers/recommendation_provider.dart';
import '../../../services/clue_service.dart';
import '../../../services/deep_link_service.dart';
import '../../../services/report_service.dart';
import '../../../utils/clue_helpers.dart';
import '../../../widgets/common/error_widget.dart' as app;
import '../../../widgets/common/loading_widget.dart';
import '../../../widgets/step_type_icon.dart';

/// Screen 06 · 클루 상세 — 명세 v2.0 §4.6
class ClueDetailScreen extends ConsumerStatefulWidget {
  final String clueId;

  const ClueDetailScreen({super.key, required this.clueId});

  @override
  ConsumerState<ClueDetailScreen> createState() => _ClueDetailScreenState();
}

class _ClueDetailScreenState extends ConsumerState<ClueDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController =
      TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _confirmDeleteClue() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgElevated,
        title: const Text('클루를 삭제할까요?',
            style: TextStyle(color: AppColors.textPrimary),),
        content: const Text(
          '삭제하면 참여 중인 사람들도 더 이상 진행할 수 없어요. 되돌릴 수 없습니다.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제',
                style: TextStyle(color: AppColors.brandRed),),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ClueService().deleteClue(widget.clueId);
      ref.invalidate(clueDetailProvider(widget.clueId));
      ref.invalidate(trendingCluesProvider);
      ref.invalidate(myCluesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('클루 삭제 완료')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clueAsync = ref.watch(clueDetailProvider(widget.clueId));

    return clueAsync.when(
      loading: () => const Scaffold(body: LoadingWidget()),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: app.AppErrorWidget(
          message: '클루를 불러올 수 없습니다',
          onRetry: () =>
              ref.invalidate(clueDetailProvider(widget.clueId)),
        ),
      ),
      data: (clue) {
        if (clue == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('클루를 찾을 수 없습니다')),
          );
        }
        return _buildScaffold(clue);
      },
    );
  }

  Widget _buildScaffold(Map<String, dynamic> clue) {
    final steps =
        (clue['steps'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
            [];
    final status = (clue['status'] ?? '').toString();
    final isActive = status == 'active';

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          _buildHeroHeader(clue),
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyTabsDelegate(controller: _tabController),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildCompositionTab(clue, steps),
            _buildMapTab(clue),
            _buildReviewTab(clue),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomCta(clue, isActive),
    );
  }

  // ─────────────────────── 히어로 헤더 ───────────────────────
  SliverAppBar _buildHeroHeader(Map<String, dynamic> clue) {
    final title = clue['title'] ?? '미션';
    final category = clue['category'] ?? '탐험';
    final status = (clue['status'] ?? '').toString();
    final thumb = clue['thumbnail_url'] as String?;

    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: AppColors.bgBase,
      foregroundColor: AppColors.textPrimary,
      leading: _CircleIconButton(
        icon: Icons.arrow_back,
        onTap: () => context.pop(),
      ),
      actions: [
        _CircleIconButton(
          icon: Icons.share,
          onTap: () => DeepLinkService.shareClue(
            clueId: widget.clueId,
            clueTitle: title,
          ),
        ),
        Builder(builder: (_) {
          final myId = ref.watch(currentUserIdProvider);
          final isCreator = myId != null && myId == clue['creator_id'];
          return PopupMenuButton<String>(
            icon: const _CircleIconButton(
              icon: Icons.more_vert,
              onTap: null,
            ),
            color: AppColors.bgElevated,
            onSelected: (value) {
              if (value == 'report') _showReportDialog();
              if (value == 'delete') _confirmDeleteClue();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag, color: AppColors.brandRed, size: 18),
                    SizedBox(width: 8),
                    Text('신고하기'),
                  ],
                ),
              ),
              if (isCreator)
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline,
                          color: AppColors.brandRed, size: 18,),
                      SizedBox(width: 8),
                      Text('클루 삭제', style: TextStyle(color: AppColors.brandRed)),
                    ],
                  ),
                ),
            ],
          );
        },),
        const SizedBox(width: 4),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (thumb != null)
              Image.network(
                thumb,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.bgSurface,
                  child: const Center(
                    child: Icon(Icons.image,
                        size: 64, color: AppColors.textMuted,),
                  ),
                ),
              )
            else
              Container(color: AppColors.bgSurface),
            // overlay gradient
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    AppColors.bgBase.withValues(alpha: 0.95),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            // 제목 + 배지 영역
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _Badge(
                        label: category,
                        color: AppColors.brandBlue,
                      ),
                      const SizedBox(width: 6),
                      _Badge(
                        label: _statusLabel(status),
                        color: _statusColor(status),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: GoogleFonts.blackHanSans(
                      fontSize: 24,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Builder(builder: (_) {
                        final name = clueCreatorName(clue);
                        final avatar = clueCreatorAvatarUrl(clue);
                        final roleLabel = clueCreatorRoleLabel(clue);
                        return Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: AppColors.bgElevated,
                              backgroundImage: avatar != null
                                  ? NetworkImage(avatar)
                                  : null,
                              child: avatar == null
                                  ? Text(
                                      name.substring(0, 1),
                                      style: GoogleFonts.notoSansKr(
                                        fontSize: 11,
                                        color: AppColors.textPrimary,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2,),
                              decoration: BoxDecoration(
                                color: AppColors.brandYellow.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                roleLabel,
                                style: GoogleFonts.notoSansKr(
                                  fontSize: 10,
                                  color: AppColors.brandYellow,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '@$name',
                              style: GoogleFonts.notoSansKr(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        );
                      },),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────── 미션 구성 탭 ───────────────────────
  Widget _buildCompositionTab(
      Map<String, dynamic> clue, List<Map<String, dynamic>> steps,) {
    final reward = clue['reward_value']?.toString() ?? '';
    final participants = clue['participant_count'] ?? 0;
    final maxParticipants = clue['max_participants'];
    final endsAt = clue['ends_at'] as String?;
    final progress =
        (maxParticipants is num && maxParticipants > 0 && participants is num)
            ? (participants / maxParticipants).clamp(0.0, 1.0)
            : 0.0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        // 통계 카드 3개
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.payments_outlined,
                value: reward.isNotEmpty ? '₩$reward' : '—',
                label: '총 상금',
                color: AppColors.brandYellow,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                icon: Icons.people_outline,
                value: maxParticipants != null
                    ? '$participants/$maxParticipants'
                    : '$participants명',
                label: '참여 중',
                color: AppColors.brandBlue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                icon: Icons.timer_outlined,
                value: _formatRemaining(endsAt),
                label: '마감',
                color: AppColors.brandOrange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // 진행도 바
        if (maxParticipants != null) ...[
          Row(
            children: [
              Text(
                '전체 진행도',
                style: GoogleFonts.notoSansKr(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '현재 $participants명 참여',
                style: GoogleFonts.notoSansKr(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: SizedBox(
              height: 6,
              child: Stack(
                children: [
                  Container(color: AppColors.borderDefault),
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: AppGradients.progress,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // 설명
        if ((clue['description'] ?? '').toString().isNotEmpty) ...[
          Text(
            '소개',
            style: GoogleFonts.notoSansKr(
              fontSize: 16,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            clue['description'],
            style: GoogleFonts.notoSansKr(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
        ],

        // 단계별 타임라인
        Text(
          '미션 단계 (${steps.length})',
          style: GoogleFonts.notoSansKr(
            fontSize: 16,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        if (steps.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Text(
              '아직 등록된 단계가 없습니다',
              style: GoogleFonts.notoSansKr(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          )
        else
          ..._buildTimeline(steps),
      ],
    );
  }

  List<Widget> _buildTimeline(List<Map<String, dynamic>> steps) {
    return List.generate(steps.length, (i) {
      final step = steps[i];
      final isLast = i == steps.length - 1;
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 원형 + 세로선
            SizedBox(
              width: 40,
              child: Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.brandYellow.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${i + 1}',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 12,
                        color: AppColors.brandYellow,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: AppColors.borderDefault,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderDefault),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          StepTypeIcon(stepType: step['type'] ?? ''),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              step['title'] ?? 'Step ${i + 1}',
                              style: GoogleFonts.notoSansKr(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          _Badge(
                            label: _stepTypeLabel(step['type']),
                            color: AppColors.brandPurple,
                            small: true,
                          ),
                        ],
                      ),
                      if ((step['description'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          step['description'],
                          style: GoogleFonts.notoSansKr(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // ─────────────────────── 지도 탭 ───────────────────────
  Widget _buildMapTab(Map<String, dynamic> clue) {
    final locationName = clue['location_name'] ?? '';
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          height: 280,
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderDefault),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.map_outlined,
                  size: 48, color: AppColors.textMuted,),
              const SizedBox(height: 12),
              Text(
                '체크포인트 위치',
                style: GoogleFonts.notoSansKr(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '참여 후 지도에서 확인 가능',
                style: GoogleFonts.notoSansKr(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (locationName.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on,
                    color: AppColors.brandYellow, size: 20,),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    locationName,
                    style: GoogleFonts.notoSansKr(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        _buildSameDistrictSection(),
      ],
    );
  }

  // ─────────────────────── 이 동네 다른 클루 ───────────────────────
  Widget _buildSameDistrictSection() {
    final async = ref.watch(sameDistrictProvider(widget.clueId));
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (clues) {
        if (clues.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.near_me,
                    color: AppColors.brandYellow, size: 18,),
                const SizedBox(width: 6),
                Text(
                  '이 동네 다른 클루',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '· 1km 이내 ${clues.length}개',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...clues.map((c) {
              final dist = (c['distance_m'] as num?)?.toInt() ?? 0;
              return GestureDetector(
                onTap: () => context.push('/clue/${c['id']}'),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderDefault),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 56,
                          height: 56,
                          child: c['thumbnail_url'] != null
                              ? Image.network(
                                  c['thumbnail_url'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: AppColors.bgElevated,
                                    child: const Icon(Icons.image_not_supported,
                                        color: AppColors.textMuted, size: 20,),
                                  ),
                                )
                              : Container(
                                  color: AppColors.bgElevated,
                                  child: const Icon(Icons.explore,
                                      color: AppColors.textMuted, size: 20,),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c['title'] ?? '미션',
                              style: GoogleFonts.notoSansKr(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on,
                                    size: 11, color: AppColors.textMuted,),
                                const SizedBox(width: 2),
                                Text(
                                  '${dist}m · ${c['location_name'] ?? '위치'}',
                                  style: GoogleFonts.notoSansKr(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (c['reward_value'] != null)
                        Text(
                          '₩${c['reward_value']}',
                          style: GoogleFonts.notoSansKr(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: AppColors.brandYellow,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  // ─────────────────────── 리뷰 탭 ───────────────────────
  Widget _buildReviewTab(Map<String, dynamic> clue) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.rate_review_outlined,
                size: 56, color: AppColors.textMuted,),
            const SizedBox(height: 12),
            Text(
              '아직 리뷰가 없어요',
              style: GoogleFonts.notoSansKr(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '첫 후기를 남겨보세요',
              style: GoogleFonts.notoSansKr(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────── 하단 CTA ───────────────────────
  Widget _buildBottomCta(Map<String, dynamic> clue, bool isActive) {
    final ended = clue['status'] == 'completed' ||
        clue['status'] == 'suspended';
    final maxParticipants = clue['max_participants'];
    final participants = clue['participant_count'] ?? 0;
    final remaining = (maxParticipants is num)
        ? (maxParticipants - participants).toInt()
        : null;
    final isUrgent = remaining != null && remaining <= 5 && remaining > 0;

    // 기존 참여 여부 확인 — "지금 참여" vs "이어서 하기" 분기
    final participationAsync =
        ref.watch(currentParticipationProvider(widget.clueId));
    final existing = participationAsync.valueOrNull;
    final inProgress = existing != null &&
        (existing['status'] == 'in_progress' || existing['status'] == null);
    final completed = existing != null && existing['status'] == 'completed';
    final inLobby = existing != null && existing['status'] == 'in_lobby';

    // ── 그룹 미션 #15 + versus #23 ──
    // coop/versus 클루의 모집/진행 상태는 5초 polling으로 받음 — clue raw 값보다 신선함.
    final gameMode = (clue['game_mode'] ?? 'solo') as String;
    final isLobbyMode = gameMode == 'coop' || gameMode == 'versus';
    final isVersus = gameMode == 'versus';
    final coopAsync = isLobbyMode
        ? ref.watch(coopStateProvider(widget.clueId))
        : const AsyncValue<Map<String, dynamic>?>.data(null);
    final coopRow = coopAsync.valueOrNull;
    final coopState = (coopRow?['coop_state'] ?? clue['coop_state'] ?? 'idle')
        as String;
    final minP =
        (coopRow?['min_participants'] ?? clue['min_participants'] ?? 1) as int;
    final curP = (coopRow?['current_participants'] ??
        clue['current_participants'] ??
        0) as int;
    final lobbyOpen =
        isLobbyMode && (coopState == 'idle' || coopState == 'recruiting');
    final coopStarted = isLobbyMode && coopState == 'started';
    final coopCancelled = isLobbyMode && coopState == 'cancelled';
    // 호환: 기존 isCoop을 참조하는 코드 흐름 유지
    final isCoop = isLobbyMode;

    String label;
    IconData icon;
    if (ended || coopCancelled) {
      label = coopCancelled
          ? (isVersus ? '대결 모집이 취소되었습니다' : '그룹 모집이 취소되었습니다')
          : '이미 마감된 미션입니다';
      icon = Icons.lock;
    } else if (completed) {
      label = '이미 완료한 미션 — 결과 보기';
      icon = Icons.check_circle;
    } else if (lobbyOpen && inLobby) {
      label = '모집 대기 중 ($curP/$minP)';
      icon = Icons.hourglass_top;
    } else if (lobbyOpen) {
      label = isVersus
          ? '⚔️ 대결 참여 ($curP/$minP)'
          : '함께 모집 참여 ($curP/$minP)';
      icon = isVersus ? Icons.flag : Icons.group_add;
    } else if (coopStarted && inLobby) {
      // 자동 시작 직후 상태 — 진입 가능
      label = isVersus ? '⚔️ 대결 시작!' : '🎉 모집 완료! 시작하기';
      icon = Icons.play_arrow;
    } else if (inProgress) {
      label = '이어서 하기';
      icon = Icons.play_arrow;
    } else if (coopStarted && !inLobby && !inProgress) {
      label = '이미 시작된 그룹 — 참여 불가';
      icon = Icons.lock;
    } else {
      label = '지금 참여하기';
      icon = Icons.location_on;
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 그룹 미션 #15 — lobby 게이지
            if (isCoop && (lobbyOpen || (coopStarted && inLobby))) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8,),
                decoration: BoxDecoration(
                  color: AppColors.brandBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.brandBlue.withValues(alpha: 0.3),),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          coopStarted
                              ? (isVersus ? '⚔️ 대결 시작' : '🎉 모집 완료')
                              : (isVersus ? '⚔️ 1등 독식 대결 모집 중' : '👥 함께 모집 중'),
                          style: GoogleFonts.notoSansKr(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.brandBlue,
                          ),
                        ),
                        Text(
                          '$curP / $minP 명',
                          style: GoogleFonts.notoSansKr(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.brandBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: minP <= 0 ? 0 : (curP / minP).clamp(0.0, 1.0),
                        backgroundColor:
                            AppColors.brandBlue.withValues(alpha: 0.15),
                        valueColor: const AlwaysStoppedAnimation(
                            AppColors.brandBlue,),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (inProgress) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4,),
                decoration: BoxDecoration(
                  color: AppColors.brandGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '● 참여 중',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 11,
                    color: AppColors.brandGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ] else if (isUrgent) ...[
              Text(
                '선착순 $remaining자리 남음',
                style: GoogleFonts.notoSansKr(
                  fontSize: 12,
                  color: AppColors.brandRed,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
            ],
            SizedBox(
              height: 56,
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: ended ? null : AppGradients.ctaYellow,
                  color: ended ? AppColors.bgElevated : null,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: ended ? null : const [AppShadows.ctaYellow],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: (ended || coopCancelled)
                        ? null
                        : (coopStarted && !inLobby && !inProgress)
                            ? null
                            : (lobbyOpen && inLobby)
                                ? null
                                : (lobbyOpen)
                                    ? () => _onJoinCoop(clue)
                                    : (coopStarted && inLobby)
                                        ? () => context.push(
                                            '/clue/${widget.clueId}/play',)
                                        : (inProgress || completed)
                                            ? () => context.push(
                                                '/clue/${widget.clueId}/play',)
                                            : () => _onJoin(clue),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            icon,
                            size: 18,
                            color:
                                ended ? AppColors.textMuted : Colors.black,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            label,
                            style: GoogleFonts.notoSansKr(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: ended
                                  ? AppColors.textMuted
                                  : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 그룹 미션 #15 — coop lobby 참여. RPC join_coop_clue 호출.
  /// 임계값 도달 시 서버가 자동으로 모든 lobby 참여자를 in_progress로 전환.
  Future<void> _onJoinCoop(Map<String, dynamic> clue) async {
    HapticFeedback.mediumImpact();
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다')),
      );
      context.go('/auth');
      return;
    }
    try {
      final service = ref.read(participationServiceProvider);
      final result = await service.joinCoop(widget.clueId);
      final ok = result['ok'] == true;
      if (!ok) {
        if (mounted) {
          final reason = result['reason']?.toString() ?? 'unknown';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('참여 실패: $reason')),
          );
        }
        return;
      }
      ref.invalidate(currentParticipationProvider(widget.clueId));
      ref.invalidate(coopStateProvider(widget.clueId));
      ref.invalidate(myParticipationsProvider);
      if (!mounted) return;
      final started = result['started'] == true;
      HapticFeedback.heavyImpact();
      if (started) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 모집 완료! 시작합니다'),
            duration: Duration(seconds: 1),
            backgroundColor: AppColors.brandGreen,
          ),
        );
        context.push('/clue/${widget.clueId}/play');
      } else {
        final cur = result['current'];
        final tgt = result['target'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ 모집 대기 중 ($cur/$tgt)'),
            duration: const Duration(seconds: 2),
            backgroundColor: AppColors.brandBlue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('네트워크 오류: $e')),
        );
      }
    }
  }

  Future<void> _onJoin(Map<String, dynamic> clue) async {
    HapticFeedback.mediumImpact();
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다')),
      );
      context.go('/auth');
      return;
    }
    try {
      final service = ref.read(participationServiceProvider);
      final participation =
          await service.joinClue(clueId: widget.clueId, userId: userId);
      // ID 검증 — joinClue가 빈 응답이거나 RLS로 막혔을 때 대비
      if (participation['id'] == null) {
        throw Exception('참여 응답에 ID 없음 — DB 권한 또는 RLS 문제 의심');
      }
      ref.invalidate(myParticipationsProvider);
      ref.invalidate(currentParticipationProvider(widget.clueId));
      if (mounted) {
        // 햅틱 + 토스트로 진행 신호
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 참여 시작! 미션 화면으로 이동합니다'),
            duration: Duration(seconds: 1),
            backgroundColor: AppColors.brandGreen,
          ),
        );
        context.push('/clue/${widget.clueId}/play');
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error_outline, color: AppColors.brandRed),
                SizedBox(width: 8),
                Text('참여 실패'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  e.toString(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.brandRed,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '💡 PGRST204 = participations 테이블 컬럼 누락 → STEP 0 SQL 실행\n'
                  '💡 23503 = clue_id 외래키 위반 → 클루가 진짜 존재하는지 확인\n'
                  '💡 401/403 = RLS 차단 → ALTER TABLE participations DISABLE ROW LEVEL SECURITY',
                  style: TextStyle(fontSize: 11, color: AppColors.brandBlue, height: 1.5),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('닫기'),
              ),
            ],
          ),
        );
      }
    }
  }

  // ─────────────────────── 신고 다이얼로그 ───────────────────────
  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('신고하기'),
        content: const Text('이 클루를 신고하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final userId = safeClient.auth.currentUser?.id;
                if (userId == null) return;
                await ReportService().submitReport(
                  reporterId: userId,
                  targetType: 'clue',
                  targetId: widget.clueId,
                  reason: 'other',
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('신고가 접수되었습니다')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('신고 실패: $e')),
                  );
                }
              }
            },
            child: const Text('신고'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────── 헬퍼 ───────────────────────
  String _statusLabel(String status) => switch (status) {
        'active' => '모집중',
        'draft' => '초안',
        'pending' => '승인대기',
        'completed' => '완료',
        'suspended' => '중지됨',
        _ => status,
      };

  Color _statusColor(String status) => switch (status) {
        'active' => AppColors.brandGreen,
        'pending' => AppColors.brandOrange,
        'completed' => AppColors.brandBlue,
        'suspended' => AppColors.brandRed,
        _ => AppColors.textMuted,
      };

  String _stepTypeLabel(dynamic type) => switch ('$type') {
        'CHECKPOINT' => 'GPS 인증',
        'SNAPSHOT' => '카메라 인증',
        'QUEST' => '정답 입력',
        'OX_QUIZ' => 'OX 퀴즈',
        'LIST' => '체크리스트',
        _ => '미션',
      };

  String _formatRemaining(String? endsAt) {
    if (endsAt == null) return '제한 없음';
    try {
      final dt = DateTime.parse(endsAt);
      final now = DateTime.now();
      final diff = dt.difference(now);
      if (diff.isNegative) return '마감';
      if (diff.inDays > 0) return 'D-${diff.inDays}';
      if (diff.inHours > 0) return '${diff.inHours}h';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m';
      return '곧 마감';
    } catch (_) {
      return '—';
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Sticky Tab Bar
// ─────────────────────────────────────────────────────────────

class _StickyTabsDelegate extends SliverPersistentHeaderDelegate {
  final TabController controller;
  _StickyTabsDelegate({required this.controller});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.bgBase,
      child: TabBar(
        controller: controller,
        indicatorColor: AppColors.brandYellow,
        indicatorWeight: 2,
        labelColor: AppColors.brandYellow,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle: GoogleFonts.notoSansKr(
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.notoSansKr(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: '미션 구성'),
          Tab(text: '지도 보기'),
          Tab(text: '리뷰'),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 46;

  @override
  double get minExtent => 46;

  @override
  bool shouldRebuild(covariant _StickyTabsDelegate oldDelegate) =>
      oldDelegate.controller != controller;
}

// ─────────────────────────────────────────────────────────────
// 서브 위젯
// ─────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final bool small;

  const _Badge({
    required this.label,
    required this.color,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 8,
        vertical: small ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(small ? 4 : 6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: GoogleFonts.notoSansKr(
          fontSize: small ? 9 : 11,
          color: color,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          FittedBox(
            child: Text(
              value,
              style: GoogleFonts.notoSansKr(
                fontSize: 18,
                color: AppColors.brandYellow,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.notoSansKr(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _CircleIconButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Material(
        color: Colors.black.withValues(alpha: 0.4),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }
}
