import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:park_buddy/screens/location_picker/location_picker_screen.dart';
import 'package:park_buddy/utils/parking_service.dart';
import 'package:park_buddy/utils/car_icons.dart';
import 'package:park_buddy/models/carpark.dart';

class StartParkingSessionScreen extends StatefulWidget {
  final Carpark? initialCarpark;

  const StartParkingSessionScreen({super.key, this.initialCarpark});

  @override
  State<StartParkingSessionScreen> createState() => _StartParkingSessionScreenState();
}

class _StartParkingSessionScreenState extends State<StartParkingSessionScreen> {
  final TextEditingController _sessionNameController = TextEditingController();
  final TextEditingController _sessionDescController = TextEditingController();
  final TextEditingController _rateThresholdController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final ParkingService _parkingService = ParkingService();

  List<Map<String, dynamic>> _cars = [];

  Carpark? _selectedLocation;
  String? _selectedCar;
  File? _parkingPicture;

  @override
  void dispose() {
    _sessionNameController.dispose();
    _sessionDescController.dispose();
    _rateThresholdController.dispose();
    super.dispose();
  }

  void _confirm(BuildContext context) {
    // TODO: update the database
    Navigator.pop(context);
  }

  Future<void> _editLocation(BuildContext context) async {
    final Carpark? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return CarparkPickerScreen(
            initialMapCenter: _selectedLocation?.position,
          );
        },
      ),
    );

    if (result != null) {
      setState(() {
        _selectedLocation = result;
      });
    }
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

  Future<void> _loadCars() async {
    final data = await _parkingService.fetchCars();
    setState(() => _cars = data);
  }

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialCarpark;
    _loadCars();
  }

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'parkNow',
      child: Scaffold(
        appBar: AppBar(title: const Text('New Session')),
        body: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                // padding: const EdgeInsets.all(16),
                children: <Widget>[
                  // 1. Carpark location
                  ListTile(
                    leading: const ListIcon(Icons.location_on),
                    title: Text(_selectedLocation?.address ?? 'Choose carpark'),
                    subtitle: _selectedLocation == null
                        ? null
                        : Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text:
                                      'Car park: ${_selectedLocation!.carParkNo}\n',
                                ),
                                TextSpan(
                                  text: '${_selectedLocation!.carParkType} • ${_selectedLocation!.shortTermParking}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                    isThreeLine: _selectedLocation != null,
                    trailing: const ListIcon(Icons.edit),
                    onTap: () => _editLocation(context),
                  ),
                  // 2. Car selection
                  ListTile(
                    leading: const ListIcon(Icons.directions_car),
                    title: DropdownMenu<String>(
                      expandedInsets: EdgeInsets.zero,
                      hintText: 'Car',
                      onSelected: (String? selectedCarplate) {
                        setState(() { _selectedCar = selectedCarplate; });
                      },
                      dropdownMenuEntries: _cars
                          .map(
                            (car) => DropdownMenuEntry<String>(
                              value: car['carplate'],
                              label: car['carname'],
                              labelWidget: ListTile(
                                title: Text(car['carname']),
                                subtitle: Text(car['carplate']),
                                contentPadding: EdgeInsets.zero,
                              ),
                              leadingIcon: Icon(carIcons[car['caricon']]),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  // 3. Session name
                  ListTile(
                    leading: const ListIcon(Icons.title),
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
                    leading: const ListIcon(Icons.notes),
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
                    leading: const ListIcon(Icons.attach_money),
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
                    leading: const ListIcon(Icons.camera_alt),
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
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _canSubmit()
                        ? () => _confirm(context)
                        : null,
                    child: Text('Create session'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Icon container for form fields
class ListIcon extends StatelessWidget {
  final IconData icon;

  const ListIcon(this.icon, {super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: 48,
      child: Icon(icon)
    );
  }
}
