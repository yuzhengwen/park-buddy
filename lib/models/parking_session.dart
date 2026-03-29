class ParkingSession {
  final String sessionId;
  final String? sessionName;
  final String? sessionDescription; // ADD
  final double? rateThreshold;      // ADD
  final String? driverId;
  final String? carPlate;
  final String? location;
  final DateTime? startTime;
  final DateTime? endTime;
  final double? currentFees;
  final List<String> images;

  const ParkingSession({
    required this.sessionId,
    this.sessionName,
    this.sessionDescription, // ADD
    this.rateThreshold,      // ADD
    this.driverId,
    this.carPlate,
    this.location,
    this.startTime,
    this.endTime,
    this.currentFees,
    this.images = const [],
  });

  bool get isOngoing => endTime == null;

  factory ParkingSession.fromMap(Map<String, dynamic> map) {
    return ParkingSession(
      sessionId: map['sessionid'] as String,
      sessionName: map['sessionname'] as String?,
      sessionDescription: map['sessiondescription'] as String?, // ADD
      rateThreshold: map['ratethreshold'] != null               // ADD
          ? (map['ratethreshold'] as num).toDouble()
          : null,
      driverId: map['driverid'] as String?,
      carPlate: map['carplate'] as String?,
      location: map['location'] as String?,
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
    String? sessionDescription, // ADD
    double? rateThreshold,      // ADD
    String? driverId,
    String? carPlate,
    String? location,
    DateTime? startTime,
    DateTime? endTime,
    double? currentFees,
    List<String>? images,
  }) {
    return ParkingSession(
      sessionId: sessionId,
      sessionName: sessionName ?? this.sessionName,
      sessionDescription: sessionDescription ?? this.sessionDescription, // ADD
      rateThreshold: rateThreshold ?? this.rateThreshold,               // ADD
      driverId: driverId ?? this.driverId,
      carPlate: carPlate ?? this.carPlate,
      location: location ?? this.location,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      currentFees: currentFees ?? this.currentFees,
      images: images ?? this.images,
    );
  }
}