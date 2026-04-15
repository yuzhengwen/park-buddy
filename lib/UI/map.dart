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
  final void Function(Carpark)? onTapMarker;
  final void Function()? onMapReady;

  const CarparkMap({
    super.key,
    required this.mapController,
    this.initialMapCenter = defaultCenter,
    this.initialMapZoom = defaultZoom,
    required this.mapTabController,
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
            final currentLocation = mapTabController.location.currentLocation;
            final carparks = mapTabController.visibleCarparks;
            final selectedCarpark = mapTabController.selectedCarpark;
            final theme = Theme.of(context);

            return MarkerLayer(
              rotate: true,
              markers: [
                if (currentLocation != null)
                  MapMarkers.currentLocationMarker(currentLocation),

                ...carparks
                    .where((carpark) => carpark != selectedCarpark)
                    .map(
                      (carpark) => MapMarkers.carparkMarker(
                        theme: theme,
                        data: carpark,
                        isSelected: false,
                        onTap: onTapMarker,
                      ),
                    ),

                if (selectedCarpark != null)
                  MapMarkers.carparkMarker(
                    theme: theme,
                    data: selectedCarpark,
                    isSelected: true,
                    onTap: onTapMarker,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
