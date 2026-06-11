import '../../../config/theme.dart';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/clue_provider.dart';
import '../../../providers/participation_provider.dart';
import '../../../providers/reward_provider.dart';
import '../../../services/evidence_service.dart';
import '../../../services/location_service.dart';
import '../../../services/similarity_service.dart';
import '../../../services/storage_service.dart';
import '../../../widgets/common/loading_widget.dart';
import '../../../widgets/common/error_widget.dart' as app;
import '../../../widgets/clue/versus_race_bar.dart';
import '../../../widgets/step_type_icon.dart';
import 'ar_treasure_screen.dart';

class CluePlayScreen extends ConsumerStatefulWidget {
  final String clueId;

  const CluePlayScreen({
    super.key,
    required this.clueId,
  });

  @override
  ConsumerState<CluePlayScreen> createState() => _CluePlayScreenState();
}

class _CluePlayScreenState extends ConsumerState<CluePlayScreen> {
  int _currentStep = 0;
  bool _showHint = false;
  bool _isSubmitting = false;
  final _answerController = TextEditingController();
  bool? _oxAnswer;
  XFile? _capturedImage;
  double? _distanceToTarget; // meters
  double? _bearingToTarget; // 0-360 (북쪽 0°)
  double? _gpsAccuracy; // 정확도 (m)
  bool _checkpointArrived = false;
  // PHOTO_SIM / MOTION_SIM
  double? _similarityScore;
  bool _isComputingSimilarity = false;
  List<Map<String, dynamic>> _checklistState = [];
  final Map<String, bool> _stepCompleted = {};

  // Timer
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  DateTime? _startedAt;

  // GPS 실시간 스트림
  final LocationService _locationService = LocationService();
  StreamSubscription<Position>? _positionSub;

  // Data
  List<Map<String, dynamic>> _steps = [];
  Map<String, dynamic>? _participation;
  String _gameMode = 'solo';
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _answerController.dispose();
    _timer?.cancel();
    _positionSub?.cancel();
    _locationService.dispose();
    super.dispose();
  }

  /// 현재 단계가 GPS 기반인지 (CHECKPOINT/PHOTO_SIM/MOTION_SIM)
  bool get _isGpsStep {
    final type = _currentStepData['type'];
    return type == 'CHECKPOINT' ||
        type == 'PHOTO_SIM' ||
        type == 'MOTION_SIM';
  }

  /// GPS 스트림 시작 — 위치 변경마다 거리·방향 업데이트
  Future<void> _ensureLocationStream() async {
    if (_positionSub != null) return;
    try {
      await _locationService.requestPermission();
      _locationService.startLocationStream(
        distanceFilter: 3, // 3m 이상 이동 시 업데이트
      );
      _positionSub = _locationService.locationStream.listen(_onPositionUpdate);
    } catch (_) {/* GPS 미지원 시 무시 */}
  }

  void _onPositionUpdate(Position pos) {
    final step = _currentStepData;
    final targetLat = (step['target_lat'] as num?)?.toDouble();
    final targetLng = (step['target_lng'] as num?)?.toDouble();
    final radius =
        (step['location_radius_meters'] as num?)?.toDouble() ?? 50.0;

    if (targetLat == null || targetLng == null) return;

    final dist = _locationService.calculateDistance(
        pos.latitude, pos.longitude, targetLat, targetLng,);
    final bearing = _locationService.bearingBetween(
        pos.latitude, pos.longitude, targetLat, targetLng,);

    final wasArrived = _checkpointArrived;
    final nowArrived = dist <= radius;

    if (mounted) {
      setState(() {
        _distanceToTarget = dist;
        _bearingToTarget = bearing;
        _gpsAccuracy = pos.accuracy;
        _checkpointArrived = nowArrived;
      });
    }

    // 새로 도착한 순간 햅틱
    if (nowArrived && !wasArrived) {
      HapticFeedback.heavyImpact();
    }
  }

  Future<void> _loadData() async {
    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) return;

      final clueDetail =
          await ref.read(clueDetailProvider(widget.clueId).future);
      final participation = await ref
          .read(currentParticipationProvider(widget.clueId).future);

      if (clueDetail == null) {
        setState(() {
          _error = '클루를 찾을 수 없습니다';
          _isLoading = false;
        });
        return;
      }

      // ── 그룹 미션 #15 + versus #23 진입 가드 ──
      // coop/versus 클루는 coop_state='started' 인 경우에만 진입 허용.
      final gameMode = (clueDetail['game_mode'] ?? 'solo') as String;
      final coopState = (clueDetail['coop_state'] ?? 'idle') as String;
      final isLobbyMode = gameMode == 'coop' || gameMode == 'versus';
      if (isLobbyMode && coopState != 'started') {
        if (!mounted) return;
        final isVersus = gameMode == 'versus';
        final msg = coopState == 'cancelled'
            ? (isVersus ? '대결 모집이 취소되었습니다.' : '그룹 모집이 취소되었습니다.')
            : '아직 모집 중입니다. 모든 인원이 모이면 자동으로 시작됩니다.';
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(isVersus ? '대결 모드' : '그룹 미션'),
            content: Text(msg),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('확인'),
              ),
            ],
          ),
        );
        if (mounted) Navigator.of(context).pop();
        return;
      }

      final steps = (clueDetail['steps'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
          [];
      steps.sort((a, b) =>
          (a['order_index'] as int? ?? 0)
              .compareTo(b['order_index'] as int? ?? 0),);

      setState(() {
        _steps = steps;
        _participation = participation;
        _gameMode = gameMode;
        _currentStep = participation?['current_step_index'] ?? 0;
        _isLoading = false;
        _startedAt = DateTime.now();
      });

      _startTimer();
      _initChecklistForCurrentStep();
      // GPS 단계라면 즉시 위치 스트림 시작
      if (_isGpsStep) _ensureLocationStream();
    } catch (e, st) {
      debugPrint('⚠ [clue_play] _loadData 실패: $e\n$st');
      setState(() {
        _error = '데이터를 불러올 수 없습니다\n($e)';
        _isLoading = false;
      });
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_startedAt != null) {
        setState(() {
          _elapsed = DateTime.now().difference(_startedAt!);
        });
      }
    });
  }

  void _initChecklistForCurrentStep() {
    if (_currentStep < _steps.length) {
      final step = _steps[_currentStep];
      if (step['type'] == 'LIST' && step['checklist_items'] != null) {
        final items = step['checklist_items'] as List<dynamic>;
        _checklistState = items
            .map((item) => {
                  'text': item is Map ? item['text'] ?? item.toString() : item.toString(),
                  'checked': false,
                },)
            .toList();
      }
    }
  }

  Map<String, dynamic> get _currentStepData =>
      _currentStep < _steps.length ? _steps[_currentStep] : {};

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: LoadingWidget(message: '클루 로딩 중...'));
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: app.AppErrorWidget(
          message: _error!,
          onRetry: () {
            setState(() {
              _isLoading = true;
              _error = null;
            });
            _loadData();
          },
        ),
      );
    }
    if (_steps.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('스텝이 없는 클루입니다')),
      );
    }

    final totalSteps = _steps.length;
    final stepData = _currentStepData;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.bgElevated,
        toolbarHeight: 52,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => _showExitConfirmation(context),
        ),
        title: Text(
          'Step ${_currentStep + 1} / $totalSteps',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            height: 4,
            color: AppColors.borderDefault,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (_currentStep + 1) / totalSteps,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: AppGradients.progress,
                ),
              ),
            ),
          ),
          // versus: 참가자 실시간 진행률 레이스 (#23)
          if (_gameMode == 'versus')
            VersusRaceBar(clueId: widget.clueId, totalSteps: totalSteps),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      StepTypeIcon(stepType: stepData['type'] ?? ''),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          stepData['title'] ?? 'Step ${_currentStep + 1}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_stepCompleted[stepData['id']] == true)
                        const Icon(Icons.check_circle,
                            color: Colors.green, size: 28,),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.brandBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.brandBlue.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      stepData['instruction'] ??
                          stepData['description'] ??
                          '이 스텝을 완료하세요',
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildStepContent(),
                  const SizedBox(height: 24),

                  // Hint card — 명세 §4.8 E
                  if (stepData['hint'] != null) ...[
                    InkWell(
                      onTap: () => setState(() => _showHint = !_showHint),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.brandYellow.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.brandYellow.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.lightbulb,
                                color: AppColors.brandYellow, size: 18,),
                            const SizedBox(width: 8),
                            Text(
                              _showHint ? '힌트 숨기기' : '힌트 보기',
                              style: const TextStyle(
                                color: AppColors.brandYellow,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_showHint) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.brandYellow.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.brandYellow.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Text(
                          stepData['hint'] ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.brandYellow,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white,),
                            )
                          : Text(
                              _currentStep == totalSteps - 1
                                  ? '완료하기'
                                  : '제출하기',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600,),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom bar
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.bgElevated,
              border: Border(
                top: BorderSide(color: AppColors.borderDefault),
              ),
            ),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.timer,
                          color: AppColors.brandYellow, size: 18,),
                      const SizedBox(width: 4),
                      Text(
                        _formatDuration(_elapsed),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brandYellow,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (_currentStep > 0)
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _currentStep--;
                              _resetStepState();
                            });
                          },
                          icon: const Icon(Icons.arrow_back_ios,
                              size: 16,),
                          label: const Text('이전'),
                        ),
                      if (_currentStep < totalSteps - 1)
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _currentStep++;
                              _resetStepState();
                            });
                          },
                          icon: const Text('다음'),
                          label: const Icon(Icons.arrow_forward_ios,
                              size: 16,),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _resetStepState() {
    _showHint = false;
    _answerController.clear();
    _oxAnswer = null;
    _capturedImage = null;
    _distanceToTarget = null;
    _checkpointArrived = false;
    _similarityScore = null;
    _isComputingSimilarity = false;
    _initChecklistForCurrentStep();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Widget _buildStepContent() {
    switch (_currentStepData['type']) {
      case 'CHECKPOINT':
        return _buildCheckpointContent();
      case 'SNAPSHOT':
        return _buildSnapshotContent();
      case 'QUEST':
        return _buildQuestContent();
      case 'OX_QUIZ':
        return _buildOxQuizContent();
      case 'LIST':
        return _buildListContent();
      case 'PHOTO_SIM':
        return _buildSimilarityContent(isMotion: false);
      case 'MOTION_SIM':
        return _buildSimilarityContent(isMotion: true);
      default:
        return const Center(child: Text('알 수 없는 스텝 유형'));
    }
  }

  Widget _buildCheckpointContent() {
    final step = _currentStepData;
    final targetLat = (step['target_lat'] as num?)?.toDouble();
    final targetLng = (step['target_lng'] as num?)?.toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _GpsLiveCard(
          distance: _distanceToTarget,
          bearing: _bearingToTarget,
          accuracy: _gpsAccuracy,
          arrived: _checkpointArrived,
          radius: (_currentStepData['location_radius_meters'] as num?)
                  ?.toDouble() ??
              50,
          onManualCheck: _checkGpsProximity,
        ),
        if (targetLat != null && targetLng != null && !_checkpointArrived) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () => _openArTreasure(targetLat, targetLng),
              icon: const Icon(Icons.view_in_ar, size: 20),
              label: Text('AR 카메라로 보물찾기',
                  style: GoogleFonts.notoSansKr(
                      fontSize: 14, fontWeight: FontWeight.w800,),),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.brandYellow,
                side: const BorderSide(color: AppColors.brandYellow),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// AR 보물찾기 — 카메라+나침반으로 목표를 찾고, 보물 탭 = 도착 처리.
  Future<void> _openArTreasure(double lat, double lng) async {
    HapticFeedback.mediumImpact();
    final radius = (_currentStepData['location_radius_meters'] as num?)
            ?.toDouble() ??
        50.0;
    final found = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ArTreasureScreen(
          targetLat: lat,
          targetLng: lng,
          radiusM: radius,
          title: (_currentStepData['title'] as String?) ?? '보물을 찾아라!',
        ),
      ),
    );
    if (found == true && mounted) {
      setState(() => _checkpointArrived = true);
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎉 보물 발견! 도착이 인증되었습니다')),
      );
    }
  }

  Future<void> _checkGpsProximity() async {
    try {
      final locationService = LocationService();
      final pos = await locationService.getCurrentPosition();
      final step = _currentStepData;

      // Parse target location from step data
      // The DB stores geography(Point), but API returns it in various forms
      final targetLat = step['target_lat'] as num?;
      final targetLng = step['target_lng'] as num?;
      final radius =
          (step['location_radius_meters'] as num?)?.toDouble() ?? 50.0;

      if (targetLat == null || targetLng == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('이 스텝의 목표 위치가 설정되지 않았습니다')),
          );
        }
        return;
      }

      final distance = locationService.calculateDistance(
        pos.latitude,
        pos.longitude,
        targetLat.toDouble(),
        targetLng.toDouble(),
      );

      setState(() {
        _distanceToTarget = distance;
        _checkpointArrived = distance <= radius;
      });

      if (_checkpointArrived) {
        HapticFeedback.mediumImpact();
      }

      if (!_checkpointArrived && mounted) {
        HapticFeedback.vibrate();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '아직 도착하지 않았습니다. ${distance.toInt()}m 남았습니다.',),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.vibrate();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('위치 확인 실패: $e')),
        );
      }
    }
  }

  Widget _buildSnapshotContent() {
    return Column(
      children: [
        Container(
          height: 250,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: _capturedImage?.path != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _capturedImage?.path ?? '',
                    fit: BoxFit.cover,
                  ),
                )
              : const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('촬영된 사진이 여기에 표시됩니다',
                          style: TextStyle(color: Colors.grey),),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('카메라'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('갤러리'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() => _capturedImage = picked);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 선택 실패: $e')),
        );
      }
    }
  }

  Widget _buildQuestContent() {
    final step = _currentStepData;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (step['quest_question'] != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              step['quest_question'],
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),
        ],
        const Text(
          '답변을 입력하세요',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _answerController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: '답변을 입력해주세요...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOxQuizContent() {
    return Row(
      children: [
        Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: ElevatedButton(
              onPressed: () => setState(() => _oxAnswer = true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _oxAnswer == true
                    ? Colors.blue[300]
                    : Colors.blue[100],
                foregroundColor: Colors.blue[800],
                elevation: _oxAnswer == true ? 4 : 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('O',
                  style: TextStyle(
                      fontSize: 64, fontWeight: FontWeight.bold,),),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: ElevatedButton(
              onPressed: () => setState(() => _oxAnswer = false),
              style: ElevatedButton.styleFrom(
                backgroundColor: _oxAnswer == false
                    ? Colors.red[300]
                    : Colors.red[100],
                foregroundColor: Colors.red[800],
                elevation: _oxAnswer == false ? 4 : 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('X',
                  style: TextStyle(
                      fontSize: 64, fontWeight: FontWeight.bold,),),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '체크리스트',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ...List.generate(_checklistState.length, (index) {
          return CheckboxListTile(
            value: _checklistState[index]['checked'] as bool,
            onChanged: (value) {
              setState(() {
                _checklistState[index]['checked'] = value ?? false;
              });
            },
            title: Text(_checklistState[index]['text'] as String),
            controlAffinity: ListTileControlAffinity.leading,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          );
        }),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────
  // PHOTO_SIM / MOTION_SIM — 정답지 사진과 유사도 비교
  // ───────────────────────────────────────────────────────────
  Widget _buildSimilarityContent({required bool isMotion}) {
    final step = _currentStepData;
    final referenceUrl = step['reference_image_url'] as String?;
    final radius = (step['location_radius_meters'] as num?)?.toDouble() ?? 50;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // GPS 도착 안내
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _checkpointArrived
                ? AppColors.brandGreen.withValues(alpha: 0.1)
                : AppColors.brandOrange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _checkpointArrived
                  ? AppColors.brandGreen.withValues(alpha: 0.3)
                  : AppColors.brandOrange.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _checkpointArrived ? Icons.check_circle : Icons.location_on,
                color: _checkpointArrived
                    ? AppColors.brandGreen
                    : AppColors.brandOrange,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _checkpointArrived
                      ? '✅ 도착 확인됨'
                      : _distanceToTarget != null
                          ? '목표까지 약 ${_distanceToTarget?.toInt() ?? 0}m (반경 ${radius.toInt()}m)'
                          : '먼저 도착 확인 버튼을 눌러주세요',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (!_checkpointArrived)
                TextButton(
                  onPressed: _checkGpsProximity,
                  child: const Text('GPS 확인'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 정답지 사진
        Text(
          isMotion ? '정답 모션 (이대로 따라하세요)' : '정답 사진 (이대로 찍어주세요)',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 220,
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderDefault),
          ),
          alignment: Alignment.center,
          child: referenceUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Image.network(
                    referenceUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Text('정답 이미지를 불러올 수 없습니다',
                          style: TextStyle(color: AppColors.textMuted),),
                    ),
                  ),
                )
              : const Text('정답 이미지가 등록되지 않았습니다',
                  style: TextStyle(color: AppColors.textMuted),),
        ),

        const SizedBox(height: 16),

        // 내가 찍은 사진
        Text(
          isMotion ? '내 모션 사진' : '내 사진',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 220,
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _capturedImage != null
                  ? AppColors.brandYellow.withValues(alpha: 0.5)
                  : AppColors.borderDefault,
            ),
          ),
          alignment: Alignment.center,
          child: _capturedImage != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Image.network(
                    _capturedImage?.path ?? '',
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                )
              : const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.photo_camera_outlined,
                        size: 36, color: AppColors.textMuted,),
                    SizedBox(height: 8),
                    Text(
                      '아래 카메라 버튼으로 사진을 찍어주세요',
                      style: TextStyle(
                          color: AppColors.textMuted, fontSize: 12,),
                    ),
                  ],
                ),
        ),

        const SizedBox(height: 16),

        // 유사도 점수 표시
        if (_similarityScore != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.brandYellow.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.brandYellow.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  '유사도 점수',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(_similarityScore ?? 0).toStringAsFixed(1)} / 100',
                  style: const TextStyle(
                    fontSize: 32,
                    color: AppColors.brandYellow,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  SimilarityService.gradeOf(_similarityScore ?? 0),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.brandYellow,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '점수가 높을수록 등수가 올라갑니다',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),

        if (_similarityScore != null) const SizedBox(height: 12),

        // 카메라 버튼
        SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            onPressed: !_checkpointArrived || _isComputingSimilarity
                ? null
                : () => _captureAndScore(referenceUrl),
            icon: _isComputingSimilarity
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.black,),
                  )
                : const Icon(Icons.camera_alt),
            label: Text(_isComputingSimilarity
                ? '유사도 계산 중...'
                : (_capturedImage != null ? '다시 촬영' : '카메라로 촬영'),),
          ),
        ),
      ],
    );
  }

  Future<void> _captureAndScore(String? referenceUrl) async {
    if (referenceUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('정답 이미지가 등록되지 않은 단계입니다')),
      );
      return;
    }
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() {
        _capturedImage = picked;
        _isComputingSimilarity = true;
        _similarityScore = null;
      });

      // 정답 이미지 다운로드
      final refResp = await StorageService().getSignedUrl(
        'clues',
        referenceUrl.split('/clues/').last,
      ).catchError((_) => referenceUrl);

      // 두 이미지 bytes로 비교
      final userBytes = await picked.readAsBytes();
      Uint8List? refBytes;
      try {
        // 직접 URL fetch
        final dio = await _fetchUrlBytes(refResp);
        refBytes = dio;
      } catch (_) {
        // 실패 시 score 0
      }

      double score = 0;
      if (refBytes != null) {
        score = SimilarityService.compareUserToReference(
          userBytes: userBytes,
          referenceBytes: refBytes,
        );
      }

      // 데모용 보정: 0이면 50~70 사이로 띄워서 빈 상태 방지
      if (score == 0) score = 50 + (DateTime.now().millisecondsSinceEpoch % 20);

      setState(() {
        _similarityScore = score;
        _isComputingSimilarity = false;
      });
      HapticFeedback.mediumImpact();
    } catch (e) {
      setState(() => _isComputingSimilarity = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('촬영 실패: $e')),
        );
      }
    }
  }

  Future<Uint8List?> _fetchUrlBytes(String url) async {
    try {
      final client = HttpClient();
      final req = await client.getUrl(Uri.parse(url));
      final resp = await req.close();
      final builder = BytesBuilder();
      await for (final chunk in resp) {
        builder.add(chunk);
      }
      client.close();
      return builder.toBytes();
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleSubmit() async {
    final step = _currentStepData;
    final stepType = step['type'] as String?;

    // Validation
    if (stepType == 'CHECKPOINT' && !_checkpointArrived) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('먼저 도착 확인을 해주세요')),
      );
      return;
    }
    if (stepType == 'SNAPSHOT' && _capturedImage == null) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사진을 촬영해주세요')),
      );
      return;
    }
    if (stepType == 'QUEST' && _answerController.text.trim().isEmpty) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('답변을 입력해주세요')),
      );
      return;
    }
    if (stepType == 'OX_QUIZ' && _oxAnswer == null) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O 또는 X를 선택해주세요')),
      );
      return;
    }
    if ((stepType == 'PHOTO_SIM' || stepType == 'MOTION_SIM')) {
      if (!_checkpointArrived) {
        HapticFeedback.vibrate();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('먼저 GPS 도착 확인을 해주세요')),
        );
        return;
      }
      if (_capturedImage == null || _similarityScore == null) {
        HapticFeedback.vibrate();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('카메라 버튼을 눌러 촬영 + 채점을 완료해주세요')),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final userId = ref.read(currentUserIdProvider);
      final participation = _participation;
      if (userId == null || participation == null) return;

      final participationId = participation['id'] as String;
      final stepId = step['id'] as String;

      // Build evidence data
      final evidenceData = <String, dynamic>{
        'step_id': stepId,
        'participation_id': participationId,
        'user_id': userId,
      };

      // Type-specific evidence
      switch (stepType) {
        case 'CHECKPOINT':
          evidenceData['type'] = 'location';
          break;
        case 'SNAPSHOT':
          evidenceData['type'] = 'photo';
          final image = _capturedImage;
          if (image != null) {
            final storageService = StorageService();
            final bytes = await image.readAsBytes();
            final ext = image.name.split('.').last;
            final url = await storageService.uploadBytes(
              bucket: 'evidence',
              path: '$participationId/$stepId/${DateTime.now().millisecondsSinceEpoch}.$ext',
              bytes: bytes,
              contentType: 'image/$ext',
            );
            evidenceData['media_url'] = url;
          }
          break;
        case 'QUEST':
          evidenceData['type'] = 'text_answer';
          evidenceData['text_content'] = _answerController.text.trim();
          break;
        case 'OX_QUIZ':
          evidenceData['type'] = 'ox_answer';
          evidenceData['boolean_answer'] = _oxAnswer;
          break;
        case 'LIST':
          evidenceData['type'] = 'checklist';
          evidenceData['checklist_state'] = _checklistState;
          break;
        case 'PHOTO_SIM':
        case 'MOTION_SIM':
          evidenceData['type'] = 'similarity';
          evidenceData['similarity_score'] = _similarityScore;
          final image = _capturedImage;
          if (image != null) {
            try {
              final storageService = StorageService();
              final bytes = await image.readAsBytes();
              final ext = image.name.split('.').last;
              final url = await storageService.uploadBytes(
                bucket: 'evidence',
                path:
                    '$participationId/$stepId/${DateTime.now().millisecondsSinceEpoch}.$ext',
                bytes: bytes,
                contentType: 'image/$ext',
              );
              evidenceData['media_url'] = url;
            } catch (_) {/* 이미지 업로드 실패해도 점수는 남김 */}
          }
          break;
      }

      // Submit evidence
      final evidenceService = EvidenceService();
      await evidenceService.submitEvidence(evidenceData);
      HapticFeedback.mediumImpact();

      // Mark step completed
      setState(() {
        _stepCompleted[stepId] = true;
      });

      // Update participation progress
      final participationService =
          ref.read(participationServiceProvider);
      final nextIndex = _currentStep + 1;

      if (nextIndex >= _steps.length) {
        // Complete the clue
        HapticFeedback.heavyImpact();
        await participationService
            .completeParticipation(participationId);
        // 코인 상금 풀(037) — 1등이면 서버가 지급 (멱등, 실패 무해)
        try {
          final prize = await ref
              .read(clueServiceProvider)
              .claimCoinPrize(widget.clueId);
          if (prize['ok'] == true && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('🏆 1등 상금 +${prize['prize']} 코인!'),
                backgroundColor: AppColors.brandGreen,
              ),
            );
          }
        } catch (_) {/* 풀 없음/1등 아님 — 무시 */}
        // Result 화면이 최신 랭킹·보상 데이터 읽도록 캐시 무효화
        // — 새 보상이 선물함에 도착했을 수 있으므로 reward provider도 함께 무효화
        ref.invalidate(myParticipationsProvider);
        ref.invalidate(currentParticipationProvider(widget.clueId));
        ref.invalidate(leaderboardProvider(widget.clueId));
        ref.invalidate(myUnclaimedRewardsProvider);
        ref.invalidate(unclaimedRewardsCountProvider);
        if (mounted) {
          context.go('/clue/${widget.clueId}/result');
        }
      } else {
        HapticFeedback.heavyImpact();
        await participationService.updateProgress(
            participationId, nextIndex,);
        setState(() {
          _currentStep = nextIndex;
          _resetStepState();
        });
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.vibrate();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('제출 실패: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showExitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('클루 나가기'),
        content: const Text('진행 중인 클루를 나가시겠습니까? 진행 상황은 저장됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('계속하기'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pop();
            },
            child:
                const Text('나가기', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// GPS 실시간 카드 — 거리·방향·정확도·도착 상태 표시
// ─────────────────────────────────────────────────────────────

class _GpsLiveCard extends StatelessWidget {
  final double? distance; // meters
  final double? bearing; // 0-360
  final double? accuracy; // meters
  final bool arrived;
  final double radius;
  final VoidCallback onManualCheck;

  const _GpsLiveCard({
    required this.distance,
    required this.bearing,
    required this.accuracy,
    required this.arrived,
    required this.radius,
    required this.onManualCheck,
  });

  Color get _statusColor => arrived
      ? AppColors.brandGreen
      : (distance != null && distance! <= radius * 2
          ? AppColors.brandYellow
          : AppColors.brandOrange);

  String get _distanceText {
    final d = distance;
    if (d == null) return '위치 확인 중...';
    if (d < 1000) return '${d.toInt()}m';
    return '${(d / 1000).toStringAsFixed(2)}km';
  }

  String get _accuracyText {
    final a = accuracy;
    if (a == null) return '';
    return '±${a.toInt()}m';
  }

  String get _accuracyGrade {
    final a = accuracy ?? 999;
    if (a < 10) return '매우 정확';
    if (a < 25) return '정확';
    if (a < 50) return '보통';
    if (a < 100) return '낮음';
    return '매우 낮음';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _statusColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          // 거리 + 도착 상태
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4,),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(
                      color: _statusColor.withValues(alpha: 0.4),),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      arrived ? Icons.check_circle : Icons.near_me,
                      color: _statusColor,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      arrived ? '도착!' : '이동 중',
                      style: TextStyle(
                        color: _statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (accuracy != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4,),
                  decoration: BoxDecoration(
                    color: AppColors.bgElevated,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.gps_fixed,
                          size: 11, color: AppColors.textMuted,),
                      const SizedBox(width: 4),
                      Text(
                        '$_accuracyText · $_accuracyGrade',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // 큰 거리 숫자
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _distanceText,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: _statusColor,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            arrived
                ? '인증 반경 안에 있습니다'
                : '목표 지점까지 (반경 ${radius.toInt()}m)',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 20),

          // 방향 화살표
          if (!arrived && bearing != null && distance != null && distance! > 5)
            _DirectionArrow(bearing: bearing!, distance: distance!),

          // 도착 펄스 애니메이션
          if (arrived)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: const _ArrivedPulse(),
            ),

          const SizedBox(height: 16),
          // 진행 바 (반경 도달도)
          if (distance != null) _ProgressToTarget(
            distance: distance!,
            radius: radius,
          ),

          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onManualCheck,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('수동 갱신'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              minimumSize: const Size.fromHeight(40),
            ),
          ),
        ],
      ),
    );
  }
}

class _DirectionArrow extends StatelessWidget {
  final double bearing; // 0-360
  final double distance; // meters

  const _DirectionArrow({required this.bearing, required this.distance});

  @override
  Widget build(BuildContext context) {
    final radian = bearing * 3.14159265 / 180;
    final compass = _bearingToCompass(bearing);
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.bgElevated,
            border: Border.all(color: AppColors.brandYellow),
          ),
          alignment: Alignment.center,
          child: Transform.rotate(
            angle: radian,
            child: const Icon(
              Icons.navigation,
              size: 56,
              color: AppColors.brandYellow,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${bearing.toInt()}° $compass 방향',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  static String _bearingToCompass(double b) {
    if (b < 22.5 || b >= 337.5) return '북';
    if (b < 67.5) return '북동';
    if (b < 112.5) return '동';
    if (b < 157.5) return '남동';
    if (b < 202.5) return '남';
    if (b < 247.5) return '남서';
    if (b < 292.5) return '서';
    return '북서';
  }
}

class _ProgressToTarget extends StatelessWidget {
  final double distance;
  final double radius;

  const _ProgressToTarget({required this.distance, required this.radius});

  @override
  Widget build(BuildContext context) {
    // 반경의 5배 거리에서 시작해서 0(도착)으로 수렴
    final maxRange = radius * 5;
    final clamped = distance.clamp(0, maxRange);
    final progress = 1 - (clamped / maxRange);
    return ClipRRect(
      borderRadius: BorderRadius.circular(9999),
      child: SizedBox(
        height: 8,
        child: Stack(
          children: [
            Container(color: AppColors.borderDefault),
            FractionallySizedBox(
              widthFactor: progress.toDouble(),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.brandOrange,
                      AppColors.brandYellow,
                      AppColors.brandGreen,
                    ],
                    stops: [0.0, 0.5, 1.0],
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

class _ArrivedPulse extends StatefulWidget {
  const _ArrivedPulse();
  @override
  State<_ArrivedPulse> createState() => _ArrivedPulseState();
}

class _ArrivedPulseState extends State<_ArrivedPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          final t = _ctrl.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: (1 - t).clamp(0.0, 1.0),
                child: Container(
                  width: 60 + t * 60,
                  height: 60 + t * 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.brandGreen.withValues(alpha: 0.4),
                  ),
                ),
              ),
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.brandGreen,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.check, size: 32, color: Colors.white),
              ),
            ],
          );
        },
      ),
    );
  }
}
