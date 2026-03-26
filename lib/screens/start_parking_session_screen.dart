import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'carpark_picker_screen.dart';
import 'package:latlong2/latlong.dart';

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

  CarparkLocation? _selectedLocation;
  String? _selectedCar;
  File? _parkingPicture;

  // TODO: placeholder cars
  final List<String> _cars = [
    'Toyota Camry - ABC123',
    'Honda Civic - XYZ789',
    'Tesla Model 3 - TES001',
  ];

  // TODO: placeholder locations
  final List<CarparkLocation> _carparks = [
    CarparkLocation('Blk 123 Apple Rd', LatLng(1.358304401350051, 103.8231520606375)),
    CarparkLocation('Blk 456 Banana St', LatLng(1.3619697156101385, 103.80923761033203)),
    CarparkLocation('Blk 789 Cherry Ave', LatLng(1.3711426261951147, 103.82042091952135)),
    CarparkLocation('Blk 101 Durian Way', LatLng(1.3524, 103.8351)),
    CarparkLocation('Blk 202 Elderberry Dr', LatLng(1.3489, 103.8210)),
    CarparkLocation('Blk 303 Fig Lane', LatLng(1.3655, 103.8150)),
    CarparkLocation('Blk 404 Grape Terrace', LatLng(1.3720, 103.8405)),
    CarparkLocation('Blk 505 Honeydew Crt', LatLng(1.3590, 103.7950)),
    CarparkLocation('Blk 606 Iceplant Rd', LatLng(1.3688, 103.8288)),
    CarparkLocation('Blk 707 Jackfruit St', LatLng(1.3450, 103.8122)),
    CarparkLocation('Blk 808 Kiwi Grove', LatLng(1.3780, 103.8321)),
    CarparkLocation('Blk 909 Lemon Blvd', LatLng(1.3533, 103.8010)),
    CarparkLocation('Blk 110 Mango Rise', LatLng(1.3611, 103.8480)),
    CarparkLocation('Blk 221 Nectarine Pl', LatLng(1.3412, 103.8255)),
    CarparkLocation('Blk 332 Orange Walk', LatLng(1.3705, 103.7880)),
    CarparkLocation('Blk 443 Papaya Link', LatLng(1.3577, 103.8550)),
    CarparkLocation('Blk 554 Quince View', LatLng(1.3644, 103.8333)),
    CarparkLocation('Blk 665 Raspberry Dr', LatLng(1.3499, 103.7999)),
    CarparkLocation('Blk 776 Strawberry Sq', LatLng(1.3755, 103.8190)),
    CarparkLocation('Blk 887 Tangerine Path', LatLng(1.3555, 103.8080)),
    CarparkLocation('Blk 998 Ugli Fruit Rd', LatLng(1.3622, 103.8222)),
    CarparkLocation('Blk 112 Vanilla Cres', LatLng(1.3477, 103.8444)),
    CarparkLocation('Blk 223 Watermelon Way', LatLng(1.3699, 103.8055)),
    CarparkLocation('Blk 334 Xigua Lane', LatLng(1.3511, 103.8188)),
    CarparkLocation('Blk 445 Yam Bean St', LatLng(1.3733, 103.8399)),
    CarparkLocation('Blk 556 Zucchini Ave', LatLng(1.3433, 103.7911)),
    CarparkLocation('Blk 124 Apricot Rd', LatLng(1.3585, 103.8240)),
    CarparkLocation('Blk 457 Blueberry St', LatLng(1.3625, 103.8105)),
    CarparkLocation('Blk 790 Cranberry Ave', LatLng(1.3715, 103.8215)),
    CarparkLocation('Blk 135 Date Palm Dr', LatLng(1.3501, 103.8301)),
    CarparkLocation('Blk 246 Eggplant Cir', LatLng(1.3666, 103.8422)),
    CarparkLocation('Blk 357 Feijoa Pl', LatLng(1.3444, 103.8033)),
    CarparkLocation('Blk 468 Guava Garden', LatLng(1.3777, 103.8111)),
    CarparkLocation('Blk 579 Hazelnut Ter', LatLng(1.3522, 103.7988)),
    CarparkLocation('Blk 680 Imbe Road', LatLng(1.3600, 103.8377)),
    CarparkLocation('Blk 791 Juniper Way', LatLng(1.3411, 103.8299)),
    CarparkLocation('Blk 802 Kumquat Blvd', LatLng(1.3690, 103.8501)),
    CarparkLocation('Blk 913 Lime Lane', LatLng(1.3588, 103.8005)),
    CarparkLocation('Blk 104 Mulberry Cres', LatLng(1.3466, 103.8177)),
    CarparkLocation('Blk 215 Olive Orchard', LatLng(1.3744, 103.8266)),
    CarparkLocation('Blk 326 Peach Parade', LatLng(1.3550, 103.8455)),
    CarparkLocation('Blk 437 Rosehip Ridge', LatLng(1.3633, 103.7922)),
    CarparkLocation('Blk 548 Starfruit Sq', LatLng(1.3701, 103.8133)),
    CarparkLocation('Blk 659 Tomato Town', LatLng(1.3422, 103.8088)),
    CarparkLocation('Blk 760 Uva Ursi Dr', LatLng(1.3599, 103.8499)),
    CarparkLocation('Blk 871 Velvet Apple St', LatLng(1.3488, 103.8311)),
    CarparkLocation('Blk 982 Wolfberry Way', LatLng(1.3677, 103.8201)),
    CarparkLocation('Blk 105 Yuzu Yard', LatLng(1.3515, 103.8050)),
    CarparkLocation('Blk 216 Zapote Zone', LatLng(1.3750, 103.7990)),
    CarparkLocation('Blk 327 Almond Alley', LatLng(1.3430, 103.8520))
  ];

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
    final CarparkLocation? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return CarparkPickerScreen(
            carparks: _carparks,
            initialMapCenter: _selectedLocation?.coords,
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
                  title: const Text('Location'),
                  subtitle: Text(_selectedLocation?.name ?? 'Not selected'),
                  isThreeLine: true,
                  trailing: const ListIcon(Icons.edit),
                  onTap: () => _editLocation(context),
                ),
                // 2. Car selection
                ListTile(
                  leading: const ListIcon(Icons.directions_car),
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
