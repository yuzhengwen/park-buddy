import 'package:flutter/material.dart';

class FeeSection extends StatelessWidget {
  final double accumulatedFees;
  final Duration elapsed;
  final int gracePeriodMinutes;
  final bool isInCentralArea;
  final double currentHalfHourRate;
  final int completedBlocks; // Pass this in from controller

  const FeeSection({
    super.key,
    required this.accumulatedFees,
    required this.elapsed,
    required this.gracePeriodMinutes,
    required this.isInCentralArea,
    required this.currentHalfHourRate,
    required this.completedBlocks,
  });

  @override
  Widget build(BuildContext context) {
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
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(
                    '\$${accumulatedFees.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.grey),
                onPressed: () => _showBreakdown(context),
              ),
            ],
          ),
          const Divider(),
        ],
      ),
    );
  }

  void _showBreakdown(BuildContext context) {
    final billableSeconds = elapsed.inSeconds - (gracePeriodMinutes * 60);
    final billableMins = billableSeconds <= 0 ? 0 : billableSeconds ~/ 60;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Fee Breakdown'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _breakdownRow('Zone', isInCentralArea ? 'Central area' : 'Outside central'),
            _breakdownRow('Current rate', '\$${currentHalfHourRate.toStringAsFixed(2)} / 30 min'),
            _breakdownRow('Grace period', '$gracePeriodMinutes mins'),
            _breakdownRow('Billable time', '$billableMins mins'),
            _breakdownRow('Completed blocks', '$completedBlocks × 30 min'),
            const Divider(),
            _breakdownRow(
              'Total',
              '\$${accumulatedFees.toStringAsFixed(2)}',
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

  Widget _breakdownRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}