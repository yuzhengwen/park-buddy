import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cars_provider.dart';
import '../utils/parking_service.dart';
import '../UI/CarCard.dart';

class MyParkingTab extends StatelessWidget {
  const MyParkingTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CarsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('My Parking', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFFFF7643),
      ),
      body: provider.isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: context.read<CarsProvider>().loadCars,
              child: provider.cars.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
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
                                    height: 1.5,
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
                      itemCount: provider.cars.length,
                      itemBuilder: (context, index) {
                        return CarCard(
                          car: provider.cars[index],
                          parkingService: ParkingService(),
                        );
                      },
                    ),
            ),
    );
  }
}
