import 'dart:core';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:park_buddy/models/carpark.dart';

// Map of carparks with interactive carpark marker pins
class CarparkPickerMap extends StatelessWidget {
  final MapController _mapController;
  final LatLng _initialMapCenter;
  final double _initialMapZoom;
  final List<Carpark> _carparks;
  final LatLng? _userLocation;
  final void Function(LatLngBounds)? _onChangedBounds;
  final void Function(Carpark carpark)? _onMarkerSelect;
  final ValueNotifier<double> _sheetSize;

  const CarparkPickerMap({
    super.key,
    required MapController mapController,
    LatLng? initialMapCenter,
    double? initialMapZoom,
    required List<Carpark> carparks,
    LatLng? userLocation,
    void Function(LatLngBounds)? onChangedBounds,
    void Function(Carpark carpark)? onMarkerSelect,
    required ValueNotifier<double> sheetSize,
  }) : _mapController = mapController,
       _initialMapCenter = initialMapCenter ?? const LatLng(1.3521, 103.8198),
       _initialMapZoom = initialMapZoom ?? 16,
       _carparks = carparks,
       _userLocation = userLocation,
       _onChangedBounds = onChangedBounds,
       _onMarkerSelect = onMarkerSelect,
       _sheetSize = sheetSize;

  @override
  Widget build(BuildContext context) {
    const sheetRadius = 28.0;
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top;
    final appBarHeight = kToolbarHeight;
    final bodyHeight = screenHeight - topPadding - appBarHeight;

    return ValueListenableBuilder<double>(
      valueListenable: _sheetSize,
      builder: (context, size, child) {
        final mapBottom = (bodyHeight * size - sheetRadius).clamp(0.0, double.infinity);
        return AnimatedContainer(
          duration: Duration(milliseconds: 30),
          margin: EdgeInsets.only(bottom: (mapBottom - sheetRadius).clamp(0.0, double.infinity)),
          child: child,
        );
      },
      child: FlutterMap(
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
      ),
    );
  }
}

// Map layer for markers (pins) within the visible map viewport
class BoundedMarkerLayer extends StatelessWidget {
  final List<Carpark> _carparks;
  final LatLng? _userLocation;
  final void Function(Carpark carpark)? _onMarkerSelect;

  const BoundedMarkerLayer({
    super.key,
    required List<Carpark> carparks,
    required LatLng? userLocation,
    void Function(Carpark carpark)? onMarkerSelect,
  }) : _carparks = carparks,
       _userLocation = userLocation,
       _onMarkerSelect = onMarkerSelect;

  // Helper function to create Marker objects from carpark details
  Marker _createMarker(Carpark carpark) => Marker(
    point: carpark.position,
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
                carpark.address,
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
                carpark.address,
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
            point: _userLocation,
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

