import 'package:flutter/material.dart';
import '../utils/parking_service.dart';

class CarsProvider extends ChangeNotifier {
  final _parkingService = ParkingService();

  List<Map<String, dynamic>> _cars = [];
  bool isLoading = true;

  List<Map<String, dynamic>> get cars => _cars;

  Future<void> loadCars() async {
    isLoading = true;
    notifyListeners();

    _cars = await _parkingService.fetchCars();
    isLoading = false;
    notifyListeners();
  }
}
