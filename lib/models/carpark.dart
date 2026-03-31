import 'package:latlong2/latlong.dart';

import '../services/svy21_converter.dart';

//car_park_no,address,x_coord,y_coord,car_park_type,type_of_parking_system,short_term_parking,free_parking,night_parking,car_park_decks,gantry_height,car_park_basement
class Carpark {
  final String carParkNo;
  final String address;
  final String blockLabel;
  final LatLng position;
  final String carParkType;
  final String shortTermParking;
  final CarparkAvailability? availability;


  const Carpark({
    required this.carParkNo,
    required this.address,
    required this.blockLabel,
    required this.position,
    required this.carParkType,
    required this.shortTermParking,
    this.availability,
  });

  // Factory for the Live Data.gov.sg API
  static Carpark? fromLiveJson(Map<String, dynamic> json) {
    final xCoord = double.tryParse(json['x_coord']?.toString() ?? '');
    final yCoord = double.tryParse(json['y_coord']?.toString() ?? '');

    if (xCoord == null || yCoord == null) return null;

    // Convert SVY21 to LatLng using your existing converter
    final latLng = Svy21Converter.toLatLng(easting: xCoord, northing: yCoord);

    return Carpark(
      carParkNo: json['car_park_no'] ?? '',
      address: json['address'] ?? '',
      blockLabel: extractBlockLabel(
        json['address'] ?? '',
        json['car_park_no'] ?? '',
      ),
      position: latLng,
      carParkType: json['car_park_type'] ?? 'Unknown',
      shortTermParking: json['short_term_parking'] ?? 'Unknown',
    );
  }

  // Your existing helper for labels
  static String extractBlockLabel(String address, String carParkNo) {
    final upperAddress = address.toUpperCase();
    final blockMatch = RegExp(
      r'\b(?:BLK|BLOCK)\s+([A-Z0-9]+)',
    ).firstMatch(upperAddress);
    return blockMatch?.group(1) ?? carParkNo;
  }

  // Support for merging availability later
  Carpark copyWith({CarparkAvailability? availability}) {
    return Carpark(
      carParkNo: carParkNo,
      address: address,
      blockLabel: blockLabel,
      position: position,
      carParkType: carParkType,
      shortTermParking: shortTermParking,
      availability: availability,
    );
  }
}

class CarparkAvailability {
  const CarparkAvailability({
    required this.carParkNo,
    required this.lotsAvailable,
    required this.totalLots,
  });

  final String carParkNo;
  final int lotsAvailable;
  final int totalLots;

  static CarparkAvailability? fromJson(Map<String, dynamic> json) {
    final carParkNo = (json['carpark_number'] as String?)?.trim();
    final infoList = json['carpark_info'] as List<dynamic>? ?? const [];
    final carLotInfo = infoList.cast<Map<String, dynamic>?>().firstWhere(
      (entry) => entry?['lot_type'] == 'C',
      orElse: () => null,
    );

    if (carParkNo == null || carParkNo.isEmpty || carLotInfo == null) {
      return null;
    }

    return CarparkAvailability(
      carParkNo: carParkNo,
      lotsAvailable:
          int.tryParse(carLotInfo['lots_available'] as String? ?? '') ?? 0,
      totalLots: int.tryParse(carLotInfo['total_lots'] as String? ?? '') ?? 0,
    );
  }
}
