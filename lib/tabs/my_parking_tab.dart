import 'package:flutter/material.dart';
import '../utils/parking_service.dart';
import '../UI/CarCard.dart';

class MyParkingTab extends StatefulWidget {
  @override
  _MyParkingTabState createState() => _MyParkingTabState();
}

class _MyParkingTabState extends State<MyParkingTab> {
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
    setState(() {
      cars = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Parking', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFFFF7643),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCars,
              child: cars.isEmpty
                  ? ListView(
                      children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.2), 
                        
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // 1. Add an illustrative icon
                              Icon(
                                Icons.directions_car_filled_outlined,
                                size: 100,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'No cars added yet',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 40),
                                child: Text(
                                  'Add your first car in your profile to get started!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    height: 1.5, // Better line spacing
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      itemCount: cars.length,
                      itemBuilder: (context, index) {
                        return CarCard(
                          car: cars[index],
                          parkingService: _parkingService,
                        );
                      },
                    ),
            ),
    );
  }
}

