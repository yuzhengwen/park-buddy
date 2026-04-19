import 'package:flutter/material.dart';
import 'package:park_buddy/screens/widgets/family_header.dart';
import 'package:park_buddy/screens/widgets/family_members_list.dart';
import 'package:park_buddy/screens/widgets/generic_dialog_utils.dart';
import '../services/family_service.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  final FamilyService _familyService = FamilyService();
  bool _isLoading = true, isInFamily = false;
  String familyName = "", joinCode = "", ownerId = "";
  List<Map<String, dynamic>> members = [];
  bool get isOwner => _familyService.supabase.auth.currentUser!.id == ownerId;

  @override
  void initState() {
    super.initState();
    loadFamily();
  }

  void _showEditNameDialog() async {
    final newName = await GenericDialogUtils.prompt(
      context: context,
      title: 'Edit Family Name',
      initialValue: familyName,
      labelText: 'Family Name',
      confirmLabel: 'Save',
      maxLength: 50,
      validator: (v) => v.isEmpty ? 'Name cannot be empty' : null,
      sanitize: (v) =>
          v.replaceAll(RegExp(r'\s+'), ' '), // collapse double spaces
    );
    if (newName == null || !mounted) return;
    try {
      await _familyService.updateFamilyName(joinCode, newName);
      setState(() => familyName = newName);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Family name updated')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> loadFamily() async {
    setState(() {
      _isLoading = true;
    });
    final data = await _familyService.getUserFamily();
    if (!mounted)
      return; // Check if widget is still in the tree before calling setState

    setState(() {
      _isLoading = false;
      if (data == null) {
        isInFamily = false;
      } else {
        isInFamily = true;
        familyName = data['familyName'];
        joinCode = data['joinCode'];
        members = List<Map<String, dynamic>>.from(data['members']);
        ownerId = data['ownerId'];
      }
    });
  }

  Future<void> _handleKick(Map<String, dynamic> member) async {
    final username = member['username'];
    if (!await GenericDialogUtils.confirm(
      context: context,
      title: 'Kick Member?',
      message: 'Remove ${member['username']} from the family?',
      confirmLabel: 'Kick',
      destructive: true,
    ))
      return;
    try {
      await _familyService.kickMember(joinCode, member['userid']);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$username has been removed')));
        await loadFamily();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleLeave() async {
    if (!await GenericDialogUtils.confirm(
      context: context,
      title: 'Leave Family?',
      message: 'Are you sure you want to leave the family?',
      confirmLabel: 'Leave',
      destructive: true,
    ))
      return;
    setState(() => _isDeleting = true);
    try {
      await _familyService.leaveFamily(joinCode);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Left family')));
        await loadFamily();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
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
                Navigator.pop(context);
                _joinFamily(enteredCode);
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
    await _familyService.createFamily("My Family");
    await loadFamily(); // this will set isLoading to false after refreshing state
  }

  void _joinFamily(String code) async {
    setState(() => _isLoading = true);
    await _familyService.joinFamily(code);
    await loadFamily();
  }

  bool _isDeleting = false;
  Future<void> _handleDelete() async {
    if (!await GenericDialogUtils.confirm(
      context: context,
      title: 'Delete Family?',
      message:
          'This will remove all members and cars. This action cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    ))
      return;

    setState(() => _isDeleting = true);

    try {
      await _familyService.deleteFamily(joinCode);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Family deleted successfully')),
        );
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // show loading state while fetching family data
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Family Management')),
      body: SafeArea(
        child: isInFamily ? _buildFamilyView() : _buildNoFamilyView(),
      ),
    );
  }

  // When user IS in a family
  Widget _buildFamilyView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FamilyHeader(
          familyName: familyName,
          joinCode: joinCode,
          isOwner: isOwner,
          onEditName: _showEditNameDialog,
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
          child: RefreshIndicator(
            onRefresh: loadFamily,
            child: FamilyMembersList(
              members: members,
              ownerId: ownerId,
              isOwner: isOwner,
              onKick: _handleKick,
            ),
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
                    onPressed: isOwner ? _handleDelete : _handleLeave,
                    child: Text(
                      isOwner ? 'Delete Family' : 'Leave Family',
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

  // When user is NOT in a family
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
