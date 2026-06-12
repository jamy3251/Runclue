import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' show CircleMarker;
import 'package:latlong2/latlong.dart';

import '../common/osm_map.dart';

/// Step 타입별 세부 필드를 제공하는 위젯.
/// _showAddStepDialog()에서 타입 선택 후 동적으로 표시한다.
///
/// 지원 타입:
///   CHECKPOINT → 지도에서 목표 위치 선택 + 반경 설정
///   SNAPSHOT   → 참고 이미지 URL (선택)
///   QUEST      → 질문 + 정답 + 답변 유형 (정확히/포함/자유)
///   OX_QUIZ    → 정답 (O/X) + 해설 + 제한시간
///   LIST       → 체크리스트 항목 추가/삭제

class CheckpointFields extends StatefulWidget {
  final Map<String, dynamic> data;

  const CheckpointFields({super.key, required this.data});

  @override
  State<CheckpointFields> createState() => _CheckpointFieldsState();
}

class _CheckpointFieldsState extends State<CheckpointFields> {
  LatLng _selectedLocation = const LatLng(37.5666, 126.9784); // 서울시청 기본
  double _radius = 50;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('목표 위치', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: OsmMap(
              center: _selectedLocation,
              zoom: 16,
              onTap: (latLng) {
                setState(() {
                  _selectedLocation = latLng;
                  widget.data['target_latitude'] = latLng.latitude;
                  widget.data['target_longitude'] = latLng.longitude;
                });
              },
              markers: [osmPin(_selectedLocation)],
              circles: [
                CircleMarker(
                  point: _selectedLocation,
                  radius: _radius,
                  useRadiusInMeter: true,
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderColor: Colors.blue,
                  borderStrokeWidth: 1,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('반경: '),
            Expanded(
              child: Slider(
                value: _radius,
                min: 10,
                max: 200,
                divisions: 19,
                label: '${_radius.round()}m',
                onChanged: (value) {
                  setState(() {
                    _radius = value;
                    widget.data['location_radius_meters'] = value.round();
                  });
                },
              ),
            ),
            Text('${_radius.round()}m'),
          ],
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    widget.data['target_latitude'] = _selectedLocation.latitude;
    widget.data['target_longitude'] = _selectedLocation.longitude;
    widget.data['location_radius_meters'] = _radius.round();
  }
}

class QuestFields extends StatelessWidget {
  final Map<String, dynamic> data;
  final TextEditingController questionController;
  final TextEditingController answerController;

  const QuestFields({
    super.key,
    required this.data,
    required this.questionController,
    required this.answerController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('질문', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: questionController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: '참여자에게 보여줄 질문',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (v) => data['quest_question'] = v,
        ),
        const SizedBox(height: 12),
        const Text('정답', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: answerController,
          decoration: InputDecoration(
            hintText: '정답을 입력하세요',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (v) => data['quest_answer'] = v,
        ),
        const SizedBox(height: 12),
        const Text('답변 유형', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'exact', label: Text('정확히')),
            ButtonSegment(value: 'contains', label: Text('포함')),
            ButtonSegment(value: 'free_text', label: Text('자유')),
          ],
          selected: {data['quest_answer_type'] ?? 'exact'},
          onSelectionChanged: (set) => data['quest_answer_type'] = set.first,
        ),
      ],
    );
  }
}

class OxQuizFields extends StatefulWidget {
  final Map<String, dynamic> data;
  final TextEditingController explanationController;

  const OxQuizFields({
    super.key,
    required this.data,
    required this.explanationController,
  });

  @override
  State<OxQuizFields> createState() => _OxQuizFieldsState();
}

class _OxQuizFieldsState extends State<OxQuizFields> {
  bool _correctAnswer = true;
  int _timeLimit = 30;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('정답', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Text('O', style: TextStyle(fontSize: 20)),
                selected: _correctAnswer,
                onSelected: (_) {
                  setState(() {
                    _correctAnswer = true;
                    widget.data['quiz_correct_answer'] = true;
                  });
                },
                selectedColor: Colors.green[100],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ChoiceChip(
                label: const Text('X', style: TextStyle(fontSize: 20)),
                selected: !_correctAnswer,
                onSelected: (_) {
                  setState(() {
                    _correctAnswer = false;
                    widget.data['quiz_correct_answer'] = false;
                  });
                },
                selectedColor: Colors.red[100],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text('해설 (선택)', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: widget.explanationController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: '정답 해설을 입력하세요',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (v) => widget.data['quiz_explanation'] = v,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('제한시간: '),
            Expanded(
              child: Slider(
                value: _timeLimit.toDouble(),
                min: 10,
                max: 120,
                divisions: 11,
                label: '$_timeLimit초',
                onChanged: (value) {
                  setState(() {
                    _timeLimit = value.round();
                    widget.data['quiz_time_limit_seconds'] = _timeLimit;
                  });
                },
              ),
            ),
            Text('$_timeLimit초'),
          ],
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    widget.data['quiz_correct_answer'] = true;
    widget.data['quiz_time_limit_seconds'] = 30;
  }
}

class ListFields extends StatefulWidget {
  final Map<String, dynamic> data;

  const ListFields({super.key, required this.data});

  @override
  State<ListFields> createState() => _ListFieldsState();
}

class _ListFieldsState extends State<ListFields> {
  final _itemController = TextEditingController();
  final List<Map<String, dynamic>> _items = [];

  @override
  void dispose() {
    _itemController.dispose();
    super.dispose();
  }

  void _addItem() {
    final text = _itemController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _items.add({'id': 'item_${_items.length}', 'text': text, 'required': true});
      widget.data['checklist_items'] = _items.map((e) => e).toList();
      _itemController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('체크리스트 항목', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _itemController,
                decoration: InputDecoration(
                  hintText: '항목을 입력하세요',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onSubmitted: (_) => _addItem(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _addItem,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Card(
            elevation: 0,
            color: Colors.grey[50],
            margin: const EdgeInsets.only(bottom: 4),
            child: ListTile(
              dense: true,
              leading: Icon(Icons.check_box_outline_blank,
                  size: 20, color: Colors.grey[400],),
              title: Text(item['text'] as String),
              trailing: IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  setState(() {
                    _items.removeAt(index);
                    widget.data['checklist_items'] =
                        _items.map((e) => e).toList();
                  });
                },
              ),
            ),
          );
        }),
      ],
    );
  }
}
