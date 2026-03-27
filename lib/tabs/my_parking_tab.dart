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
        backgroundColor: Color(0xFF6200EA),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : cars.isEmpty
              ? Center(child: Text('No cars registered yet'))
              : ListView.builder(
                  itemCount: cars.length,
                  itemBuilder: (context, index) {
                    return CarCard(
                      car: cars[index],
                      parkingService: _parkingService,
                    );
                  },
                ),
    );
  }
}

