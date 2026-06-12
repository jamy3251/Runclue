import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import 'clan_war_screen.dart' show clanServiceProvider, myClanProvider;

final clanDetailProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, clanId) async {
  return ref.watch(clanServiceProvider).clanById(clanId);
});

final clanMembersProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, clanId) async {
  return ref.watch(clanServiceProvider).clanMembers(clanId);
});

final clanMessagesProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, clanId) {
  return ref.watch(clanServiceProvider).messageStream(clanId);
});

/// 클랜 상세 — 정보·멤버 탭 + 실시간 채팅 탭 (042).
/// 채팅은 클랜 멤버만 (RLS) — 비멤버는 멤버 목록만 구경 가능.
class ClanDetailScreen extends ConsumerWidget {
  const ClanDetailScreen({super.key, required this.clanId});
  final String clanId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clan = ref.watch(clanDetailProvider(clanId)).valueOrNull;
    final myClan = ref.watch(myClanProvider).valueOrNull;
    final isMember = myClan != null && myClan['id'] == clanId;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.bgBase,
        appBar: AppBar(
          backgroundColor: AppColors.bgElevated,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: Text(clan?['name'] as String? ?? '클랜',
              style: GoogleFonts.blackHanSans(
                  fontSize: 18, color: AppColors.textPrimary,),),
          bottom: TabBar(
            indicatorColor: AppColors.brandYellow,
            labelColor: AppColors.brandYellow,
            unselectedLabelColor: AppColors.textMuted,
            tabs: const [
              Tab(text: '멤버', icon: Icon(Icons.groups, size: 18)),
              Tab(text: '채팅', icon: Icon(Icons.chat_bubble, size: 18)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _MembersTab(clanId: clanId, clan: clan),
            isMember
                ? _ChatTab(clanId: clanId)
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('채팅은 클랜 멤버만 이용할 수 있어요',
                          style: GoogleFonts.notoSansKr(
                              fontSize: 13, color: AppColors.textMuted,),),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _MembersTab extends ConsumerWidget {
  const _MembersTab({required this.clanId, required this.clan});
  final String clanId;
  final Map<String, dynamic>? clan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(clanMembersProvider(clanId));

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(clanMembersProvider(clanId)),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (clan != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppColors.brandYellow.withValues(alpha: 0.14),
                  AppColors.brandOrange.withValues(alpha: 0.06),
                ],),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((clan!['description'] as String?)?.isNotEmpty ==
                      true)
                    Text(clan!['description'] as String,
                        style: GoogleFonts.notoSansKr(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.5,),),
                  const SizedBox(height: 6),
                  Text(
                      '멤버 ${clan!['member_count']} · 누적 ${clan!['total_points']}점',
                      style: GoogleFonts.notoSansKr(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.brandYellow,),),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          Text('멤버 (이번 주 기여순)',
              style: GoogleFonts.notoSansKr(
                  fontSize: 13, fontWeight: FontWeight.w900,),),
          const SizedBox(height: 8),
          members.when(
            loading: () => const Center(
                child: Padding(
              padding: EdgeInsets.all(20),
              child:
                  CircularProgressIndicator(color: AppColors.brandYellow),
            ),),
            error: (e, _) => Text('멤버 로드 실패: $e',
                style: GoogleFonts.notoSansKr(
                    fontSize: 12, color: AppColors.brandRed,),),
            data: (list) => Column(
              children: list.map((m) {
                final profile = m['profiles'] as Map<String, dynamic>?;
                final isLeader = m['role'] == 'leader';
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10,),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor:
                            AppColors.brandYellow.withValues(alpha: 0.2),
                        child: Text(isLeader ? '👑' : '🏃',
                            style: const TextStyle(fontSize: 14)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          profile?['nickname'] as String? ?? '익명',
                          style: GoogleFonts.notoSansKr(
                              fontSize: 13, fontWeight: FontWeight.w700,),
                        ),
                      ),
                      Text('+${m['week_points'] ?? 0}점',
                          style: GoogleFonts.notoSansKr(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: AppColors.brandGreen,),),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatTab extends ConsumerStatefulWidget {
  const _ChatTab({required this.clanId});
  final String clanId;

  @override
  ConsumerState<_ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends ConsumerState<_ChatTab> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;
    setState(() => _sending = true);
    try {
      final profile = await ref.read(currentProfileProvider.future);
      await ref.read(clanServiceProvider).sendMessage(
            clanId: widget.clanId,
            userId: uid,
            nickname: profile?['nickname'] as String? ?? '익명',
            content: text,
          );
      _input.clear();
      HapticFeedback.selectionClick();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('전송 실패: $e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages =
        ref.watch(clanMessagesProvider(widget.clanId)).valueOrNull ??
            const [];
    final myId = ref.watch(currentUserIdProvider);

    // 새 메시지 도착 시 맨 아래로
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });

    return Column(
      children: [
        Expanded(
          child: messages.isEmpty
              ? Center(
                  child: Text('첫 메시지를 남겨보세요! 🛡️',
                      style: GoogleFonts.notoSansKr(
                          fontSize: 13, color: AppColors.textMuted,),),
                )
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final m = messages[i];
                    final mine = m['user_id'] == myId;
                    final ts = DateTime.tryParse(
                        m['created_at'] as String? ?? '',);
                    return Align(
                      alignment: mine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8,),
                        constraints: BoxConstraints(
                          maxWidth:
                              MediaQuery.of(context).size.width * 0.72,
                        ),
                        decoration: BoxDecoration(
                          color: mine
                              ? AppColors.brandYellow
                                  .withValues(alpha: 0.18)
                              : AppColors.bgSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: mine
                                ? AppColors.brandYellow
                                    .withValues(alpha: 0.4)
                                : AppColors.borderDefault,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!mine)
                              Text(m['nickname'] as String? ?? '익명',
                                  style: GoogleFonts.notoSansKr(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.brandBlue,),),
                            Text(m['content'] as String? ?? '',
                                style: GoogleFonts.notoSansKr(
                                    fontSize: 13,
                                    color: AppColors.textPrimary,
                                    height: 1.4,),),
                            if (ts != null)
                              Text(timeago.format(ts, locale: 'ko'),
                                  style: GoogleFonts.notoSansKr(
                                      fontSize: 9,
                                      color: AppColors.textDisabled,),),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            color: AppColors.bgElevated,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    maxLength: 500,
                    style: GoogleFonts.notoSansKr(fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: '메시지 입력...',
                      counterText: '',
                      isDense: true,
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.brandYellow,),)
                      : const Icon(Icons.send,
                          color: AppColors.brandYellow,),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
