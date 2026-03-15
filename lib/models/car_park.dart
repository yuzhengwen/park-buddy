import 'parking_rate.dart';

class CarPark {
  const CarPark({
    required this.id,
    required this.name,
    required this.address,
    required this.availableLots,
    required this.source,
    required this.rates,
    this.latitude,
    this.longitude,
    this.postalCode,
    this.xCoordinate,
    this.yCoordinate,
    this.type,
    this.shortTermParking,
    this.freeParking,
    this.nightParking,
  });

  final String id;
  final String name;
  final String address;
  final int availableLots;
  final String source;
  final List<ParkingRate> rates;
  final double? latitude;
  final double? longitude;
  final String? postalCode;
  final double? xCoordinate;
  final double? yCoordinate;
  final String? type;
  final String? shortTermParking;
  final String? freeParking;
  final String? nightParking;

  CarPark copyWith({
    String? id,
    String? name,
    String? address,
    int? availableLots,
    String? source,
    List<ParkingRate>? rates,
    double? latitude,
    double? longitude,
    String? postalCode,
    double? xCoordinate,
    double? yCoordinate,
    String? type,
    String? shortTermParking,
    String? freeParking,
    String? nightParking,
  }) {
    return CarPark(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      availableLots: availableLots ?? this.availableLots,
      source: source ?? this.source,
      rates: rates ?? this.rates,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      postalCode: postalCode ?? this.postalCode,
      xCoordinate: xCoordinate ?? this.xCoordinate,
      yCoordinate: yCoordinate ?? this.yCoordinate,
      type: type ?? this.type,
      shortTermParking: shortTermParking ?? this.shortTermParking,
      freeParking: freeParking ?? this.freeParking,
      nightParking: nightParking ?? this.nightParking,
    );
  }
}
