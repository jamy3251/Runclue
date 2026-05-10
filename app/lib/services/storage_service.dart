import '../config/supabase_safe.dart';
import 'dart:io';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final SupabaseClient _client = safeClient;

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
      throw Exception('Failed to upload evidence: $e');
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
      throw Exception('Failed to upload profile image: $e');
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
      throw Exception('Failed to upload clue image: $e');
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
      throw Exception('Failed to upload bytes: $e');
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
