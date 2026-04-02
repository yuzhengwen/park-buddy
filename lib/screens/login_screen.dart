import 'package:flutter/material.dart';
import 'package:park_buddy/UI/generic_dialog_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'main_screen.dart';
import '../utils/auth.dart';
import 'dart:async';
import '../services/user_service.dart';
import 'edit_profile.dart'; // Ensure this points to your EditProfileScreen file

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final StreamSubscription<AuthState> _authSubscription;
  final supabase = Supabase.instance.client;
  final UserService _userService = UserService(); // Instantiate here
  String? _userId;

  @override
  void initState() {
    super.initState();

    // Listen for auth changes (Magic Link, GitHub, etc.)
    _authSubscription = supabase.auth.onAuthStateChange.listen((data) async {
      if (!mounted|| ModalRoute.of(context)?.isCurrent != true) return;

      final session = data.session;
      if (session != null) {
        setState(() {
          _userId = session.user.id;
        });
        
        // This handles the routing check automatically when the deeplink returns
        print("DEBUG: Listener caught session!");
        await _handleNavigation();
      } else {
        setState(() {
          _userId = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  /// This is the master "Decision" function
Future<void> _handleNavigation() async {
    print("DEBUG: Starting _handleNavigation check...");
    
    try {
      // Check if profile exists
      bool profileExists = await _userService.userProfileExists();
      print("DEBUG: Profile exists in DB: $profileExists");

      if (!mounted) return;

      if (profileExists) {
        print("DEBUG: Navigating to MainScreen");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      } else {
        print("DEBUG: Navigating to Setup (EditProfileScreen)");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const EditProfileScreen(isFirstTime: true),
          ),
        );
      }
    } catch (e) {
      print("DEBUG: ERROR DURING NAVIGATION: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Navigation error: $e")),
        );
      }
    }
  }

  Future<void> signInWithMagicLink(String email) async {
    try {
      await supabase.auth.signInWithOtp(
        email: email,
        emailRedirectTo: 'com.parkingbuddy.app://auth-callback',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Check your email for the Magic Link!')),
        );
      }
    } catch (e) {
      debugPrint("Magic Link Error: $e");
    }
  }

  Future<void> signInWithGithub() async {
    try {
      await supabase.auth.signInWithOAuth(
        OAuthProvider.github,
        redirectTo: kIsWeb ? null : 'com.parkingbuddy.app://auth-callback',
        authScreenLaunchMode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint("GitHub Error: $e");
    }
  }

  Future<void> _signInAnonymously() async {
    try {
      final response = await supabase.auth.signInAnonymously();
      if (!mounted) return;

      setState(() {
        _userId = response.user?.id;
      });

      // Navigate using the check logic
      await _handleNavigation();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ElevatedButton(
            //   onPressed: _signInAnonymously,
            //   child: const Text('Sign in Anonymously'),
            // ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: signInWithGithub,
              child: const Text('Sign in with GitHub'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                final email = await GenericDialogUtils.prompt(
                  context: context,
                  title: 'Enter your email',
                  hintText: 'Email',
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Email cannot be empty';
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                );
                if (email != null) {
                  signInWithMagicLink(email);
                }
              },
              child: const Text('Sign in with Magic Link'),
            ),
          ],
        ),
      ),
    );
  }
}