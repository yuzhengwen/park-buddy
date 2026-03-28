import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class FamilyHeader extends StatelessWidget {
  final String familyName;
  final String joinCode;
  final bool isOwner;
  final VoidCallback onEditName;

  const FamilyHeader({
    super.key,
    required this.familyName,
    required this.joinCode,
    required this.isOwner,
    required this.onEditName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.grey[200],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  familyName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isOwner)
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  tooltip: 'Edit family name',
                  onPressed: onEditName,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Text("Join Code: "),
              SelectableText(
                joinCode,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.copy, size: 18),
                tooltip: 'Copy join code',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: joinCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Join code copied!')),
                  );
                },
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.share, size: 18),
                tooltip: 'Share join code',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  Share.share(
                    'Join my family on Park Buddy! Use code: $joinCode',
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
