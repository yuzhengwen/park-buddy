import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

class StorageService {
  final _supabase = Supabase.instance.client;
  static const _bucket = 'parking-images';

  // Uploads raw bytes to Storage, returns the public URL
  Future<String> uploadImage(String sessionId, Uint8List bytes) async {
    final fileName =
        '$sessionId/${DateTime.now().millisecondsSinceEpoch}.jpg';

    await _supabase.storage.from(_bucket).uploadBinary(
          fileName,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );

    return _supabase.storage.from(_bucket).getPublicUrl(fileName);
  }
}