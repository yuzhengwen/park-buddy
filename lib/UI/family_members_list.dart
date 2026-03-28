import 'package:flutter/material.dart';

class FamilyMembersList extends StatelessWidget {
  final List<Map<String, dynamic>> members;
  final String ownerId;

  const FamilyMembersList({
    super.key,
    required this.members,
    required this.ownerId,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        final isOwner = member['userid'] == ownerId;
        return ListTile(
          leading: const Icon(Icons.person),
          title: Row(
            children: [
              Text(member['username']),
              if (isOwner)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'OWNER',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
