import 'package:flutter/material.dart';
import '../services/parking_service.dart';
import 'widgets/CarCard.dart';
import 'modify_car_screen.dart';
import '../services/car_service.dart';
import '../services/user_service.dart';
class CarScreen extends StatefulWidget {
  const CarScreen({super.key});

  @override
  State<CarScreen> createState() => _CarScreenState();
}

class _CarScreenState extends State<CarScreen> {
  final _parkingService = ParkingService();
  final _carService = CarService();
  final _userService = UserService();
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
            SizedBox(
                height: MediaQuery.of(context).size.height - 150, 
                child: const Center(child: CircularProgressIndicator(color: Color(0xFFFF7643)),),)
            else if (cars.isEmpty)
              Container(
                height: MediaQuery.of(context).size.height * 0.6, 
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.directions_car_filled_outlined, 
                      size: 80, 
                      color: Colors.grey.shade300
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "No cars added yet",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Tap the button below to get started",
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cars.length,
                itemBuilder: (context, index) {
                  return CarCard(
                    car: cars[index],
                    parkingService: _parkingService,
                    userService: _userService,
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("${cars[index]['carname']} removed successfully!"))
                        );
                        _loadCars(); // Refresh list
                      } else if (result is Map<String, dynamic>) {
                        // User updated details
                        await _carService.updateCar(cars[index]['carplate'], result);
                          ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("${cars[index]['carname']} updated successfully!"))
                        );
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
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.5))),
        ),
        child: SafeArea(
          child: ElevatedButton.icon(
            onPressed: _navigateToAddCar
            ,
            icon: const Icon(Icons.add),
            label: const Text("Add Car"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7643),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ),
      ),
    );
  }
}



