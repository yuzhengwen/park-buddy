import 'dart:core';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:park_buddy/utils/location.dart';
import 'package:park_buddy/screens/location_picker/map.dart';
import 'package:park_buddy/screens/location_picker/bottom_sheet.dart';
import 'package:park_buddy/models/carpark.dart';

class CarparkPickerScreen extends StatefulWidget {
  final LatLng? initialMapCenter;
  final double? initialMapZoom;

  const CarparkPickerScreen({
    super.key,
    this.initialMapCenter,
    this.initialMapZoom,
  });

  @override
  State<CarparkPickerScreen> createState() => _CarparkPickerScreenState();
}

class _CarparkPickerScreenState extends State<CarparkPickerScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  final ValueNotifier<double> _sheetSize = ValueNotifier(0.25);
  final DraggableScrollableController _sheetController = DraggableScrollableController();

  // TODO: read from API
  final List<Carpark> _carparks = const [];

  LatLng? _userLocation;
  List<Carpark> _boundedCarparks = const <Carpark>[];

  Future<void> _goToUser() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          timeLimit: Duration(milliseconds: 500),
        ),
      );
      final success = _mapController.move(
        LatLng(pos.latitude, pos.longitude),
        widget.initialMapZoom ?? 16,
      );
      if (success) {
        _onMapChangedBounds(_mapController.camera.visibleBounds);
      }

    } on TimeoutException {
      return;
    } on LocationServiceDisabledException {
      return;
    }
  }

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

    _goToUser();
  }

  @override
  void dispose() {
    _mapController.dispose();
    _locationService.dispose();
    _sheetSize.dispose();
    super.dispose();
  }

  void _onConfirm(BuildContext context, Carpark carpark) {
    Navigator.pop(context, carpark);
  }

  void _onMapChangedBounds(LatLngBounds bounds) {
    setState(() {
      _boundedCarparks = _carparks
          .where((carpark) => bounds.contains(carpark.position))
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
            sheetSize: _sheetSize,
          ),
          CarparkPickerBottomSheet(
            carparks: _boundedCarparks,
            onItemSelect: (carpark) => _onConfirm(context, carpark),
            sheetSize: _sheetSize,
            controller: _sheetController,
          ),
        ],
      ),
    );
  }
}
