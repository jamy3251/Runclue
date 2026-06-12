import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/supabase_safe.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/clue_provider.dart';
import '../../services/clue_service.dart';
import '../../services/step_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/common/location_picker_modal.dart';

/// Screen 04 · 클루 만들기 — 명세 v2.0 §4.4
/// 5단계 위저드: 기본정보 → 매장·위치 → 단계 → 보상·분배 → 미리보기
class CreateClueScreen extends ConsumerStatefulWidget {
  const CreateClueScreen({super.key});

  @override
  ConsumerState<CreateClueScreen> createState() => _CreateClueScreenState();
}

class _CreateClueScreenState extends ConsumerState<CreateClueScreen> {
  static const int _totalSteps = 5;
  int _currentStep = 0;

  static const String _darkMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#1d1d2b"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#8e8e93"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#1d1d2b"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"visibility":"off"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"road","elementType":"geometry.fill","stylers":[{"color":"#2c2c3a"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#1d1d2b"}]},
  {"featureType":"road.highway","elementType":"geometry.fill","stylers":[{"color":"#3a3a4a"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0e0e1a"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#4e4e5e"}]}
]
''';

  // ── Step 1: 기본 정보 ──
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _category = '카페·맛집';
  static const _categoryOptions = [
    ('카페·맛집', Icons.coffee),
    ('탐험', Icons.explore),
    ('퀴즈', Icons.help_outline),
    ('숨바꼭질', Icons.visibility_off),
    ('인증샷', Icons.camera_alt),
    ('체험', Icons.psychology),
  ];

  // ── Step 2: 매장·위치 ──
  final _storeNameController = TextEditingController();
  final _addressController = TextEditingController();
  // 시립대 좌표를 기본값으로
  double _lat = 37.5836;
  double _lng = 127.0588;
  final _radiusController = TextEditingController(text: '50');

  // ── Step 3: 단계(스텝) ──
  final List<_StepDraft> _steps = [];

  // ── Step 4: 보상 + 분배 ──
  String _rewardKind = 'menu_discount'; // menu_discount / gifticon / cash
  final _rewardLabelController = TextEditingController(text: '아메리카노 무료');
  final _rewardValueController = TextEditingController(text: '4500');
  String _distributionMode = 'first_come'; // first_come / rank / random / all / coop_split
  final _winnerCountController = TextEditingController(text: '20');

  // ── 그룹 미션 #15 ──
  String _gameMode = 'solo'; // solo / coop
  final _minParticipantsController = TextEditingController(text: '3');

  // ── 유효 기간 ──
  DateTime? _startsAt;
  DateTime? _endsAt;
  bool _isEvent = false;  // 단기 이벤트 (술집/축제/세미나) — 24h 자동 만료

  // ── 썸네일 + 제출 ──
  File? _thumbnail;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _storeNameController.dispose();
    _addressController.dispose();
    _radiusController.dispose();
    _rewardLabelController.dispose();
    _rewardValueController.dispose();
    _winnerCountController.dispose();
    super.dispose();
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _titleController.text.trim().isNotEmpty &&
            _descController.text.trim().length >= 10;
      case 1:
        return _storeNameController.text.trim().isNotEmpty &&
            _addressController.text.trim().isNotEmpty;
      case 2:
        return _steps.isNotEmpty;
      case 3:
        return _rewardLabelController.text.trim().isNotEmpty &&
            (_distributionMode == 'all' ||
                int.tryParse(_winnerCountController.text) != null);
      default:
        return true;
    }
  }

  void _next() {
    if (!_canProceed()) {
      _toast('필수 항목을 모두 입력해주세요');
      return;
    }
    HapticFeedback.lightImpact();
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    }
  }

  void _back() {
    HapticFeedback.lightImpact();
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      _confirmExit();
    }
  }

  void _confirmExit() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('나가기'),
        content: const Text('작성 중인 내용이 있습니다. 계속 진행하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('계속 작성'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pop();
            },
            child: const Text('나가기',
                style: TextStyle(color: AppColors.brandRed),),
          ),
        ],
      ),
    );
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  /// 긴 에러 메시지를 dialog로 — 사용자가 메시지 통째로 복사해서 신고 가능
  void _showErrorDetails(String title, String detail) {
    // 사용자에게 보이는 친절한 요약 — 기술 코드는 펼치기 영역에
    final friendly = _humanizeError(detail);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.brandRed),
            const SizedBox(width: 8),
            Text(title,
                style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w900),),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              friendly,
              style: GoogleFonts.notoSansKr(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 12),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: Text(
                '기술 상세 보기',
                style: GoogleFonts.notoSansKr(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              children: [
                SelectableText(
                  detail,
                  style: GoogleFonts.firaMono(
                    fontSize: 11,
                    color: AppColors.brandRed,
                    height: 1.5,
                  ),
                ),
              ],
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

  /// 기술 에러 메시지에서 사용자에게 의미 있는 요약을 만든다.
  String _humanizeError(String detail) {
    if (detail.contains('PGRST204')) {
      return '서버 스키마가 아직 최신이 아니에요. 잠시 후 다시 시도하거나 운영팀에 문의해 주세요.';
    }
    if (detail.contains('23502')) {
      return '필수 항목이 비어 있어요. 모든 단계를 확인하고 다시 시도해 주세요.';
    }
    if (detail.contains('23514')) {
      return '입력값이 허용 범위를 벗어났어요. 보상 종류나 단계 유형을 다시 확인해 주세요.';
    }
    if (detail.contains('PGRST301') || detail.contains('JWT')) {
      return '로그인 세션이 만료됐어요. 다시 로그인한 뒤 시도해 주세요.';
    }
    if (detail.contains('network') ||
        detail.contains('Network') ||
        detail.contains('SocketException')) {
      return '네트워크 연결이 불안정해요. Wi-Fi/데이터를 확인하고 다시 시도해 주세요.';
    }
    return '클루 등록에 실패했어요. 입력값을 확인하고 다시 시도해 주세요.';
  }

  Future<void> _pickThumbnail() async {
    try {
      final picker = ImagePicker();
      final picked =
          await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked != null) {
        setState(() => _thumbnail = File(picked.path));
      }
    } catch (e) {
      _toast('이미지 선택 실패: $e');
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    HapticFeedback.mediumImpact();
    setState(() => _isSubmitting = true);

    try {
      // 세션 강제 새로고침 시도 — 만료됐을 수 있음
      String? userId = ref.read(currentUserIdProvider);
      if (userId == null) {
        try {
          await safeClient.auth.refreshSession();
        } catch (_) {/* refresh 실패 시 아래에서 처리 */}
        userId = safeClient.auth.currentUser?.id;
      }

      if (userId == null) {
        _toast('로그인이 필요합니다');
        if (mounted) {
          await Future.delayed(const Duration(milliseconds: 600));
          if (mounted) context.go('/auth/login');
        }
        return;
      }

      final clueService = ClueService();
      final stepService = StepService();

      // 보상 데이터
      final rewardValue = int.tryParse(_rewardValueController.text) ?? 0;
      final winnerCount = _distributionMode == 'all'
          ? null
          : int.tryParse(_winnerCountController.text);

      final clueData = <String, dynamic>{
        'creator_id': userId,
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'category': _category,
        'status': 'active', // MVP: 자동 승인 (Wave 2에서 'pending'으로 변경 + 검토 워크플로)
        'location_name': _storeNameController.text.trim(),
        'address': _addressController.text.trim(),
        'lat': _lat,
        'lng': _lng,
        'reward_type': _rewardKind,
        'reward_value': rewardValue,
        'reward_label': _rewardLabelController.text.trim(),
        'distribution_mode': _gameMode == 'coop'
            ? 'coop_split'
            : _gameMode == 'versus'
                ? 'versus_first'
                : _distributionMode,
        'max_participants': winnerCount,
        'current_participants': 0,
        'game_mode': _gameMode,
        if (_gameMode == 'coop' || _gameMode == 'versus')
          'min_participants':
              int.tryParse(_minParticipantsController.text) ?? 3,
        if (_gameMode == 'coop' || _gameMode == 'versus')
          'coop_state': 'recruiting',
        if (_startsAt != null) 'starts_at': _startsAt!.toUtc().toIso8601String(),
        if (_endsAt != null)
          'ends_at': _endsAt!.toUtc().toIso8601String()
        else if (_isEvent)
          'ends_at': DateTime.now()
              .toUtc()
              .add(const Duration(hours: 24))
              .toIso8601String(),
        if (_isEvent) 'is_event': true,
      };

      final created = await clueService.createClue(clueData);
      final clueId = created['id'] as String;

      // 썸네일
      // 썸네일 — 실패해도 클루 생성은 성공으로 처리하되, 토스트로 알려줌
      bool thumbnailFailed = false;
      String? thumbnailErrorMsg;
      if (_thumbnail != null) {
        try {
          final url =
              await StorageService().uploadClueImage(_thumbnail!, clueId);
          await clueService.updateClue(clueId, {'thumbnail_url': url});
        } catch (e) {
          thumbnailFailed = true;
          thumbnailErrorMsg = e.toString();
        }
      }

      // 단계
      final storageService = StorageService();
      for (var i = 0; i < _steps.length; i++) {
        final s = _steps[i];
        final stepData = <String, dynamic>{
          'clue_id': clueId,
          'order_index': i,
          'type': s.type,
          'title': s.title,
          'instruction': s.instruction,
          'hint': s.hint,
        };

        switch (s.type) {
          case 'CHECKPOINT':
            stepData['target_lat'] = _lat;
            stepData['target_lng'] = _lng;
            stepData['location_radius_meters'] =
                int.tryParse(_radiusController.text) ?? 50;
            stepData['validation_type'] = 'auto';
            break;
          case 'QUEST':
            stepData['quest_question'] = s.question;
            stepData['quest_answer'] = s.answer;
            stepData['validation_type'] = 'auto';
            break;
          case 'OX_QUIZ':
            stepData['quiz_correct_answer'] = s.oxAnswer;
            stepData['validation_type'] = 'auto';
            break;
          case 'SNAPSHOT':
          case 'GROUP_PHOTO':
          case 'PARTY_MISSION':
          case 'RECEIPT':
            stepData['validation_type'] = 'manual';
            break;
          case 'LIST':
            stepData['checklist_items'] = s.checklistItems;
            stepData['validation_type'] = 'auto';
            break;
          case 'PHOTO_SIM':
          case 'MOTION_SIM':
            // GPS 도착 + 정답지 사진 + 유사도 채점
            stepData['target_lat'] = _lat;
            stepData['target_lng'] = _lng;
            stepData['location_radius_meters'] =
                int.tryParse(_radiusController.text) ?? 50;
            stepData['validation_type'] = 'similarity';
            // 정답 사진 업로드
            if (s.referenceImage != null) {
              try {
                final url = await storageService.uploadClueImage(
                  s.referenceImage!,
                  '${clueId}_step_$i',
                );
                stepData['reference_image_url'] = url;
              } catch (_) {/* 정답지 실패는 silently */}
            }
            break;
        }

        await stepService.createStep(stepData);
      }

      // 마지막 검증 — 진짜 DB에 있는지 fresh fetch
      Map<String, dynamic>? dbClue;
      try {
        dbClue = await clueService.getClueById(clueId);
      } catch (_) {/* fetch 실패해도 success 표시는 진행 */}

      if (!mounted) return;
      // 탐색 페이지가 새 클루를 즉시 보여주도록 캐시 무효화
      ref.invalidate(trendingCluesProvider);
      ref.invalidate(myCluesProvider);
      // 썸네일 실패 알림 — 사용자가 '왜 사진이 안 보이지?' 라고 헤매지 않게
      if (thumbnailFailed) {
        _toast('썸네일 업로드 실패 — 클루는 등록됐어요. ${thumbnailErrorMsg ?? ""}');
      }
      _showSubmitSuccess(clueId, dbClue);
    } catch (e) {
      if (!mounted) return;
      _showErrorDetails('제출 실패', e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSubmitSuccess(String clueId, [Map<String, dynamic>? dbClue]) {
    final isReallySaved = dbClue != null;
    final accent = isReallySaved ? AppColors.brandGreen : AppColors.brandRed;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
                isReallySaved
                    ? Icons.check_circle
                    : Icons.warning_amber_rounded,
                color: accent,),
            const SizedBox(width: 8),
            Text(isReallySaved ? '클루 등록 완료' : '저장 확인 실패',
                style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w900),),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accent.withValues(alpha: 0.3)),
              ),
              child: Text(
                isReallySaved
                    ? '탐색 페이지에서 바로 확인할 수 있어요.\n탐험가들이 곧 참여하기 시작할 거예요!'
                    : '요청은 전송됐지만 저장 여부를 확인하지 못했어요.\n잠시 후 다시 시도하거나 운영팀에 문의해 주세요.',
                style: GoogleFonts.notoSansKr(
                  fontSize: 13,
                  color: accent,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '※ 정식 출시 후에는 운영진 검수(약 24시간)를 거치게 됩니다.',
              style: GoogleFonts.notoSansKr(
                fontSize: 11,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/home');
            },
            child: const Text('홈으로'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/explore');
            },
            child: const Text('탐색에서 확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.bgElevated,
        toolbarHeight: 56,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: _back,
        ),
        title: Text(
          '클루 만들기 ${_currentStep + 1}/$_totalSteps',
          style: GoogleFonts.notoSansKr(
            fontSize: 14,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          // 단계 도트
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(_totalSteps, (i) {
                final active = i == _currentStep;
                final done = i < _currentStep;
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: done
                        ? AppColors.brandYellow
                        : active
                            ? Colors.white
                            : AppColors.borderDefault,
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: KeyedSubtree(
                  key: ValueKey(_currentStep),
                  child: _buildCurrentStep(),
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStepBasic();
      case 1:
        return _buildStepLocation();
      case 2:
        return _buildStepSteps();
      case 3:
        return _buildStepReward();
      case 4:
        return _buildStepPreview();
      default:
        return const SizedBox();
    }
  }

  // ─────────────── Step 1: 기본 정보 ───────────────
  Widget _buildStepBasic() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      children: [
        const _StepHeader(
          title: '클루 소개',
          subtitle: '탐험가에게 보일 첫 인상이에요',
        ),
        const SizedBox(height: 20),
        const _DarkLabel('썸네일 (선택)'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickThumbnail,
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderDefault),
              image: _thumbnail != null
                  ? DecorationImage(
                      image: FileImage(_thumbnail!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            alignment: Alignment.center,
            child: _thumbnail == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_photo_alternate_outlined,
                          color: AppColors.textMuted, size: 32,),
                      const SizedBox(height: 8),
                      Text(
                        '대표 이미지 추가',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  )
                : null,
          ),
        ),
        const SizedBox(height: 16),
        const _DarkLabel('클루 제목 *'),
        const SizedBox(height: 8),
        _DarkInput(
          controller: _titleController,
          hint: '예: 회기동 숨겨진 카페 발견하기',
          maxLength: 40,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        const _DarkLabel('카테고리'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categoryOptions.map((opt) {
            final selected = _category == opt.$1;
            return GestureDetector(
              onTap: () => setState(() => _category = opt.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8,),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.brandYellow
                      : AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(
                    color: selected
                        ? AppColors.brandYellow
                        : AppColors.borderDefault,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(opt.$2,
                        size: 14,
                        color: selected
                            ? Colors.black
                            : AppColors.textMuted,),
                    const SizedBox(width: 6),
                    Text(
                      opt.$1,
                      style: GoogleFonts.notoSansKr(
                        fontSize: 12,
                        color: selected ? Colors.black : AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        const _DarkLabel('소개 (10자 이상) *'),
        const SizedBox(height: 8),
        _DarkInput(
          controller: _descController,
          hint: '탐험가가 어떤 경험을 하게 될지 설명해주세요',
          maxLines: 5,
          maxLength: 300,
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  // ─────────────── Step 2: 매장·위치 ───────────────
  Widget _buildStepLocation() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      children: [
        const _StepHeader(
          title: '매장·위치',
          subtitle: '탐험가가 방문할 장소를 알려주세요',
        ),
        const SizedBox(height: 20),
        const _DarkLabel('매장명 *'),
        const SizedBox(height: 8),
        _DarkInput(
          controller: _storeNameController,
          hint: '예: 회기동 카페 RUNCLUE',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        const _DarkLabel('주소 *'),
        const SizedBox(height: 8),
        _DarkInput(
          controller: _addressController,
          hint: '예: 서울 동대문구 회기로 12',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        const _DarkLabel('지도에서 위치 선택 *'),
        const SizedBox(height: 8),
        // 미니맵 미리보기 — 지도 SDK 활성화됐으면 정상 표시, 안 되면 카드 폴백
        GestureDetector(
          onTap: _pickLocationFromMap,
          child: _MapPreview(
            lat: _lat,
            lng: _lng,
            darkStyle: _darkMapStyle,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on,
                  color: AppColors.brandYellow, size: 16,),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${_lat.toStringAsFixed(6)}, ${_lng.toStringAsFixed(6)}',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              TextButton(
                onPressed: _pickLocationFromMap,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                ),
                child: const Text('직접 입력'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const _DarkLabel('인증 반경 (m)'),
        const SizedBox(height: 8),
        _DarkInput(
          controller: _radiusController,
          hint: '50',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 8),
        Text(
          '※ 탐험가가 이 반경 안에 들어가야 GPS 인증이 통과됩니다',
          style: GoogleFonts.notoSansKr(
            fontSize: 11,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Future<void> _pickLocationFromMap() async {
    HapticFeedback.lightImpact();
    final result = await LocationPickerModal.show(context);
    if (result != null && mounted) {
      setState(() {
        _lat = result.latitude;
        _lng = result.longitude;
        // 주소가 비어있으면 자동 채움, 사용자가 입력한 게 있으면 보존
        if (_addressController.text.trim().isEmpty &&
            result.address.isNotEmpty) {
          _addressController.text = result.address;
        }
      });
    }
  }

  // ─────────────── Step 3: 단계(스텝) ───────────────
  Widget _buildStepSteps() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      children: [
        const _StepHeader(
          title: '미션 단계',
          subtitle: '탐험가가 풀어야 할 단계를 추가하세요 (1개 이상)',
        ),
        const SizedBox(height: 20),

        // 추가된 단계 목록
        if (_steps.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderDefault),
            ),
            alignment: Alignment.center,
            child: Column(
              children: [
                const Icon(Icons.add_circle_outline,
                    color: AppColors.textMuted, size: 36,),
                const SizedBox(height: 8),
                Text(
                  '아래 버튼으로 첫 단계를 추가하세요',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          )
        else
          ...List.generate(_steps.length, (i) {
            final s = _steps[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.brandYellow,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.title.isNotEmpty ? s.title : '(제목 없음)',
                          style: GoogleFonts.notoSansKr(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _stepTypeLabel(s.type),
                          style: GoogleFonts.notoSansKr(
                            fontSize: 11,
                            color: AppColors.brandPurple,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: AppColors.textMuted, size: 20,),
                    onPressed: () => setState(() => _steps.removeAt(i)),
                  ),
                ],
              ),
            );
          }),

        const SizedBox(height: 16),

        // 단계 추가 버튼
        OutlinedButton.icon(
          onPressed: _showAddStepSheet,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('단계 추가'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            foregroundColor: AppColors.brandYellow,
            side: BorderSide(
              color: AppColors.brandYellow.withValues(alpha: 0.5),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddStepSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgElevated,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddStepSheet(
        onAdd: (draft) => setState(() => _steps.add(draft)),
      ),
    );
  }

  String _stepTypeLabel(String type) => switch (type) {
        'PHOTO_SIM' => '⭐ GPS+사진 유사도',
        'MOTION_SIM' => '⭐ GPS+모션 유사도',
        'CHECKPOINT' => 'GPS 위치 인증',
        'SNAPSHOT' => '카메라 인증샷',
        'QUEST' => '정답 입력 퀘스트',
        'OX_QUIZ' => 'OX 퀴즈',
        'LIST' => '체크리스트',
        'GROUP_PHOTO' => '단체 인증샷',
        'PARTY_MISSION' => '파티 미션',
        'RECEIPT' => '구매 영수증 인증',
        _ => type,
      };

  // ─────────────── Step 4: 보상 + 분배 ───────────────
  Widget _buildStepReward() {
    const rewardOptions = [
      ('menu_discount', '메뉴 할인', Icons.local_offer),
      ('gifticon', '기프티콘', Icons.card_giftcard),
      ('cash', '캐시 (Wave3)', Icons.payments),
    ];
    const distOptions = [
      ('first_come', '선착순', Icons.flash_on,
          '먼저 완료한 N명에게 지급'),
      ('rank', '등수별', Icons.emoji_events,
          '완료 시간 1~N등에게 차등 지급'),
      ('random', '랜덤 추첨', Icons.casino,
          '완료자 중 N명 무작위 추첨'),
      ('all', '전원 지급', Icons.groups, '완료한 전원에게 지급 (인원 무제한)'),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      children: [
        const _StepHeader(
          title: '보상 + 분배 방식',
          subtitle: '어떤 보상을, 누구에게 줄지 정하세요',
        ),
        const SizedBox(height: 20),

        const _DarkLabel('보상 종류'),
        const SizedBox(height: 8),
        Row(
          children: rewardOptions.map((opt) {
            final selected = _rewardKind == opt.$1;
            final disabled = opt.$1 == 'cash';
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: disabled
                      ? null
                      : () => setState(() => _rewardKind = opt.$1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.brandYellow.withValues(alpha: 0.15)
                          : AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? AppColors.brandYellow
                            : AppColors.borderDefault,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(opt.$3,
                            color: disabled
                                ? AppColors.textDisabled
                                : selected
                                    ? AppColors.brandYellow
                                    : AppColors.textMuted,
                            size: 22,),
                        const SizedBox(height: 6),
                        Text(
                          opt.$2,
                          style: GoogleFonts.notoSansKr(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: disabled
                                ? AppColors.textDisabled
                                : selected
                                    ? AppColors.brandYellow
                                    : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),
        const _DarkLabel('보상 내용 *'),
        const SizedBox(height: 8),
        _DarkInput(
          controller: _rewardLabelController,
          hint: '예: 아메리카노 무료, 5,000원 할인',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        const _DarkLabel('보상 가치 (원)'),
        const SizedBox(height: 8),
        _DarkInput(
          controller: _rewardValueController,
          hint: '4500',
          keyboardType: TextInputType.number,
        ),

        const SizedBox(height: 28),

        // ── 게임 모드 (#15 + #23) — solo / coop / versus 3선택 ──
        const _DarkLabel('게임 모드 *'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _GameModeTile(
                selected: _gameMode == 'solo',
                onTap: () => setState(() => _gameMode = 'solo'),
                color: AppColors.brandYellow,
                icon: Icons.person,
                label: '솔로',
                desc: '혼자 도전',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _GameModeTile(
                selected: _gameMode == 'coop',
                onTap: () => setState(() => _gameMode = 'coop'),
                color: AppColors.brandBlue,
                icon: Icons.groups,
                label: '그룹',
                desc: 'N명 공동 보상',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _GameModeTile(
                selected: _gameMode == 'versus',
                onTap: () => setState(() => _gameMode = 'versus'),
                color: AppColors.brandRed,
                icon: Icons.flag,
                label: '대결',
                desc: '1등 독식',
              ),
            ),
          ],
        ),
        if (_gameMode == 'coop' || _gameMode == 'versus') ...[
          const SizedBox(height: 12),
          const _DarkLabel('필요 인원 (2~10명)'),
          const SizedBox(height: 8),
          _DarkInput(
            controller: _minParticipantsController,
            hint: '3',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 8),
          Text(
            _gameMode == 'coop'
                ? '※ 그룹 모드는 풀을 N등분 — 모두 동일한 보상을 받습니다.'
                : '※ 대결 모드는 첫 완료자가 풀을 독식 — 나머지는 보상 없음.',
            style: GoogleFonts.notoSansKr(
                fontSize: 11, color: AppColors.textMuted,),
          ),
        ],

        const SizedBox(height: 28),

        const _DarkLabel('분배 방식 *'),
        const SizedBox(height: 8),
        if (_gameMode == 'coop' || _gameMode == 'versus') ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (_gameMode == 'coop'
                      ? AppColors.brandBlue
                      : AppColors.brandRed)
                  .withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: (_gameMode == 'coop'
                          ? AppColors.brandBlue
                          : AppColors.brandRed)
                      .withValues(alpha: 0.3),),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_outline,
                    size: 16,
                    color: _gameMode == 'coop'
                        ? AppColors.brandBlue
                        : AppColors.brandRed,),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _gameMode == 'coop'
                        ? '그룹 모드 — 자동으로 N등분 분배'
                        : '대결 모드 — 첫 완료자 풀 독식',
                    style: GoogleFonts.notoSansKr(
                        fontSize: 12,
                        color: _gameMode == 'coop'
                            ? AppColors.brandBlue
                            : AppColors.brandRed,),
                  ),
                ),
              ],
            ),
          ),
        ] else
        ...distOptions.map((opt) {
          final selected = _distributionMode == opt.$1;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => setState(() => _distributionMode = opt.$1),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.brandBlue.withValues(alpha: 0.10)
                      : AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? AppColors.brandBlue
                        : AppColors.borderDefault,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(opt.$3,
                        color: selected
                            ? AppColors.brandBlue
                            : AppColors.textMuted,),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            opt.$2,
                            style: GoogleFonts.notoSansKr(
                              fontSize: 14,
                              color: selected
                                  ? AppColors.brandBlue
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            opt.$4,
                            style: GoogleFonts.notoSansKr(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (selected)
                      const Icon(Icons.check_circle,
                          color: AppColors.brandBlue, size: 20,),
                  ],
                ),
              ),
            ),
          );
        }),

        const SizedBox(height: 12),

        if (_distributionMode != 'all') ...[
          const _DarkLabel('수령 인원 *'),
          const SizedBox(height: 8),
          _DarkInput(
            controller: _winnerCountController,
            hint: '20',
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
          ),
        ],

        const SizedBox(height: 20),

        // 단기 이벤트 토글 (술집/축제/세미나)
        InkWell(
          onTap: () => setState(() => _isEvent = !_isEvent),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isEvent
                  ? AppColors.brandRed.withValues(alpha: 0.10)
                  : AppColors.bgSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isEvent
                    ? AppColors.brandRed.withValues(alpha: 0.4)
                    : AppColors.borderDefault,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isEvent ? Icons.celebration : Icons.celebration_outlined,
                  color: _isEvent ? AppColors.brandRed : AppColors.textMuted,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('단기 이벤트 (24시간 한정)',
                          style: GoogleFonts.notoSansKr(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: _isEvent
                                  ? AppColors.brandRed
                                  : AppColors.textPrimary,),),
                      const SizedBox(height: 2),
                      Text(
                        '술집·축제·세미나처럼 짧고 강한 한정 미션. 24h 후 자동 만료.',
                        style: GoogleFonts.notoSansKr(
                            fontSize: 11, color: AppColors.textMuted,),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isEvent,
                  activeColor: AppColors.brandRed,
                  onChanged: (v) => setState(() => _isEvent = v),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // 유효 기간 — 시간제한 미션 (선택)
        const _DarkLabel('유효 기간 (선택)'),
        const SizedBox(height: 4),
        Text(
          '시작/종료 시각 — 비워두면 즉시 시작 + 무기한',
          style: GoogleFonts.notoSansKr(
              fontSize: 11, color: AppColors.textMuted,),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _DatePickerTile(
                label: '시작',
                value: _startsAt,
                onPick: (dt) => setState(() => _startsAt = dt),
                onClear: () => setState(() => _startsAt = null),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DatePickerTile(
                label: '종료',
                value: _endsAt,
                onPick: (dt) => setState(() => _endsAt = dt),
                onClear: () => setState(() => _endsAt = null),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 비용 미리보기
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.brandGreen.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.brandGreen.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline,
                  color: AppColors.brandGreen, size: 18,),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _calcCostPreview(),
                  style: GoogleFonts.notoSansKr(
                    fontSize: 13,
                    color: AppColors.brandGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _calcCostPreview() {
    final value = int.tryParse(_rewardValueController.text) ?? 0;
    if (_distributionMode == 'all') {
      return '예상 최대 비용: 완료자 1명당 ₩$value';
    }
    final n = int.tryParse(_winnerCountController.text) ?? 0;
    final total = value * n;
    final fee = (total * 0.15).round();
    return '예상 총 보상비 ₩$total · 플랫폼 수수료 15% (₩$fee)';
  }

  // ─────────────── Step 5: 미리보기 ───────────────
  Widget _buildStepPreview() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      children: [
        const _StepHeader(
          title: '미리보기 + 제출',
          subtitle: '탐험가에게 보일 카드를 확인하세요',
        ),
        const SizedBox(height: 20),

        // 카드 미리보기
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.brandYellow),
            image: _thumbnail != null
                ? DecorationImage(
                    image: FileImage(_thumbnail!),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.5),
                      BlendMode.darken,
                    ),
                  )
                : null,
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _previewBadge(_category, AppColors.brandBlue),
                  const SizedBox(width: 6),
                  _previewBadge('NEW', AppColors.brandGreen),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _titleController.text.isEmpty
                    ? '(제목 없음)'
                    : _titleController.text,
                style: GoogleFonts.blackHanSans(
                  fontSize: 20,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _storeNameController.text.isEmpty
                    ? '매장명 미입력'
                    : '📍 ${_storeNameController.text}',
                style: GoogleFonts.notoSansKr(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _descController.text.isEmpty
                    ? '소개 미입력'
                    : _descController.text,
                style: GoogleFonts.notoSansKr(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  height: 1.5,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              const Divider(color: AppColors.borderDefault, height: 24),
              Row(
                children: [
                  const Icon(Icons.payments,
                      color: AppColors.brandYellow, size: 16,),
                  const SizedBox(width: 4),
                  Text(
                    _rewardLabelController.text.isEmpty
                        ? '보상 미입력'
                        : _rewardLabelController.text,
                    style: GoogleFonts.notoSansKr(
                      fontSize: 13,
                      color: AppColors.brandYellow,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _distributionLabel(),
                    style: GoogleFonts.notoSansKr(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 단계 요약
        Text(
          '단계 ${_steps.length}개',
          style: GoogleFonts.notoSansKr(
            fontSize: 13,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        ..._steps.asMap().entries.map((e) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '${e.key + 1}. ${e.value.title} · ${_stepTypeLabel(e.value.type)}',
              style: GoogleFonts.notoSansKr(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          );
        }),

        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.brandOrange.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.brandOrange.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline,
                  color: AppColors.brandOrange, size: 18,),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '제출 후 운영진 승인을 거쳐 탐색 페이지에 노출됩니다 (보통 24시간 이내)',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 12,
                    color: AppColors.brandOrange,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _previewBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.notoSansKr(
          fontSize: 9,
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  String _distributionLabel() {
    final mode = switch (_distributionMode) {
      'first_come' => '선착순',
      'rank' => '등수별',
      'random' => '랜덤',
      _ => '전원',
    };
    if (_distributionMode == 'all') return mode;
    return '$mode ${_winnerCountController.text}명';
  }

  // ─────────────── 하단 바 ───────────────
  Widget _buildBottomBar() {
    final isLast = _currentStep == _totalSteps - 1;
    final canProceed = _canProceed();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.bgElevated,
        border: Border(top: BorderSide(color: AppColors.borderDefault)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _back,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text('이전'),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 50,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: canProceed && !_isSubmitting
                        ? AppGradients.ctaYellow
                        : null,
                    color: canProceed && !_isSubmitting
                        ? null
                        : AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: canProceed && !_isSubmitting
                        ? const [AppShadows.ctaYellow]
                        : null,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: canProceed && !_isSubmitting
                          ? (isLast ? _submit : _next)
                          : null,
                      child: Center(
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                      Colors.black,),
                                ),
                              )
                            : Text(
                                isLast ? '제출하기' : '다음 단계',
                                style: GoogleFonts.notoSansKr(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: canProceed
                                      ? Colors.black
                                      : AppColors.textMuted,
                                ),
                              ),
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
}

// ─────────────────────────────────────────────────────────────
// 단계 추가 시트
// ─────────────────────────────────────────────────────────────

class _AddStepSheet extends StatefulWidget {
  final ValueChanged<_StepDraft> onAdd;
  const _AddStepSheet({required this.onAdd});

  @override
  State<_AddStepSheet> createState() => _AddStepSheetState();
}

class _AddStepSheetState extends State<_AddStepSheet> {
  String? _selectedType;
  final _titleC = TextEditingController();
  final _instructionC = TextEditingController();
  final _hintC = TextEditingController();
  final _questionC = TextEditingController();
  final _answerC = TextEditingController();
  bool _oxAnswer = true;
  final _checklistC = TextEditingController();

  static const _types = [
    // ⭐ MVP 핵심 2종 — 사장님 정답지 사진 업로드 + 유사도 채점
    ('PHOTO_SIM', 'GPS+사진 유사도', '도착 후 정답 사진과 비슷한 사진 촬영',
        Icons.photo_camera_back, AppColors.brandYellow),
    ('MOTION_SIM', 'GPS+모션 유사도', '도착 후 정답 모션과 비슷한 포즈 촬영',
        Icons.accessibility_new, AppColors.brandPurple),
    // 추가 단계 유형
    ('CHECKPOINT', 'GPS 위치 인증', '매장 도착 확인',
        Icons.location_on, AppColors.brandBlue),
    ('SNAPSHOT', '카메라 인증샷', '메뉴 사진 등',
        Icons.camera_alt, AppColors.brandPurple),
    ('QUEST', '정답 입력 퀘스트', '퀴즈/암호 풀기',
        Icons.help_outline, AppColors.brandOrange),
    ('OX_QUIZ', 'OX 퀴즈', '예/아니오 선택',
        Icons.check_circle_outline, AppColors.brandGreen),
    ('LIST', '체크리스트', '여러 항목 완료',
        Icons.checklist, AppColors.brandYellow),
    // 단체전 (MT 시즌/학교 대항/파티)
    ('GROUP_PHOTO', '단체 인증샷', '조원 모두와 함께 찍기',
        Icons.groups, AppColors.brandGreen),
    ('PARTY_MISSION', '파티 미션', '지정 미션 수행 인증 (응원·포즈 등)',
        Icons.celebration, AppColors.brandRed),
    // 사장 ROI 측정 — 방문→구매 전환 지표 (K5)
    ('RECEIPT', '구매 영수증 인증', '영수증 사진 — 지시문에 최소 금액 명시',
        Icons.receipt_long, AppColors.brandBlue),
  ];

  File? _referenceImage;

  @override
  void dispose() {
    _titleC.dispose();
    _instructionC.dispose();
    _hintC.dispose();
    _questionC.dispose();
    _answerC.dispose();
    _checklistC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('단계 추가',
                style: GoogleFonts.notoSansKr(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),),
            const SizedBox(height: 16),

            const _DarkLabel('단계 유형'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _types.map((t) {
                final selected = _selectedType == t.$1;
                return GestureDetector(
                  onTap: () => setState(() => _selectedType = t.$1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8,),
                    decoration: BoxDecoration(
                      color: selected
                          ? t.$5.withValues(alpha: 0.15)
                          : AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(9999),
                      border: Border.all(
                        color: selected ? t.$5 : AppColors.borderDefault,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(t.$4,
                            size: 14,
                            color: selected ? t.$5 : AppColors.textMuted,),
                        const SizedBox(width: 6),
                        Text(t.$2,
                            style: GoogleFonts.notoSansKr(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: selected ? t.$5 : AppColors.textMuted,
                            ),),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),
            const _DarkLabel('단계 제목 *'),
            const SizedBox(height: 8),
            _DarkInput(
              controller: _titleC,
              hint: '예: 매장 입장 인증',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            const _DarkLabel('탐험가에게 보일 안내'),
            const SizedBox(height: 8),
            _DarkInput(
              controller: _instructionC,
              hint: '무엇을 해야 하는지 설명',
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            const _DarkLabel('힌트 (선택)'),
            const SizedBox(height: 8),
            _DarkInput(
              controller: _hintC,
              hint: '막힐 때 보여줄 힌트',
            ),

            // 유형별 추가 필드
            if (_selectedType == 'QUEST') ...[
              const SizedBox(height: 16),
              const _DarkLabel('퀘스트 질문'),
              const SizedBox(height: 8),
              _DarkInput(controller: _questionC, hint: '예: 매장 비밀 메뉴 이름은?'),
              const SizedBox(height: 12),
              const _DarkLabel('정답'),
              const SizedBox(height: 8),
              _DarkInput(controller: _answerC, hint: '대소문자 무시'),
            ],
            if (_selectedType == 'OX_QUIZ') ...[
              const SizedBox(height: 16),
              const _DarkLabel('OX 정답'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _OxButton(
                      label: 'O (예)',
                      selected: _oxAnswer,
                      color: AppColors.brandBlue,
                      onTap: () => setState(() => _oxAnswer = true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _OxButton(
                      label: 'X (아니오)',
                      selected: !_oxAnswer,
                      color: AppColors.brandRed,
                      onTap: () => setState(() => _oxAnswer = false),
                    ),
                  ),
                ],
              ),
            ],
            if (_selectedType == 'LIST') ...[
              const SizedBox(height: 16),
              const _DarkLabel('체크리스트 항목 (줄바꿈으로 구분)'),
              const SizedBox(height: 8),
              _DarkInput(
                controller: _checklistC,
                hint: '메뉴판 보기\n자리 잡기\n주문하기',
                maxLines: 4,
              ),
            ],
            if (_selectedType == 'PHOTO_SIM' ||
                _selectedType == 'MOTION_SIM') ...[
              const SizedBox(height: 16),
              _DarkLabel(_selectedType == 'PHOTO_SIM'
                  ? '정답 사진 업로드 *'
                  : '정답 모션 사진 업로드 *',),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickReferenceImage,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _referenceImage != null
                          ? AppColors.brandYellow
                          : AppColors.borderDefault,
                      width: _referenceImage != null ? 1.5 : 1,
                    ),
                    image: _referenceImage != null
                        ? DecorationImage(
                            image: FileImage(_referenceImage!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: _referenceImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _selectedType == 'PHOTO_SIM'
                                  ? Icons.add_photo_alternate
                                  : Icons.accessibility_new,
                              color: AppColors.textMuted,
                              size: 36,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _selectedType == 'PHOTO_SIM'
                                  ? '탐험가가 따라 찍을 정답 사진을 올려주세요'
                                  : '정답이 될 모션·포즈 사진을 올려주세요',
                              style: GoogleFonts.notoSansKr(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        )
                      : Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4,),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '변경',
                                style: GoogleFonts.notoSansKr(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.brandBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.brandBlue.withValues(alpha: 0.2),),
                ),
                child: Text(
                  _selectedType == 'PHOTO_SIM'
                      ? '💡 탐험가는 GPS 도착 후 같은 구도/대상의 사진을 촬영합니다.\n   유사도 점수가 높을수록 등수가 올라가요.'
                      : '💡 탐험가는 GPS 도착 후 정답 모션과 같은 포즈를 취해 사진을 찍습니다.\n   포즈 유사도 점수로 등수가 매겨져요.',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 11,
                    color: AppColors.brandBlue,
                    height: 1.5,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _canAdd() ? _add : null,
                child: const Text('단계 추가'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canAdd() {
    if (_selectedType == null || _titleC.text.trim().isEmpty) return false;
    if ((_selectedType == 'PHOTO_SIM' || _selectedType == 'MOTION_SIM') &&
        _referenceImage == null) {
      return false;
    }
    return true;
  }

  Future<void> _pickReferenceImage() async {
    try {
      final picker = ImagePicker();
      final picked =
          await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
      if (picked != null) {
        setState(() => _referenceImage = File(picked.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지 선택 실패: $e')),
      );
    }
  }

  void _add() {
    HapticFeedback.lightImpact();
    final draft = _StepDraft(
      type: _selectedType!,
      title: _titleC.text.trim(),
      instruction: _instructionC.text.trim(),
      hint: _hintC.text.trim().isNotEmpty ? _hintC.text.trim() : null,
      question: _questionC.text.trim().isNotEmpty
          ? _questionC.text.trim()
          : null,
      answer: _answerC.text.trim().isNotEmpty ? _answerC.text.trim() : null,
      oxAnswer: _selectedType == 'OX_QUIZ' ? _oxAnswer : null,
      checklistItems: _selectedType == 'LIST'
          ? _checklistC.text
              .split('\n')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .map((e) => {'text': e, 'required': true})
              .toList()
          : null,
      referenceImage: _referenceImage,
    );
    widget.onAdd(draft);
    Navigator.pop(context);
  }
}

class _OxButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _OxButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.2) : AppColors.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : AppColors.borderDefault,
            width: selected ? 1.5 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.notoSansKr(
            fontSize: 14,
            color: selected ? color : AppColors.textMuted,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 보조 위젯 + 모델
// ─────────────────────────────────────────────────────────────

class _StepDraft {
  final String type;
  final String title;
  final String instruction;
  final String? hint;
  final String? question;
  final String? answer;
  final bool? oxAnswer;
  final List<Map<String, dynamic>>? checklistItems;
  final File? referenceImage; // PHOTO_SIM / MOTION_SIM 정답지

  _StepDraft({
    required this.type,
    required this.title,
    required this.instruction,
    this.hint,
    this.question,
    this.answer,
    this.oxAnswer,
    this.checklistItems,
    this.referenceImage,
  });
}

class _StepHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _StepHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: GoogleFonts.blackHanSans(
              fontSize: 24,
              color: AppColors.textPrimary,
            ),),
        const SizedBox(height: 6),
        Text(subtitle,
            style: GoogleFonts.notoSansKr(
              fontSize: 13,
              color: AppColors.textMuted,
            ),),
      ],
    );
  }
}

class _GameModeTile extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final Color color;
  final IconData icon;
  final String label;
  final String desc;
  const _GameModeTile({
    required this.selected,
    required this.onTap,
    required this.color,
    required this.icon,
    required this.label,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.12)
              : AppColors.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : AppColors.borderDefault,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? color : AppColors.textMuted),
            const SizedBox(height: 4),
            Text(label,
                style: GoogleFonts.notoSansKr(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? color : AppColors.textPrimary,
                ),),
            Text(desc,
                style: GoogleFonts.notoSansKr(
                    fontSize: 9, color: AppColors.textMuted,),),
          ],
        ),
      ),
    );
  }
}

class _DarkLabel extends StatelessWidget {
  final String text;
  const _DarkLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.notoSansKr(
        fontSize: 12,
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _DarkInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int? maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  const _DarkInput({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: GoogleFonts.notoSansKr(
        fontSize: 14,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.notoSansKr(
          fontSize: 14,
          color: AppColors.textDisabled,
        ),
        filled: true,
        fillColor: AppColors.bgSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderDefault),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderDefault),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.brandYellow),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        counterStyle: GoogleFonts.notoSansKr(
          fontSize: 11,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 위치 카드용 그리드 페인터 (지도 느낌의 격자 배경)
// ─────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────
// 미니맵 미리보기 — GoogleMap 시도, 실패 시 격자 카드 폴백
// ─────────────────────────────────────────────────────────────
class _MapPreview extends StatefulWidget {
  final double lat;
  final double lng;
  final String darkStyle;
  const _MapPreview({
    required this.lat,
    required this.lng,
    required this.darkStyle,
  });

  @override
  State<_MapPreview> createState() => _MapPreviewState();
}

class _MapPreviewState extends State<_MapPreview> {
  // 미니 GoogleMap을 비활성화 — SurfaceView가 일부 디바이스(Note 9 등)에서 GPU 노이즈 유발.
  // 폴백 카드만 사용하고, 실제 지도는 풀스크린 picker(Hybrid Composition 적용)에서만.
  final bool _mapFailed = true;
  Timer? _initTimer;

  @override
  void dispose() {
    _initTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.brandYellow.withValues(alpha: 0.4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (!_mapFailed)
            AbsorbPointer(
              child: GoogleMap(
                key: ValueKey('preview_${widget.lat}_${widget.lng}'),
                initialCameraPosition: CameraPosition(
                  target: LatLng(widget.lat, widget.lng),
                  zoom: 16,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('store'),
                    position: LatLng(widget.lat, widget.lng),
                  ),
                },
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
                mapToolbarEnabled: false,
                onMapCreated: (controller) {
                  _initTimer?.cancel();
                  try {
                    controller.setMapStyle(widget.darkStyle);
                  } catch (_) {}
                },
              ),
            )
          else
            // 폴백: 격자 카드
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.bgSurface,
                      AppColors.brandYellow.withValues(alpha: 0.08),
                      AppColors.brandBlue.withValues(alpha: 0.06),
                    ],
                  ),
                ),
                child: CustomPaint(painter: _GridPainter()),
              ),
            ),
          // 폴백일 때 중앙 핀
          if (_mapFailed)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.brandYellow,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brandYellow.withValues(alpha: 0.5),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.location_on,
                        size: 28, color: Colors.black,),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6,),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      '${widget.lat.toStringAsFixed(4)}, ${widget.lng.toStringAsFixed(4)}',
                      style: GoogleFonts.firaMono(
                        fontSize: 11,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // 가독성 오버레이
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.3),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // 우하단 CTA
          Positioned(
            right: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8,),
              decoration: BoxDecoration(
                color: AppColors.brandYellow,
                borderRadius: BorderRadius.circular(9999),
                boxShadow: const [AppShadows.ctaYellow],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.touch_app, size: 14, color: Colors.black),
                  const SizedBox(width: 4),
                  Text(
                    '탭해서 지도 열기',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 11,
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.brandYellow.withValues(alpha: 0.08)
      ..strokeWidth = 0.5;

    const step = 24.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // 중심 십자
    final centerPaint = Paint()
      ..color = AppColors.brandBlue.withValues(alpha: 0.3)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(size.width / 2 - 16, size.height / 2),
      Offset(size.width / 2 + 16, size.height / 2),
      centerPaint,
    );
    canvas.drawLine(
      Offset(size.width / 2, size.height / 2 - 16),
      Offset(size.width / 2, size.height / 2 + 16),
      centerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 시작/종료 날짜 picker tile.
class _DatePickerTile extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onPick;
  final VoidCallback onClear;

  const _DatePickerTile({
    required this.label,
    required this.value,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    final text = hasValue
        ? '${value!.year}.${value!.month.toString().padLeft(2, '0')}.${value!.day.toString().padLeft(2, '0')}'
        : '날짜 선택';
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? now,
          firstDate: now.subtract(const Duration(days: 1)),
          lastDate: now.add(const Duration(days: 365)),
          builder: (ctx, child) => Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppColors.brandYellow,
                onPrimary: Colors.black,
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) onPick(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasValue
                ? AppColors.brandYellow.withValues(alpha: 0.4)
                : AppColors.borderDefault,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today,
                size: 14,
                color: hasValue
                    ? AppColors.brandYellow
                    : AppColors.textMuted,),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.notoSansKr(
                          fontSize: 10, color: AppColors.textMuted,),),
                  const SizedBox(height: 2),
                  Text(text,
                      style: GoogleFonts.notoSansKr(
                          fontSize: 13,
                          color: hasValue
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                          fontWeight: FontWeight.w600,),),
                ],
              ),
            ),
            if (hasValue)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close,
                    size: 16, color: AppColors.textMuted,),
              ),
          ],
        ),
      ),
    );
  }
}

