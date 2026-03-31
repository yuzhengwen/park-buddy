import 'package:latlong2/latlong.dart';
import '../services/svy21_converter.dart';
class ParkingSession {
  final String sessionId;
  final String? sessionName;
  final String? sessionDescription;
  final double? rateThreshold;
  final String? driverId;
  final String? carPlate;
  final String? location; // stores "x_coord,y_coord" SVY21 string
  final String? carparkName;
  final LatLng? carparkPosition; // derived from location, not stored in DB
  final DateTime? startTime;
  final DateTime? endTime;
  final double? currentFees;
  final List<String> images;

  const ParkingSession({
    required this.sessionId,
    this.sessionName,
    this.sessionDescription,
    this.rateThreshold,
    this.driverId,
    this.carPlate,
    this.location,
    this.carparkName,
    this.carparkPosition,
    this.startTime,
    this.endTime,
    this.currentFees,
    this.images = const [],
  });

  bool get isOngoing => endTime == null;

  factory ParkingSession.fromMap(Map<String, dynamic> map) {
    LatLng? position;
    final locationStr = map['location'] as String?;

    if (locationStr != null && locationStr.isNotEmpty) {
      // Clean the string: Remove ( ) and spaces
      final cleanStr = locationStr.replaceAll('(', '').replaceAll(')', '').trim();
      final parts = cleanStr.split(',');

      if (parts.length == 2) {
        // 2. Parse as direct GPS doubles
        final double? lon = double.tryParse(parts[0].trim());
        final double? lat = double.tryParse(parts[1].trim());

        if (lat != null && lon != null) {
          // 3. Assign directly to LatLng (Lat, Lng)
          // Ensure you pass them in the order the LatLng class expects
          position = LatLng(lat, lon); 
        }
      }
    }

    return ParkingSession(
      sessionId: map['sessionid'] as String,
      sessionName: map['sessionname'] as String?,
      sessionDescription: map['sessiondescription'] as String?,
      rateThreshold: map['ratethreshold'] != null
          ? (map['ratethreshold'] as num).toDouble()
          : null,
      driverId: map['driverid'] as String?,
      carPlate: map['carplate'] as String?,
      location: locationStr,
      carparkName: map['carparkname'] as String?,
      carparkPosition: position,
      startTime: map['parkingstarttime'] != null
          ? DateTime.tryParse(map['parkingstarttime'].toString())
          : null,
      endTime: map['parkingendtime'] != null
          ? DateTime.tryParse(map['parkingendtime'].toString())
          : null,
      currentFees: map['currentfees'] != null
          ? (map['currentfees'] as num).toDouble()
          : null,
      images: List<String>.from(map['images'] ?? []),
    );
  }

  ParkingSession copyWith({
    String? sessionName,
    String? sessionDescription,
    double? rateThreshold,
    String? driverId,
    String? carPlate,
    String? location,
    String? carparkName,
    LatLng? carparkPosition,
    DateTime? startTime,
    DateTime? endTime,
    double? currentFees,
    List<String>? images,
  }) {
    return ParkingSession(
      sessionId: sessionId,
      sessionName: sessionName ?? this.sessionName,
      sessionDescription:
          sessionDescription ?? this.sessionDescription,
      rateThreshold: rateThreshold ?? this.rateThreshold,
      driverId: driverId ?? this.driverId,
      carPlate: carPlate ?? this.carPlate,
      location: location ?? this.location,
      carparkName: carparkName ?? this.carparkName,
      carparkPosition: carparkPosition ?? this.carparkPosition,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      currentFees: currentFees ?? this.currentFees,
      images: images ?? this.images,
    );
  }
}