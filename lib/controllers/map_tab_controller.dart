import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:park_buddy/models/carpark.dart';
import 'package:park_buddy/utils/math_utils.dart';
import 'package:park_buddy/services/api_controller.dart';
import 'package:park_buddy/services/location_service.dart';
import 'package:park_buddy/services/location_search_service.dart';

class MapTabController extends ChangeNotifier {
  static const defaultRadiusKm = 1.0;

  final _apiController = ApiController();
  final _locationService = LocationService();
  final _searchService = SearchService();

  Timer? _availabilityRefreshTimer;
  List<Carpark> _allCarparks = const [];
  Carpark? _nearestCarpark;
  String _statusMessage = '';
  bool _isLoadingCarparks = false;
  double _radiusKm = defaultRadiusKm;
  Carpark? _selectedCarpark;
  LatLng? _searchCenter;

  LocationService get location => _locationService;
  SearchService get search => _searchService;
  Carpark? get nearestCarpark => _nearestCarpark;
  String get statusMessage => _statusMessage;
  bool get isLoadingCarparks => _isLoadingCarparks;

  double get radiusKm => _radiusKm;

  set radiusKm(double radiusKm) {
    _radiusKm = radiusKm;
    notifyListeners();
  }

  Carpark? get selectedCarpark => _selectedCarpark;

  set selectedCarpark(Carpark? carpark) {
    _selectedCarpark = carpark;
    notifyListeners();
  }

  LatLng? get visibleCarparksCentre => _searchCenter;

  set visibleCarparksCentre(LatLng? centre) {
    _searchCenter = centre;
    notifyListeners();
  }

  List<Carpark> get visibleCarparks {
    final origin = _searchCenter ?? _locationService.currentLocation;
    if (origin == null) return const [];

    return _allCarparks
        .where((carpark) =>
            MathUtils.distanceKm(origin, carpark.position) <= radiusKm,
        )
        .toList();
  }

  Future<void> initialize() async {
    _locationService.addListener(_onLocationServiceChanged);
    await Future.wait([_loadCarparkData(), _locationService.startLiveLocation()]);
    if (_locationService.currentLocation != null) _updateNearestCarpark();
    _startAvailabilityRefresh();
    _searchService.getAllCarparks = () => _allCarparks;
    notifyListeners();
  }

  @override
  void dispose() {
    _locationService.removeListener(_onLocationServiceChanged);
    _locationService.dispose();
    _searchService.dispose();
    _availabilityRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCarparkData() async {
    _isLoadingCarparks = true;
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

      _allCarparks = locations
          .map((carpark) => carpark.copyWith(
            availability: availabilityMap[carpark.carParkNo],
          ))
          .whereType<Carpark>()
          .toList();

      _statusMessage = 'Loaded ${_allCarparks.length} HDB car parks.';

    } catch (error) {
      _statusMessage = 'Unable to load HDB car parks: $error';

    } finally {
      _isLoadingCarparks = false;
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
    _statusMessage = 'Fetching carpark availability...';
    notifyListeners();

    try {
      final availabilityMap = await _apiController.fetchAvailabilityMap();
      _allCarparks = _allCarparks
          .map((carpark) => carpark.copyWith(
            availability: availabilityMap[carpark.carParkNo],
          ))
          .toList();
      _statusMessage = 'Fetched ${_allCarparks.length} carpark availability data.';

    } catch (_) {
      // Keep the last successful availability values if refresh fails.
      _statusMessage = 'Error fetching carpark availability.';

    } finally {
      notifyListeners();
    }
  }

  void _onLocationServiceChanged() {
    _updateNearestCarpark();
    notifyListeners();
  }

  void _updateNearestCarpark() {
    if (location.currentLocation == null) return;
    Carpark? nearest;
    double nearestDistance = .infinity;
    for (final carpark in _allCarparks) {
      final distance = MathUtils.distanceKm(
        location.currentLocation!,
        carpark.position,
      );
      if (distance < nearestDistance) {
        nearest = carpark;
        nearestDistance = distance;
      }
    }
    _nearestCarpark = nearest;
  }
}
