import 'package:flutter/services.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/car_park.dart';
import '../services/asset_hdb_car_park_repository.dart';
import '../services/hdb_rate_repository.dart';
import '../services/svy21_converter.dart';
import 'car_park_provider.dart';

class HdbCarParkProvider implements CarParkProvider {
  HdbCarParkProvider({
    http.Client? client,
    HdbRateRepository? rateRepository,
  })  : _client = client ?? http.Client(),
        _rateRepository = rateRepository ?? const HdbRateRepository(),
        _assetRepository = AssetHdbCarParkRepository(
          rateRepository: rateRepository,
        ),
        _svy21Converter = const Svy21Converter();

  static const String _carParkInfoDatasetId =
      'd_23f946fa557947f93a8043bbef41dd09';
  static final Uri _carParkInfoUri = Uri.parse(
    'https://data.gov.sg/api/action/datastore_search?resource_id=$_carParkInfoDatasetId&limit=5000',
  );

  // Keep the old public endpoint for easier client-side testing.
  static final Uri _availabilityUri = Uri.parse(
    'https://api.data.gov.sg/v1/transport/carpark-availability',
  );

  final http.Client _client;
  final HdbRateRepository _rateRepository;
  final AssetHdbCarParkRepository _assetRepository;
  final Svy21Converter _svy21Converter;

  @override
  Future<List<CarPark>> fetchCarParks() async {
    final List<Map<String, dynamic>> records = await _fetchInfoRecords();
    final Map<String, int> availabilityByCarPark = await _fetchAvailability();

    if (records.isEmpty) {
      return _assetRepository.getCarParks();
    }

    return records
        .whereType<Map<String, dynamic>>()
        .map((Map<String, dynamic> record) {
          final String id = (record['car_park_no'] ?? '').toString();
          final String name = 'HDB Car Park $id';
          final String address = (record['address'] ?? '').toString();
          final String carParkType = (record['car_park_type'] ?? '').toString();
          final double xCoordinate = _parseCoordinate(record['x_coord']);
          final double yCoordinate = _parseCoordinate(record['y_coord']);
          final Svy21Coordinate latLng = _toLatLng(
            xCoordinate: xCoordinate,
            yCoordinate: yCoordinate,
          );

          return CarPark(
            id: id,
            name: name,
            address: address,
            availableLots: availabilityByCarPark[id] ?? 0,
            source: 'HDB',
            rates: _rateRepository.ratesForCarPark(carParkType),
            latitude: latLng.latitude,
            longitude: latLng.longitude,
            xCoordinate: xCoordinate,
            yCoordinate: yCoordinate,
            type: carParkType,
            shortTermParking: record['short_term_parking']?.toString(),
            freeParking: record['free_parking']?.toString(),
            nightParking: record['night_parking']?.toString(),
          );
        })
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> _fetchInfoRecords() async {
    try {
      final http.Response response = await _client.get(_carParkInfoUri);
      if (response.statusCode != 200) {
        return <Map<String, dynamic>>[];
      }

      final Map<String, dynamic> infoJson =
          jsonDecode(response.body) as Map<String, dynamic>;
      if (infoJson['code'] != null && infoJson['code'] != 0) {
        return <Map<String, dynamic>>[];
      }

      final List<dynamic> records =
          (infoJson['result']?['records'] as List<dynamic>? ?? <dynamic>[]);
      return records.whereType<Map<String, dynamic>>().toList(growable: false);
    } on PlatformException {
      return <Map<String, dynamic>>[];
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  Future<Map<String, int>> _fetchAvailability() async {
    try {
      final http.Response response = await _client.get(_availabilityUri);
      if (response.statusCode != 200) {
        return <String, int>{};
      }

      final Map<String, dynamic> availabilityJson =
          jsonDecode(response.body) as Map<String, dynamic>;
      return _parseAvailability(availabilityJson);
    } catch (_) {
      return <String, int>{};
    }
  }

  Map<String, int> _parseAvailability(Map<String, dynamic> json) {
    final List<dynamic> items = json['items'] as List<dynamic>? ?? <dynamic>[];
    if (items.isEmpty) {
      return <String, int>{};
    }

    final List<dynamic> carParkData =
        (items.first as Map<String, dynamic>)['carpark_data'] as List<dynamic>? ??
            <dynamic>[];

    final Map<String, int> availabilityByCarPark = <String, int>{};

    for (final dynamic entry in carParkData) {
      final Map<String, dynamic> typedEntry =
          entry as Map<String, dynamic>? ?? <String, dynamic>{};
      final String carParkNumber =
          (typedEntry['carpark_number'] ?? '').toString();
      final List<dynamic> info =
          typedEntry['carpark_info'] as List<dynamic>? ?? <dynamic>[];

      final int totalAvailableLots = info
          .whereType<Map<String, dynamic>>()
          .map(
            (Map<String, dynamic> carParkInfo) =>
                int.tryParse((carParkInfo['lots_available'] ?? '0').toString()) ?? 0,
          )
          .fold<int>(0, (int sum, int value) => sum + value);

      availabilityByCarPark[carParkNumber] = totalAvailableLots;
    }

    return availabilityByCarPark;
  }

  double _parseCoordinate(dynamic value) {
    return double.tryParse((value ?? '0').toString()) ?? 0;
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
