import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../controllers/car_controller.dart';

class AddCarScreen extends StatefulWidget {
  final Map<String, dynamic>? carToEdit;

  const AddCarScreen({super.key, this.carToEdit});

  @override
  State<AddCarScreen> createState() => _AddCarScreenState();
}

class _AddCarScreenState extends State<AddCarScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _plateController;
  //late String selectedIcon;

  // --- IMAGE STATE ---
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  String? _existingImageUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.carToEdit?['carname'] ?? '');
    _plateController = TextEditingController(text: widget.carToEdit?['carplate'] ?? '');
    _existingImageUrl = widget.carToEdit?['caricon']; 
  }

  @override
  void dispose() {
    _nameController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? selected = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (selected != null) {
      setState(() {
        _imageFile = File(selected.path);
      });
    }
  }

  void _submitData() async {
    final supabase = Supabase.instance.client;
    if (_formKey.currentState!.validate()) {
      final carData = {
        'carname': _nameController.text,
        'carplate': _plateController.text.toUpperCase(),
        'ownerid': supabase.auth.currentUser?.id,
        'new_image_file': _imageFile,
      };
      
      Navigator.pop(context, carData);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.carToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Edit Vehicle" : "Add Vehicle"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // --- CAR PHOTO SELECTOR ---
              _buildPhotoPicker(),
              const SizedBox(height: 24),
              
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Car Nickname',
                  border: OutlineInputBorder(),
                ),
                validator: CarValidationController.validateNickname,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _plateController,
                decoration: const InputDecoration(
                  labelText: 'License Plate',
                  border: OutlineInputBorder(),
                ),
                validator: CarValidationController.validatePlate,
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 24),
              ///_buildIconSelector(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomButtons(isEditing),
    );
  }

  Widget _buildPhotoPicker() {
    double screenWidth = MediaQuery.of(context).size.width;
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Stack(
          children: [
            
            Container(
              width: screenWidth,
              height: (screenWidth*0.8) * 0.6,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFF7643), width: 2),
                image: _imageFile != null
                    ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                    : (_existingImageUrl != null
                        ? DecorationImage(image: NetworkImage(_existingImageUrl!), fit: BoxFit.cover)
                        : null),
              ),
              child: (_imageFile == null && _existingImageUrl == null)
                  ? const Icon(Icons.add_a_photo, size: 40, color: Colors.grey)
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: Color(0xFFFF7643), shape: BoxShape.circle),
                child: const Icon(Icons.edit, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons(bool isEditing) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: _submitData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7643),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text(isEditing ? "Update Car" : "Add Car"),
            ),
            if (isEditing) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _confirmDelete,
                icon: const Icon(Icons.delete_outline),
                label: const Text("Remove Car"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmDelete() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Vehicle?"),
        content: Text("Are you sure you want to remove ${_nameController.text}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) Navigator.pop(context, 'delete');
  }
}