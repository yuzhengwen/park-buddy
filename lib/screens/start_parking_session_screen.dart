import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:park_buddy/UI/carpark_picker_screen.dart';
import 'package:park_buddy/services/notification_service.dart' as notif;
import 'package:park_buddy/utils/parking_service.dart';
import 'package:park_buddy/utils/car_icons.dart';
import 'package:park_buddy/utils/hdb_fee_calculator.dart';
import 'package:park_buddy/models/carpark.dart';
import 'package:park_buddy/services/parking_session_service.dart';
import 'package:park_buddy/services/storage_service.dart';

class StartParkingSessionScreen extends StatefulWidget {
  final Carpark? initialCarpark;

  const StartParkingSessionScreen({super.key, this.initialCarpark});

  @override
  State<StartParkingSessionScreen> createState() => _StartParkingSessionScreenState();
}

class _StartParkingSessionScreenState extends State<StartParkingSessionScreen> {
  final _sessionNameController = TextEditingController();
  final _sessionDescController = TextEditingController();
  final _rateThresholdController = TextEditingController();
  final _picker = ImagePicker();
  final _parkingService = ParkingService();
  final _parkingSessionService = ParkingSessionService();
  final _storageService = StorageService();

  List<Map<String, dynamic>> _cars = [];
  Carpark? _selectedLocation;
  String? _selectedCarPlate;
  List<File> _parkingPictures = const [];
  bool _isLoading = false;

  @override
  void dispose() {
    _sessionNameController.dispose();
    _sessionDescController.dispose();
    _rateThresholdController.dispose();
    super.dispose();
  }

  /// Check whether all required fields are filled
  bool _canSubmit() {
    return _selectedLocation != null && _selectedCarPlate != null;
  }

  /// Send the created parking session details to the database.
  Future<void> _submit() async {
    try {
      if (!_canSubmit()) throw StateError('Some required fields are empty.');

      final sessionName = _sessionNameController.text;
      final sessionDesc = _sessionDescController.text;

      setState(() => _isLoading = true);

      final session = await _parkingSessionService.createParkingSession(
        carPlate: _selectedCarPlate!,
        carparkLocation: _selectedLocation!.position,
        carparkName: _selectedLocation!.address,
        sessionName: sessionName.isNotEmpty ? sessionName : null,
        sessionDescription: sessionDesc.isNotEmpty ? sessionDesc : null,
        rateThreshold: double.tryParse(_rateThresholdController.text),
      );

      tz.TZDateTime? estimatedTime;
      if (session.rateThreshold != null) {
        estimatedTime = HdbFeeCalculator.calculateTimeToReachThreshold(
          threshold: session.rateThreshold!,
          startTime: session.startTime!,
          carparkPosition: session.carparkPosition,
        );
        
        if (estimatedTime != null) {
          notif.scheduleRateAlert(session, estimatedTime);
        }
      }

      if (_parkingPictures.isNotEmpty) {
        // Upload images in parallel
        final imgUrls = await Future.wait(
          _parkingPictures.map((img) async {
            final bytes = await img.readAsBytes();
            return _storageService.uploadImage(
              bucket: "parking-images",
              folder: session.sessionId,
              bytes: bytes,
            );
          }),
        );

        // Create the image links in the database
        await _parkingSessionService.updateSessionImages(session.sessionId, imgUrls);
      }

      if (mounted) {
        // Return result data to the calling screen
        Navigator.pop(context, {
          'notificationScheduled': session.rateThreshold != null,
          'estimatedTime': session.rateThreshold != null ? estimatedTime?.toLocal() : null,
        });
      }

    } catch (e) {
      if (mounted) {
        debugPrint(e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: Could not create session.'))
        );
      }
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _editLocation(BuildContext context) async {
    final Carpark? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CarparkPickerScreen(
          initialLocation: _selectedLocation?.position,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedLocation = result;
      });
    }
  }

  Future<XFile?> _pickImageWithSheet() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return null;

    return _picker.pickImage(source: source, imageQuality: 85);
  }

  Future<void> _editParkingImage() async {
    try {
      final photo = await _pickImageWithSheet();
 
      if (photo != null) {
        setState(() {
          _parkingPictures = [..._parkingPictures, File(photo.path)];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking photo: $e')),
        );
      }
    }
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
                      setState(() { _selectedCarPlate = selectedCarplate; });
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
                  onTap: _editParkingImage,
                ),
                // Show uploaded picture
                if (_parkingPictures.isNotEmpty)
                  SizedBox(
                    height: 200,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.all(8),
                      itemCount: _parkingPictures.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) => ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _parkingPictures[index],
                          width: 250,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      persistentFooterButtons: [
        // Confirmation button
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: SizedBox(
              height: 48,
              width: double.infinity,
              child: FilledButton(
                onPressed: _canSubmit() && !_isLoading ? _submit : null,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator()
                      )
                    : const Text('Create session'),
              ),
            ),
          ),
        ),
      ],
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
