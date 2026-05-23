import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/theme.dart';
import '../../providers/clue_provider.dart';
import '../../utils/clue_helpers.dart';
import '../../widgets/clue_card.dart';

/// SharedPreferences key for recent searches.
const _recentSearchesKey = 'recent_searches';

/// Max number of recent searches to store.
const _maxRecentSearches = 10;

/// Hardcoded popular/trending search terms.
const _popularSearches = ['보물찾기', '카페투어', '퀴즈', '동네탐험', '맛집'];

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  Timer? _debounce;
  String _debouncedQuery = '';
  List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _controller.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onSearchChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Recent searches persistence ──────────────────────────

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList(_recentSearchesKey) ?? [];
    });
  }

  Future<void> _addRecentSearch(String query) async {
    if (query.trim().isEmpty) return;
    final trimmed = query.trim();
    _recentSearches.remove(trimmed);
    _recentSearches.insert(0, trimmed);
    if (_recentSearches.length > _maxRecentSearches) {
      _recentSearches = _recentSearches.sublist(0, _maxRecentSearches);
    }
    setState(() {});
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentSearchesKey, _recentSearches);
  }

  Future<void> _removeRecentSearch(String query) async {
    _recentSearches.remove(query);
    setState(() {});
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentSearchesKey, _recentSearches);
  }

  Future<void> _clearRecentSearches() async {
    _recentSearches.clear();
    setState(() {});
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentSearchesKey);
  }

  // ── Debounced search ─────────────────────────────────────

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _debouncedQuery = _controller.text.trim();
        });
      }
    });
  }

  void _submitSearch(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    _controller.text = trimmed;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: trimmed.length),
    );
    _addRecentSearch(trimmed);
    setState(() {
      _debouncedQuery = trimmed;
    });
    _focusNode.unfocus();
  }

  // ── Build ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final hasQuery = _debouncedQuery.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: hasQuery ? _buildSearchResults() : _buildSuggestions(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Search bar ───────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenH,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: true,
              style: GoogleFonts.notoSansKr(
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: '클루 검색...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.textMuted,
                  size: 22,
                ),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                        onPressed: () {
                          _controller.clear();
                          setState(() {
                            _debouncedQuery = '';
                          });
                          _focusNode.requestFocus();
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.bgSurface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: const BorderSide(color: AppColors.borderDefault),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: const BorderSide(color: AppColors.borderDefault),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: BorderSide(
                    color: AppColors.brandYellow.withValues(alpha: 0.5),
                  ),
                ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: _submitSearch,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '취소',
              style: GoogleFonts.notoSansKr(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Suggestions (recent + popular) ───────────────────────

  Widget _buildSuggestions() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
      children: [
        // Recent searches
        if (_recentSearches.isNotEmpty) ...[
          _buildSectionHeader(
            '최근 검색',
            trailing: GestureDetector(
              onTap: _clearRecentSearches,
              child: Text(
                '전체 삭제',
                style: GoogleFonts.notoSansKr(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _recentSearches.map((term) {
              return _SearchChip(
                label: term,
                onTap: () => _submitSearch(term),
                onDelete: () => _removeRecentSearch(term),
                icon: Icons.history,
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],

        // Popular searches
        _buildSectionHeader('인기 검색어'),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: _popularSearches.map((term) {
            return _SearchChip(
              label: term,
              onTap: () => _submitSearch(term),
              icon: Icons.trending_up,
              iconColor: AppColors.brandYellow,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, {Widget? trailing}) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.notoSansKr(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        if (trailing != null) trailing,
      ],
    );
  }

  // ── Search results ───────────────────────────────────────

  Widget _buildSearchResults() {
    final asyncResults = ref.watch(clueSearchProvider(_debouncedQuery));

    return asyncResults.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: AppColors.brandYellow,
          strokeWidth: 2,
        ),
      ),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                '검색 중 오류가 발생했습니다',
                style: GoogleFonts.notoSansKr(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
      data: (results) {
        if (results.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenH,
            vertical: AppSpacing.sm,
          ),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final clue = results[index];
            return ClueCard(
              title: clue['title'] as String? ?? '제목 없음',
              creatorName: clueCreatorName(clue),
              category: clue['category'] as String? ?? '기타',
              locationText: clue['location_text'] as String? ?? '온라인',
              participantCount: clue['participant_count'] as int? ?? 0,
              thumbnailUrl: clue['thumbnail_url'] as String?,
              rewardText: clue['reward_text'] as String?,
              statusBadge: clue['status_badge'] as String?,
              distanceText: clue['distance_text'] as String?,
              onTap: () {
                final id = clue['id'] as String?;
                if (id != null) {
                  Navigator.of(context).pop();
                  // Navigate to clue detail
                  // context.push('/clue/$id');
                }
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '검색 결과가 없습니다',
              style: GoogleFonts.notoSansKr(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '다른 키워드로 검색해 보세요',
              style: GoogleFonts.notoSansKr(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Search chip widget ───────────────────────────────────────

class _SearchChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final IconData icon;
  final Color? iconColor;

  const _SearchChip({
    required this.label,
    required this.onTap,
    this.onDelete,
    required this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: iconColor ?? AppColors.textMuted,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: GoogleFonts.notoSansKr(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
            if (onDelete != null) ...[
              const SizedBox(width: AppSpacing.xs),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(
                  Icons.close,
                  size: 14,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
