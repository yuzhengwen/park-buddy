import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:park_buddy/models/carpark.dart';
import 'package:park_buddy/utils/math_utils.dart';
import 'package:park_buddy/services/api_controller.dart';
import 'package:park_buddy/services/location_service.dart';

class LocationSearchResult {
  const LocationSearchResult({required this.position, required this.label});

  final LatLng position;
  final String label;
}

class MapTabController extends ChangeNotifier {
  static const defaultRadiusKm = 1.0;
  static const _oneMapSearchUrl =
      'https://www.onemap.gov.sg/api/common/elastic/search';

  final _apiController = ApiController();
  final _locationService = LocationService();

  Timer? _availabilityRefreshTimer;
  List<Carpark> _allCarparks = const [];
  List<Carpark> _visibleCarparks = const [];
  String _statusMessage = 'Loading HDB car parks...';
  String? _loadError;
  bool _isLoadingCarparks = true;
  bool _isSearchingLocation = false;
  double _radiusKm = defaultRadiusKm;
  String _searchText = '';
  String? _selectedCarparkNo;
  Carpark? _selectedCarpark;
  LatLng? _currentLocation;
  LatLng? _searchCenter;
  String? _searchCenterLabel;
  bool _isUsingTextFallback = false;
  void Function(LatLng)? _locationEnableCallback;

  // ── Getters ──────────────────────────────────────────────────────────────

  LatLng? get currentLocation => _currentLocation;
  List<Carpark> get allCarparks => _allCarparks;
  List<Carpark> get visibleCarparks => _visibleCarparks;
  String get statusMessage => _statusMessage;
  String? get loadError => _loadError;
  bool get isLoadingCarparks => _isLoadingCarparks;
  bool get isSearchingLocation => _isSearchingLocation;
  double get radiusKm => _radiusKm;
  String get searchText => _searchText;
  String? get selectedCarparkNo => _selectedCarparkNo;
  Carpark? get selectedCarpark => _selectedCarpark;
  LatLng? get searchCenter => _searchCenter;
  String? get searchCenterLabel => _searchCenterLabel;
  bool get isUsingTextFallback => _isUsingTextFallback;
  
  set locationEnableCallback(void Function(LatLng)? value) =>
    _locationEnableCallback = value;

  // ── Initialisation ────────────────────────────────────────────────────────

  Future<void> initialize() async {
    _locationService.addListener(_handleLocationUpdate);
    await Future.wait([loadCarparkData(), _locationService.startLiveLocation()]);
    refreshVisibleCarparks();
    _startAvailabilityRefresh();
  }

  // ── Carpark data ──────────────────────────────────────────────────────────

  Future<void> loadCarparkData() async {
    _isLoadingCarparks = true;
    _loadError = null;
    _statusMessage = 'Loading HDB car parks...';
    notifyListeners();

    try {
      final locations = await _apiController.fetchCarparkLocations();
      Map<String, CarparkAvailability> availabilityMap = const {};
      try {
        availabilityMap = await _apiController.fetchAvailabilityMap();
      } catch (_) {
        // Show static car park locations even if live availability is unavailable.
      }

      final merged = locations
          .map(
            (carpark) => carpark.copyWith(
              availability: availabilityMap[carpark.carParkNo],
            ),
          )
          .whereType<Carpark>()
          .toList();

      _allCarparks = merged;
      _isLoadingCarparks = false;
      _statusMessage = 'Loaded ${merged.length} HDB car parks.';
    } catch (error) {
      _isLoadingCarparks = false;
      _loadError = 'Unable to load HDB car parks: $error';
      _statusMessage = _loadError!;
    }

    notifyListeners();
  }

  void _startAvailabilityRefresh() {
    _availabilityRefreshTimer?.cancel();
    _availabilityRefreshTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => unawaited(_refreshAvailability()),
    );
  }

  Future<void> _refreshAvailability() async {
    try {
      final availabilityMap = await _apiController.fetchAvailabilityMap();
      _allCarparks = _allCarparks.map((carpark) {
        return carpark.copyWith(
          availability: availabilityMap[carpark.carParkNo],
        );
      }).toList();
      notifyListeners();
      refreshVisibleCarparks();
    } catch (_) {
      // Keep the last successful availability values if refresh fails.
    }
  }

  // ── Location ──────────────────────────────────────────────────────────────

  void _handleLocationUpdate() {
    final newLocation = _locationService.currentLocation;
    if (_currentLocation == null && newLocation != null) {
      _locationEnableCallback?.call(newLocation);
    }
    _currentLocation = newLocation;
    notifyListeners();
  }

  // ── Search ────────────────────────────────────────────────────────────────

  void handleSearchChanged(String text) {
    if (text.trim().isEmpty) {
      _searchText = '';
      _searchCenter = null;
      _searchCenterLabel = null;
      _isUsingTextFallback = false;
      notifyListeners();
      refreshVisibleCarparks();
      return;
    }

    _searchText = text.trim().toLowerCase();
    notifyListeners();
  }

  Future<void> applySearchAndRadius({
    required String searchQuery,
    required String radiusText,
    required VoidCallback onMoveMap,
  }) async {
    final radius = double.tryParse(radiusText.trim());
    if (radius != null && radius > 1.0) {
      _radiusKm = 1.0;
      _statusMessage = 'Maximum radius is 1 km. Setting to 1 km.';
    } else {
      _radiusKm = (radius == null || radius <= 0) ? defaultRadiusKm : radius;
    }

    if (searchQuery.isEmpty) {
      _searchCenter = null;
      _searchCenterLabel = null;
      _isUsingTextFallback = false;
      notifyListeners();
      refreshVisibleCarparks();
      return;
    }

    _isSearchingLocation = true;
    _statusMessage = 'Searching for "$searchQuery"...';
    notifyListeners();

    try {
      final searchResult = await _searchLocation(searchQuery);

      if (searchResult != null) {
        _searchCenter = searchResult.position;
        _searchCenterLabel = searchResult.label;
        _isUsingTextFallback = false;
        _statusMessage = 'Showing car parks near ${searchResult.label}.';
        onMoveMap();
      } else {
        _searchCenter = null;
        _searchCenterLabel = null;
        _isUsingTextFallback = true;
        _statusMessage =
            'No location match found. Showing car parks matching the text instead.';
      }
    } catch (_) {
      _searchCenter = null;
      _searchCenterLabel = null;
      _isUsingTextFallback = true;
      _statusMessage =
          'Location search is unavailable right now. Showing text matches instead.';
    } finally {
      _isSearchingLocation = false;
      notifyListeners();
    }

    refreshVisibleCarparks();
  }

  Future<LocationSearchResult?> _searchLocation(String query) async {
    final uri = Uri.parse(_oneMapSearchUrl).replace(
      queryParameters: {
        'searchVal': query,
        'returnGeom': 'Y',
        'getAddrDetails': 'Y',
        'pageNum': '1',
      },
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Location search failed (${response.statusCode}).');
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final results = payload['results'] as List<dynamic>? ?? const [];
    if (results.isEmpty) return null;

    final first = results.first as Map<String, dynamic>;
    final lat = double.tryParse(first['LATITUDE'] as String? ?? '');
    final lng = double.tryParse(first['LONGITUDE'] as String? ?? '');
    if (lat == null || lng == null) return null;

    return LocationSearchResult(
      position: LatLng(lat, lng),
      label: query.trim(),
    );
  }

  // ── Carpark filtering / sorting ───────────────────────────────────────────

  void refreshVisibleCarparks() {
    final origin = _searchCenter ?? _locationService.currentLocation;

    final filtered = _allCarparks.where((carpark) {
      if (_isUsingTextFallback && _searchText.isNotEmpty) {
        final matchesSearch =
            carpark.address.toLowerCase().contains(_searchText) ||
            carpark.carParkNo.toLowerCase().contains(_searchText);
        if (!matchesSearch) return false;
      }

      if (origin == null) {
        // Don't show carpark if no location available and no search performed
        return _isUsingTextFallback || _searchText.isNotEmpty;
      }

      return MathUtils.distanceKm(origin, carpark.position) <= _radiusKm;
    }).toList();

    if (origin != null) {
      filtered.sort(
        (a, b) => MathUtils.distanceKm(
          origin,
          a.position,
        ).compareTo(MathUtils.distanceKm(origin, b.position)),
      );
    } else {
      filtered.sort((a, b) => a.address.compareTo(b.address));
    }

    _visibleCarparks = filtered;
    if (_selectedCarparkNo != null &&
        !_visibleCarparks.any((c) => c.carParkNo == _selectedCarparkNo)) {
      _selectedCarparkNo = null;
    }

    notifyListeners();
  }

  // ── Map interactions ──────────────────────────────────────────────────────

  void selectCarpark(Carpark carpark) {
    _selectedCarpark = carpark;
    _selectedCarparkNo = carpark.carParkNo;
    notifyListeners();
  }

  void unselectCarpark() {
    _selectedCarpark = null;
    _selectedCarparkNo = null;
    notifyListeners();
  }

  // ── Utility ───────────────────────────────────────────────────────────────
  Carpark? getNearestCarpark(LatLng position) {
    Carpark? nearest;
    double nearestDistance = double.infinity;
    for (final carpark in _allCarparks) {
      final distance = MathUtils.distanceKm(position, carpark.position);
      if (distance < nearestDistance) {
        nearest = carpark;
        nearestDistance = distance;
      }
    }
    return nearest;
  }

  Carpark? getSelectedOrNearestCarpark() {
    if (_selectedCarparkNo != null) {
      try {
        return _allCarparks.firstWhere(
          (carpark) => carpark.carParkNo == _selectedCarparkNo,
        );
      } on StateError { /* fall through */ }
    }

    if (_locationService.currentLocation != null) {
      return getNearestCarpark(_locationService.currentLocation!);
    }

    return null;
  }

  // ── Disposal ──────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _locationService.removeListener(_handleLocationUpdate);
    _availabilityRefreshTimer?.cancel();
    super.dispose();
  }
}
