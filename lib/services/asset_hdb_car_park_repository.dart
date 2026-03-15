import 'package:flutter/services.dart' show rootBundle;

import '../models/car_park.dart';
import 'hdb_rate_repository.dart';
import 'svy21_converter.dart';

class AssetHdbCarParkRepository {
  AssetHdbCarParkRepository({
    HdbRateRepository? rateRepository,
    Svy21Converter? svy21Converter,
  })  : _rateRepository = rateRepository ?? const HdbRateRepository(),
        _svy21Converter = svy21Converter ?? const Svy21Converter();

  final HdbRateRepository _rateRepository;
  final Svy21Converter _svy21Converter;

  Future<List<CarPark>> getCarParks() async {
    final String csv = await rootBundle.loadString('assets/hdb_carparks.csv');
    final List<String> lines = csv.split('\n').where((String line) => line.trim().isNotEmpty).toList(growable: false);
    if (lines.length <= 1) {
      return <CarPark>[];
    }

    return lines.skip(1).map(_fromCsvLine).whereType<CarPark>().toList(growable: false);
  }

  CarPark? _fromCsvLine(String line) {
    final List<String> parts = line.split(',');
    if (parts.length < 12) {
      return null;
    }

    final String id = parts[0].trim();
    final String address = parts[1].trim();
    final double xCoordinate = double.tryParse(parts[2].trim()) ?? 0;
    final double yCoordinate = double.tryParse(parts[3].trim()) ?? 0;
    final String carParkType = parts[4].trim();
    final Svy21Coordinate latLng = _toLatLng(
      xCoordinate: xCoordinate,
      yCoordinate: yCoordinate,
    );

    return CarPark(
      id: id,
      name: 'HDB Car Park $id',
      address: address,
      availableLots: 0,
      source: 'HDB',
      rates: _rateRepository.ratesForCarPark(carParkType),
      latitude: latLng.latitude,
      longitude: latLng.longitude,
      xCoordinate: xCoordinate,
      yCoordinate: yCoordinate,
      type: carParkType,
      shortTermParking: parts[6].trim(),
      freeParking: parts[7].trim(),
      nightParking: parts[8].trim(),
    );
  }

  Svy21Coordinate _toLatLng({
    required double xCoordinate,
    required double yCoordinate,
  }) {
    if (xCoordinate == 0 || yCoordinate == 0) {
      return const Svy21Coordinate(
        latitude: 1.3521,
        longitude: 103.8198,
      );
    }

    return _svy21Converter.toLatLng(
      northing: yCoordinate,
      easting: xCoordinate,
    );
  }
}
