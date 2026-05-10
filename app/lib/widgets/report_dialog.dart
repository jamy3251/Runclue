import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/report_service.dart';

/// 신고 다이얼로그. 신고 사유 선택 + 선택적 설명 입력.
///
/// 사용: ReportDialog.show(context, targetType: 'clue', targetId: clueId)
class ReportDialog extends StatefulWidget {
  final String targetType;
  final String targetId;

  const ReportDialog({
    super.key,
    required this.targetType,
    required this.targetId,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String targetType,
    required String targetId,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => ReportDialog(
        targetType: targetType,
        targetId: targetId,
      ),
    );
  }

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  String? _selectedReason;
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  static const _reasons = [
    {'value': 'inappropriate', 'label': '부적절한 콘텐츠'},
    {'value': 'spam', 'label': '스팸/광고'},
    {'value': 'fraud', 'label': '사기/허위'},
    {'value': 'safety', 'label': '안전 위협'},
    {'value': 'harassment', 'label': '괴롭힘/모욕'},
    {'value': 'copyright', 'label': '저작권 침해'},
    {'value': 'other', 'label': '기타'},
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedReason == null) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isSubmitting = true);

    try {
      await ReportService().submitReport(
        reporterId: userId,
        targetType: widget.targetType,
        targetId: widget.targetId,
        reason: _selectedReason!,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('신고 실패: $e')),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('신고하기'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '신고 사유를 선택해주세요',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ..._reasons.map((reason) {
              return RadioListTile<String>(
                value: reason['value']!,
                groupValue: _selectedReason,
                onChanged: (v) => setState(() => _selectedReason = v),
                title: Text(reason['label']!, style: const TextStyle(fontSize: 14)),
                dense: true,
                contentPadding: EdgeInsets.zero,
              );
            }),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '상세 설명 (선택)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: _selectedReason == null || _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  height: 18, width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('신고'),
        ),
      ],
    );
  }
}
