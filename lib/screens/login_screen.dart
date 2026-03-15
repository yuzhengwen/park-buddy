import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final supabase = Supabase.instance.client;
  String? _userId;

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
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    }
  }

  Future<void> _signOut() async {
    try {
      await supabase.auth.signOut();
      setState(() {
        _userId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logged out successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
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
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _userId != null ? _signOut : null,
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