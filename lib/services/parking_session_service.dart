import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/parking_session.dart';

class ParkingSessionService {
  final _supabase = Supabase.instance.client;

  /// Create a new parking session in the database.
  ///
  /// Returns the stored parking session on success. Throws database errors on
  /// failure.
  Future<ParkingSession> createParkingSession(ParkingSession parkingSession) async {
    final result = await _supabase
        .from('parkingsession')
        .insert(parkingSession.toMap())
        .select()
        .single();
    return ParkingSession.fromMap(result);
  }

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

  // Returns null if location has no matching carpark or fee row
  Future<({double hourlyFee, int gracePeriod})?> fetchFeeDetails(
      String location) async {
    final carparkResponse = await _supabase
        .from('carparks')
        .select('feeid')
        .eq('location', location)
        .maybeSingle();

    if (carparkResponse == null) return null;
    final feeId = carparkResponse['feeid'];
    if (feeId == null) return null;

    final feeResponse = await _supabase
        .from('parkingfee')
        .select('hourlyfee, graceperiod')
        .eq('feeid', feeId)
        .maybeSingle();

    if (feeResponse == null) return null;
    return (
      hourlyFee: (feeResponse['hourlyfee'] as num).toDouble(),
      gracePeriod: feeResponse['graceperiod'] as int,
    );
  }

  Future<void> endParking(
      String sessionId, DateTime endTime, double fees) async {
    await _supabase.from('parkingsession').update({
      'parkingendtime': endTime.toUtc().toIso8601String(),
      'currentfees': fees,
    }).eq('sessionid', sessionId);
  }

  // DB operation so it lives here, not in storage service
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
    required String? location,
  }) async {
    await _supabase.from('parkingsession').update({
      'sessionname': sessionName,
      'sessiondescription': sessionDescription,
      'ratethreshold': rateThreshold,
      'location': location,
    }).eq('sessionid', sessionId);
  }
}
