import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddCarScreen extends StatefulWidget {
  // Pass the car data map here if you are editing
  final Map<String, dynamic>? carToEdit;

  const AddCarScreen({super.key, this.carToEdit});

  @override
  State<AddCarScreen> createState() => _AddCarScreenState();
}

class _AddCarScreenState extends State<AddCarScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _plateController;
  late String selectedIcon;

  final List<Map<String, dynamic>> carIcons = [
    {'name': 'sedan', 'icon': Icons.directions_car},
    {'name': 'suv', 'icon': Icons.directions_car_filled},
    {'name': 'van', 'icon': Icons.airport_shuttle},
    {'name': 'sports', 'icon': Icons.speed}, // Changed to speed icon for variety
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill controllers if editing, otherwise start empty
    _nameController = TextEditingController(text: widget.carToEdit?['carname'] ?? '');
    _plateController = TextEditingController(text: widget.carToEdit?['carplate'] ?? '');
    selectedIcon = widget.carToEdit?['caricon'] ?? 'sedan';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  void _submitData() async {
    final supabase = Supabase.instance.client;
    if (_formKey.currentState!.validate()) {
      final carData = {
        'carname': _nameController.text,
        'carplate': _plateController.text.toUpperCase(),
        'caricon': selectedIcon,
        'ownerid': supabase.auth.currentUser?.id,
      };
      
      // Return the data to the previous screen
      Navigator.pop(context, carData);
    }
  }
  void _confirmDelete() async {
      bool? confirm = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Delete Vehicle?"),
          content: Text("Are you sure you want to remove ${_nameController.text}?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirm == true) {
        // Return a 'delete' signal instead of the car map
        Navigator.pop(context, 'delete');
      }
    }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.carToEdit != null;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Car Nickname'),
                validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _plateController,
                decoration: const InputDecoration(labelText: 'License Plate'),
                enabled: !isEditing, // Usually best to lock the ID/Plate during edit
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 24),
              const Text("Select Car Type", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildIconSelector(), // Abstracted for cleanliness
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- PRIMARY BUTTON (Add or Update) ---
              ElevatedButton(
                onPressed: _submitData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6200EA),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text(widget.carToEdit != null ? "Update Car" : "Add Car"),
              ),
              SizedBox(height: 12),
              // --- SECONDARY DELETE BUTTON (Only shows if Editing) ---
              if (widget.carToEdit != null) ...[
                ElevatedButton.icon(
                onPressed: () => _confirmDelete(),
                icon: const Icon(Icons.delete_outline, color: Colors.white),
                label: const Text("Remove Car", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red ,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: carIcons.map((item) {
        bool isSelected = selectedIcon == item['name'];
        return GestureDetector(
          onTap: () => setState(() => selectedIcon = item['name']),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              // Highlight color if selected
              color: isSelected 
                  ? const Color(0xFF6200EA).withOpacity(0.1) 
                  : Colors.transparent,
              border: Border.all(
                color: isSelected ? const Color(0xFF6200EA) : Colors.grey.shade300,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              item['icon'],
              size: 40,
              color: isSelected ? const Color(0xFF6200EA) : Colors.grey,
            ),
          ),
        );
      }).toList(),
    );
  }
}