import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class CarparkLocation {
  final String carparkName;
  final LatLng carparkCoords;

  const CarparkLocation(
    this.carparkName,
    this.carparkCoords,
  );
}

class CarparkPickerScreen extends StatefulWidget {
  final LatLng initialMapCenter;
  final double initialMapZoom;

  const CarparkPickerScreen({
    super.key,
    this.initialMapCenter = const LatLng(1.3521, 103.8198),
    this.initialMapZoom = 14,
  });

  @override
  State<CarparkPickerScreen> createState() => _CarparkPickerScreenState();
}

class _CarparkPickerScreenState extends State<CarparkPickerScreen> {
  CarparkLocation? _selectedLocation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Carpark')),
      body: Stack(
        children: <Widget>[
          // 1. Interactive map in the background
          FlutterMap(
            options: MapOptions(
              initialCenter: widget.initialMapCenter,
              initialZoom: widget.initialMapZoom,
            ),
            children: <Widget>[
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.sc2006_parking',
              ),
            ],
          ),
          // 2. Carpark list & selection UI
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _selectedLocation != null
                        ? () => Navigator.pop(context, _selectedLocation)
                        : null,
                    child: const Text('Set location'),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
