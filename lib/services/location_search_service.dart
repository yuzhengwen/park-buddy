import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:park_buddy/models/carpark.dart';
import 'package:string_similarity/string_similarity.dart';

/// Determines what kind of results to expect.
enum SearchResultSource { carpark, building }

/// Result of a location search.
class SearchResult {
  final String searchVal;
  final String blkNo;
  final String roadName;
  final String building;
  final String address;
  final String postal;
  final LatLng position;
  final SearchResultSource source;

  const SearchResult({
    required this.source,
    required this.searchVal,
    this.blkNo = '',
    this.roadName = '',
    this.building = '',
    this.address = '',
    this.postal = '',
    required this.position,
  });

  static SearchResult? fromMap(
    Map<String, dynamic> map,
    SearchResultSource source,
  ) {
    final lat = double.tryParse(map['LATITUDE']?.toString() ?? '');
    final lng = double.tryParse(map['LONGITUDE']?.toString() ?? '');
    final searchVal = map['SEARCHVAL']?.toString();

    if (lat == null || lng == null || searchVal == null) return null;

    return SearchResult(
      source: source,
      searchVal: searchVal,
      blkNo: map['BLK_NO'] ?? '',
      roadName: map['ROAD_NAME'] ?? '',
      building: map['BUILDING'] ?? '',
      address: map['ADDRESS'] ?? '',
      postal: map['POSTAL'] ?? '',
      position: LatLng(lat, lng),
    );
  }
}

/// Provides location lookup for positions and addresses.
class SearchService extends ChangeNotifier {
  static const _oneMapSearchUrl = 'https://www.onemap.gov.sg/api/common/elastic/search';

  List<Carpark> Function()? getAllCarparks;
  bool _isSearchingLocations = false;
  List<SearchResult> _searchResults = const [];
  String? _searchQuery;
  Completer<bool> _waitForDebounce = Completer<bool>();
  Timer? _searchDebounceTimer;

  bool get isSearchingLocations => _isSearchingLocations;
  List<SearchResult> get searchResults => _searchResults;
  String? get searchQuery => _searchQuery;

  /// Search for locations with debounce to avoid exceeding API rate limits.
  /// Meant to be called as the user types.
  Future<void> debouncedLocationSearch(String query, {double delay = 0.5}) async {
    if (!_waitForDebounce.isCompleted) _waitForDebounce.complete(false);
    _waitForDebounce = Completer<bool>();

    // Cancel the previous timer if the user types again before delay
    _searchDebounceTimer?.cancel();

    _searchDebounceTimer = Timer(
      Duration(milliseconds: (delay * 1000).round()),
      () async {
        if (query.isNotEmpty) {
          await _startLocationSearch(query);
        } else {
          clearLocationSearch();
        }
        _waitForDebounce.complete(true);
      });

    await _waitForDebounce.future;
  }

  Future<List<SearchResult>> _startLocationSearch(String query) async {
    if (query.isEmpty) {
      clearLocationSearch();
      return const [];
    }

    _isSearchingLocations = true;
    _searchQuery = query;
    notifyListeners();

    try {
      final uri = Uri.parse(_oneMapSearchUrl).replace(
        queryParameters: {
          'searchVal': query,
          'returnGeom': 'Y',
          'getAddrDetails': 'Y',
          'pageNum': '1',
        },
      );

      final response = await http.get(uri);

      // Check if the query has changed after waiting for result
      if (query != _searchQuery) return const [];

      if (response.statusCode != 200) return const [];

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final webResults = payload['results'] as List<dynamic>? ?? const [];

      final List<SearchResult> combinedResults = [];

      // Add local matches
      if (getAllCarparks != null) {
        combinedResults.addAll(
            getAllCarparks!()
            .where((cp) =>
                cp.address.toLowerCase().contains(query.toLowerCase()) ||
                cp.carParkNo.toLowerCase().contains(query.toLowerCase())
            )
            .map((cp) => SearchResult(
              source: .carpark,
              searchVal: '${cp.address} (${cp.carParkNo})',
              address: cp.address,
              position: cp.position,
            )),
        );
      }

      // Add web matches
      for (var item in webResults) {
        final res = SearchResult.fromMap(
          item as Map<String, dynamic>,
          .building,
        );
        if (res != null) combinedResults.add(res);
      }

      // Sort by similarity
      combinedResults.sort((a, b) =>
        b.searchVal.similarityTo(query).compareTo(a.searchVal.similarityTo(query))
      );

      _searchResults = combinedResults;
      return _searchResults;

    } finally {
      if (query == _searchQuery) {
        _isSearchingLocations = false;
        notifyListeners();
      }
    }
  }

  void clearLocationSearch() {
    _searchResults = const [];
    notifyListeners();
  }
}
