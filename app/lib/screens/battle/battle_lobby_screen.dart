import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../providers/battle_provider.dart';
import '../../providers/currency_provider.dart';
import '../../widgets/common/currency_balance_chip.dart';

/// Battle 큐 진입 + 매칭 대기 화면.
/// matched 상태로 전환되면 자동으로 game 화면으로 이동.
class BattleLobbyScreen extends ConsumerStatefulWidget {
  const BattleLobbyScreen({super.key});

  @override
  ConsumerState<BattleLobbyScreen> createState() => _BattleLobbyScreenState();
}

class _BattleLobbyScreenState extends ConsumerState<BattleLobbyScreen> {
  final _stake = TextEditingController(text: '100');
  String _gameType = 'rps';
  String? _matchId;
  bool _busy = false;
  bool _navigated = false;

  static const _games = <(String, String, String, IconData)>[
    ('rps', '가위바위보', '3초 안에 결판', Icons.front_hand),
    ('tap', '서로 때리기', '10초 탭 연사', Icons.sports_mma),
    ('coin_grab', '동전 줍기', '15초 동전 탭', Icons.monetization_on),
  ];

  @override
  void dispose() {
    _stake.dispose();
    super.dispose();
  }

  Future<void> _onEnqueue() async {
    if (_busy) return;
    final stake = int.tryParse(_stake.text.trim()) ?? 0;
    if (stake < 10 || stake > 2000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('베팅액은 10~2000 코인 사이입니다')),
      );
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _busy = true);
    try {
      final res = await ref
          .read(battleServiceProvider)
          .enqueue(stakeCoin: stake, gameType: _gameType);
      if (!mounted) return;
      if (res['ok'] == true) {
        ref.invalidate(balancesProvider);
        setState(() => _matchId = res['match_id'] as String?);
        if (res['status'] == 'matched') {
          _goGame(res['match_id'] as String);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_reasonMessage(res))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _goGame(String matchId) {
    if (_navigated) return;
    _navigated = true;
    HapticFeedback.heavyImpact();
    context.pushReplacement('/battle/game/$matchId');
  }

  Future<void> _onCancel() async {
    if (_matchId == null) return;
    final res = await ref.read(battleServiceProvider).cancel(_matchId!);
    if (!mounted) return;
    if (res['ok'] == true) {
      ref.invalidate(balancesProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('취소됨 — ${res['refund']} 코인 환불')),
      );
      setState(() => _matchId = null);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('취소 실패: ${res['reason']}')),
      );
    }
  }

  static String _reasonMessage(Map<String, dynamic> res) {
    final reason = res['reason']?.toString() ?? 'unknown';
    switch (reason) {
      case 'insufficient_coin':
        return '코인 부족 (보유 ${res['have']}/필요 ${res['need']})';
      case 'stake_out_of_range':
        return '베팅액은 10~2000 사이입니다';
      case 'auth_required':
        return '로그인이 필요합니다';
      default:
        return '실패: $reason';
    }
  }

  @override
  Widget build(BuildContext context) {
    final matchAsync = _matchId != null
        ? ref.watch(battleMatchProvider(_matchId!))
        : const AsyncValue<Map<String, dynamic>?>.data(null);

    // matched 전환 자동 감지
    final row = matchAsync.valueOrNull;
    if (row != null && row['status'] == 'matched' && !_navigated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _goGame(row['id'] as String);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Battle 큐'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: Center(child: CurrencyBalanceChips()),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _matchId == null ? _buildEnqueue() : _buildWaiting(row),
      ),
    );
  }

  Widget _buildEnqueue() {
    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              AppColors.brandRed.withValues(alpha: 0.16),
              AppColors.brandYellow.withValues(alpha: 0.10),
            ]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.sports_kabaddi,
                      color: AppColors.brandRed, size: 22),
                  const SizedBox(width: 6),
                  Text('미니게임 베팅 대전',
                      style: GoogleFonts.notoSansKr(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.brandRed)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '같은 게임·베팅액으로 큐에 진입한 다른 사용자와 매칭됩니다.\n'
                '5분 안 매칭되면 CPU와 자동 대전.\n'
                '이기면 베팅 × 1.9 코인 획득 (수수료 5%).',
                style: GoogleFonts.notoSansKr(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('게임 선택',
            style: GoogleFonts.notoSansKr(
                fontSize: 13, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Row(
          children: _games.map((g) {
            final selected = _gameType == g.$1;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _gameType = g.$1);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 12),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.brandRed.withValues(alpha: 0.14)
                          : AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? AppColors.brandRed
                            : AppColors.brandRed.withValues(alpha: 0.15),
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(g.$4,
                            size: 24,
                            color: selected
                                ? AppColors.brandRed
                                : AppColors.textMuted),
                        const SizedBox(height: 6),
                        Text(g.$2,
                            style: GoogleFonts.notoSansKr(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: selected
                                    ? AppColors.brandRed
                                    : AppColors.textPrimary)),
                        Text(g.$3,
                            style: GoogleFonts.notoSansKr(
                                fontSize: 9, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Text('베팅액 (10 ~ 2000 코인)',
            style: GoogleFonts.notoSansKr(
                fontSize: 13, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        TextField(
          controller: _stake,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            hintText: '100',
            prefixIcon: Icon(Icons.savings, color: AppColors.brandYellow),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [10, 50, 100, 500, 1000, 2000]
              .map((v) => ActionChip(
                    label: Text('$v'),
                    onPressed: () => _stake.text = v.toString(),
                  ))
              .toList(),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _busy ? null : _onEnqueue,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text('큐 진입',
                    style: GoogleFonts.notoSansKr(
                        fontSize: 16, fontWeight: FontWeight.w900)),
          ),
        ),
      ],
    );
  }

  Widget _buildWaiting(Map<String, dynamic>? row) {
    final vsCpu = row?['vs_cpu'] == true;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.brandRed),
          const SizedBox(height: 20),
          Text(
            vsCpu ? 'CPU와 매칭 중...' : '상대방 매칭 대기 중...',
            style: GoogleFonts.notoSansKr(
                fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            '5분 안에 다른 사용자가 안 오면\nCPU와 자동 매칭됩니다',
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansKr(
                fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: _onCancel,
            icon: const Icon(Icons.close, size: 16),
            label: const Text('취소 + 코인 환불'),
            style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
