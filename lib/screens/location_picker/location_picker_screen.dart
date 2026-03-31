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
import 'package:park_buddy/controllers/map_tab_controller.dart';

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
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  final ValueNotifier<double> _sheetSize = ValueNotifier(0.25);
  late final MapTabController _controller;  // ← replaces _locationService + _carparks + _boundedCarparks + _userLocation

  bool _hasCenteredOnUser = false;

  @override
  void initState() {
    super.initState();

    _controller = MapTabController();
    _controller.addListener(_onControllerUpdate);
    _controller.addListener(() {
      // Auto-center on user once location is available
      if (_controller.currentPosition != null && !_hasCenteredOnUser) {
        _hasCenteredOnUser = true;
        final pos = _controller.currentPosition!;
        _mapController.move(LatLng(pos.latitude, pos.longitude), widget.initialMapZoom ?? 16);
      }
    });

    _sheetController.addListener(() {
      _sheetSize.value = _sheetController.size;
    });

    // If a center was passed in (e.g. editing existing session), go there first
    if (widget.initialMapCenter != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(widget.initialMapCenter!, widget.initialMapZoom ?? 16);
        _hasCenteredOnUser = true; // don't override with user location
      });
    }

    _controller.initialize(); // loads carparks + starts location
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    _sheetSize.dispose();
    _sheetController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onConfirm(BuildContext context, Carpark carpark) {
    Navigator.pop(context, carpark);
  }

  void _onMapChangedBounds(LatLngBounds bounds) {
    // MapTabController handles filtering — nothing needed here
  }

  @override
  Widget build(BuildContext context) {
    final pos = _controller.currentPosition;
    final userLocation = pos != null ? LatLng(pos.latitude, pos.longitude) : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Select Carpark')),
      body: Stack(
        children: [
          CarparkPickerMap(
            mapController: _mapController,
            carparks: _controller.visibleCarparks,  // ← was _boundedCarparks
            userLocation: userLocation,             // ← was _userLocation
            onChangedBounds: _onMapChangedBounds,
            onMarkerSelect: (carpark) => _onConfirm(context, carpark),
            initialMapCenter: widget.initialMapCenter,
            initialMapZoom: widget.initialMapZoom,
            sheetSize: _sheetSize,
          ),
          CarparkPickerBottomSheet(
            carparks: _controller.visibleCarparks,  // ← was _boundedCarparks
            onItemSelect: (carpark) => _onConfirm(context, carpark),
            controller: _sheetController,
          ),
        ],
      ),
    );
  }
}
