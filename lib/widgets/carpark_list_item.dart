import 'package:flutter/material.dart';
import 'package:park_buddy/models/carpark.dart';

class CarparkListItem extends StatelessWidget {
  final Carpark carpark;
  final double? distanceKm;
  final void Function(Carpark)? onItemSelect;
  final void Function(Carpark)? onItemInfo;

  const CarparkListItem({
    super.key,
    required this.carpark,
    this.distanceKm,
    this.onItemSelect,
    this.onItemInfo,
  });

  @override
  Widget build(BuildContext context) {
    final parts = [
      if (distanceKm != null) '${distanceKm!.toStringAsFixed(2)} km',
      if (carpark.availability != null) '${carpark.availability!.lotsAvailable} lots',
    ];
    final subtitle = parts.isNotEmpty ? parts.join(' • ') : null;

    return ListTile(
      title: Text(carpark.address),
      subtitle: subtitle != null ? Text(subtitle) : null,
      onTap: () => onItemInfo?.call(carpark),
      trailing: IconButton.filledTonal(
        icon: const Icon(Icons.arrow_forward),
        onPressed: () => onItemSelect?.call(carpark),
      ),
    );
  }
}
