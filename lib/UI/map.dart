import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:park_buddy/models/carpark.dart';
import 'package:park_buddy/controllers/map_tab_controller.dart';
import 'package:park_buddy/UI/map_markers.dart';

class CarparkMap extends StatelessWidget {
  static const defaultCenter = LatLng(1.3521, 103.8198);
  static const defaultZoom = 16.0;

  final MapController mapController;
  final LatLng initialMapCenter;
  final double initialMapZoom;
  final MapTabController mapTabController;
  final void Function(LatLngBounds)? onChangedBounds;
  final void Function(Carpark)? onTapMarker;
  final void Function()? onMapReady;

  const CarparkMap({
    super.key,
    required this.mapController,
    this.initialMapCenter = defaultCenter,
    this.initialMapZoom = defaultZoom,
    required this.mapTabController,
    this.onChangedBounds,
    this.onTapMarker,
    this.onMapReady,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: initialMapCenter,
        initialZoom: initialMapZoom,
        onMapReady: () {
          onMapReady?.call();
          onChangedBounds?.call(mapController.camera.visibleBounds);
        },
        onMapEvent: (event) {
          if (event is MapEventMoveEnd) {
            onChangedBounds?.call(event.camera.visibleBounds);
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.park_buddy',
        ),
        ListenableBuilder(
          listenable: mapTabController,
          builder: (context, child) {
            final currentLocation = mapTabController.currentLocation;
            final carparks = mapTabController.visibleCarparks;
            final searchLocation = mapTabController.searchCenter;
            final searchLabel = mapTabController.searchCenterLabel ?? '?';
            final selectedCarparkNo = mapTabController.selectedCarparkNo;
            final theme = Theme.of(context);

            return MarkerLayer(
              rotate: true,
              markers: [
                if (currentLocation != null)
                  MapMarkers.currentLocationMarker(currentLocation),

                ...carparks.map(
                  (carpark) => MapMarkers.carparkMarker(
                    theme: theme,
                    data: carpark,
                    isSelected: carpark.carParkNo == selectedCarparkNo,
                    onTap: onTapMarker,
                  ),
                ),

                if (searchLocation != null)
                  MapMarkers.searchMarker(
                    theme: theme,
                    location: searchLocation,
                    label: searchLabel,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
