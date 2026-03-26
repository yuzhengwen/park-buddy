import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ParkingSessionDetailScreen extends StatefulWidget {
  final Map<String, dynamic> session;

  const ParkingSessionDetailScreen({required this.session});

  @override
  State<ParkingSessionDetailScreen> createState() => _ParkingSessionDetailScreenState();
}

class _ParkingSessionDetailScreenState extends State<ParkingSessionDetailScreen> {
  String? driverName;
  String? carName;

  @override
  void initState() {
    super.initState();
    _fetchDriverName();
    _fetchCarName();
  }

  Future<void> _fetchDriverName() async {

    final driverId = widget.session['driverid'];
    if (driverId == null) return;

    final response = await Supabase.instance.client
        .from('users')
        .select('username')
        .eq('userid', driverId)
        .maybeSingle();

    if (response != null && mounted) {
      setState(() => driverName = response['username']);
    }
  }

  Future<void> _fetchCarName() async {

    final carplate = widget.session['carplate'];
    if (carplate == null) return;

    final response = await Supabase.instance.client
        .from('cars')
        .select('carname')
        .eq('carplate', carplate)
        .maybeSingle();

    if (response != null && mounted) {
      setState(() => carName = response['carname']);
    }
  }

  String _formatDateTime(dynamic raw) {
    if (raw == null) return '-';
    final dt = DateTime.tryParse(raw.toString());
    if (dt == null) return raw.toString();
    return '${_weekday(dt.weekday)} ${dt.day.toString().padLeft(2, '0')} '
        '${_month(dt.month)} ${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')} '
        '${dt.hour >= 12 ? 'PM' : 'AM'}';
  }

  String _weekday(int d) =>
      ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d - 1];

  String _month(int m) =>
      ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
       'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m - 1];

  String _parkingDuration() {
    final start = DateTime.tryParse(widget.session['parkingstarttime']?.toString() ?? '');
    if (start == null) return '';
    final end = widget.session['parkingendtime'] != null
        ? DateTime.tryParse(widget.session['parkingendtime'].toString())
        : DateTime.now();
    if (end == null) return '';
    final diff = end.difference(start);
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    return '${h}h ${m}min';
  }

  @override
  Widget build(BuildContext context) {
    final bool isOngoing = widget.session['parkingendtime'] == null;
    final List<dynamic> images = widget.session['images'] ?? [];
    final fees = widget.session['currentfees'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parking Session', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF6200EA),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _detailRow('Session Name', widget.session['sessionname'] ?? '-'),
                    _detailRow(
                      'Parking time',
                      _formatDateTime(widget.session['parkingstarttime']),
                    ),
                    _detailRow(
                      'Parking status',
                      isOngoing ? 'Ongoing' : 'Completed on ${_formatDateTime(widget.session['parkingendtime'])}',
                    ),
                    _detailRowWithIcon(
                      'Accumulated fees',
                      '\$${fees ?? 0}',
                      icon: IconButton(
                        icon: const Icon(Icons.info_outline, color: Colors.grey),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              content: const Text('Fees accumulated since parking started.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('OK'),
                                )
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    _detailRow('Driver', driverName ?? 'Loading...'),
                    _detailRowWithIcon(
                      'Location',
                      widget.session['location'] ?? '-',
                      icon: const Icon(Icons.location_on_outlined, color: Colors.grey),
                    ),

                    // Car photos
                    if (images.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 160,
                        child: Row(
                          children: images.take(2).map<Widget>((url) {
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    url.toString(),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        Container(color: Colors.grey[200]),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    _detailRow('Car', "$carName, ${widget.session['carplate']}"),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),

          // Bottom bar
          if (isOngoing)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Parking duration: ${_parkingDuration()}',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6200EA),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        // TODO: implement end parking logic
                      },
                      child: const Text(
                        'END PARKING',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const Divider(),
        ],
      ),
    );
  }

  Widget _detailRowWithIcon(String label, String value, {Widget? icon}) {
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
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(value,
                      style: const TextStyle(fontSize: 14, color: Colors.grey)),
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