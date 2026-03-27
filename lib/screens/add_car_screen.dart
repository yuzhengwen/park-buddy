import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddCarScreen extends StatefulWidget {
  const AddCarScreen({super.key});

  @override
  State<AddCarScreen> createState() => _AddCarScreenState();
}

class _AddCarScreenState extends State<AddCarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _plateController = TextEditingController();
  
  // Default selection
  String selectedIcon = 'sedan';

  // The 4 icons to choose from
  final List<Map<String, dynamic>> carIcons = [
    {'name': 'sedan', 'icon': Icons.directions_car},
    {'name': 'suv', 'icon': Icons.directions_car_filled},
    {'name': 'van', 'icon': Icons.airport_shuttle},
    {'name': 'sports', 'icon': Icons.directions_car_filled},
  ];

  void _submitData()async{
    final supabase = Supabase.instance.client;
    if (_formKey.currentState!.validate()) {
      final newCar = {
        'carname': _nameController.text,
        'carplate': _plateController.text.toUpperCase(),
        'caricon': selectedIcon,
        'ownerid': supabase.auth.currentUser?.id, // Auto-filled logic
        
      };
      try {
        await supabase.from('cars').insert(newCar);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Car added successfully')),
        );

        Navigator.pop(context, newCar); // optional
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
      // Pop back and pass the data
      Navigator.pop(context, newCar);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add New Vehicle")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Car Nickname (e.g. My Tesla)'),
                validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _plateController,
                decoration: const InputDecoration(labelText: 'License Plate Number'),
                textCapitalization: TextCapitalization.characters,
                validator: (value) => value!.isEmpty ? 'Please enter plate number' : null,
              ),
              const SizedBox(height: 24),
              const Text("Select Car Type", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              
              // Icon Selection Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: carIcons.map((item) {
                  bool isSelected = selectedIcon == item['name'];
                  return GestureDetector(
                    onTap: () => setState(() => selectedIcon = item['name']),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF6200EA).withOpacity(0.1) : Colors.transparent,
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
              ),
            ],
          ),
        ),
      ),
      // Fixed Add Button at the bottom
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _submitData,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6200EA),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
          ),
          child: const Text("Add Car"),
        ),
      ),
    );
  }
}