import 'package:flutter/material.dart';
import 'package:park_buddy/widgets/generic_dialog_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'main_screen.dart';
import '../utils/auth.dart';
import 'dart:async';
import '../services/user_service.dart';
import 'edit_profile.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final StreamSubscription<AuthState> _authSubscription;
  final supabase = Supabase.instance.client;
  final UserService _userService = UserService();
  bool _isLoading = true;
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
          _isLoading = true; // Show loading while we check profile
        });
        
        // This handles the routing check automatically when the deeplink returns
        print("DEBUG: Listener caught session!");
        await _handleNavigation();
      } else {
        setState(() {
          _userId = null;
          _isLoading = false;
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
        setState(() {
          _isLoading = false; 
        });
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
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> signInWithMagicLink(String email) async {
    try {
      setState(() {
        _isLoading = true; // Show loading while we start GitHub flow
      });
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
      setState(() {
        _isLoading = true; // Show loading while we start GitHub flow
      });
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

// Your updated Widget build method

Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- App Logo ---
              // Replace 'assets/app_icon.png' with your actual image path
              Image.asset(
                'assets/app_icon.png', 
                height: 180,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),

              // --- Welcome Text ---
              const Text(
                'Park Buddy',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A4A4A),
                ),
              ),
              const Text(
                'Your parking companion',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 40),

              // --- GitHub Button (Brand Solid) ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: () => signInWithGithub(),
                  icon: const FaIcon(FontAwesomeIcons.github, size: 20),
                  label: const Text(
                    'Sign in with GitHub',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF24292E), // GitHub Gray
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // --- Magic Link Button (Clean Outline) ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton.icon(
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
                    if (email != null) signInWithMagicLink(email);
                  },
                  icon: const Icon(Icons.auto_awesome, size: 20),
                  label: const Text(
                    'Sign in with Magic Link',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF67B27C), // Icon Green
                    side: const BorderSide(color: Color(0xFF67B27C), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              const Text(
                'By signing in, you agree to our Terms of Service',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}