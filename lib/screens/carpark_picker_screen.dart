import 'dart:core';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:park_buddy/utils/location.dart';

class CarparkLocation {
  final String name;
  final LatLng coords;

  const CarparkLocation(
    this.name,
    this.coords,
  );
}

class CarparkPickerScreen extends StatefulWidget {
  final LatLng? initialMapCenter;
  final double? initialMapZoom;
  final List<CarparkLocation> carparks;

  const CarparkPickerScreen({
    super.key,
    required this.carparks,
    this.initialMapCenter,
    this.initialMapZoom,
  });

  @override
  State<CarparkPickerScreen> createState() => _CarparkPickerScreenState();
}

class _CarparkPickerScreenState extends State<CarparkPickerScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();

  LatLng? _userLocation;
  List<CarparkLocation> _boundedCarparks = const <CarparkLocation>[];
  CarparkLocation? _selectedLocation;

  @override
  void initState() {
    super.initState();

    // Initialise live location
    _locationService.begin(
      onLocationUpdate: (position) {
        setState(() {
          _userLocation = position != null
              ? LatLng(position.latitude, position.longitude)
              : null;
        });
      },
      onError: (e) {
        if (!mounted) return;
        ScaffoldMessenger
            .of(context)
            .showSnackBar(
              SnackBar(content: Text('Location error: $e'))
            );
      },
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    _locationService.dispose();
    super.dispose();
  }

  void _onConfirm(BuildContext context, CarparkLocation carpark) {
    Navigator.pop(context, carpark);
  }

  void _onMapChangedBounds(LatLngBounds bounds) {
    setState(() {
      _boundedCarparks = widget.carparks
          .where((carpark) => bounds.contains(carpark.coords))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Carpark')),
      body: Stack(
        children: <Widget>[
          CarparkPickerMap(
            mapController: _mapController,
            carparks: _boundedCarparks,
            userLocation: _userLocation,
            onChangedBounds: _onMapChangedBounds,
            onMarkerSelect: (carpark) => _onConfirm(context, carpark),
            initialMapCenter: widget.initialMapCenter,
            initialMapZoom: widget.initialMapZoom,
          ),
        ],
      ),
      bottomSheet: CarparkPickerBottomSheet(
        carparks: _boundedCarparks,
        onItemSelect: (carpark) => _onConfirm(context, carpark),
      ),
      // persistentFooterButtons: <Widget>[
      //   CarparkPickerConfirmButton(
      //     onPressed: _selectedLocation != null
      //         ? () => _onConfirm(context)
      //         : null,
      //   ),
      // ],
    );
  }
}

// Map of carparks with interactive carpark marker pins
class CarparkPickerMap extends StatelessWidget {
  final MapController _mapController;
  final LatLng _initialMapCenter;
  final double _initialMapZoom;
  final List<CarparkLocation> _carparks;
  final LatLng? _userLocation;
  final void Function(LatLngBounds)? _onChangedBounds;
  final void Function(CarparkLocation carpark)? _onMarkerSelect;

  const CarparkPickerMap({
    super.key,
    required MapController mapController,
    LatLng? initialMapCenter,
    double? initialMapZoom,
    required List<CarparkLocation> carparks,
    LatLng? userLocation,
    void Function(LatLngBounds)? onChangedBounds,
    void Function(CarparkLocation carpark)? onMarkerSelect,
  }) : _mapController = mapController,
       _initialMapCenter = initialMapCenter ?? const LatLng(1.3521, 103.8198),
       _initialMapZoom = initialMapZoom ?? 16,
       _carparks = carparks,
       _userLocation = userLocation,
       _onChangedBounds = onChangedBounds,
       _onMarkerSelect = onMarkerSelect;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _initialMapCenter,
        initialZoom: _initialMapZoom,
        onMapReady: () {
          _onChangedBounds?.call(_mapController.camera.visibleBounds);
        },
        onMapEvent: (evt) {
          if (evt is MapEventMoveEnd) {
            _onChangedBounds?.call(evt.camera.visibleBounds);
          }
        },
      ),
      children: <Widget>[
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.sc2006_parking',
        ),
        BoundedMarkerLayer(
          carparks: _carparks,
          userLocation: _userLocation,
          onMarkerSelect: _onMarkerSelect,
        ),
      ],
    );
  }
}

// Map layer for markers (pins) within the visible map viewport
class BoundedMarkerLayer extends StatelessWidget {
  final List<CarparkLocation> _carparks;
  final LatLng? _userLocation;
  final void Function(CarparkLocation carpark)? _onMarkerSelect;

  const BoundedMarkerLayer({
    super.key,
    required List<CarparkLocation> carparks,
    required LatLng? userLocation,
    void Function(CarparkLocation carpark)? onMarkerSelect,
  }) : _carparks = carparks,
       _userLocation = userLocation,
       _onMarkerSelect = onMarkerSelect;

  // Helper function to create Marker objects from carpark details
  Marker _createMarker(CarparkLocation carpark) => Marker(
    point: carpark.coords,
    height: 70,
    width: 160,
    alignment: Alignment.topCenter,
    child: GestureDetector(
      onTap: () => _onMarkerSelect?.call(carpark),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          // Stack to create outline effect for text
          Stack(
            children: <Widget>[
              Text(
                carpark.name,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                style: TextStyle(
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 3
                    ..color = Colors.white,
                ),
              ),
              Text(
                carpark.name,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
          Icon(Icons.location_pin, color: Colors.red),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return MarkerLayer(
      rotate: true,
      alignment: Alignment.bottomCenter,
      markers: <Marker>[
        // Nearby carpark markers
        ..._carparks.map((carpark) => _createMarker(carpark)),

        // User location marker
        if (_userLocation != null)
          Marker(
            point: _userLocation!,
            alignment: Alignment.topCenter,
            height: 40,
            width: 40,
            child: Icon(
              Icons.location_history,
              color: Colors.blue,
              size: 40,
            ),
          ),
      ],
    );
  }
}

// Bottom sheet holding the list of carpark locations
class CarparkPickerBottomSheet extends StatelessWidget {
  final List<CarparkLocation> _carparks;
  final void Function(CarparkLocation carpark)? _onItemSelect;

  const CarparkPickerBottomSheet({
    super.key,
    required List<CarparkLocation> carparks,
    void Function(CarparkLocation carpark)? onItemSelect,
  }) : _carparks = carparks,
       _onItemSelect = onItemSelect;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => CustomScrollView(
        controller: scrollController,
        slivers: <Widget>[
          SliverPersistentHeader(
            delegate: DragHandleDelegate(),
            pinned: true,
          ),
          if (_carparks.isNotEmpty)
            SliverList.builder(
              itemCount: _carparks.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_carparks[index].name),
                  onTap: () => _onItemSelect?.call(_carparks[index]),
                );
              },
            )
          else
            SliverFillRemaining(
              child: Center(
                child: Text(
                  'No carparks found',
                  style: TextStyle(color: Theme.of(context).colorScheme.outline),
                ),
              ),
            ),
        ],
      ),
      snap: true,
      snapSizes: [0.5, 0.9],
    );
  }
}

// Bottom sheet drag handle
class DragHandleDelegate extends SliverPersistentHeaderDelegate {
  final double height = 36;

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;

  @override
  Widget build(context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        color: Theme.of(context).colorScheme.surfaceContainerLow,
      ),
      alignment: Alignment(0, 0),
      child: Container(
        width: 32,
        height: 4,
        margin: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outline,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

// Confirm button at the bottom of the screen, enabled once a location is selected
class CarparkPickerConfirmButton extends StatelessWidget {
  final void Function()? _onPressed;

  const CarparkPickerConfirmButton({
    super.key,
    required void Function()? onPressed,
  }) : _onPressed = onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: EdgeInsets.all(8),
      child: SizedBox(
        height: 48,
        width: double.infinity,
        child: FilledButton(
          onPressed: _onPressed,
          child: const Text('Set location'),
        ),
      ),
    );
  }
}
