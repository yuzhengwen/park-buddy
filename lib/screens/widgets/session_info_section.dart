import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/parking_session_controller.dart';
import '../../../utils/date_formatter.dart';

class SessionInfoSection extends StatelessWidget {
  const SessionInfoSection();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ParkingSessionController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _detailRow('Session Name', c.session?.sessionName),
        _detailRow('Parking time',
            DateFormatter.formatDateTime(c.session?.startTime?.toIso8601String())),
        _detailRow(
          'Parking status',
          c.isOngoing
              ? 'Ongoing'
              : 'Completed on ${DateFormatter.formatDateTime(c.session?.endTime?.toIso8601String())}',
        ),
        _detailRow('Driver', c.driverName ?? 'Loading...'),
        _detailRowWithIcon(
          'Location',
          c.session?.location,
          icon: const Icon(Icons.location_on_outlined,
              color: Colors.grey),
        ),
        _detailRow(
          'Car',
          '${c.carName ?? 'Loading...'}, ${c.session?.carPlate ?? '-'}',
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _detailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          Text(value ?? '-',
              style: const TextStyle(
                  fontSize: 14, color: Colors.grey)),
          const Divider(),
        ],
      ),
    );
  }

  Widget _detailRowWithIcon(String label, String? value,
      {Widget? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(value ?? '-',
                      style: const TextStyle(
                          fontSize: 14, color: Colors.grey)),
                ],
              ),
              if (icon != null) icon,
            ],
          ),
          const Divider(),
        ],
      ),
    );
  }
}