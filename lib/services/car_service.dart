import 'package:supabase_flutter/supabase_flutter.dart';
import 'storage_service.dart';
import 'dart:io';
import 'dart:typed_data';

class CarService {
  final _supabase = Supabase.instance.client;
  final _storageService = StorageService();

  Future<bool> addCar(Map<String, dynamic> carData) async {
    try {
      // 1. Check if an image was actually picked
      if (carData['new_image_file'] != null && carData['new_image_file'] is File) {
        final File imageFile = carData['new_image_file'];
        final Uint8List bytes = await imageFile.readAsBytes();

        // 2. Upload only if the file exists
        final String imageUrl = await _storageService.uploadImage(
          bucket: 'car-images',
          folder: _supabase.auth.currentUser!.id,
          bytes: bytes,
        );

        carData['caricon'] = imageUrl;
      } else {
        carData['caricon'] = null; 
      }
      carData.remove('new_image_file');

      await Future.delayed(const Duration(milliseconds: 500));
      await _supabase.from('cars').insert(carData); 
      
      return true;
    } catch (e) {
      print("Add Car Error: $e");
      return false;
    }
  }

Future<void> updateCar(String oldPlate, Map<String, dynamic> data) async {
    if (data['new_image_file'] != null) {
      File file = data['new_image_file'];
      Uint8List bytes = await file.readAsBytes();

      String url = await _storageService.uploadImage(
        bucket: 'car-images', 
        folder: _supabase.auth.currentUser!.id,
        bytes: bytes,
      );

      data['caricon'] = url;
    }

    data.remove('new_image_file');
    await _supabase.from('cars').update(data).eq('carplate', oldPlate);
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