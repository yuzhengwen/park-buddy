import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/car_park.dart';
import '../services/api_controller.dart';
import '../services/location_service.dart';
import '../services/location_search_service.dart';
import 'start_parking_session_screen.dart';

class CarParkFinderPage extends StatefulWidget {
  const CarParkFinderPage({
    super.key,
    required this.apiController,
  });

  final ApiController apiController;

  @override
  State<CarParkFinderPage> createState() => _CarParkFinderPageState();
}

class _CarParkFinderPageState extends State<CarParkFinderPage> {
  static const LatLng _singaporeCenter = LatLng(1.3521, 103.8198);
  static const double _defaultZoom = 14;
  static const double _defaultRadiusMeters = 1000;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _radiusController = TextEditingController(text: '1');
  final MapController _mapController = MapController();
  final LocationService _locationService = const LocationService();
  final LocationSearchService _locationSearchService = LocationSearchService();
  final Distance _distance = const Distance();

  List<CarPark> _allCarParks = <CarPark>[];
  List<CarPark> _visibleCarParks = <CarPark>[];
  LatLng _mapCenter = _singaporeCenter;
  double _mapZoom = _defaultZoom;
  double _selectedRadiusMeters = _defaultRadiusMeters;
  LocationSearchResult? _searchedLocation;
  Position? _currentPosition;
  bool _isLoading = true;
  bool _isListCollapsed = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final List<CarPark> carParks = await widget.apiController.fetchAllCarParks();
      final Position? position = await _locationService.getCurrentPosition();

      setState(() {
        _allCarParks = carParks.where(_hasMapCoordinates).toList(growable: false);
        _currentPosition = position;
        _mapCenter = position == null
            ? _singaporeCenter
            : LatLng(position.latitude, position.longitude);
        _selectedRadiusMeters = _parseRadiusMeters();
        _isLoading = false;
      });

      _applyFilters();
      _moveMap();
    } catch (error) {
      setState(() {
        _errorMessage = 'Failed to load car parks: $error';
        _isLoading = false;
      });
    }
  }

  bool _hasMapCoordinates(CarPark carPark) {
    return carPark.latitude != null && carPark.longitude != null;
  }

  Future<void> _runSearch() async {
    final String query = _searchController.text.trim();
    setState(() {
      _selectedRadiusMeters = _parseRadiusMeters();
    });

    if (query.isEmpty) {
      setState(() {
        _searchedLocation = null;
      });
      _applyFilters();
      return;
    }

    final LocationSearchResult? result = await _locationSearchService.search(query);
    if (!mounted) {
      return;
    }

    setState(() {
      _searchedLocation = result;
    });

    _applyFilters();
  }

  void _applyFilters() {
    final String query = _searchController.text.trim().toLowerCase();
    final bool hasSearchQuery = query.isNotEmpty;
    Iterable<CarPark> filtered = _allCarParks;

    if (hasSearchQuery && _searchedLocation == null) {
      filtered = filtered.where((CarPark carPark) {
        final String searchable = <String>[
          carPark.name,
          carPark.address,
          carPark.postalCode ?? '',
          carPark.id,
        ].join(' ').toLowerCase();

        return searchable.contains(query);
      });
    }

    if (_searchedLocation != null) {
      filtered = filtered.where((CarPark carPark) {
        return _distance.as(
              LengthUnit.Meter,
              _searchedLocation!.point,
              LatLng(carPark.latitude!, carPark.longitude!),
            ) <=
            _selectedRadiusMeters;
      });
    } else if (!hasSearchQuery && _currentPosition != null) {
      filtered = filtered.where((CarPark carPark) {
        return _distanceToCarPark(carPark) <= _selectedRadiusMeters;
      });
    }

    final List<CarPark> results = filtered.toList(growable: false)
      ..sort(_compareByReference);

    if (_searchedLocation != null && results.isEmpty) {
      final List<CarPark> nearest = _allCarParks.toList(growable: false)
        ..sort(_compareByReference);
      setState(() {
        _visibleCarParks = nearest;
        _mapCenter = _searchedLocation!.point;
        _mapZoom = 14;
      });
      _moveMap();
      return;
    }

    setState(() {
      _visibleCarParks = results;
      if (_searchedLocation != null) {
        _mapCenter = _searchedLocation!.point;
        _mapZoom = 14;
      } else if (hasSearchQuery && _visibleCarParks.isNotEmpty) {
        _mapCenter = LatLng(_visibleCarParks.first.latitude!, _visibleCarParks.first.longitude!);
        _mapZoom = 15;
      } else if (_currentPosition != null) {
        _mapCenter = LatLng(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );
        _mapZoom = _defaultZoom;
      }
    });

    _moveMap();
  }

  int _compareByDistance(CarPark a, CarPark b) {
    if (_currentPosition == null) {
      return a.name.compareTo(b.name);
    }

    final LatLng current = LatLng(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );
    final double distanceA = _distance.as(
      LengthUnit.Meter,
      current,
      LatLng(a.latitude!, a.longitude!),
    );
    final double distanceB = _distance.as(
      LengthUnit.Meter,
      current,
      LatLng(b.latitude!, b.longitude!),
    );

    return distanceA.compareTo(distanceB);
  }

  int _compareByReference(CarPark a, CarPark b) {
    if (_searchedLocation != null) {
      final double distanceA = _distance.as(
        LengthUnit.Meter,
        _searchedLocation!.point,
        LatLng(a.latitude!, a.longitude!),
      );
      final double distanceB = _distance.as(
        LengthUnit.Meter,
        _searchedLocation!.point,
        LatLng(b.latitude!, b.longitude!),
      );

      return distanceA.compareTo(distanceB);
    }

    return _compareByDistance(a, b);
  }

  void _moveMap() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _mapController.move(_mapCenter, _mapZoom);
    });
  }

  double _distanceToCarPark(CarPark carPark) {
    if (_currentPosition == null) {
      return double.infinity;
    }

    return _distance.as(
      LengthUnit.Meter,
      LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      LatLng(carPark.latitude!, carPark.longitude!),
    );
  }

  String _distanceLabel(CarPark carPark) {
    if (_currentPosition == null) {
      return 'Distance unavailable';
    }

    final double meters = _distanceToCarPark(carPark);

    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km away';
    }

    return '${meters.toStringAsFixed(0)} m away';
  }

  double _parseRadiusMeters() {
    final double? radiusKm = double.tryParse(_radiusController.text.trim());
    if (radiusKm == null || radiusKm <= 0) {
      return _defaultRadiusMeters;
    }

    return radiusKm * 1000;
  }

  List<Marker> _buildMarkers() {
    final List<Marker> markers = _visibleCarParks
        .map(
          (CarPark carPark) => Marker(
            point: LatLng(carPark.latitude!, carPark.longitude!),
            width: 44,
            height: 44,
            child: const Icon(
              Icons.location_on,
              color: Colors.red,
              size: 36,
            ),
          ),
        )
        .toList(growable: true);

    if (_currentPosition != null) {
      markers.add(
        Marker(
          point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          width: 28,
          height: 28,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
          ),
        ),
      );
    }

    if (_searchedLocation != null) {
      markers.add(
        Marker(
          point: _searchedLocation!.point,
          width: 36,
          height: 36,
          child: const Icon(
            Icons.search,
            color: Colors.black87,
            size: 28,
          ),
        ),
      );
    }

    return markers;
  }

  void _zoomIn() {
    setState(() {
      _mapZoom = (_mapZoom + 1).clamp(3, 18).toDouble();
    });
    _moveMap();
  }

  void _zoomOut() {
    setState(() {
      _mapZoom = (_mapZoom - 1).clamp(3, 18).toDouble();
    });
    _moveMap();
  }

  Future<void> _recenterOnUser() async {
    final Position? position = await _locationService.getCurrentPosition();
    if (!mounted) {
      return;
    }

    setState(() {
      _currentPosition = position;
      _searchedLocation = null;
      if (position != null) {
        _mapCenter = LatLng(position.latitude, position.longitude);
        _mapZoom = _defaultZoom;
      }
    });

    _applyFilters();
  }

  String _radiusLabel(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(0)} km';
    }

    return '${meters.toStringAsFixed(0)} m';
  }

  @override
  Widget build(BuildContext context) {
    final bool hasSearchQuery = _searchController.text.trim().isNotEmpty;

    return Scaffold(
      body: Stack(
        children: <Widget>[
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_errorMessage != null)
            Center(child: Text(_errorMessage!))
          else
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _mapCenter,
                initialZoom: _defaultZoom,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: <Widget>[
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.sc2006_parking',
                ),
                MarkerLayer(markers: _buildMarkers()),
              ],
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        TextField(
                          controller: _searchController,
                          textInputAction: TextInputAction.search,
                          onChanged: (_) => _runSearch(),
                          onSubmitted: (_) => _runSearch(),
                          decoration: InputDecoration(
                            hintText: 'Search by car park, address, or postal code',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchedLocation = null;
                                });
                                _applyFilters();
                              },
                              icon: const Icon(Icons.close),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF4F6F8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: TextField(
                                controller: _radiusController,
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                onSubmitted: (_) => _runSearch(),
                                decoration: InputDecoration(
                                  labelText: 'Distance (km)',
                                  hintText: '1',
                                  filled: true,
                                  fillColor: const Color(0xFFF4F6F8),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ActionChip(
                              avatar: const Icon(Icons.my_location, size: 18),
                              label: const Text('Use my location'),
                              onPressed: _recenterOnUser,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _currentPosition == null
                              ? 'Location permission not granted. Showing a Singapore-wide fallback view.'
                              : _searchedLocation != null
                                  ? 'Showing all car parks within ${_radiusLabel(_selectedRadiusMeters)} of ${_searchedLocation!.label}.'
                                  : hasSearchQuery
                                      ? 'Search is showing matching car parks across the loaded dataset.'
                                  : 'Showing car parks within ${_radiusLabel(_selectedRadiusMeters)} of your live location.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        FloatingActionButton.small(
                          heroTag: 'zoomIn',
                          onPressed: _zoomIn,
                          child: const Icon(Icons.add),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton.small(
                          heroTag: 'zoomOut',
                          onPressed: _zoomOut,
                          child: const Icon(Icons.remove),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton.small(
                          heroTag: 'locateMe',
                          onPressed: _recenterOnUser,
                          child: const Icon(Icons.gps_fixed),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton.extended(
                          heroTag: 'parkNow',
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (context) => StartParkingSessionScreen(),
                            ));
                          },
                          label: const Text('Park Now'),
                          icon: const Icon(Icons.local_parking),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        constraints: const BoxConstraints(maxHeight: 300),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.96),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        height: _isListCollapsed ? 96 : null,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      _currentPosition == null
                                          ? 'Nearby HDB car parks'
                                          : 'Nearest HDB car parks',
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                  ),
                                  IconButton(
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
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F1ED),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      '${_visibleCarParks.length} shown',
                                      style: Theme.of(context).textTheme.labelMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!_isListCollapsed) ...<Widget>[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                                child: Text(
                                  _currentPosition == null
                                      ? 'Grant location access to rank results around the user.'
                                      : _searchedLocation != null
                                          ? 'Results are centered on the searched location.'
                                          : hasSearchQuery
                                              ? 'Search results are not limited by the nearby radius.'
                                              : 'Results are filtered to ${_radiusLabel(_selectedRadiusMeters)} from your current position.',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                              Expanded(
                                child: _visibleCarParks.isEmpty
                                    ? const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(24),
                                          child: Text(
                                            'No car parks found in this radius. Try a larger radius or search another area.',
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      )
                                    : ListView.builder(
                                        itemCount: _visibleCarParks.length,
                                        itemBuilder: (BuildContext context, int index) {
                                          final CarPark carPark = _visibleCarParks[index];
                                          final double estimatedFee =
                                              widget.apiController.calculateEstimatedParkingFee(
                                            carPark: carPark,
                                            durationMinutes: 60,
                                          );

                                          return ListTile(
                                            onTap: () {
                                              setState(() {
                                                _mapCenter = LatLng(
                                                  carPark.latitude!,
                                                  carPark.longitude!,
                                                );
                                                _mapZoom = 16;
                                              });
                                              _moveMap();
                                            },
                                            title: Text(carPark.name),
                                            subtitle: Text(
                                              '${carPark.address}\n${_distanceLabel(carPark)} | Est. 1h fee: \$${estimatedFee.toStringAsFixed(2)}',
                                            ),
                                            trailing: carPark.availableLots > 0
                                                ? Text('${carPark.availableLots} lots')
                                                : const Text('N/A'),
                                            isThreeLine: true,
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
