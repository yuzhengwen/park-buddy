import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/parking_session.dart';

class ParkingSessionService {
  final _supabase = Supabase.instance.client;

  Future<ParkingSession> fetchSession(String sessionId) async {
    final response = await _supabase
        .from('parkingsession')
        .select()
        .eq('sessionid', sessionId)
        .maybeSingle();

    if (response == null) {
      throw Exception('Session not found: $sessionId');
    }
    return ParkingSession.fromMap(response);
  }

  Future<String?> fetchDriverName(String driverId) async {
    final response = await _supabase
        .from('users')
        .select('username')
        .eq('userid', driverId)
        .maybeSingle();
    return response?['username'] as String?;
  }

  Future<String?> fetchCarName(String carPlate) async {
    final response = await _supabase
        .from('cars')
        .select('carname')
        .eq('carplate', carPlate)
        .maybeSingle();
    return response?['carname'] as String?;
  }

  // Removed: fetchFeeDetails — no longer using parkingfee table

  Future<void> endParking(
      String sessionId, DateTime endTime, double fees) async {
    await _supabase.from('parkingsession').update({
      'parkingendtime': endTime.toUtc().toIso8601String(),
      'currentfees': fees,
    }).eq('sessionid', sessionId);
  }

  Future<void> updateSessionImages(
      String sessionId, List<String> imageUrls) async {
    await _supabase.from('parkingsession').update({
      'images': imageUrls,
    }).eq('sessionid', sessionId);
  }

  Future<void> updateSessionDetails({
    required String sessionId,
    required String? sessionName,
    required String? sessionDescription,
    required double? rateThreshold,
    required String? location, // stores "x_coord,y_coord"
  }) async {
    await _supabase.from('parkingsession').update({
      'sessionname': sessionName,
      'sessiondescription': sessionDescription,
      'ratethreshold': rateThreshold,
      'location': location,
    }).eq('sessionid', sessionId);
  }
}