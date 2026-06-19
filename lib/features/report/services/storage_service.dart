import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart' hide StorageException;
import 'package:uuid/uuid.dart';
import '../../../core/errors/exceptions.dart';

class StorageService {
  final SupabaseClient _supabase;
  static const _uuid = Uuid();
  static const String _bucketName = 'road-images';

  StorageService({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? Supabase.instance.client;

  /// Uploads pothole image to the road-images bucket and returns its public URL
  Future<String> uploadPotholeImage(File imageFile) async {
    try {
      final fileName = '${_uuid.v4()}.jpg';

      // Upload file to the public bucket
      await _supabase.storage.from(_bucketName).upload(
            fileName,
            imageFile,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      // Get public access URL
      final publicUrl =
          _supabase.storage.from(_bucketName).getPublicUrl(fileName);
      return publicUrl;
    } on StorageException {
      rethrow;
    } catch (e) {
      throw StorageException('Failed to upload image: ${e.toString()}');
    }
  }

  /// Deletes an image from the storage bucket using its public URL
  Future<void> deleteImage(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        final fileName = pathSegments.last;
        await _supabase.storage.from(_bucketName).remove([fileName]);
      }
    } catch (_) {
      // Silently fail on delete as in original firebase implementation
    }
  }
}
