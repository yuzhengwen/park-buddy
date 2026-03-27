import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:park_buddy/UI/carpark_marker.dart';
import 'package:park_buddy/UI/current_location_marker.dart';
import 'package:park_buddy/UI/search_location_marker.dart';
import 'package:park_buddy/models/carpark.dart';
import '../services/api_controller.dart';

import '../screens/start_parking_session_screen.dart';

class MapTab extends StatefulWidget {
  const MapTab({super.key});

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  static const _defaultCenter = LatLng(1.3521, 103.8198);
  static const _defaultRadiusKm = 1.0;
  static const _oneMapSearchUrl =
      'https://www.onemap.gov.sg/api/common/elastic/search';

  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _radiusController = TextEditingController(
    text: '1',
  );

  final ApiController _apiController = ApiController();

  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  Timer? _availabilityRefreshTimer;

  List<Carpark> _allCarparks = const [];
  List<Carpark> _visibleCarparks = const [];
  String _statusMessage = 'Loading HDB car parks...';
  String? _loadError;
  bool _isTracking = false;
  bool _isLoadingCarparks = true;
  bool _isListCollapsed = false;
  bool _isSearchingLocation = false;
  double _radiusKm = _defaultRadiusKm;
  String _searchText = '';
  String? _selectedCarparkNo;
  LatLng? _searchCenter;
  String? _searchCenterLabel;
  bool _isUsingTextFallback = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    unawaited(_initializePage());
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _availabilityRefreshTimer?.cancel();
    _searchController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  Future<void> _initializePage() async {
    await Future.wait([_loadCarparkData(), _startLiveLocation()]);
    if (!mounted) {
      return;
    }
    _refreshVisibleCarparks();
    _startAvailabilityRefresh();
  }

  Future<void> _loadCarparkData() async {
    setState(() {
      _isLoadingCarparks = true;
      _loadError = null;
      _statusMessage = 'Loading HDB car parks...';
    });

    try {
      final locations = await _apiController.fetchCarparkLocations();
      Map<String, CarparkAvailability> availabilityMap = const {};
      try {
        availabilityMap = await _apiController.fetchAvailabilityMap();
      } catch (_) {
        // Show static car park locations even if live availability is unavailable.
      }

      final merged = locations
          .map((carpark) {
            return carpark.copyWith(
              availability: availabilityMap[carpark.carParkNo],
            );
          })
          .whereType<Carpark>()
          .toList();

      if (!mounted) {
        return;
      }

      setState(() {
        _allCarparks = merged;
        _isLoadingCarparks = false;
        _statusMessage = 'Loaded ${merged.length} HDB car parks.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingCarparks = false;
        _loadError = 'Unable to load HDB car parks: $error';
        _statusMessage = _loadError!;
      });
    }
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
      if (!mounted) {
        return;
      }

      setState(() {
        _allCarparks = _allCarparks.map((carpark) {
          return carpark.copyWith(
            availability: availabilityMap[carpark.carParkNo],
          );
        }).toList();
      });
      _refreshVisibleCarparks();
    } catch (_) {
      // Keep the last successful availability values if refresh fails.
    }
  }

  Future<void> _startLiveLocation() async {
    setState(() {
      _statusMessage = 'Preparing live location...';
    });

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isTracking = false;
        _statusMessage = 'Location services are turned off. Please enable GPS.';
      });
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isTracking = false;
        _statusMessage = 'Location permission denied.';
      });
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isTracking = false;
        _statusMessage =
            'Location permission is permanently denied. Open settings to allow it.';
      });
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _currentPosition = position;
      _isTracking = true;
      _statusMessage = 'Live location is active.';
    });
    _moveMapToPosition(position.latitude, position.longitude);
    _refreshVisibleCarparks();

    await _positionStream?.cancel();
    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
            distanceFilter: 5,
          ),
        ).listen(
          (position) {
            if (!mounted) {
              return;
            }
            setState(() {
              _currentPosition = position;
              _isTracking = true;
              _statusMessage = 'Location updated just now.';
            });
            _moveMapToPosition(position.latitude, position.longitude);
            _refreshVisibleCarparks();
          },
          onError: (Object error) {
            if (!mounted) {
              return;
            }
            setState(() {
              _isTracking = false;
              _statusMessage = 'Unable to track location: $error';
            });
          },
        );
  }

  void _handleSearchChanged() {
    if (_searchController.text.trim().isEmpty) {
      setState(() {
        _searchText = '';
        _searchCenter = null;
        _searchCenterLabel = null;
        _isUsingTextFallback = false;
      });
      _refreshVisibleCarparks();
      return;
    }

    setState(() {
      _searchText = _searchController.text.trim().toLowerCase();
    });
  }

  Future<void> _applySearchAndRadius() async {
    final radius = double.tryParse(_radiusController.text.trim());
    if (radius == null || radius <= 0) {
      setState(() {
        _radiusKm = _defaultRadiusKm;
        _radiusController.text = _defaultRadiusKm.toStringAsFixed(0);
      });
    } else {
      setState(() {
        _radiusKm = radius;
      });
    }

    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchCenter = null;
        _searchCenterLabel = null;
        _isUsingTextFallback = false;
      });
      _refreshVisibleCarparks();
      return;
    }

    setState(() {
      _isSearchingLocation = true;
      _statusMessage = 'Searching for "$query"...';
    });

    try {
      final searchResult = await _searchLocation(query);
      if (!mounted) {
        return;
      }

      if (searchResult != null) {
        setState(() {
          _searchCenter = searchResult.position;
          _searchCenterLabel = searchResult.label;
          _isUsingTextFallback = false;
          _statusMessage = 'Showing car parks near ${searchResult.label}.';
        });
        _mapController.move(searchResult.position, 15);
      } else {
        setState(() {
          _searchCenter = null;
          _searchCenterLabel = null;
          _isUsingTextFallback = true;
          _statusMessage =
              'No location match found. Showing car parks matching the text instead.';
        });
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _searchCenter = null;
        _searchCenterLabel = null;
        _isUsingTextFallback = true;
        _statusMessage =
            'Location search is unavailable right now. Showing text matches instead.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSearchingLocation = false;
        });
      }
    }

    _refreshVisibleCarparks();
  }

  void _refreshVisibleCarparks() {
    final userOrigin = _currentPosition == null
        ? null
        : LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    final origin = _searchCenter ?? userOrigin;

    debugPrint(
      "Total Carparks: ${_allCarparks.length}",
    ); // Is the JSON actually loaded?
    debugPrint("Origin: $origin"); // Is your GPS or Search center valid?

    final filtered = _allCarparks.where((carpark) {
      if (carpark == null) return false;
      if (_isUsingTextFallback && _searchText.isNotEmpty) {
        final matchesSearch =
            carpark.address.toLowerCase().contains(_searchText) ||
            carpark.carParkNo.toLowerCase().contains(_searchText);
        if (!matchesSearch) {
          return false;
        }
      }

      if (origin == null) {
        return true;
      }

      final distanceKm = _distanceKm(origin, carpark.position);
      return distanceKm <= _radiusKm;
    }).toList();

    print("Filtered Count: ${filtered.length}");

    if (origin != null) {
      filtered.sort((a, b) {
        final aDistance = _distanceKm(origin, a.position);
        final bDistance = _distanceKm(origin, b.position);
        return aDistance.compareTo(bDistance);
      });
    } else {
      filtered.sort((a, b) => a.address.compareTo(b.address));
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _visibleCarparks = filtered;
      if (_selectedCarparkNo != null &&
          !_visibleCarparks.any(
            (carpark) => carpark.carParkNo == _selectedCarparkNo,
          )) {
        _selectedCarparkNo = null;
      }
    });
  }

  Future<void> _openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  void _moveMapToPosition(double latitude, double longitude) {
    _mapController.move(LatLng(latitude, longitude), 16);
  }

  double _distanceKm(LatLng from, LatLng to) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(to.latitude - from.latitude);
    final dLng = _toRadians(to.longitude - from.longitude);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(from.latitude)) *
            math.cos(_toRadians(to.latitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _toRadians(double degrees) => degrees * math.pi / 180;

  void _focusCarpark(Carpark carpark) {
    setState(() {
      _selectedCarparkNo = carpark.carParkNo;
    });
    _mapController.move(carpark.position, 17);
  }

  Carpark getNearestCarpark(LatLng position) {
    Carpark? nearest;
    double nearestDistance = double.infinity;

    for (final carpark in _allCarparks) {
      final distance = _distanceKm(position, carpark.position);
      if (distance < nearestDistance) {
        nearest = carpark;
        nearestDistance = distance;
      }
    }

    return nearest!;
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
    if (results.isEmpty) {
      return null;
    }

    final first = results.first as Map<String, dynamic>;
    final lat = double.tryParse(first['LATITUDE'] as String? ?? '');
    final lng = double.tryParse(first['LONGITUDE'] as String? ?? '');
    if (lat == null || lng == null) {
      return null;
    }

    return LocationSearchResult(
      position: LatLng(lat, lng),
      label: query.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final position = _currentPosition;
    final currentLatLng = position == null
        ? _defaultCenter
        : LatLng(position.latitude, position.longitude);
    final listOrigin = _searchCenter ?? currentLatLng;
    final hasActiveSearch = _searchController.text.trim().isNotEmpty;
    final markerCarparks = hasActiveSearch ? _visibleCarparks : _allCarparks;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: currentLatLng,
            initialZoom: 15,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.park_buddy',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: currentLatLng,
                  width: 56,
                  height: 56,
                  child: const CurrentLocationMarker(),
                ),
                ...markerCarparks.map(
                  (carpark) => Marker(
                    point: carpark.position,
                    width: 90,
                    height: 60,
                    child: GestureDetector(
                      onTap: () => _focusCarpark(carpark),
                      child: CarparkMarker(
                        blockLabel: carpark.blockLabel,
                        lotsAvailable: carpark.availability?.lotsAvailable,
                        isSelected: carpark.carParkNo == _selectedCarparkNo,
                      ),
                    ),
                  ),
                ),
                if (_searchCenter != null)
                  Marker(
                    point: _searchCenter!,
                    width: 140,
                    height: 52,
                    child: SearchLocationMarker(
                      label:
                          _searchCenterLabel ?? _searchController.text.trim(),
                    ),
                  ),
              ],
            ),
          ],
        ),
        Positioned(
          left: 16,
          right: 16,
          top: 16,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Card(
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                textInputAction: TextInputAction.search,
                                decoration: InputDecoration(
                                  hintText:
                                      'Place, address, postal code, or block no.',
                                  prefixIcon: const Icon(Icons.search),
                                  suffixIcon: _searchText.isEmpty
                                      ? null
                                      : IconButton(
                                          onPressed: () {
                                            _searchController.clear();
                                          },
                                          icon: const Icon(Icons.clear),
                                        ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onSubmitted: (_) => _applySearchAndRadius(),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 110,
                              child: TextField(
                                controller: _radiusController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: InputDecoration(
                                  labelText: 'Km',
                                  hintText: '1',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onSubmitted: (_) => _applySearchAndRadius(),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              height: 56,
                              child: FilledButton(
                                onPressed: _isSearchingLocation
                                    ? null
                                    : _applySearchAndRadius,
                                child: Text(
                                  _isSearchingLocation ? '...' : 'Apply',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(
                              _isTracking
                                  ? Icons.gps_fixed
                                  : Icons.location_off,
                              color: _isTracking ? Colors.green : Colors.orange,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _searchCenterLabel == null
                                    ? _statusMessage
                                    : 'Search area: $_searchCenterLabel',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            IconButton(
                              onPressed: _openAppSettings,
                              icon: const Icon(Icons.settings),
                              tooltip: 'Open app settings',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 220,
          child: FloatingActionButton.small(
            heroTag: 'recenter-map',
            onPressed: position == null
                ? null
                : () =>
                      _moveMapToPosition(position.latitude, position.longitude),
            child: const Icon(Icons.my_location),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 160,
          child: FloatingActionButton.extended(
            heroTag: 'parkNow',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StartParkingSessionScreen(),
              ),
            ),
            label: const Text('Park Now'),
            icon: const Icon(Icons.local_parking),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              height: _isListCollapsed ? 82 : 280,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 16,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isListCollapsed = !_isListCollapsed;
                      });
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Nearest HDB Car Parks (${_visibleCarparks.length})',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _isListCollapsed = !_isListCollapsed;
                                  });
                                },
                                icon: Icon(
                                  _isListCollapsed
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                ),
                                label: Text(
                                  _isListCollapsed ? 'Expand' : 'Collapse',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_isListCollapsed)
                    Expanded(child: _buildCarparkList(context, listOrigin)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCarparkList(BuildContext context, LatLng listOrigin) {
    if (_isLoadingCarparks) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_loadError!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => unawaited(_loadCarparkData()),
                child: const Text('Retry Data Load'),
              ),
            ],
          ),
        ),
      );
    }

    if (_visibleCarparks.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No HDB car parks match the current search and radius.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: _visibleCarparks.length,
      separatorBuilder: (_, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final carpark = _visibleCarparks[index];
        final distanceKm = _distanceKm(listOrigin, carpark.position);
        final isSelected = carpark.carParkNo == _selectedCarparkNo;

        return Material(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _focusCarpark(carpark),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    child: Text('${index + 1}'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          carpark.address,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        Text('Car park: ${carpark.carParkNo}'),
                        const SizedBox(height: 4),
                        Text(
                          '${distanceKm.toStringAsFixed(2)} km away'
                          '${carpark.availability == null ? '' : ' • ${carpark.availability!.lotsAvailable} lots free'}',
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${carpark.carParkType} • ${carpark.shortTermParking}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class LocationSearchResult {
  const LocationSearchResult({required this.position, required this.label});

  final LatLng position;
  final String label;
}
