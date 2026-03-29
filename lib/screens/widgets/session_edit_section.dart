import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/parking_session_controller.dart';
import '../../screens/location_picker/location_picker_screen.dart';
import '../../models/carpark.dart';

class SessionEditSection extends StatefulWidget {
  const SessionEditSection({super.key});

  @override
  State<SessionEditSection> createState() => _SessionEditSectionState();
}

class _SessionEditSectionState extends State<SessionEditSection> {
  // Track which field is currently being edited
  String? _editingField; // 'name' | 'description' | 'rate' | 'location'

  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _rateController = TextEditingController();
  String? _pendingLocation;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  void _startEditing(String field, ParkingSessionController c) {
    setState(() {
      _editingField = field;
      // Pre-fill with current values
      _nameController.text = c.session?.sessionName ?? '';
      _descController.text = c.session?.sessionDescription ?? '';
      _rateController.text =
          c.session?.rateThreshold?.toString() ?? '';
      _pendingLocation = c.session?.location;
    });
  }

  void _cancelEditing() {
    setState(() => _editingField = null);
  }

  Future<void> _save(
      BuildContext context, ParkingSessionController c) async {
    try {
      await c.saveDetails(
        sessionName: _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
        sessionDescription: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        rateThreshold: double.tryParse(_rateController.text.trim()),
        location: _pendingLocation,
      );
      setState(() => _editingField = null);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  Future<void> _pickLocation(
      BuildContext context, ParkingSessionController c) async {
    final Carpark? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CarparkPickerScreen(
          initialMapCenter: c.session?.location != null
              ? null // pass LatLng if you have coords stored
              : null,
        ),
      ),
    );
    if (result != null) {
      setState(() => _pendingLocation = result.address);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ParkingSessionController>();

    return Column(
      children: [
        // Session name
        _buildEditableTile(
          context: context,
          controller: c,
          field: 'name',
          icon: Icons.title,
          label: 'Session name',
          currentValue: c.session?.sessionName ?? 'Not set',
          editWidget: TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Session name',
              hintText: 'Enter session name...',
              border: OutlineInputBorder(),
            ),
          ),
        ),

        // Location
        _buildEditableTile(
          context: context,
          controller: c,
          field: 'location',
          icon: Icons.location_on,
          label: 'Location',
          currentValue: c.session?.location ?? 'Not set',
          editWidget: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              _pendingLocation ?? c.session?.location ?? 'Not selected',
              style: const TextStyle(fontSize: 14),
            ),
            trailing: FilledButton(
              onPressed: () => _pickLocation(context, c),
              child: const Text('Change'),
            ),
          ),
        ),

        // Session description
        _buildEditableTile(
          context: context,
          controller: c,
          field: 'description',
          icon: Icons.notes,
          label: 'Description',
          currentValue: c.session?.sessionDescription ?? 'Not set',
          editWidget: TextField(
            controller: _descController,
            decoration: const InputDecoration(
              labelText: 'Session description',
              hintText: 'Enter description...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ),

        // Rate threshold
        _buildEditableTile(
          context: context,
          controller: c,
          field: 'rate',
          icon: Icons.attach_money,
          label: 'Rate threshold',
          currentValue: c.session?.rateThreshold != null
              ? '\$${c.session!.rateThreshold!.toStringAsFixed(2)}'
              : 'Not set',
          editWidget: TextField(
            controller: _rateController,
            decoration: const InputDecoration(
              labelText: 'Rate threshold',
              hintText: '0.00',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(
                decimal: true),
          ),
        ),
      ],
    );
  }

  Widget _buildEditableTile({
    required BuildContext context,
    required ParkingSessionController controller,
    required String field,
    required IconData icon,
    required String label,
    required String currentValue,
    required Widget editWidget,
  }) {
    final isEditing = _editingField == field;

    return Column(
      children: [
        ListTile(
          leading: SizedBox(
            height: 48,
            width: 48,
            child: Icon(icon),
          ),
          title: Text(label),
          subtitle: isEditing ? null : Text(currentValue),
          trailing: isEditing
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _cancelEditing,
                )
              : IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _startEditing(field, controller),
                ),
        ),

        // Inline edit area — only shown when this field is active
        if (isEditing)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                editWidget,
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _cancelEditing,
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: controller.isSavingDetails
                          ? null
                          : () => _save(context, controller),
                      child: controller.isSavingDetails
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white),
                            )
                          : const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        const Divider(height: 1),
      ],
    );
  }
}
