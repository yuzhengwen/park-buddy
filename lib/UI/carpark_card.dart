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
    final lotsLabel = carpark.availability != null && carpark.availability!.lotsAvailable == 1
        ? 'lot'
        : 'lots';
    final numLots = carpark.availability != null
        ? '${carpark.availability!.lotsAvailable}\n$lotsLabel'
        : 'n/a';

    return Card.outlined(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () => onItemSelect?.call(carpark),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
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
                child: Text(
                  numLots,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
