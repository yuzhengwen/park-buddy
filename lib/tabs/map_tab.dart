import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:park_buddy/UI/carpark_marker.dart';
import 'package:park_buddy/UI/current_location_marker.dart';
import 'package:park_buddy/UI/search_location_marker.dart';
import 'package:park_buddy/models/carpark.dart';

import '../screens/start_parking_session_screen.dart';
import '../UI/carpark_list_panel.dart';
import '../UI/map_search_bar.dart';
import '../controllers/map_tab_controller.dart';

class MapTab extends StatefulWidget {
  const MapTab({super.key});

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  final _mapController = MapController();
  final _searchController = TextEditingController();
  final _radiusController = TextEditingController(text: '1');
  late final MapTabController _controller;

  bool _hasCenteredOnUser = false;

  @override
  void initState() {
    super.initState();
    _controller = MapTabController();
    _searchController.addListener(
      () => _controller.handleSearchChanged(_searchController.text),
    );
    unawaited(_controller.initialize());
    _controller.addListener(_onControllerUpdate);
    _controller.addListener(() {
      if (_controller.currentPosition != null && !_hasCenteredOnUser) {
        _hasCenteredOnUser = true;
        final pos = _controller.currentPosition!;
        _mapController.move(LatLng(pos.latitude, pos.longitude), 16);
      }
      _onControllerUpdate();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    _searchController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  // ── Helpers that bridge controller actions with MapController ─────────────

  void _applySearchAndRadius() {
    final searchResult = _controller.searchCenter;
    _controller.applySearchAndRadius(
      searchQuery: _searchController.text.trim(),
      radiusText: _radiusController.text,
      onMoveMap: () {
        if (searchResult != null) {
          _mapController.move(searchResult, 15);
        }
      },
    );
  }

  void _focusCarpark(Carpark carpark) {
    _controller.focusCarpark(
      carpark,
      onMoveMap: () => _mapController.move(carpark.position, 17),
    );
  }

  void _recenterOnUser() {
    final pos = _controller.currentPosition;
    if (pos != null) {
      _mapController.move(LatLng(pos.latitude, pos.longitude), 16);
    }
  }

  String? _panelLocationStatus() {
    if (_controller.isTracking) {
      return 'Updated just now';
    }
    return null;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    debugPrint('MapTab rebuild');
    final pos = _controller.currentPosition;
    final currentLatLng = pos == null
        ? MapTabController.defaultCenter
        : LatLng(pos.latitude, pos.longitude);
    final listOrigin = _controller.searchCenter ?? currentLatLng;
    final markerCarparks = _controller.visibleCarparks;

    return Stack(
      children: [
        // ── Map ──────────────────────────────────────────────────────────────
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
                        isSelected:
                            carpark.carParkNo == _controller.selectedCarparkNo,
                      ),
                    ),
                  ),
                ),
                if (_controller.searchCenter != null)
                  Marker(
                    point: _controller.searchCenter!,
                    width: 140,
                    height: 52,
                    child: SearchLocationMarker(
                      label:
                          _controller.searchCenterLabel ??
                          _searchController.text.trim(),
                    ),
                  ),
              ],
            ),
          ],
        ),

        // ── Search bar overlay ────────────────────────────────────────────────
        Positioned(
          left: 16,
          right: 16,
          top: 16,
          child: SafeArea(
            bottom: false,
            child: MapSearchBar(
              searchController: _searchController,
              radiusController: _radiusController,
              isSearchingLocation: _controller.isSearchingLocation,
              searchText: _controller.searchText,
              onApply: _applySearchAndRadius,
              onOpenSettings: _controller.openAppSettings,
            ),
          ),
        ),

        // ── Recenter FAB ──────────────────────────────────────────────────────
        Positioned(
          right: 16,
          bottom: 220,
          child: FloatingActionButton.small(
            heroTag: 'recenter-map',
            onPressed: pos == null ? null : _recenterOnUser,
            child: const Icon(Icons.my_location),
          ),
        ),

        // ── Park Now FAB ──────────────────────────────────────────────────────
        Positioned(
          right: 16,
          bottom: 160,
          child: FloatingActionButton.extended(
            heroTag: 'parkNow',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StartParkingSessionScreen(
                  initialCarpark: _controller.getSelectedOrNearestCarpark(),
                ),
              ),
            ),
            label: const Text('Park Now'),
            icon: const Icon(Icons.local_parking),
          ),
        ),

        // ── Bottom carpark panel ──────────────────────────────────────────────
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: CarparkListPanel(
            visibleCarparks: _controller.visibleCarparks,
            isLoadingCarparks: _controller.isLoadingCarparks,
            isListCollapsed: _controller.isListCollapsed,
            loadError: _controller.loadError,
            listOrigin: listOrigin,
            selectedCarparkNo: _controller.selectedCarparkNo,
            locationStatusText: _panelLocationStatus(),
            onToggleCollapse: _controller.toggleListCollapsed,
            onCarparkTap: _focusCarpark,
            onRetry: () => unawaited(_controller.loadCarparkData()),
          ),
        ),
      ],
    );
  }
}
