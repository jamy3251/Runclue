import '../config/supabase_safe.dart';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final SupabaseClient _client = safeClient;

  /// 업로드 실패 시 운영자가 바로 원인을 알 수 있도록 콘솔에 분류해서 노출.
  Never _logAndThrow(String op, String bucket, Object e) {
    final msg = e.toString();
    if (msg.contains('Bucket not found')) {
      debugPrint(
          '⚠ [storage] $op($bucket): 버킷이 존재하지 않습니다. '
          'supabase/migrations/003 적용 필요. (raw=$e)');
      throw Exception('스토리지 버킷($bucket)이 없어요 — 운영자에게 문의해주세요');
    }
    if (msg.contains('new row violates row-level security') ||
        msg.contains('42501')) {
      debugPrint(
          '⚠ [storage] $op($bucket): RLS 정책 거부. '
          'supabase/migrations/003 적용 필요. (raw=$e)');
      throw Exception('스토리지 권한이 없어요 — 다시 로그인하거나 운영자에게 문의해주세요');
    }
    debugPrint('⚠ [storage] $op($bucket) 실패: $e');
    throw Exception('$op 실패: $e');
  }

  /// Upload evidence file to the evidence bucket.
  ///
  /// Returns the public URL of the uploaded file.
  Future<String> uploadEvidence(
    File file,
    String participationId,
    String stepId,
  ) async {
    try {
      final extension = file.path.split('.').last;
      final path =
          '$participationId/$stepId/${DateTime.now().millisecondsSinceEpoch}.$extension';

      await _client.storage.from('evidence').upload(
            path,
            file,
            fileOptions: const FileOptions(upsert: true),
          );

      final url = _client.storage.from('evidence').getPublicUrl(path);
      return url;
    } catch (e) {
      _logAndThrow('uploadEvidence', 'evidence', e);
    }
  }

  /// Upload a profile image for a user.
  ///
  /// Returns the public URL of the uploaded image.
  Future<String> uploadProfileImage(File file, String userId) async {
    try {
      final extension = file.path.split('.').last;
      final path =
          '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$extension';

      await _client.storage.from('profiles').upload(
            path,
            file,
            fileOptions: const FileOptions(upsert: true),
          );

      final url = _client.storage.from('profiles').getPublicUrl(path);
      return url;
    } catch (e) {
      _logAndThrow('uploadProfileImage', 'profiles', e);
    }
  }

  /// Upload a clue image.
  ///
  /// Returns the public URL of the uploaded image.
  Future<String> uploadClueImage(File file, String clueId) async {
    try {
      final extension = file.path.split('.').last;
      final path =
          '$clueId/${DateTime.now().millisecondsSinceEpoch}.$extension';

      await _client.storage.from('clues').upload(
            path,
            file,
            fileOptions: const FileOptions(upsert: true),
          );

      final url = _client.storage.from('clues').getPublicUrl(path);
      return url;
    } catch (e) {
      _logAndThrow('uploadClueImage', 'clues', e);
    }
  }

  /// Upload raw bytes (useful for web or in-memory data).
  ///
  /// Returns the public URL of the uploaded file.
  Future<String> uploadBytes({
    required String bucket,
    required String path,
    required Uint8List bytes,
    String? contentType,
  }) async {
    try {
      await _client.storage.from(bucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: contentType,
            ),
          );

      final url = _client.storage.from(bucket).getPublicUrl(path);
      return url;
    } catch (e) {
      _logAndThrow('uploadBytes', bucket, e);
    }
  }

  /// Delete a file from a storage bucket.
  Future<void> deleteFile(String bucket, String path) async {
    try {
      await _client.storage.from(bucket).remove([path]);
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  /// Get a temporary signed URL for a private file.
  Future<String> getSignedUrl(
    String bucket,
    String path, {
    int expiresIn = 3600,
  }) async {
    try {
      final url = await _client.storage
          .from(bucket)
          .createSignedUrl(path, expiresIn);
      return url;
    } catch (e) {
      throw Exception('Failed to get signed URL: $e');
    }
  }
}
