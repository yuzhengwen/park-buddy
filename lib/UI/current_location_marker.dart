import 'package:flutter/material.dart';

class CurrentLocationMarker extends StatelessWidget {
  const CurrentLocationMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blueAccent.withValues(alpha: 0.18),
      ),
      padding: const EdgeInsets.all(8),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.blueAccent,
        ),
        child: const Icon(
          Icons.person_pin_circle,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}
