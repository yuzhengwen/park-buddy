import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:typed_data';
import 'storage_service.dart';
class UserService {
  final _supabase = Supabase.instance.client;
  final _storageService = StorageService();
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

      try {
        final Uint8List bytes = await imageFile.readAsBytes();

        final String publicUrl = await _storageService.uploadImage(
          bucket: 'avatars',
          folder: userId!,
          bytes: bytes,
        );

        return publicUrl;
      } catch (e) {
        print("Storage Error: $e");
        throw Exception("Failed to upload image to storage via StorageService.");
      }
    }
    Future<String> getOwnernameByUserId(String userId) async {
        try {
          final data = await _supabase
              .from('users')
              .select('username')
              .eq('userid', userId)
              .single();

          return data['username'] ?? "Unknown User";
        } catch (e) {
          // If user isn't found or there's an error
          return "Family Member";
        }
      }

    bool isCurrentUser(String? idToCompare) {
      if (idToCompare == null || userId.isEmpty) return false;
      return userId == idToCompare;
    }
}