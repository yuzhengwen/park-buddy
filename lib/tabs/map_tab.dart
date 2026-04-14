import 'dart:async';
import 'package:flutter/material.dart';
import 'package:park_buddy/models/carpark.dart';
import 'package:park_buddy/screens/start_parking_session_screen.dart';
import 'package:park_buddy/controllers/map_tab_controller.dart';
import 'package:park_buddy/UI/map_with_sheet.dart';

class MapTab extends StatefulWidget {
  const MapTab({super.key});

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  final _controller = MapTabController();

  @override
  void initState() {
    super.initState();
    unawaited(_controller.initialize());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startParkingSession(Carpark? carpark) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StartParkingSessionScreen(
          initialCarpark: carpark,
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
      onConfirmCarpark: _startParkingSession,
      confirmCarparkText: 'Park here',
      floatingActionButton: FloatingActionButton.extended(
        label: const Text('Park Now'),
        icon: const Icon(Icons.local_parking),
        onPressed: () => _startParkingSession(_controller.nearestCarpark),
      ),
    );
  }
}
