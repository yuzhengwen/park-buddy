import 'package:flutter/material.dart';
import '../utils/family_service.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  final FamilyService _familyService = FamilyService();
  bool _isLoading = true;

  late bool isInFamily;
  late String familyName;
  late String joinCode;
  late List<String> members;

  @override
  void initState() {
    super.initState();
    loadFamily();
  }

  Future<void> loadFamily() async {
    setState(() {
      _isLoading = true;
    });
    final data = await _familyService.getUserFamily();

    setState(() {
      _isLoading = false;
      if (data == null) {
        isInFamily = false;
      } else {
        isInFamily = true;
        familyName = data['familyName'];
        joinCode = data['joinCode'];
        members = data['members'];
      }
    });
  }

  void _showJoinDialog() {
    String enteredCode = "";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Join Family"),
          content: TextField(
            decoration: const InputDecoration(hintText: "Enter Join Code"),
            onChanged: (value) {
              enteredCode = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                _joinFamily(enteredCode);
                Navigator.pop(context);
              },
              child: const Text("Join"),
            ),
          ],
        );
      },
    );
  }

  void _createFamily() async {
    setState(() => _isLoading = true);
    final code = await _familyService.createFamily("My Family");
    await loadFamily(); // this will set isLoading to false after refreshing state
  }

  void _joinFamily(String code) async {
    setState(() => _isLoading = true);
    await _familyService.joinFamily(code);
    await loadFamily();
  }

  bool _isDeleting = false;
  Future<void> _handleDelete() async {
    bool confirm = await _showDeleteDialog();
    if (!confirm) return;

    setState(() => _isDeleting = true);

    try {
      // Note: use the 'joinCode' variable that you loaded in loadFamily()
      await _familyService.deleteFamily(joinCode);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Family deleted successfully')),
        );

        // ✅ Refresh the state to show the "No Family" view
        await loadFamily();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Future<bool> _showDeleteDialog() async {
    return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Family?'),
            content: const Text(
              'This will remove all members and cars. This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // show loading state while fetching family data
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Family Management')),
      body: isInFamily ? _buildFamilyView() : _buildNoFamilyView(),
    );
  }

  // ✅ When user IS in a family
  Widget _buildFamilyView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔹 Header section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          color: Colors.grey[200],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                familyName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
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
                ],
              ),
            ],
          ),
        ),

        // 🔹 Members title
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            "Family Members",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),

        // 🔹 Member list
        Expanded(
          child: ListView.builder(
            itemCount: members.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(members[index]),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: SizedBox(
            width: double.infinity,
            child: _isDeleting
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onPressed: _handleDelete,
                    child: const Text(
                      'Delete Family',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // ❌ When user is NOT in a family
  Widget _buildNoFamilyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'You are not in a family',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _showJoinDialog,
            child: const Text('Join Family (Enter Code)'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _createFamily,
            child: const Text('Create Family'),
          ),
        ],
      ),
    );
  }
}
