import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:park_buddy/models/parking_session.dart';
import 'package:park_buddy/UI/carpark_picker_screen.dart';
import 'package:park_buddy/services/notification_service.dart';
import 'package:park_buddy/utils/parking_service.dart';
import 'package:park_buddy/utils/car_icons.dart';
import 'package:park_buddy/utils/hdb_fee_calculator.dart';
import 'package:park_buddy/models/carpark.dart';
import 'package:park_buddy/services/parking_session_service.dart';
import 'package:park_buddy/services/storage_service.dart';
import 'package:park_buddy/services/service_locator.dart';

class StartParkingSessionScreen extends StatefulWidget {
  final Carpark? initialCarpark;
  final List<Map<String, dynamic>> cars;

  const StartParkingSessionScreen({
    super.key,
    this.initialCarpark,
    required this.cars,
  });

  @override
  State<StartParkingSessionScreen> createState() => _StartParkingSessionScreenState();
}

class _StartParkingSessionScreenState extends State<StartParkingSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sessionNameController = TextEditingController();
  final _sessionDescController = TextEditingController();
  final _rateThresholdController = TextEditingController();
  final _selectedLocationNotifier = ValueNotifier<Carpark?>(null);
  final _selectedCarPlateNotifier = ValueNotifier<String?>(null);
  final _picker = ImagePicker();
  final _parkingService = ParkingService();
  final _parkingSessionService = ParkingSessionService();
  final _storageService = StorageService();
  final _notifService = getIt<NotifService>();

  List<Map<String, dynamic>> _availableCars = [];
  List<File> _parkingPictures = const [];
  bool _isLoading = false;

  @override
  void dispose() {
    _sessionNameController.dispose();
    _sessionDescController.dispose();
    _rateThresholdController.dispose();
    _selectedLocationNotifier.dispose();
    _selectedCarPlateNotifier.dispose();
    super.dispose();
  }

  /// Check whether all required fields are filled
  bool _canSubmit() {
    return _selectedLocationNotifier.value != null &&
        _selectedCarPlateNotifier.value != null &&
        _sessionNameController.text.isNotEmpty;
  }

  /// Send the created parking session details to the database.
  Future<void> _submit() async {
    try {
      if (!_canSubmit()) throw StateError('Some required fields are empty.');
      final hasActive = await _parkingService.hasActiveSession(_selectedCarPlateNotifier.value!);
      if (hasActive) throw StateError('This car already has an active session.');

      final sessionName = _sessionNameController.text;
      final sessionDesc = _sessionDescController.text;

      double? rate;
      if (_rateThresholdController.text.isNotEmpty) {
        rate = double.tryParse(_rateThresholdController.text);
        if (rate == null || rate < 0) {
          throw StateError('Parking rate threshold must be positive');
        }
      }

      setState(() => _isLoading = true);

      final session = await _parkingSessionService.createParkingSession(
        carPlate: _selectedCarPlateNotifier.value!,
        carparkLocation: _selectedLocationNotifier.value!.position,
        carparkName: _selectedLocationNotifier.value!.address,
        sessionName: sessionName.isNotEmpty ? sessionName : null,
        sessionDescription: sessionDesc.isNotEmpty ? sessionDesc : null,
        rateThreshold: rate,
      );

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
        await _parkingSessionService.updateSessionImages(
          session.sessionId,
          imgUrls,
        );
      }

      if (session.rateThreshold != null) {
        await _scheduleRateAlert(session);
      }

      if (mounted) Navigator.pop(context, session);

    } catch (e) {
      if (mounted) {
        debugPrint(e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not create session: $e'))
        );
      }

    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _scheduleRateAlert(ParkingSession session) async {
    final estimatedTime = HdbFeeCalculator.calculateThresholdTime(
      threshold: session.rateThreshold!,
      startTime: session.startTime!,
      carparkPosition: session.carparkPosition,
    );

    if (estimatedTime == null) {
      throw StateError('Unable to calculate rate threshold trigger time');
    }

    await _notifService.scheduleRateAlert(
      session: session,
      scheduledTime: estimatedTime,
    );
  }

  Future<void> _editLocation(BuildContext context) async {
    final Carpark? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CarparkPickerScreen(
          initialLocation: _selectedLocationNotifier.value?.position,
        ),
      ),
    );

    if (result != null) {
      _selectedLocationNotifier.value = result;
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

  Future<void> _loadAvailCars() async {
    final checks = await Future.wait(
      widget.cars.map((car) => _parkingService.hasActiveSession(car['carplate'])),
    );
    if (!mounted) return;
    setState(() {
      _availableCars = [
        for (int i = 0; i < widget.cars.length; i++)
          if (!checks[i]) widget.cars[i],
      ];
    });
  }

  @override
  void initState() {
    super.initState();
    _selectedLocationNotifier.value = widget.initialCarpark;
    _loadAvailCars();
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
                ValueListenableBuilder<Carpark?>(
                  valueListenable: _selectedLocationNotifier,
                  builder: (context, selectedLocation, _) {
                    return ListTile(
                      leading: const ListIcon(Icons.location_on),
                      title: Text(selectedLocation?.address ?? 'Choose carpark'),
                      subtitle: selectedLocation == null
                          ? null
                          : Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text:
                                        'Car park: ${selectedLocation.carParkNo}\n',
                                  ),
                                  TextSpan(
                                    text: '${selectedLocation.carParkType} • ${selectedLocation.shortTermParking}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                      isThreeLine: selectedLocation != null,
                      trailing: const ListIcon(Icons.edit),
                      onTap: () => _editLocation(context),
                    );
                  },
                ),
                // 2. Car selection
                ValueListenableBuilder<String?>(
                  valueListenable: _selectedCarPlateNotifier,
                  builder: (context, selectedCarPlate, _) {
                    return ListTile(
                      leading: const ListIcon(Icons.directions_car),
                      title: DropdownMenu<String>(
                        expandedInsets: EdgeInsets.zero,
                        hintText: 'Select Car',
                        initialSelection: selectedCarPlate,
                        onSelected: (String? selectedCarplate) {
                          _selectedCarPlateNotifier.value = selectedCarplate;
                        },
                        dropdownMenuEntries: _availableCars
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
                    );
                  },
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
              child: ListenableBuilder(
                listenable: Listenable.merge([
                  _sessionNameController,
                  _selectedLocationNotifier,
                  _selectedCarPlateNotifier,
                ]),
                builder: (context, _) {
                  final canSubmit = _canSubmit();

                  return FilledButton(
                    onPressed: canSubmit && !_isLoading ? _submit : null,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator()
                          )
                        : const Text('Create session'),
                  );
                },
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
