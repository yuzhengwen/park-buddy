import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../screens/start_parking_session_screen.dart';

class MapTab extends StatefulWidget {
  const MapTab({super.key});

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  static const _defaultCenter = LatLng(1.3521, 103.8198);
  static const _defaultRadiusKm = 1.0;
  static const _hdbCarparksAsset = 'assets/hdb_carparks.json';
  static const _availabilityUrl =
      'https://api.data.gov.sg/v1/transport/carpark-availability';
  static const _oneMapSearchUrl =
      'https://www.onemap.gov.sg/api/common/elastic/search';

  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _radiusController = TextEditingController(
    text: '1',
  );

  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  Timer? _availabilityRefreshTimer;

  List<HdbCarpark> _allCarparks = const [];
  List<HdbCarpark> _visibleCarparks = const [];
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
    await Future.wait([
      _loadCarparkData(),
      _startLiveLocation(),
    ]);
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
      final locations = await _fetchCarparkLocations();
      Map<String, CarparkAvailability> availabilityMap = const {};
      try {
        availabilityMap = await _fetchAvailabilityMap();
      } catch (_) {
        // Show static car park locations even if live availability is unavailable.
      }

      final merged = locations.map((carpark) {
        return carpark.copyWith(availability: availabilityMap[carpark.carParkNo]);
      }).toList();

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

  Future<List<HdbCarpark>> _fetchCarparkLocations() async {
    final jsonString = await rootBundle.loadString(_hdbCarparksAsset);
    final records = jsonDecode(jsonString) as List<dynamic>;
    return records
        .map((record) => HdbCarpark.fromJson(record as Map<String, dynamic>))
        .where((carpark) => carpark != null)
        .cast<HdbCarpark>()
        .toList();
  }

  Future<Map<String, CarparkAvailability>> _fetchAvailabilityMap() async {
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

  void _startAvailabilityRefresh() {
    _availabilityRefreshTimer?.cancel();
    _availabilityRefreshTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => unawaited(_refreshAvailability()),
    );
  }

  Future<void> _refreshAvailability() async {
    try {
      final availabilityMap = await _fetchAvailabilityMap();
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
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
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
    _positionStream = Geolocator.getPositionStream(
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

    final filtered = _allCarparks.where((carpark) {
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
          !_visibleCarparks.any((carpark) => carpark.carParkNo == _selectedCarparkNo)) {
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

  void _focusCarpark(HdbCarpark carpark) {
    setState(() {
      _selectedCarparkNo = carpark.carParkNo;
    });
    _mapController.move(carpark.position, 17);
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
                  child: const _CurrentLocationMarker(),
                ),
                ...markerCarparks.map(
                  (carpark) => Marker(
                    point: carpark.position,
                    width: 90,
                    height: 60,
                    child: GestureDetector(
                      onTap: () => _focusCarpark(carpark),
                      child: _CarparkMarker(
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
                    child: _SearchLocationMarker(
                      label: _searchCenterLabel ?? _searchController.text.trim(),
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
                              _isTracking ? Icons.gps_fixed : Icons.location_off,
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
                : () => _moveMapToPosition(position.latitude, position.longitude),
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
              MaterialPageRoute(builder: (context) => StartParkingSessionScreen())
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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                                  style: Theme.of(context).textTheme.titleMedium,
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
                    Expanded(
                      child: _buildCarparkList(context, listOrigin),
                    ),
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
              Text(
                _loadError!,
                textAlign: TextAlign.center,
              ),
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

class _CurrentLocationMarker extends StatelessWidget {
  const _CurrentLocationMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blueAccent.withValues(alpha: 0.18),
      ),
      padding: const EdgeInsets.all(8),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.blueAccent,
        ),
        child: const Icon(
          Icons.person_pin_circle,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}

class _SearchLocationMarker extends StatelessWidget {
  const _SearchLocationMarker({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.deepOrange,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_on,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CarparkMarker extends StatelessWidget {
  const _CarparkMarker({
    required this.blockLabel,
    required this.lotsAvailable,
    required this.isSelected,
  });

  final String blockLabel;
  final int? lotsAvailable;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final hasAvailability = lotsAvailable != null;
    final hasLots = (lotsAvailable ?? 0) > 0;
    final markerColor = isSelected
        ? Colors.indigo
        : !hasAvailability
            ? Colors.blueGrey
            : hasLots
            ? Colors.green
            : Colors.redAccent;

    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: markerColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              blockLabel,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              hasAvailability ? '${lotsAvailable!}' : 'Unknown',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class LocationSearchResult {
  const LocationSearchResult({
    required this.position,
    required this.label,
  });

  final LatLng position;
  final String label;
}

class HdbCarpark {
  const HdbCarpark({
    required this.carParkNo,
    required this.address,
    required this.blockLabel,
    required this.position,
    required this.carParkType,
    required this.shortTermParking,
    this.availability,
  });

  final String carParkNo;
  final String address;
  final String blockLabel;
  final LatLng position;
  final String carParkType;
  final String shortTermParking;
  final CarparkAvailability? availability;

  HdbCarpark copyWith({
    CarparkAvailability? availability,
  }) {
    return HdbCarpark(
      carParkNo: carParkNo,
      address: address,
      blockLabel: blockLabel,
      position: position,
      carParkType: carParkType,
      shortTermParking: shortTermParking,
      availability: availability,
    );
  }

  static HdbCarpark? fromJson(Map<String, dynamic> json) {
    final carParkNo = (json['car_park_no'] as String?)?.trim();
    final address = (json['address'] as String?)?.trim();
    final xCoordText = (json['x_coord'] as String?)?.trim();
    final yCoordText = (json['y_coord'] as String?)?.trim();

    final xCoord = double.tryParse(xCoordText ?? '');
    final yCoord = double.tryParse(yCoordText ?? '');

    if (carParkNo == null ||
        carParkNo.isEmpty ||
        address == null ||
        address.isEmpty ||
        xCoord == null ||
        yCoord == null) {
      return null;
    }

    final latLng = SvY21Converter.toLatLng(xCoord, yCoord);
    return HdbCarpark(
      carParkNo: carParkNo,
      address: address,
      blockLabel: _extractBlockLabel(address, carParkNo),
      position: latLng,
      carParkType: (json['car_park_type'] as String?)?.trim() ?? 'Unknown',
      shortTermParking:
          (json['short_term_parking'] as String?)?.trim() ?? 'Unknown',
    );
  }

  static String _extractBlockLabel(String address, String carParkNo) {
    final upperAddress = address.toUpperCase();
    final blockMatch = RegExp(r'\b(?:BLK|BLOCK)\s+([A-Z0-9]+)').firstMatch(
      upperAddress,
    );
    if (blockMatch != null) {
      return blockMatch.group(1)!;
    }

    final leadingNumberMatch = RegExp(r'^([A-Z0-9]+)').firstMatch(upperAddress);
    if (leadingNumberMatch != null) {
      return leadingNumberMatch.group(1)!;
    }

    return carParkNo;
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
      lotsAvailable: int.tryParse(carLotInfo['lots_available'] as String? ?? '') ?? 0,
      totalLots: int.tryParse(carLotInfo['total_lots'] as String? ?? '') ?? 0,
    );
  }
}

class SvY21Converter {
  static const double _a = 6378137;
  static const double _f = 1 / 298.257223563;
  static const double _originLat = 1.366666;
  static const double _originLon = 103.833333;
  static const double _originNorthing = 38744.572;
  static const double _originEasting = 28001.642;
  static const double _scaleFactor = 1.0;

  static LatLng toLatLng(double easting, double northing) {
    final b = _a * (1 - _f);
    final e2 = (2 * _f) - (_f * _f);
    final n = (_a - b) / (_a + b);
    final n2 = n * n;
    final n3 = n2 * n;
    final n4 = n2 * n2;

    final lat0 = _degToRad(_originLat);
    final lon0 = _degToRad(_originLon);

    final sigma = (northing - _originNorthing) / _scaleFactor;
    final meridionalArc = _calcMeridionalArc(lat0, n, n2, n3, n4, b);
    final footprintLat =
        (sigma + meridionalArc) / (_a * _scaleFactor) + lat0;

    final sinFootprint = math.sin(footprintLat);
    final cosFootprint = math.cos(footprintLat);
    final tanFootprint = math.tan(footprintLat);

    final rho = _calcRho(e2, sinFootprint);
    final v = _calcV(_a, e2, sinFootprint);
    final psi = v / rho;
    final t = tanFootprint;
    final w = (easting - _originEasting) / (_scaleFactor * v);

    final w2 = w * w;
    final w4 = w2 * w2;
    final w6 = w4 * w2;
    final w8 = w4 * w4;

    final lat = footprintLat -
        ((t / (2 * rho * v)) * w2) +
        ((t / (24 * rho * math.pow(v, 3))) *
                ((-4 * psi * psi) + (9 * psi * (1 - (t * t))) + (12 * t * t)) *
                w4) -
        ((t / (720 * rho * math.pow(v, 5))) *
                ((8 * math.pow(psi, 4) * (11 - (24 * t * t))) -
                    (12 * math.pow(psi, 3) * (21 - (71 * t * t))) +
                    (15 * psi * psi * (15 - (98 * t * t) + (15 * math.pow(t, 4)))) +
                    (180 * psi * (5 * t * t - 3 * math.pow(t, 4))) +
                    (360 * math.pow(t, 4))) *
                w6) +
        ((t / (40320 * rho * math.pow(v, 7))) *
                (1385 +
                    (3633 * t * t) +
                    (4095 * math.pow(t, 4)) +
                    (1575 * math.pow(t, 6))) *
                w8);

    final lon = lon0 +
        (w / cosFootprint) -
        ((w * w2 / (6 * cosFootprint)) * (psi + (2 * t * t))) +
        ((w * w4 / (120 * cosFootprint)) *
            ((-4 * math.pow(psi, 3) * (1 - (6 * t * t))) +
                (psi * psi * (9 - (68 * t * t))) +
                (72 * psi * t * t) +
                (24 * math.pow(t, 4)))) -
        ((w * w6 / (5040 * cosFootprint)) *
            (61 +
                (662 * t * t) +
                (1320 * math.pow(t, 4)) +
                (720 * math.pow(t, 6))));

    return LatLng(_radToDeg(lat), _radToDeg(lon));
  }

  static double _calcMeridionalArc(
    double lat,
    double n,
    double n2,
    double n3,
    double n4,
    double b,
  ) {
    return b *
        _scaleFactor *
        (((1 + n + ((5 / 4) * n2) + ((5 / 4) * n3) + ((81 / 64) * n4)) *
                (lat - _degToRad(_originLat))) -
            (((3 * n) + (3 * n2) + ((21 / 8) * n3) + ((55 / 8) * n4)) *
                math.sin(lat - _degToRad(_originLat)) *
                math.cos(lat + _degToRad(_originLat))) +
            ((((15 / 8) * n2) + ((15 / 8) * n3) + ((35 / 24) * n4)) *
                math.sin(2 * (lat - _degToRad(_originLat))) *
                math.cos(2 * (lat + _degToRad(_originLat)))) -
            ((((35 / 24) * n3) + ((105 / 64) * n4)) *
                math.sin(3 * (lat - _degToRad(_originLat))) *
                math.cos(3 * (lat + _degToRad(_originLat)))) +
            (((315 / 512) * n4) *
                math.sin(4 * (lat - _degToRad(_originLat))) *
                math.cos(4 * (lat + _degToRad(_originLat)))));
  }

  static double _calcRho(double e2, double sinLat) {
    return (_a * (1 - e2)) / math.pow(1 - (e2 * sinLat * sinLat), 1.5);
  }

  static double _calcV(double a, double e2, double sinLat) {
    return a / math.sqrt(1 - (e2 * sinLat * sinLat));
  }

  static double _degToRad(double degrees) => degrees * math.pi / 180;

  static double _radToDeg(double radians) => radians * 180 / math.pi;
}
