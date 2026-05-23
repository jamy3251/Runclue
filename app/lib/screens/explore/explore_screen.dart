import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../providers/clue_provider.dart';
import '../../providers/profile_provider.dart';
import '../../services/location_service.dart';
import '../../utils/clue_helpers.dart';
import '../../widgets/clue_card.dart';
import '../../widgets/common/category_filter_tabs.dart';
import '../../widgets/common/earnings_notification_banner.dart';

enum _SortMode { popular, distance, reward, deadline }

/// Screen 03 · 탐색 / ClueList — 명세 v2.0 §4.3
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() =>
      _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  int _selectedCategory = 0;
  _SortMode _sortMode = _SortMode.popular;
  String _searchQuery = '';
  Timer? _searchDebounce;
  final _searchController = TextEditingController();

  // 거리 기반 검색
  double? _distanceFilterKm; // null = 전체, 1, 3, 5, 10
  Position? _userPosition;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _maybeFetchLocation();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _maybeFetchLocation() async {
    if (_userPosition != null || _isLoadingLocation) return;
    setState(() => _isLoadingLocation = true);
    try {
      final svc = LocationService();
      await svc.requestPermission();
      final pos = await svc.getCurrentPosition();
      if (mounted) {
        setState(() {
          _userPosition = pos;
          _isLoadingLocation = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _searchQuery = value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final cluesAsync = _searchQuery.isNotEmpty
        ? ref.watch(clueSearchProvider(_searchQuery))
        : ref.watch(trendingCluesProvider);

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        bottom: false, // 바텀 nav가 안쪽에서 처리
        child: RefreshIndicator(
          color: AppColors.brandYellow,
          backgroundColor: AppColors.bgElevated,
          onRefresh: () async {
            ref.invalidate(trendingCluesProvider);
            if (_searchQuery.isNotEmpty) {
              ref.invalidate(clueSearchProvider(_searchQuery));
            }
          },
          child: CustomScrollView(
            slivers: [
              // 긴급 수익 알림 배너
              SliverPersistentHeader(
                pinned: true,
                delegate: _PinnedHeaderDelegate(
                  height: 36,
                  child: ref.watch(myProfileProvider).when(
                        data: (profile) {
                          if (profile == null) return const SizedBox.shrink();
                          final name = profile['nickname'] ??
                              profile['display_name'] ??
                              '탐험가';
                          return EarningsNotificationBanner(
                            userName: name,
                            amount: '₩18,000',
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                ),
              ),

              // 헤더 + 검색바
              SliverToBoxAdapter(child: _buildSearchHeader()),

              // 카테고리 탭
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: CategoryFilterTabs(
                    tabs: const [
                      FilterTab(label: '전체', icon: Icons.local_fire_department),
                      FilterTab(label: '실시간', icon: Icons.radio),
                      FilterTab(label: '탐험', icon: Icons.explore),
                      FilterTab(label: '퀴즈', icon: Icons.help_outline),
                      FilterTab(label: '카페·맛집', icon: Icons.coffee),
                      FilterTab(label: '근처', icon: Icons.location_on),
                    ],
                    selectedIndex: _selectedCategory,
                    onSelected: (i) {
                      setState(() => _selectedCategory = i);
                      // "근처" 탭이면 위치 권한 요청
                      if (i == 5) _maybeFetchLocation();
                    },
                  ),
                ),
              ),

              // 거리 필터 chips
              SliverToBoxAdapter(child: _buildDistanceChips()),

              // 정렬 탭
              SliverToBoxAdapter(child: _buildSortTabs()),

            // 미션 카드 리스트
            cluesAsync.when(
              data: (clues) {
                final filtered = _applyFilter(clues);
                if (filtered.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(
                      query: _searchQuery,
                      onCreate: () => context.push('/create'),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final clue = filtered[index];
                        final dist = _distanceToClue(clue);
                        return ClueCard(
                          title: clue['title'] ?? '제목 없음',
                          creatorName: clueCreatorName(clue),
                          category: clue['category'] ?? '탐험',
                          locationText:
                              clue['location_name'] ?? clue['address'] ?? '위치 미설정',
                          participantCount: clue['current_participants'] ?? 0,
                          thumbnailUrl: clue['thumbnail_url'],
                          rewardText: clue['reward_value'] != null
                              ? '₩${clue['reward_value']}'
                              : null,
                          statusBadge: clue['status'] == 'active'
                              ? 'LIVE'
                              : null,
                          progressPercent: _progressOf(clue),
                          distanceText:
                              dist != null ? '${dist.toStringAsFixed(1)}km' : null,
                          onTap: () => context.push('/clue/${clue['id']}'),
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.brandYellow,
                  ),
                ),
              ),
              error: (_, __) => SliverFillRemaining(
                hasScrollBody: false,
                child: _ErrorState(
                  onRetry: () => ref.invalidate(trendingCluesProvider),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
      // FAB가 바텀 nav에 안 가리도록 위로 띄움
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: _buildFab(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // ─────────────────────── 거리 필터 chips ───────────────────────
  Widget _buildDistanceChips() {
    if (_selectedCategory != 5 && _distanceFilterKm == null) {
      // "근처" 탭이 아니고 거리 필터도 안 켰으면 숨김
      return const SizedBox.shrink();
    }
    final options = const [
      (null, '전체'),
      (1.0, '1km'),
      (3.0, '3km'),
      (5.0, '5km'),
      (10.0, '10km'),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Icon(
            _userPosition != null ? Icons.my_location : Icons.location_off,
            size: 14,
            color: _userPosition != null
                ? AppColors.brandGreen
                : AppColors.textMuted,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: options.map((opt) {
                  final selected = _distanceFilterKm == opt.$1;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () async {
                        if (_userPosition == null) await _maybeFetchLocation();
                        setState(() => _distanceFilterKm = opt.$1);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.brandYellow.withValues(alpha: 0.15)
                              : AppColors.bgSurface,
                          borderRadius: BorderRadius.circular(9999),
                          border: Border.all(
                            color: selected
                                ? AppColors.brandYellow
                                : AppColors.borderDefault,
                          ),
                        ),
                        child: Text(
                          opt.$2,
                          style: GoogleFonts.notoSansKr(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? AppColors.brandYellow
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          if (_isLoadingLocation)
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: AppColors.brandYellow,
              ),
            ),
        ],
      ),
    );
  }

  /// 클루까지 거리(km). lat/lng·_userPosition 둘 중 하나라도 없으면 null
  double? _distanceToClue(Map<String, dynamic> clue) {
    final pos = _userPosition;
    if (pos == null) return null;
    final lat = (clue['lat'] as num?)?.toDouble();
    final lng = (clue['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;
    final meters = Geolocator.distanceBetween(
      pos.latitude,
      pos.longitude,
      lat,
      lng,
    );
    return meters / 1000.0;
  }

  // ─────────────────────── 검색 헤더 ───────────────────────
  Widget _buildSearchHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '탐색',
            style: GoogleFonts.blackHanSans(
              fontSize: 28,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderDefault),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.search,
                    color: AppColors.textMuted, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: GoogleFonts.notoSansKr(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: '어떤 가게를 방문해볼까요?',
                      hintStyle: GoogleFonts.notoSansKr(
                        fontSize: 14,
                        color: AppColors.textDisabled,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                    child: const Icon(Icons.close,
                        color: AppColors.textMuted, size: 18),
                  )
                else
                  const Icon(Icons.tune,
                      color: AppColors.textMuted, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────── 정렬 탭 ───────────────────────
  Widget _buildSortTabs() {
    final tabs = const [
      ('인기순', _SortMode.popular),
      ('거리순', _SortMode.distance),
      ('상금순', _SortMode.reward),
      ('마감순', _SortMode.deadline),
    ];
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.borderDefault),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: tabs
            .map(
              (t) => Padding(
                padding: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: () => setState(() => _sortMode = t.$2),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _sortMode == t.$2
                              ? AppColors.brandYellow
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      t.$1,
                      style: GoogleFonts.notoSansKr(
                        fontSize: 13,
                        color: _sortMode == t.$2
                            ? AppColors.brandYellow
                            : AppColors.textDisabled,
                        fontWeight: _sortMode == t.$2
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // ─────────────────────── FAB ───────────────────────
  Widget _buildFab() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppGradients.ctaYellow,
        boxShadow: [
          BoxShadow(
            color: AppColors.brandYellow.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          context.push('/create');
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add, color: Colors.black, size: 28),
      ),
    );
  }

  // ─────────────────────── 헬퍼 ───────────────────────
  List<Map<String, dynamic>> _applyFilter(List<Map<String, dynamic>> clues) {
    Iterable<Map<String, dynamic>> result = clues;

    // 만료된 클루 자동 숨김 (ends_at 이 과거이면 제외).
    // null 이면 무기한이라 통과.
    final now = DateTime.now();
    result = result.where((c) {
      final endsAt = c['ends_at'];
      if (endsAt == null) return true;
      final dt = DateTime.tryParse(endsAt.toString());
      if (dt == null) return true;
      return dt.isAfter(now);
    });

    // 카테고리 필터 (간단 매핑 — 0:전체, 5:근처)
    if (_selectedCategory == 1) {
      result = result.where((c) => c['status'] == 'active');
    } else if (_selectedCategory == 2) {
      result = result.where((c) => (c['category'] ?? '').toString().contains('탐험'));
    } else if (_selectedCategory == 3) {
      result = result.where((c) => (c['category'] ?? '').toString().contains('퀴즈'));
    } else if (_selectedCategory == 4) {
      result = result.where(
          (c) => (c['category'] ?? '').toString().contains('카페'));
    } else if (_selectedCategory == 5) {
      // 근처 탭은 lat/lng가 있는 클루만
      result = result.where((c) =>
          (c['lat'] as num?) != null && (c['lng'] as num?) != null);
    }

    // 거리 필터 — 사용자 위치 + 클루 lat/lng 둘 다 있어야 적용
    if (_distanceFilterKm != null && _userPosition != null) {
      final pos = _userPosition!;
      final maxKm = _distanceFilterKm!;
      result = result.where((c) {
        final lat = (c['lat'] as num?)?.toDouble();
        final lng = (c['lng'] as num?)?.toDouble();
        if (lat == null || lng == null) return false;
        final m = Geolocator.distanceBetween(
            pos.latitude, pos.longitude, lat, lng);
        return m <= maxKm * 1000;
      });
    }

    final list = result.toList();
    switch (_sortMode) {
      case _SortMode.popular:
        list.sort((a, b) => ((b['current_participants'] ?? 0) as int)
            .compareTo((a['current_participants'] ?? 0) as int));
        break;
      case _SortMode.distance:
        if (_userPosition != null) {
          final pos = _userPosition!;
          double distOf(Map<String, dynamic> c) {
            final lat = (c['lat'] as num?)?.toDouble();
            final lng = (c['lng'] as num?)?.toDouble();
            if (lat == null || lng == null) return 9e9;
            return Geolocator.distanceBetween(
                pos.latitude, pos.longitude, lat, lng);
          }
          list.sort((a, b) => distOf(a).compareTo(distOf(b)));
        } else {
          // 사용자 위치 없으면 lat/lng 있는 것 우선
          list.sort((a, b) {
            final aHas = a['lat'] != null ? 0 : 1;
            final bHas = b['lat'] != null ? 0 : 1;
            return aHas.compareTo(bHas);
          });
        }
        break;
      case _SortMode.reward:
        // reward_value는 DB에서 text 타입이라 String으로 옴 — num 캐스트 시 TypeError → white screen.
        num parseReward(dynamic v) {
          if (v == null) return 0;
          if (v is num) return v;
          return num.tryParse(v.toString()) ?? 0;
        }
        list.sort((a, b) => parseReward(b['reward_value'])
            .compareTo(parseReward(a['reward_value'])));
        break;
      case _SortMode.deadline:
        list.sort((a, b) {
          final ea = a['ends_at']?.toString() ?? '9999';
          final eb = b['ends_at']?.toString() ?? '9999';
          return ea.compareTo(eb);
        });
        break;
    }
    return list;
  }

  double? _progressOf(Map<String, dynamic> clue) {
    final cur = clue['current_participants'];
    final max = clue['max_participants'];
    if (cur is num && max is num && max > 0) {
      return (cur / max).clamp(0.0, 1.0);
    }
    return null;
  }
}

// ─────────────────────────────────────────────────────────────
// 빈 상태 / 에러 상태
// ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String query;
  final VoidCallback onCreate;

  const _EmptyState({required this.query, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            query.isNotEmpty ? Icons.search_off : Icons.explore_off,
            size: 56,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            query.isNotEmpty
                ? '"$query"에 해당하는 클루가 없어요'
                : '아직 미션이 없어요',
            style: GoogleFonts.notoSansKr(
              fontSize: 15,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '새로 만들어보세요!',
            style: GoogleFonts.notoSansKr(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('클루 만들기'),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off, size: 56, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(
            '미션을 불러올 수 없습니다',
            style: GoogleFonts.notoSansKr(
              fontSize: 15,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '네트워크 연결을 확인해주세요',
            style: GoogleFonts.notoSansKr(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Sticky Header Delegate (수익 알림 배너용)
// ─────────────────────────────────────────────────────────────

class _PinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;

  _PinnedHeaderDelegate({required this.height, required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.bgBase,
      child: child,
    );
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant _PinnedHeaderDelegate old) =>
      old.child != child;
}
