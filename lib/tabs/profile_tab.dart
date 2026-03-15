import 'package:flutter/material.dart';
import '../utils/auth.dart'; // <- import your reusable logout function

class ProfileTab extends StatefulWidget {
  @override
  _ProfileTabState createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Profile Tab Screen",
            style: TextStyle(fontSize: 24),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => signOut(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('Logout'),
          ),
        ],
      ),
    );
  }
}