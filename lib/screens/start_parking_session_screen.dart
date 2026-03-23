import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class StartParkingSessionScreen extends StatefulWidget {
  const StartParkingSessionScreen({super.key});

  @override
  State<StartParkingSessionScreen> createState() => _StartParkingSessionScreenState();
}

class _StartParkingSessionScreenState extends State<StartParkingSessionScreen> {
  final TextEditingController _sessionNameController = TextEditingController();
  final TextEditingController _sessionDescController = TextEditingController();
  final TextEditingController _rateThresholdController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String? _selectedLocation;
  String? _selectedCar;
  File? _parkingPicture;

  // TODO: placeholder cars
  final List<String> _cars = [
    'Toyota Camry - ABC123',
    'Honda Civic - XYZ789',
    'Tesla Model 3 - TES001',
  ];

  @override
  void dispose() {
    _sessionNameController.dispose();
    _sessionDescController.dispose();
    _rateThresholdController.dispose();
    super.dispose();
  }

  void _confirm() {
    // TODO: go to next screen
  }

  Future<void> _editLocation() async {
    // TODO: launch map and carpark picker
  }

  Future<void> _takeParkingPicture({
    required BuildContext context,
  }) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
 
      if (photo != null) {
        setState(() {
          _parkingPicture = File(photo.path);
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking photo: $e')),
        );
      }
    }
  }

  // whether all required fields are filled
  bool _canSubmit() {
    return _selectedLocation != null && _selectedCar != null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Session')),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              // padding: const EdgeInsets.all(16),
              children: <Widget>[
                // 1. Carpark location
                ListTile(
                  leading: const SizedBox(
                    height: 48,
                    width: 48,
                    child: Icon(Icons.location_on),
                  ),
                  title: const Text('Location'),
                  subtitle: Text(_selectedLocation ?? 'Not selected'),
                  isThreeLine: true,
                  trailing: const SizedBox(
                    height: 48,
                    width: 48,
                    child: Icon(Icons.edit)
                  ),
                  onTap: _editLocation,
                ),
                // 2. Car selection
                ListTile(
                  leading: const SizedBox(
                    height: 48,
                    width: 48,
                    child: Icon(Icons.directions_car)
                  ),
                  title: DropdownMenu(
                    width: double.infinity,
                    hintText: 'Car',
                    onSelected: (String? selectedCar) {
                      setState(() { _selectedCar = selectedCar; });
                    },
                    dropdownMenuEntries: _cars
                      .map((car) => DropdownMenuEntry(value: car, label: car))
                      .toList(),
                  ),
                ),
                // 3. Session name
                ListTile(
                  leading: const SizedBox(
                    height: 48,
                    width: 48,
                    child: Icon(Icons.title)
                  ),
                  title: TextField(
                    controller: _sessionNameController,
                    decoration: const InputDecoration(
                      labelText: 'Session name',
                      hintText: 'Enter session name...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                // 4. Session description
                ListTile(
                  leading: const SizedBox(
                    height: 48,
                    width: 48,
                    child: Icon(Icons.notes)
                  ),
                  title: TextField(
                    controller: _sessionDescController,
                    decoration: const InputDecoration(
                      labelText: 'Session description',
                      hintText: 'Enter description...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ),
                // 5. Rate threshold
                ListTile(
                  leading: const SizedBox(
                    height: 48,
                    width: 48,
                    child: Icon(Icons.attach_money)
                  ),
                  title: TextField(
                    controller: _rateThresholdController,
                    decoration: const InputDecoration(
                      labelText: 'Rate threshold',
                      hintText: '0.00',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                // 6. Upload parking photo
                ListTile(
                  leading: const SizedBox(
                    height: 48,
                    width: 48,
                    child: Icon(Icons.camera_alt)
                  ),
                  title: const Text('Photo'),
                  subtitle: const Text('Tap to take photo'),
                  onTap: () { _takeParkingPicture(context: context); },
                ),
                // Show uploaded picture
                if (_parkingPicture != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _parkingPicture!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Confirmation button
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                height: 48,
                width: double.infinity,
                child: FilledButton(
                  onPressed: _canSubmit() ? _confirm : null,
                  child: Text('Create session'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Form item to edit location
class LocationField extends StatelessWidget {
  final void Function() onEditLocation;
  final String _parkLocation;

  const LocationField({
    super.key,
    required this.onEditLocation,
    required String parkLocation,
  }) : _parkLocation = parkLocation;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onEditLocation,
      child: Row(
        children: [
          Expanded(child: Text(_parkLocation)),
          const Icon(Icons.edit),
        ],
      ),
    );
  }
}
