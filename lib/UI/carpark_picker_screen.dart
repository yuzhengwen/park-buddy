import 'dart:core';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:park_buddy/controllers/map_tab_controller.dart';
import 'package:park_buddy/UI/map_with_sheet.dart';

class CarparkPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;

  const CarparkPickerScreen({
    super.key,
    this.initialLocation,
  });

  @override
  State<CarparkPickerScreen> createState() => _CarparkPickerScreenState();
}

class _CarparkPickerScreenState extends State<CarparkPickerScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Carpark')),
      body: MapWithSheet(
        onConfirmCarpark: (carpark) {
          final currentRoute = ModalRoute.of(context);

          Navigator.of(context)
            .popUntilWithResult(
              (route) => route != currentRoute,
              carpark,
            );
        },
        initialPosition: widget.initialLocation,
        mapTabController: _controller,
      ),
    );
  }
}
