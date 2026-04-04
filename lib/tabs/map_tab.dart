import 'dart:async';
import 'package:flutter/material.dart';
import 'package:park_buddy/screens/start_parking_session_screen.dart';
import 'package:park_buddy/controllers/map_tab_controller.dart';
import 'package:park_buddy/UI/map_search_bar.dart';
import 'package:park_buddy/UI/map_with_sheet.dart';

class MapTab extends StatefulWidget {
  const MapTab({super.key});

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  final _searchController = TextEditingController();
  final _radiusController = TextEditingController(text: '1');
  final _controller = MapTabController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(
      () => _controller.handleSearchChanged(_searchController.text),
    );
    unawaited(_controller.initialize());
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  // ── Helpers that bridge controller actions with MapController ─────────────

  void _applySearchAndRadius() {
    final searchResult = _controller.searchCenter;
    _controller.applySearchAndRadius(
      searchQuery: _searchController.text.trim(),
      radiusText: _radiusController.text,
      onMoveMap: () {
        // if (searchResult != null) {
        //   _mapController.move(searchResult, CarparkMap.defaultZoom);
        // }
      },
    );
  }

  void _startParkingSession() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StartParkingSessionScreen(
          initialCarpark: _controller.getSelectedOrNearestCarpark(),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return MapWithSheet(
      sheetTitle: 'Nearest HDB Car Parks',
      mapTabController: _controller,
      floatingActionButton: FloatingActionButton.extended(
        label: const Text('Park Now'),
        icon: const Icon(Icons.local_parking),
        onPressed: _startParkingSession,
      ),
      searchBar: SafeArea(
        bottom: false,
        child: MapSearchBar(
          searchController: _searchController,
          radiusController: _radiusController,
          isSearchingLocation: _controller.isSearchingLocation,
          searchText: _controller.searchText,
          onApply: _applySearchAndRadius,
          onOpenSettings: () {},
        ),
      ),
    );
  }
}
