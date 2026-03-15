import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart'; // <-- for kIsWeb
import 'main_screen.dart'; // <-- import the main screen
import '../utils/auth.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final supabase = Supabase.instance.client;
  String? _userId;
  Future<void> signInWithGithub() async {
    await supabase.auth.signInWithOAuth(
      OAuthProvider.github,
      redirectTo: kIsWeb
          ? null
          : 'my.scheme://my-host', // Optionally set the redirect link to bring back the user via deeplink.
      authScreenLaunchMode: kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode
                .externalApplication, // Launch the auth screen in a new webview on mobile.
    );
  }

  Future<void> _signInAnonymously() async {
    try {
      final session = await supabase.auth.signInAnonymously();

      if (session != null) {
        setState(() {
          _userId = session.user?.id;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logged in anonymously: ${_userId}')),
        );
        // Navigate directly
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MainScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login failed: $e')));
    }
  }

  @override
  void initState() {
    super.initState();

    // Listen for auth changes
    supabase.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        setState(() {
          _userId = session.user?.id;
        });

        // Navigate to MainScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MainScreen()),
        );

        // Optional toast
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Logged in: ${_userId}')));
      } else {
        setState(() {
          _userId = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login (Anon)')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _signInAnonymously,
              child: Text('Sign in Anonymously'),
            ),
            ElevatedButton(
              onPressed: signInWithGithub,
              child: Text('Sign in with GitHub'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _userId != null ? () => signOut(context) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _userId != null ? Colors.red : Colors.grey,
              ),
              child: Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
