import 'dart:core';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:park_buddy/models/carpark.dart';
import 'package:park_buddy/controllers/map_tab_controller.dart';
import 'package:park_buddy/UI/map_with_sheet.dart';

class CarparkPickerScreen extends StatefulWidget {
  final Carpark? initialCarpark;
  final LatLng? initialLocation;

  const CarparkPickerScreen({
    super.key,
    this.initialCarpark,
    this.initialLocation,
  });

  const CarparkPickerScreen.fromLocation(
    this.initialLocation, {
    super.key,
    this.initialCarpark,
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

    if (widget.initialCarpark != null) {
      _controller.selectCarpark(widget.initialCarpark!);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onConfirm() {
    Navigator.pop(context, _controller.selectedCarpark);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Carpark')),
      body: MapWithSheet(
        initialPosition: widget.initialCarpark == null
            ? widget.initialLocation
            : null,
        mapTabController: _controller,
      ),
      persistentFooterButtons: [
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: SizedBox(
              height: 48,
              width: double.infinity,
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, child) => FilledButton(
                  onPressed: _controller.selectedCarpark != null
                      ? _onConfirm
                      : null,
                  child: Text('Set location'),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
