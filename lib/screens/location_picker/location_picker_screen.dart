import 'dart:core';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:park_buddy/utils/location.dart';
import 'package:park_buddy/screens/location_picker/map.dart';
import 'package:park_buddy/screens/location_picker/location.dart';
import 'package:park_buddy/screens/location_picker/bottom_sheet.dart';

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
    );
  }
}
