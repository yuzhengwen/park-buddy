import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class UserService {
  final _supabase = Supabase.instance.client;

  // 1. Get current user object
  User? get currentUser => _supabase.auth.currentUser;

  // 2. Get Display Name safely
  String get userId => _supabase.auth.currentUser?.id ?? "Guest User";

  // 3. Get Email
  String get email => currentUser?.email ?? "No email linked";

  Future<Map<String, dynamic>?> getProfile() async {
      if (userId == null) return null;
      
      try {
        final data = await _supabase
            .from('users')
            .select('username, profilepic') // Select both columns
            .eq('userid', userId!)
            .single();
        print(data); // Debug print to check the fetched data
        return data; // Returns {'username': '...', 'profilepic': '...'}
      } catch (e) {
        print("Error fetching profile: $e");
        return null;
      }
    }
    Future<void> updateProfile({required String newName, String? newAvatar}) async {
        if (userId == null) return;

        final updates = {
          'username': newName,
          // 'updated_at': DateTime.now().toIso8601String(),
        };

        if (newAvatar != null) {
          updates['profilepic'] = newAvatar;
        }

        await _supabase
            .from('users')
            .update(updates)
            .eq('userid', userId!);
    }
    Future<String> uploadProfilePicture(File imageFile) async {
    if (userId == null) throw Exception("User not logged in");

    // Create a unique path using timestamp to avoid browser caching issues
    final String fileName = '$userId/${DateTime.now()}.jpg';

    try {
      // Upload to the 'avatars' bucket
      print("UPLOAD ATTEMPT ---");
print("Bucket: avatars");
print("Path: $userId/${DateTime.now().millisecondsSinceEpoch}.jpg");
print("Auth ID from Supabase: ${_supabase.auth.currentUser?.id}");
      await _supabase.storage.from('avatars').upload(
            fileName,
            imageFile,
            fileOptions: const FileOptions(upsert: true),
          );

      // Return the public URL so the UI can pass it to the save method
      return _supabase.storage.from('avatars').getPublicUrl(fileName);
    } catch (e) {
      print("Storage Error: $e");
      throw Exception("Failed to upload image to storage.");
    }
  }
}