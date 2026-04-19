import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:park_buddy/models/carpark.dart';
import 'package:park_buddy/screens/start_parking_session_screen.dart';
import 'package:park_buddy/controllers/map_tab_controller.dart';
import 'package:park_buddy/screens/widgets/map_with_sheet.dart';
import 'package:park_buddy/providers/cars_provider.dart';
import 'package:park_buddy/utils/hdb_fee_calculator.dart';

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

  void _startParkingSession(Carpark? carpark) async {
    final cars = context.read<CarsProvider>().cars;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StartParkingSessionScreen(
          initialCarpark: carpark,
          cars: cars,
        ),
      ),
    );

    var msg = 'Session created.';

    if (result.rateThreshold != null) {
      final scheduledTime = HdbFeeCalculator.calculateThresholdTime(
        threshold: result.rateThreshold!,
        startTime: result.startTime!,
        carparkPosition: result.carparkPosition,
      );

      if (scheduledTime == null) {
        throw StateError('Unable to calculate rate threshold trigger time');
      }

      msg = '$msg Alert scheduled for ${DateFormat.jm().format(scheduledTime)}';
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
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
