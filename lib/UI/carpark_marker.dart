// markers.dart
import 'package:flutter/material.dart';

class CarparkMarker extends StatelessWidget {
  const CarparkMarker({
    required this.blockLabel,
    required this.lotsAvailable,
    required this.isSelected,
  });

  final String blockLabel;
  final int? lotsAvailable;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final hasAvailability = lotsAvailable != null;
    final hasLots = (lotsAvailable ?? 0) > 0;
    final markerColor = isSelected
        ? Colors.indigo
        : !hasAvailability
        ? Colors.blueGrey
        : hasLots
        ? Colors.green
        : Colors.redAccent;

    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: markerColor,
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
          children: [
            Text(
              blockLabel,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              hasAvailability ? '${lotsAvailable!}' : 'Unknown',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
