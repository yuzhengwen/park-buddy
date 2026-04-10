import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:park_buddy/controllers/map_tab_controller.dart';
import 'package:park_buddy/models/carpark.dart';
import 'package:park_buddy/UI/bottom_sheet.dart';
import 'package:park_buddy/UI/map.dart';
import 'package:park_buddy/UI/carpark_card.dart';

/// Layout of a map with a draggable sheet of locations.
class MapWithSheet extends StatefulWidget {
  final String? sheetTitle;
  final MapTabController mapTabController;
  final Widget? floatingActionButton;
  final Widget? searchBar;
  final LatLng? initialPosition;

  const MapWithSheet({
    super.key,
    required this.mapTabController,
    this.sheetTitle,
    this.floatingActionButton,
    this.searchBar,
    this.initialPosition,
  });

  @override
  State<MapWithSheet> createState() => _MapWithSheetState();
}

class _MapWithSheetState extends State<MapWithSheet> {
  final _sheetController = DraggableScrollableController();
  final _mapController = MapController();
  final _whenMapReady = Completer<void>();

  @override
  void initState() {
    super.initState();
    widget.mapTabController.locationEnableCallback = (location) async {
      await _whenMapReady.future;
      unawaited(_setInitialPosition());
    };
  }

  Future<void> _setInitialPosition() async {
    await _whenMapReady.future;
    final selected = widget.mapTabController.selectedCarpark;
    final userLocation = widget.mapTabController.currentLocation;

    final pos = selected?.position ?? widget.initialPosition ?? userLocation;
    if (pos != null) _mapController.move(pos, CarparkMap.defaultZoom);
  }

  @override
  void dispose() {
    _sheetController.dispose();
   _mapController.dispose();
    super.dispose();
  }

  void _onMapReady() {
    if (!_whenMapReady.isCompleted) {
      _whenMapReady.complete();
    }
  }

  void _closeSheet(
    ScrollController scrollController,
    DraggableScrollableController sheetController,
  ) {
    scrollController.jumpTo(0);
    sheetController.animateTo(
      0.25,
      duration: Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  void _recenterOnUser() {
    widget.mapTabController.unselectCarpark();
    final userLocation = widget.mapTabController.currentLocation;
    if (userLocation != null) {
      _mapController.move(userLocation, CarparkMap.defaultZoom);
    }
  }

  void _onTapMarker(Carpark carpark) {
    widget.mapTabController.selectCarpark(carpark);
    _mapController.move(carpark.position, CarparkMap.defaultZoom);
  }

  void _onTapListItem(
    ScrollController scrollController,
    DraggableScrollableController sheetController,
    Carpark carpark,
  ) {
    _closeSheet(scrollController, sheetController);
    _onTapMarker(carpark);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        children: [
          _Content(
            sheetController: _sheetController,
            parentHeight: constraints.maxHeight,
            child: Stack(
              children: [
                CarparkMap(
                  mapController: _mapController,
                  mapTabController: widget.mapTabController,
                  onTapMarker: _onTapMarker,
                  onMapReady: _onMapReady,
                ),
                if (widget.searchBar != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    right: 8,
                    child: widget.searchBar!,
                  ),
              ],
            ),
          ),
          ListenableBuilder(
            listenable: widget.mapTabController,
            builder: (context, child) {
              final userLocation = widget.mapTabController.currentLocation;
              final carparks = widget.mapTabController.visibleCarparks;

              return DraggableBottomSheet(
                sheetController: _sheetController,
                title: widget.sheetTitle,
                emptyText: 'No car parks nearby.',
                itemCount: carparks.length,
                itemBuilder: (scrollController, context, index) => CarparkCard(
                  carpark: carparks[index],
                  userLocation: userLocation,
                  onItemSelect: (carpark) => _onTapListItem(
                    scrollController,
                    _sheetController,
                    carpark,
                  ),
                ),
              );
            },
          ),
          _SheetAnchor(
            sheetController: _sheetController,
            parentHeight: constraints.maxHeight,
            child: Column(
              crossAxisAlignment: .end,
              spacing: 8,
              children: [
                ListenableBuilder(
                  listenable: widget.mapTabController,
                  builder: (context, child) {
                    final userLocation = widget.mapTabController.currentLocation;

                    return _RecenterButton(
                      onPressed: userLocation != null ? _recenterOnUser : null,
                    );
                  },
                ),
                if (widget.floatingActionButton != null)
                  widget.floatingActionButton!,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Button that recentres the map on user.
class _RecenterButton extends StatelessWidget {
  final void Function()? onPressed;

  const _RecenterButton({this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FloatingActionButton.small(
      onPressed: onPressed,
      heroTag: null,
      shape: CircleBorder(),
      backgroundColor: colorScheme.secondaryContainer,
      foregroundColor: colorScheme.onSecondaryContainer,
      child: Icon(
        onPressed != null ? Icons.my_location : Icons.location_disabled,
      ),
    );
  }
}

/// Main content of the page, beneath the buttons and bottom sheet.
class _Content extends StatelessWidget {
  final DraggableScrollableController sheetController;
  final double parentHeight;
  final Widget? child;

  const _Content({
    required this.sheetController,
    required this.parentHeight,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: sheetController,
      builder: (context, child) {
        final size = sheetController.isAttached ? sheetController.size : 0.25;
        final height = ((1 - size) * parentHeight + 28.0).clamp(100.0, parentHeight);

        return SizedBox(height: height, child: child);
      },
      child: child,
    );
  }
}

/// Anchors its child widget (usually a floating action button) to float right
/// above the bottom sheet.
class _SheetAnchor extends StatelessWidget {
  final DraggableScrollableController sheetController;
  final Widget child;
  final double parentHeight;

  const _SheetAnchor({
    required this.sheetController,
    required this.child,
    required this.parentHeight,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: sheetController,
      builder: (context, child) {
        final size = sheetController.isAttached ? sheetController.size : 0.25;
        final offset = size * parentHeight + 16.0;
        final isVisible = sheetController.isAttached
            ? sheetController.size <= 0.5
            : true;

        return Positioned(
          right: 16,
          bottom: offset,
          child: AnimatedScale(
            scale: isVisible ? 1.0 : 0.0,
            duration: Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: AnimatedOpacity(
              opacity: isVisible ? 1.0 : 0.0,
              duration: Duration(milliseconds: 200),
              child: child!,
            ),
          ),
        );
      },
      child: child,
    );
  }
}
