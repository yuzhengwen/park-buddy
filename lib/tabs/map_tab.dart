import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:park_buddy/models/carpark.dart';
import 'package:park_buddy/screens/start_parking_session_screen.dart';
import 'package:park_buddy/controllers/map_tab_controller.dart';
import 'package:park_buddy/UI/map_with_sheet.dart';
import 'package:park_buddy/providers/cars_provider.dart';

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
    
    // Show popup if notification was scheduled
    if (result is Map<String, dynamic> && result['notificationScheduled'] == true) {
      final estimatedTime = result['estimatedTime'];
      if (estimatedTime != null) {
        _showNotificationScheduledPopup(estimatedTime);
      }
    }
  }

  void _showNotificationScheduledPopup(DateTime estimatedTime) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Notification scheduled for ${_formatTime(estimatedTime)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = time.difference(now);
    
    if (difference.isNegative) {
      return 'Now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes.toInt()} minutes';
    } else if (difference.inHours < 24) {
      return '${difference.inHours.toInt()} hours';
    } else {
      return '${difference.inDays} days';
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
