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

  Future<void> deleteUserAccount() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // 1. Delete their profile data from your public 'profiles' table
      await _supabase
          .from('users')
          .delete()
          .match({'userid': userId});

      // 2. Log them out immediately
      await _supabase.auth.signOut();
      
      // Note: To fully delete the AUTH user, you usually trigger 
      // a PostgreSQL function or an Edge Function for security.
    } catch (e) {
      throw Exception("Failed to delete account: $e");
    }
  }
  Future<bool> userProfileExists() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;
    print("DEBUG: Querying DB for userid: ${user.id}");

    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('userid', user.id)
          .maybeSingle(); // Use maybeSingle to avoid errors if not found
      
      return response != null;
    } catch (e) {
      return false;
    }
  }
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
    Future<void> updateProfile({
      required String newName, 
      String? newAvatar, 
      String? email,
    }) async {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final updates = {
        'userid': user.id,
        'username': newName,
        'email':user.email,
      };

      if (newAvatar != null) {
        updates['profilepic'] = newAvatar;
      }

      await _supabase.from('users').upsert(updates);
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