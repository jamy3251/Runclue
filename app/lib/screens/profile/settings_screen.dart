import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/supabase_safe.dart';
import '../../config/theme.dart';

/// Generic text content screen for terms, privacy policy, etc.
class TextContentScreen extends StatelessWidget {
  final String title;
  final String content;

  const TextContentScreen({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Text(
          content,
          style: const TextStyle(fontSize: 14, height: 1.8),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Notification Settings — DB 연동
// ─────────────────────────────────────────────────────────────

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  bool _clueUpdates = true;
  bool _communityReplies = true;
  bool _promotions = false;
  bool _clanActivity = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final client = safeClient;
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _loading = false);
        return;
      }
      final row = await client
          .from('profiles')
          .select('notification_settings')
          .eq('id', userId)
          .maybeSingle();
      if (row != null && row['notification_settings'] != null) {
        final s = row['notification_settings'] as Map<String, dynamic>;
        setState(() {
          _clueUpdates = s['clue_updates'] ?? true;
          _communityReplies = s['community_replies'] ?? true;
          _clanActivity = s['clan_activity'] ?? true;
          _promotions = s['promotions'] ?? false;
        });
      }
    } catch (_) {
      // UI preview mode — use defaults
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveSettings() async {
    try {
      final client = safeClient;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;
      await client.from('profiles').update({
        'notification_settings': {
          'clue_updates': _clueUpdates,
          'community_replies': _communityReplies,
          'clan_activity': _clanActivity,
          'promotions': _promotions,
        },
      }).eq('id', userId);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('설정 저장에 실패했습니다')),
        );
      }
    }
  }

  void _toggle(bool value, void Function(bool) setter) {
    setState(() => setter(value));
    _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('알림설정'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SwitchListTile(
                  title: const Text('클루 업데이트'),
                  subtitle: const Text('참여 중인 클루의 상태 변화 알림'),
                  value: _clueUpdates,
                  activeColor: AppColors.brandYellow,
                  onChanged: (v) => _toggle(v, (val) => _clueUpdates = val),
                ),
                SwitchListTile(
                  title: const Text('댓글/답글'),
                  subtitle: const Text('내 게시글에 댓글이 달릴 때 알림'),
                  value: _communityReplies,
                  activeColor: AppColors.brandYellow,
                  onChanged: (v) => _toggle(v, (val) => _communityReplies = val),
                ),
                SwitchListTile(
                  title: const Text('클랜 활동'),
                  subtitle: const Text('클랜 관련 소식 알림'),
                  value: _clanActivity,
                  activeColor: AppColors.brandYellow,
                  onChanged: (v) => _toggle(v, (val) => _clanActivity = val),
                ),
                SwitchListTile(
                  title: const Text('프로모션'),
                  subtitle: const Text('이벤트 및 프로모션 알림'),
                  value: _promotions,
                  activeColor: AppColors.brandYellow,
                  onChanged: (v) => _toggle(v, (val) => _promotions = val),
                ),
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Privacy Settings — DB 연동
// ─────────────────────────────────────────────────────────────

class PrivacySettingsScreen extends ConsumerStatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  ConsumerState<PrivacySettingsScreen> createState() =>
      _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState
    extends ConsumerState<PrivacySettingsScreen> {
  bool _profilePublic = true;
  bool _showActivity = true;
  bool _showRanking = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final client = safeClient;
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _loading = false);
        return;
      }
      final row = await client
          .from('profiles')
          .select('privacy_settings')
          .eq('id', userId)
          .maybeSingle();
      if (row != null && row['privacy_settings'] != null) {
        final s = row['privacy_settings'] as Map<String, dynamic>;
        setState(() {
          _profilePublic = s['profile_public'] ?? true;
          _showActivity = s['show_activity'] ?? true;
          _showRanking = s['show_ranking'] ?? true;
        });
      }
    } catch (_) {
      // UI preview mode
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveSettings() async {
    try {
      final client = safeClient;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;
      await client.from('profiles').update({
        'privacy_settings': {
          'profile_public': _profilePublic,
          'show_activity': _showActivity,
          'show_ranking': _showRanking,
        },
      }).eq('id', userId);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('설정 저장에 실패했습니다')),
        );
      }
    }
  }

  void _toggle(bool value, void Function(bool) setter) {
    setState(() => setter(value));
    _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('개인정보'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SwitchListTile(
                  title: const Text('프로필 공개'),
                  subtitle: const Text('다른 유저가 내 프로필을 볼 수 있음'),
                  value: _profilePublic,
                  activeColor: AppColors.brandYellow,
                  onChanged: (v) => _toggle(v, (val) => _profilePublic = val),
                ),
                SwitchListTile(
                  title: const Text('활동 기록 공개'),
                  subtitle: const Text('클루 참여/완료 기록 공개'),
                  value: _showActivity,
                  activeColor: AppColors.brandYellow,
                  onChanged: (v) => _toggle(v, (val) => _showActivity = val),
                ),
                SwitchListTile(
                  title: const Text('랭킹 노출'),
                  subtitle: const Text('주간/전체 랭킹에 표시'),
                  value: _showRanking,
                  activeColor: AppColors.brandYellow,
                  onChanged: (v) => _toggle(v, (val) => _showRanking = val),
                ),
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Block Management — DB 연동
// ─────────────────────────────────────────────────────────────

class BlockManagementScreen extends ConsumerStatefulWidget {
  const BlockManagementScreen({super.key});

  @override
  ConsumerState<BlockManagementScreen> createState() =>
      _BlockManagementScreenState();
}

class _BlockManagementScreenState extends ConsumerState<BlockManagementScreen> {
  List<Map<String, dynamic>> _blockedUsers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    try {
      final client = safeClient;
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _loading = false);
        return;
      }
      final rows = await client
          .from('blocks')
          .select('id, blocked_user:profiles!blocked_user_id(id, nickname, avatar_url)')
          .eq('blocker_user_id', userId);
      setState(() {
        _blockedUsers = List<Map<String, dynamic>>.from(rows);
      });
    } catch (_) {
      // UI preview mode
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _unblock(String blockId) async {
    try {
      await safeClient.from('blocks').delete().eq('id', blockId);
      setState(() {
        _blockedUsers.removeWhere((b) => b['id'] == blockId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('차단이 해제되었습니다')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('차단 해제에 실패했습니다')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('차단관리'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _blockedUsers.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.block, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        '차단한 유저가 없습니다',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _blockedUsers.length,
                  itemBuilder: (context, index) {
                    final block = _blockedUsers[index];
                    final user = block['blocked_user'] as Map<String, dynamic>?;
                    final nickname = user?['nickname'] ?? '알 수 없음';
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.bgElevated,
                        backgroundImage: user?['avatar_url'] != null
                            ? NetworkImage(user!['avatar_url'])
                            : null,
                        child: user?['avatar_url'] == null
                            ? Text(nickname[0], style: const TextStyle(color: AppColors.textSecondary))
                            : null,
                      ),
                      title: Text(nickname),
                      trailing: TextButton(
                        onPressed: () => _unblock(block['id']),
                        child: const Text('해제', style: TextStyle(color: AppColors.brandRed)),
                      ),
                    );
                  },
                ),
    );
  }
}
