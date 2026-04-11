import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:park_buddy/models/carpark.dart';

class MapMarkers {
  static Marker currentLocationMarker(LatLng location) {
    return Marker(
      point: location,
      width: 56,
      height: 56,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.blueAccent.withValues(alpha: 0.18),
        ),
        padding: const EdgeInsets.all(8),
        child: const DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blueAccent,
          ),
          child: Icon(
            Icons.person_pin_circle,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }

  static Marker carparkMarker({
    required ThemeData theme,
    required Carpark data,
    required bool isSelected,
    void Function(Carpark)? onTap,
  }) {
    final blockLabel = 'Blk ${data.blockLabel}';
    final lotsAvailable = data.availability?.lotsAvailable;
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    Color background, foreground;
    if (isSelected) {
      background = colorScheme.primary;
      foreground = colorScheme.onPrimary;
    } else if (lotsAvailable == null) {
      background = Color.alphaBlend(
        colorScheme.onSurface.withValues(alpha: 0.12),
        colorScheme.surface,
      );
      foreground = Color.alphaBlend(
        colorScheme.onSurface.withValues(alpha: 0.38),
        background,
      );
    } else if (lotsAvailable > 0) {
      background = colorScheme.surfaceContainerLow;
      foreground = colorScheme.onSurface;
    } else {
      background = colorScheme.errorContainer;
      foreground = colorScheme.onErrorContainer;
    }

    final blockLabelText = textTheme.labelSmall?.copyWith(
      color: foreground,
      fontSize: 10,
      fontWeight: FontWeight.normal,
    );
    final lotsAvailableText = textTheme.labelMedium?.copyWith(
      color: foreground,
      fontSize: 12,
      fontWeight: FontWeight.bold,
    );

    return Marker(
      point: data.position,
      width: 90,
      height: 60,
      child: GestureDetector(
        onTap: () => onTap?.call(data),
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 2,
              children: [
                Text(
                  blockLabel,
                  style: blockLabelText,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  lotsAvailable != null ? '$lotsAvailable' : 'Unknown',
                  style: lotsAvailableText,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Marker searchMarker({
    required ThemeData theme,
    required LatLng location,
    required String label,
  }) {
    final colorScheme = theme.colorScheme;
    final background = colorScheme.secondary;
    final foreground = colorScheme.onSecondary;
    final labelText = theme.textTheme.labelMedium?.copyWith(color: foreground);

    return Marker(
      point: location,
      width: 140,
      height: 52,
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              Icon(Icons.search, color: foreground, size: 16),
              Flexible(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: labelText,
                ),
              ),
            ],
          ),
        ),
      )
    );
  }
}
