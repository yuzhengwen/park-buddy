import 'package:flutter/material.dart';
import 'package:park_buddy/tabs/profile_tab.dart';
import '../utils/family_service.dart';
import '../utils/parking_service.dart';
import '../UI/CarCard.dart';
import 'add_car_screen.dart';


class CarScreen extends StatefulWidget {
  const CarScreen({super.key});

  @override
  State<CarScreen> createState() => _CarScreenState();
}

class _CarScreenState extends State<CarScreen> {
  final _parkingService = ParkingService();
  List<Map<String, dynamic>> cars = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCars();
  }

  Future<void> _loadCars() async {
    final data = await _parkingService.fetchCars();
    if (mounted) setState(() { cars = data; isLoading = false; });
  }

  Future<void> _navigateToAddCar() async {
    // 1. Open the screen and WAIT for the result
    final Map<String, dynamic>? newCarData = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddCarScreen()),
    );

    // 2. Check if the user actually added a car (didn't just press back)
    if (newCarData != null) {
      // 3. OPTIONAL: Save to your backend/database first
      // await _parkingService.saveNewCar(newCarData);

      // 4. Update the UI immediately
      setState(() {
        cars.add(newCarData); 
      });
      
      // Show a little success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${newCarData['carname']} added successfully!")),
      );
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Divider(),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cars.length,
                itemBuilder: (context, index) {
                  return CarCard(
                    car: cars[index],
                    parkingService: _parkingService,
                    showIcons: false,
                    canExpand: false,
                    onEdit: () { print("Editing ${cars[index]['carname']}");},
                  );
                },
              ),
            // Gives some breathing room at the bottom so the list doesn't 
            // get hidden behind the fixed button.
            const SizedBox(height: 100), 
          ],
        ),
      ),
      
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
        ),
        child: SafeArea(
          child: ElevatedButton.icon(
            onPressed: _navigateToAddCar
            ,
            icon: const Icon(Icons.add),
            label: const Text("Add Car"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6200EA),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ),
      ),
    );
  }
}


