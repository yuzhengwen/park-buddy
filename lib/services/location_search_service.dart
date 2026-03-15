import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class LocationSearchResult {
  const LocationSearchResult({
    required this.label,
    required this.point,
  });

  final String label;
  final LatLng point;
}

class LocationSearchService {
  LocationSearchService({
    http.Client? client,
  }) : _client = client ?? http.Client();

  final http.Client _client;

  Future<LocationSearchResult?> search(String query) async {
    final String normalized = query.trim();
    if (normalized.isEmpty) {
      return null;
    }

    final Uri uri = Uri.https(
      'www.onemap.gov.sg',
      '/api/common/elastic/search',
      <String, String>{
        'searchVal': normalized,
        'returnGeom': 'Y',
        'getAddrDetails': 'Y',
        'pageNum': '1',
      },
    );

    try {
      final http.Response response = await _client.get(uri);
      if (response.statusCode != 200) {
        return null;
      }

      final Map<String, dynamic> json =
          jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> results = json['results'] as List<dynamic>? ?? <dynamic>[];
      if (results.isEmpty) {
        return null;
      }

      final Map<String, dynamic> first = results.first as Map<String, dynamic>;
      final double? latitude = double.tryParse((first['LATITUDE'] ?? '').toString());
      final double? longitude = double.tryParse((first['LONGITUDE'] ?? '').toString());
      if (latitude == null || longitude == null) {
        return null;
      }

      final String label = (first['SEARCHVAL'] ?? first['ADDRESS'] ?? normalized).toString();

      return LocationSearchResult(
        label: label,
        point: LatLng(latitude, longitude),
      );
    } catch (_) {
      return null;
    }
  }
}
