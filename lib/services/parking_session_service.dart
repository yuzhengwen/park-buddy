import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:park_buddy/services/user_service.dart';

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

  // TODO: ideally fetchSessions from utils/parking_service should be migrated here
  // TODO: add updateParkingSession (which fields may be updated??)
}

/// Interface class to avoid interacting with database table directly
class ParkingSession {
  final String? sessionId;
  final String driverId;
  final String carPlate;
  final LatLng location;
  final String? sessionName;
  final DateTime parkingStartTime;
  final DateTime? parkingEndTime;
  final double? currentFees;
  final List<String> images;

  ParkingSession({
    this.sessionId,
    String? driverId,
    required this.carPlate,
    required this.location,
    this.sessionName,
    DateTime? parkingStartTime,
    this.parkingEndTime,
    this.currentFees,
    this.images = const [],
  }) : driverId = driverId ?? UserService().userId,
       parkingStartTime = parkingStartTime ?? DateTime.now();

  /// Convert database row to ParkingSession object.
  factory ParkingSession.fromMap(Map<String, dynamic> map) {
    final parts = (map['location'] as String)
        .replaceAll(RegExp(r'[()]'), '')
        .split(',');
    final location = LatLng(double.parse(parts[1]), double.parse(parts[0]));

    return ParkingSession(
      sessionId: map['sessionid'] as String,
      driverId: map['driverid'] as String,
      carPlate: map['carplate'] as String,
      location: location,
      sessionName: map['sessionname'] as String?,
      parkingStartTime: DateTime.parse(map['parkingstarttime']),
      parkingEndTime: map['parkingendtime'] != null
          ? DateTime.parse(map['parkingendtime'])
          : null,
      currentFees: map['currentfees'] != null
          ? (map['currentfees'] as num).toDouble()
          : null,
      images: List<String>.from(map['images'] as List<String>? ?? const <String>[]),
    );
  }

  /// Convert ParkingSession object to database row.
  Map<String, dynamic> toMap() {
    return {
      if (sessionId != null) 'sessionid': sessionId,
      'driverid': driverId,
      'carplate': carPlate,
      'location': '(${location.longitude},${location.latitude})',
      'sessionname': sessionName,
      'parkingstarttime': parkingStartTime.toIso8601String(),
      'parkingendtime': parkingEndTime?.toIso8601String(),
      'currentfees': currentFees,
      if (images.isNotEmpty) 'images': images,
    };
  }
}
