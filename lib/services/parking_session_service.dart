import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:latlong2/latlong.dart';
import '../services/user_service.dart';
import '../models/parking_session.dart';

class ParkingSessionService {
  final _supabase = Supabase.instance.client;

  Future<ParkingSession> createParkingSession({
    String? sessionId,
    String? driverId,
    required String carPlate,
    required LatLng carparkLocation,
    String? carparkName,
    String? sessionName,
    String? sessionDescription,
    double? rateThreshold,
    List<String> images = const [],
    DateTime? startTime,
    DateTime? endTime,
    double? currentFees,
  }) async {
  final result = await _supabase
      .from('parkingsession')
      .insert({
        'sessionid': ?sessionId,
        'driverid': driverId ?? UserService().userId,
        'carplate': carPlate,
        'location': '(${carparkLocation.longitude},${carparkLocation.latitude})',
        'carparkname': carparkName,
        'sessionname': ?sessionName,
        'sessiondescription': ?sessionDescription,
        'ratethreshold': ?rateThreshold,
        if (images.isNotEmpty) 'images': images,
        'parkingstarttime': (startTime ?? DateTime.now()).toIso8601String(),
        'parkingendtime': ?(endTime?.toIso8601String()),
        'currentfees': ?currentFees,
      })
      .select()
      .single();
  await _supabase.from('cars').update({'isparked': true}).eq('carplate', carPlate);
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

  Future<void> endParking(
      String sessionId, String carPlate, DateTime endTime, double fees) async {
    await _supabase.from('parkingsession').update({
      'parkingendtime': endTime.toUtc().toIso8601String(),
      'currentfees': fees,
    }).eq('sessionid', sessionId);
    await _supabase.from('cars').update({'isparked': false}).eq('carplate', carPlate);
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
    String? carparkName,
    required LatLng? location,
  }) async {
    await _supabase.from('parkingsession').update({
      'sessionname': sessionName,
      'sessiondescription': sessionDescription,
      'ratethreshold': rateThreshold,
      if (location != null) 'location': '(${location.longitude}, ${location.latitude})',
      'carparkname': carparkName,
    }).eq('sessionid', sessionId);
  }
}
