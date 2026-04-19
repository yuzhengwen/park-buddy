import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/login_screen.dart';
import 'package:flutter/foundation.dart';
class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
Future<void> signOut(BuildContext context) async {
  try {
    await _supabase.auth.signOut();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Logged out successfully')));

    // Navigate back to login and remove all previous routes
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
      (route) => false,
    );
  } catch (e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
  }
}

  Future<void> signInWithMagicLink(String email) async {
      await _supabase.auth.signInWithOtp(
        email: email,
        emailRedirectTo: 'com.parkingbuddy.app://auth-callback',
      );
  }

  Future<void> signInWithGithub() async {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.github,
        redirectTo: kIsWeb ? null : 'com.parkingbuddy.app://auth-callback',
        authScreenLaunchMode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
      );
}
}