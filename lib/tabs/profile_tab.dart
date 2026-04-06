import 'package:flutter/material.dart';
import '../utils/auth.dart'; // <- import your reusable logout function
import '../screens/family_screen.dart'; // <- import the family screen
import '../screens/car_screen.dart'; // <- import the car screen
import '../screens/edit_profile.dart';
import '../services/user_service.dart'; // <- import the user service to fetch profile data

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  _ProfileTabState createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final UserService _userService = UserService();

  @override
  Widget build(BuildContext context) {
      return Scaffold(
      body: FutureBuilder<Map<String, dynamic>?>(
        // Point directly to your service
        future: _userService.getProfile(),
        builder: (context, snapshot) {
          // 1. Show loading spinner while waiting for Supabase
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Extract data (Fallbacks included)
          final profileData = snapshot.data;
          final String username = profileData?['username'] ?? "No Name Set";
          final String? avatarUrl = profileData?['profilepic'];
          final String userEmail = _userService.email;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Profile Picture (Updates dynamically)
                CircleAvatar(
                  radius: 60,
                  backgroundColor: const Color(0xFFFF7643),
                  backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null 
                      ? const Icon(Icons.person, size: 50, color: Colors.white) 
                      : null,
                ),
                const SizedBox(height: 15),

                // Username & Email
                Text(
                  username,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  userEmail,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final updated = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                          );
                          // Rebuilds the FutureBuilder to fetch new data
                          if (updated == true) setState(() {});
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit Profile'),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.logout, color: Colors.white),
                        label: const Text('Logout'),
                        onPressed: () => signOut(context),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      ),
                    ),
                  ],
                ),
            const Divider(height: 40),

            // Action Buttons (Cars & Family)
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.directions_car,
                    label: 'Cars',
                    color: Colors.blueAccent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CarScreen()),
                      );},
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.family_restroom,
                    label: 'Family',
                    color: Colors.greenAccent.shade700,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => FamilyScreen()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ); // End of SingleChildScrollView
        },
      ), 
    ); // End of Scaffold
  }

  // Helper method to keep the code DRY (Don't Repeat Yourself)
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color),
        ),
        child: Column(
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}