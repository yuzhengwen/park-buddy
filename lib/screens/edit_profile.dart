import 'package:flutter/material.dart';
import '../services/user_service.dart'; // Import your new service
import 'package:image_picker/image_picker.dart'; // For image picking 
import 'dart:io';
import 'main_screen.dart'; // Import the main screen to navigate after setup
import '../controllers/profile_controller.dart'; // Import validation logic

class EditProfileScreen extends StatefulWidget {
  
  final bool isFirstTime;
  const EditProfileScreen({super.key,this.isFirstTime = false});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final UserService _userService = UserService();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  late TextEditingController _nameController;
  String? _avatarUrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _loadCurrentProfile();
  }

  @override
  void dispose() {
     _nameController.dispose();
    super.dispose();
  }
  Future<void> _loadCurrentProfile() async {
    final data = await _userService.getProfile();
    if (data != null) {
      setState(() {
        _nameController.text = data['username'] ?? "";
        _avatarUrl = data['profilepic']; // Store the URL
      });
    }
  }
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      String? uploadedUrl;

      // Step 1: Upload the picture if a new one was picked
      if (_imageFile != null) {
        uploadedUrl = await _userService.uploadProfilePicture(_imageFile!);
      }

      // Step 2: Update the database (passing the new URL if we have one)
      await _userService.updateProfile(
        newName: _nameController.text,
        newAvatar: uploadedUrl,
        email: widget.isFirstTime ? _userService.email : null,
      );

      if (mounted) {
        if (widget.isFirstTime) {
          // If this is a new setup, move FORWARD to the app
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
        } else {
          // If they were just editing from the settings menu, go BACK
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
}
  Future<void> _pickImage(ImageSource source) async {
    final XFile? selected = await _picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 500,
    );

    if (selected != null) {
      setState(() {
        _imageFile = File(selected.path);
        _avatarUrl=_imageFile!.path; // Update the avatar URL to the local file path for immediate preview
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isFirstTime ? "Set Up Profile" : "Edit Profile")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
            GestureDetector(
              onTap: () => _pickImage(ImageSource.gallery),
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFFFF7643),
                    backgroundImage: _imageFile != null 
                          ? FileImage(_imageFile!) as ImageProvider // <--- Correct for local files
                          : (_avatarUrl != null && _avatarUrl!.isNotEmpty
                              ? NetworkImage(_avatarUrl!) as ImageProvider // <--- Correct for URLs
                              : null),
                    child: _avatarUrl == null 
                        ? const Icon(Icons.person, size: 50, color: Colors.white) 
                        : null,
                  ),
                  // The Edit Icon Overlay
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF7643),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
              const SizedBox(height: 32),

              // Name Input
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "Display Name",
                  prefixIcon: const Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: ProfileController.validateNickname,
              ),
              
              const SizedBox(height: 16),
              
              // Email (Read Only - standard practice)
              TextFormField(
                initialValue: _userService.email,
                enabled: false,
                decoration: InputDecoration(
                  labelText: "Email Address",
                  prefixIcon: const Icon(Icons.email_outlined),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SafeArea(
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _handleSave,
            icon: _isSaving 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.check),
            label: Text(_isSaving ? "Saving..." : "Save Changes"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7643),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ),
    );
  }

}