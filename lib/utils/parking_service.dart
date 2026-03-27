import 'package:supabase_flutter/supabase_flutter.dart';

class ParkingService {
  final _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchCars() async {
    final response = await _supabase.from('cars').select();
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> fetchSessions(String carplate) async {
    final response = await _supabase
        .from('parkingsession')
        .select()
        .eq('carplate', carplate)
        .order('parkingstarttime', ascending: false)
        .limit(3);
    return List<Map<String, dynamic>>.from(response);
  }
}