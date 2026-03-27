import 'package:flutter/material.dart';
import '../utils/parking_service.dart';
import '../UI/CarCard.dart';
import 'modify_car_screen.dart';
import '../services/car_service.dart';


class CarScreen extends StatefulWidget {
  const CarScreen({super.key});

  @override
  State<CarScreen> createState() => _CarScreenState();
}

class _CarScreenState extends State<CarScreen> {
  final _parkingService = ParkingService();
  final _carService = CarService();
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

    if (newCarData != null) {
    try {
      await _carService.addCar(newCarData);
      _loadCars(); // Refresh list from Supabase
      } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
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
                    onEdit: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddCarScreen(carToEdit: cars[index]),
                        ),
                      );

                      if (result == 'delete') {
                        // User pressed delete
                        await _carService.deleteCar(cars[index]['carplate']);
                        _loadCars(); // Refresh list
                      } else if (result is Map<String, dynamic>) {
                        // User updated details
                        await _carService.updateCar(cars[index]['carplate'], result);
                        _loadCars(); // Refresh list
                      }
                    },
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


