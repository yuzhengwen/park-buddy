import 'package:flutter/material.dart';
import '../../utils/date_formatter.dart';
import 'package:provider/provider.dart';
import '../../../controllers/parking_session_controller.dart';

class SessionSummaryCard extends StatelessWidget {
  final DateTime? startTime;
  final bool isOngoing;
  final DateTime? endTime;
  final String? driverName;
  final String? carName;
  final String? carPlate;  

  const SessionSummaryCard({
    required this.isOngoing,
    this.startTime,
    this.endTime,
    this.driverName,
    this.carName,
    this.carPlate,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ParkingSessionController>();

    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Parking Session',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOngoing
                        ? Colors.green.shade100
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isOngoing ? 'Ongoing' : 'Completed',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isOngoing
                          ? Colors.green.shade700
                          : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Info rows
            _cardRow(Icons.access_time, 'Start time',
                DateFormatter.formatDateTime(startTime?.toIso8601String())),
            if (!isOngoing)
              _cardRow(Icons.flag_outlined, 'End time',
                  DateFormatter.formatDateTime(endTime?.toIso8601String())),
            _cardRow(Icons.person_outline, 'Driver',
                driverName ?? 'Loading...'),
            _cardRow(Icons.directions_car_outlined, 'Car',
                '${carName ?? 'Loading...'}, ${carPlate ?? '-'}'),
            const Divider(height: 24),

            // Fees — highlighted
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Accumulated fees',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),

                Row(
                  children: [
                    Text(
                      '\$${c.accumulatedFees.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF6200EA),
                      ),
                    ),
                    const SizedBox(width: 4), // spacing
                    IconButton(
                      icon: const Icon(
                        Icons.info_outline,
                        color: Colors.grey,
                      ),
                      onPressed: () => _showFeeBreakdown(context, c),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 10),
          Text('$label: ',
              style: const TextStyle(
                  fontSize: 13, color: Colors.grey)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showFeeBreakdown(BuildContext context, ParkingSessionController c) {
    // 1. Get billable minutes (integer result)
    final int billableSeconds = c.elapsed.inSeconds - (c.gracePeriodMinutes * 60);
    final int billableMins = billableSeconds <= 0 ? 0 : billableSeconds ~/ 60;

    // 2. Use the controller's blocks instead of calculating here
    final int blocks = c.completedBlocks;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Fee Breakdown'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _breakdownRow('Zone', c.isInCentralArea ? 'Central area' : 'Outside central'),
            _breakdownRow('Current rate', '\$${c.currentHalfHourRate.toStringAsFixed(2)} / 30 min'),
            _breakdownRow('Grace period', '${c.gracePeriodMinutes} mins'),
            _breakdownRow('Billable time', '$billableMins mins'),
            // FIX: Use 'blocks' from the controller
            _breakdownRow('Completed blocks', '$blocks × 30 min'),
            const Divider(),
            _breakdownRow(
              'Total',
              '\$${c.accumulatedFees.toStringAsFixed(2)}',
              bold: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _breakdownRow(String label, String value,
      {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 14, color: Colors.grey[700])),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: bold
                      ? FontWeight.bold
                      : FontWeight.normal)),
        ],
      ),
    );
  }
}
