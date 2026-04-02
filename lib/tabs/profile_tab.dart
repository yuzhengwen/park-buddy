import 'package:flutter/material.dart';
import '../utils/auth.dart'; 
import '../screens/family_screen.dart'; 
import '../screens/car_screen.dart'; 
import '../screens/edit_profile.dart';
import '../services/user_service.dart';
import '../screens/login_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  _ProfileTabState createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final UserService _userService = UserService();

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account?"),
        content: const Text("This action is permanent and cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await _userService.deleteUserAccount();
              // Redirect to Login Screen
              Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder: (_) => LoginScreen()),(route) => false,);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Profile", style: TextStyle(color: Colors.black)),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _userService.getProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final profileData = snapshot.data;
          final String username = profileData?['username'] ?? "No Name Set";
          final String? avatarUrl = profileData?['profilepic'];
          final String userEmail = _userService.email;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                // --- YOUR ORIGINAL PICTURE LOGIC ---
                CircleAvatar(
                  radius: 60,
                  backgroundColor: const Color(0xFF6200EA),
                  backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null 
                      ? const Icon(Icons.person, size: 50, color: Colors.white) 
                      : null,
                ),
                const SizedBox(height: 15),
                Text(
                  username,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  userEmail,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 30),

                // --- NEW UI ROWS (Using standard Icons) ---
                
                ProfileMenu(
                  text: "Edit Profile",
                  icon: Icons.person_outline, 
                  press: () async {
                    final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                    );
                    if (updated == true) setState(() {});
                  },
                ),

                ProfileMenu(
                  text: "Cars",
                  icon: Icons.directions_car_filled_outlined,
                  press: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CarScreen())),
                ),

                ProfileMenu(
                  text: "Family",
                  icon: Icons.group_outlined,
                  press: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FamilyScreen())),
                ),

                ProfileMenu(
                  text: "Delete Account",
                  icon: Icons.delete,
                  press: () => _showDeleteDialog(context),
                ),

                ProfileMenu(
                  text: "Log Out",
                  icon: Icons.logout,
                  press: () => signOut(context),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// --- ICON-BASED MENU (No SVG dependency needed) ---
class ProfileMenu extends StatelessWidget {
  const ProfileMenu({
    super.key,
    required this.text,
    required this.icon,
    this.press,
  });

  final String text;
  final IconData icon; // Uses IconData instead of String path
  final VoidCallback? press;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: TextButton(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          backgroundColor: const Color(0xFFF5F6F9),
        ),
        onPressed: press,
        child: Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFFFF7643), // Matches that orange color
              size: 24,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(color: Color(0xFF757575), fontSize: 16),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Color(0xFF757575), size: 16),
          ],
        ),
      ),
    );
  }
}