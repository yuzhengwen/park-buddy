import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../services/svy21_converter.dart';
import '../models/carpark.dart';

class ApiController {
  static const _hdbCarparksAsset = 'assets/hdb_carparks.json';
  // HDB Carpark Information (Static info: Address, Coordinates, Type)
  static const String _infoUrl =
      'https://data.gov.sg/api/action/datastore_search?resource_id=d_23f946fa557947f93a8043bbef41dd09&limit=5000';

  // Real-time Availability (Dynamic info: Lots available)
  static const String _availabilityUrl =
      'https://api.data.gov.sg/v1/transport/carpark-availability';

  /// Fetches the base carpark data (Address, X/Y coords) from the live API
  Future<List<Carpark>> fetchLiveCarparkLocations() async {
    try {
      final response = await http.get(Uri.parse(_infoUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List records = data['result']['records'];

        return records.map((record) {
          // Convert SVY21 strings to doubles
          double x = double.tryParse(record['x_coord'] ?? '0') ?? 0;
          double y = double.tryParse(record['y_coord'] ?? '0') ?? 0;

          // Use your existing converter logic
          LatLng latLng = Svy21Converter.toLatLng(northing: y, easting: x);

          return Carpark(
            carParkNo: record['car_park_no'] ?? '',
            address: record['address'] ?? '',
            blockLabel: Carpark.extractBlockLabel(
              record['address'] ?? '',
              record['car_park_no'] ?? '',
            ),
            position: latLng,
            carParkType: record['car_park_type'] ?? 'Unknown',
            shortTermParking: record['short_term_parking'] ?? 'Unknown',
          );
        }).toList();
      }
    } catch (e) {
      debugPrint("Error fetching live locations: $e");
    }
    return [];
  }

  Future<List<Carpark>> fetchCarparkLocations() async {
    try {
      final jsonString = await rootBundle.loadString(_hdbCarparksAsset);
      final decoded = jsonDecode(jsonString);

      // Check if it's a Map with a nested list (common in exported JSONs)
      List<dynamic> records;
      if (decoded is Map) {
        // Adjust 'records' to whatever key your JSON uses (e.g., 'items' or 'data')
        records = decoded['records'] ?? [];
        debugPrint(
          "Detected Map structure. Found ${records.length} records under key 'records'",
        );
      } else {
        records = decoded as List<dynamic>;
        debugPrint("Detected List structure. Found ${records.length} records");
      }

      final list = records
          .map((record) {
            final carpark = Carpark.fromLiveJson(
              record as Map<String, dynamic>,
            );
            if (carpark == null) {
              // This is your smoking gun
              debugPrint(
                "FAILED TO PARSE RECORD: ${record['car_park_no'] ?? record['address']}",
              );
            }
            return carpark;
          })
          .whereType<Carpark>() // cleaner way to filter nulls
          .toList();

      debugPrint("Final Carpark List Count: ${list.length}");
      return list;
    } catch (e) {
      debugPrint("CRITICAL ERROR IN fetchCarparkLocations: $e");
      return [];
    }
  }
  // Future<List<Carpark>> fetchCarparkLocations() async {
  //   final jsonString = await rootBundle.loadString(_hdbCarparksAsset);
  //   final records = jsonDecode(jsonString) as List<dynamic>;
  //   return records
  //       .map((record) => Carpark.fromLiveJson(record as Map<String, dynamic>))
  //       .where((carpark) => carpark != null)
  //       .cast<Carpark>()
  //       .toList();
  // }

  Future<Map<String, CarparkAvailability>> fetchAvailabilityMap() async {
    final response = await http.get(Uri.parse(_availabilityUrl));
    if (response.statusCode != 200) {
      throw Exception(
        'Availability API request failed (${response.statusCode}).',
      );
    }

    final Map<String, dynamic> payload =
        jsonDecode(response.body) as Map<String, dynamic>;
    final items = payload['items'] as List<dynamic>? ?? const [];
    if (items.isEmpty) {
      return const {};
    }

    final firstItem = items.first as Map<String, dynamic>;
    final carparkData = firstItem['carpark_data'] as List<dynamic>? ?? const [];
    final availabilityMap = <String, CarparkAvailability>{};

    for (final rawCarpark in carparkData) {
      final availability = CarparkAvailability.fromJson(
        rawCarpark as Map<String, dynamic>,
      );
      if (availability != null) {
        availabilityMap[availability.carParkNo] = availability;
      }
    }

    return availabilityMap;
  }
}
