import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/parking_session_controller.dart';

class SessionBottomBar extends StatelessWidget {
  const SessionBottomBar();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ParkingSessionController>();

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border:
            Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Parking duration: ${c.formattedDuration}',
            style:
                const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7643),
                padding:
                    const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: c.isEndingParking
                  ? null
                  : () => _endParking(context, c),
              child: c.isEndingParking
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('END PARKING',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _endParking(
      BuildContext context, ParkingSessionController c) async {
    try {
      await c.endParking();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to end session: $e')),
        );
      }
    }
  }
}
