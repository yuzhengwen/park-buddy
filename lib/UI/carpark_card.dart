import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:park_buddy/models/carpark.dart';
import 'package:park_buddy/utils/math_utils.dart';

class CarparkCard extends StatelessWidget {
  final void Function(Carpark carpark)? onItemSelect;
  final Carpark carpark;
  final LatLng? userLocation;

  const CarparkCard({
    super.key,
    required this.onItemSelect,
    required this.carpark,
    this.userLocation,
  });

  @override
  Widget build(BuildContext context) {
    final carparkNo = 'Car park: ${carpark.carParkNo}';
    final distanceKm = userLocation != null
        ? ' • ${MathUtils.distanceKm(userLocation!, carpark.position).toStringAsFixed(2)} km'
        : '';
    late final List<Text> lots;
    if (carpark.availability != null) {
      lots = [
        Text(
          '${carpark.availability!.lotsAvailable}',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: .center,
        ),
        Text(
          carpark.availability!.lotsAvailable == 1 ? 'lot': 'lots',
          style: Theme.of(context).textTheme.titleSmall,
          textAlign: .center,
        ),
      ];
    } else {
      lots = [
        Text(
          'n/a',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: .center,
        ),
      ];
    }

    return Card.outlined(
      clipBehavior: Clip.hardEdge,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              spacing: 16,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      Text(
                        carpark.address,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text('$carparkNo $distanceKm'),
                      Text('${carpark.carParkType} • ${carpark.shortTermParking}',
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 50,
                  child: Column(
                    children: lots,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.0),
            Align(
              alignment: .bottomRight,
              child: FilledButton.tonal(
                onPressed: () => onItemSelect?.call(carpark),
                child: Text('Park here')
              ),
            ),
          ],
        ),
      ),
    );
  }
}
