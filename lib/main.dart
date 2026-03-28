import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://saslrisbvxdwowextgbh.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNhc2xyaXNidnhkd293ZXh0Z2JoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM1NTcyMjcsImV4cCI6MjA4OTEzMzIyN30.QSNyqc0leDJ6IOnWQW053r4NFaq2nrnS5LCYPFaJ4s8',
    authOptions: FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce, // Recommended for mobile
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Park Buddy',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: LoginScreen(),
    );
  }
}
