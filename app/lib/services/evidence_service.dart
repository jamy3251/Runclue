import 'package:supabase_flutter/supabase_flutter.dart';

import 'location_service.dart';

class EvidenceService {
  final SupabaseClient _client;
  final LocationService _locationService;

  EvidenceService({
    SupabaseClient? client,
    LocationService? locationService,
  })  : _client = client ?? Supabase.instance.client,
        _locationService = locationService ?? LocationService();

  /// Submit a new evidence record.
  Future<Map<String, dynamic>> submitEvidence(
    Map<String, dynamic> evidenceData,
  ) async {
    try {
      final response = await _client
          .from('evidences')
          .insert(evidenceData)
          .select()
          .single();
      return response;
    } catch (e) {
      throw Exception('Failed to submit evidence: $e');
    }
  }

  /// Get evidences for a specific step and participation.
  Future<List<Map<String, dynamic>>> getEvidencesForStep(
    String stepId,
    String participationId,
  ) async {
    try {
      final response = await _client
          .from('evidences')
          .select('*')
          .eq('step_id', stepId)
          .eq('participation_id', participationId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch evidences: $e');
    }
  }

  /// Get pending evidences for the clue creator to review.
  Future<List<Map<String, dynamic>>> getEvidencesForReview(
    String clueId,
    String creatorId,
  ) async {
    try {
      final response = await _client
          .from('evidences')
          .select('*, steps!inner(clue_id), participations!inner(user_id)')
          .eq('steps.clue_id', clueId)
          .eq('status', 'pending')
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch evidences for review: $e');
    }
  }

  /// Validate (approve/reject) an evidence submission.
  Future<Map<String, dynamic>> validateEvidence({
    required String evidenceId,
    required String status,
    String? reason,
    String? validatorId,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status,
        'validated_at': DateTime.now().toIso8601String(),
        if (reason != null) 'rejection_reason': reason,
        if (validatorId != null) 'validator_id': validatorId,
      };

      final response = await _client
          .from('evidences')
          .update(updateData)
          .eq('id', evidenceId)
          .select()
          .single();
      return response;
    } catch (e) {
      throw Exception('Failed to validate evidence: $e');
    }
  }

  /// Auto-validate a checkpoint evidence by checking GPS proximity.
  ///
  /// Returns true if user location is within the step's required radius.
  bool autoValidateCheckpoint(
    Map<String, dynamic> evidence,
    Map<String, dynamic> step,
  ) {
    try {
      final userLat = (evidence['latitude'] as num).toDouble();
      final userLng = (evidence['longitude'] as num).toDouble();
      final targetLat = (step['latitude'] as num).toDouble();
      final targetLng = (step['longitude'] as num).toDouble();
      final radiusMeters = (step['radius_meters'] as num?)?.toDouble() ?? 50.0;

      final distance = _locationService.calculateDistance(userLat, userLng, targetLat, targetLng);
      return distance <= radiusMeters;
    } catch (e) {
      return false;
    }
  }

  /// Auto-validate a quiz evidence by checking the answer match.
  ///
  /// Returns true if the submitted answer matches the correct answer
  /// (case-insensitive, trimmed).
  bool autoValidateQuiz(
    Map<String, dynamic> evidence,
    Map<String, dynamic> step,
  ) {
    try {
      final submittedAnswer =
          (evidence['answer'] as String?)?.trim().toLowerCase() ?? '';
      final correctAnswer =
          (step['correct_answer'] as String?)?.trim().toLowerCase() ?? '';
      return submittedAnswer.isNotEmpty && submittedAnswer == correctAnswer;
    } catch (e) {
      return false;
    }
  }

  /// Auto-validate a checklist evidence by verifying all required items
  /// are checked.
  ///
  /// Returns true if every required checklist item is present in the
  /// submitted items.
  bool autoValidateChecklist(
    Map<String, dynamic> evidence,
    Map<String, dynamic> step,
  ) {
    try {
      final requiredItems =
          List<String>.from(step['checklist_items'] ?? []);
      final submittedItems =
          List<String>.from(evidence['checked_items'] ?? []);

      if (requiredItems.isEmpty) return false;

      return requiredItems.every(
        (item) => submittedItems.contains(item),
      );
    } catch (e) {
      return false;
    }
  }

}
