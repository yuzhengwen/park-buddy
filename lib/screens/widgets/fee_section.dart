import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/parking_session_controller.dart';

class FeeSection extends StatelessWidget {
  const FeeSection();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ParkingSessionController>();

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
                  const Text('Accumulated fees',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(
                    '\$${c.accumulatedFees.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.info_outline,
                    color: Colors.grey),
                onPressed: () =>
                    _showFeeBreakdown(context, c),
              ),
            ],
          ),
          const Divider(),
        ],
      ),
    );
  }

  void _showFeeBreakdown(
      BuildContext context, ParkingSessionController c) {
    final billableSeconds = c.elapsed.inSeconds -
        ((c.gracePeriodMinutes ?? 0) * 60);
    final billableMins = billableSeconds <= 0
        ? 0
        : (billableSeconds / 60).floor();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Fee Breakdown'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _breakdownRow('Hourly rate',
                '\$${c.hourlyFee?.toStringAsFixed(2) ?? '-'}'),
            _breakdownRow('Grace period',
                '${c.gracePeriodMinutes ?? '-'} mins'),
            _breakdownRow(
                'Billable time', '$billableMins mins'),
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