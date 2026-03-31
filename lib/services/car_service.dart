import 'package:supabase_flutter/supabase_flutter.dart';

class CarService {
  final _supabase = Supabase.instance.client;

  Future<bool> addCar(Map<String, dynamic> carData) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      await _supabase.from('cars').insert(carData); 
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateCar(String oldPlate, Map<String, dynamic> updatedData) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      await _supabase.from('cars').update(updatedData).eq('carplate', oldPlate);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteCar(String carPlate) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      await _supabase.from('cars').delete().eq('carplate', carPlate);
      return true;
    } catch (e) {
      return false;
    }
  }
}