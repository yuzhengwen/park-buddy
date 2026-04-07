import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
class StorageService {
  final _supabase = Supabase.instance.client;

  Future<String> uploadImage({
    required String bucket,
    required String folder,
    required Uint8List bytes,
  }) async {
    final fileName = '$folder/${DateTime.now().millisecondsSinceEpoch}.jpg';

    await _supabase.storage.from(bucket).uploadBinary(
          fileName,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true, // Overwrites if the file already exists
          ),
        );

    return _supabase.storage.from(bucket).getPublicUrl(fileName);
  }
}