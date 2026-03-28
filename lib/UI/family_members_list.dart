import 'package:flutter/material.dart';

class FamilyMembersList extends StatelessWidget {
  final List<Map<String, dynamic>> members;
  final String ownerId;
  final bool isOwner;
  final void Function(Map<String, dynamic> member)? onKick;

  const FamilyMembersList({
    super.key,
    required this.members,
    required this.ownerId,
    this.isOwner = false,
    this.onKick,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        final isMemberOwner = member['userid'] == ownerId;
        return ListTile(
          leading: const Icon(Icons.person),
          title: Row(
            children: [
              Text(member['username']),
              if (isMemberOwner)
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
          trailing: isOwner && !isMemberOwner
              ? IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                  onPressed: () => onKick?.call(member),
                )
              : null,
        );
      },
    );
  }
}
