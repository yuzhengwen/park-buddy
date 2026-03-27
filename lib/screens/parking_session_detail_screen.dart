import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ParkingSessionDetailScreen extends StatefulWidget {
  final Map<String, dynamic> session;
  const ParkingSessionDetailScreen({required this.session});

  @override
  State<ParkingSessionDetailScreen> createState() =>
      _ParkingSessionDetailScreenState();
}

class _ParkingSessionDetailScreenState
    extends State<ParkingSessionDetailScreen> {
  // --- State variables ---
  String? driverName;
  String? carName;
  double? hourlyFee;
  int? gracePeriodMinutes;
  List<String> imageUrls = [];
  bool isUploadingImage = false;
  bool isEndingParking = false;
  bool isLoadingSession = true;
  late bool isOngoing;
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  DateTime? _endTime;
  Map<String, dynamic>? _freshSession;

  final _supabase = Supabase.instance.client;
  final _picker = ImagePicker();

  // ─────────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    // Set defaults from passed-in session first so screen
    // isn't blank while the fresh fetch is in flight
    isOngoing = widget.session['parkingendtime'] == null;
    imageUrls = List<String>.from(widget.session['images'] ?? []);
    _fetchSession();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // SESSION GETTER
  // Falls back to the original passed-in session
  // while _freshSession is still loading
  // ─────────────────────────────────────────────

  Map<String, dynamic> get _session => _freshSession ?? widget.session;

  // ─────────────────────────────────────────────
  // TIMER
  // ─────────────────────────────────────────────

  void _startTimer() {
    final start = DateTime.tryParse(
        _session['parkingstarttime']?.toString() ?? '');
    if (start == null) return;
    _elapsed = DateTime.now().difference(start);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed = DateTime.now().difference(start));
    });
  }

  // ─────────────────────────────────────────────
  // DATA FETCHING
  // ─────────────────────────────────────────────

  Future<void> _fetchSession() async {
    final sessionId = widget.session['sessionid'];
    final response = await _supabase
        .from('parkingsession')
        .select()
        .eq('sessionid', sessionId)
        .maybeSingle();

    if (response != null && mounted) {
      final endTimeRaw = response['parkingendtime'];
      final freshIsOngoing = endTimeRaw == null;

      DateTime? freshEndTime;
      Duration freshElapsed = Duration.zero;

      final start = DateTime.tryParse(
          response['parkingstarttime']?.toString() ?? '');

      if (!freshIsOngoing) {
        // Completed session — calculate fixed elapsed from DB values
        final end = DateTime.tryParse(endTimeRaw.toString());
        if (start != null && end != null) {
          freshElapsed = end.difference(start);
          freshEndTime = end;
        }
      }

      setState(() {
        _freshSession = response;
        isOngoing = freshIsOngoing;
        imageUrls = List<String>.from(response['images'] ?? []);
        _endTime = freshEndTime;
        _elapsed = freshElapsed;
        isLoadingSession = false;
      });

      // Start timer only after we know it's truly ongoing
      if (isOngoing) _startTimer();

      // Fetch related data using fresh session values
      _fetchDriverName(response['driverid']);
      _fetchCarName(response['carplate']);
      _fetchFeeDetails(response['location']);
    } else if (mounted) {
      setState(() => isLoadingSession = false);
    }
  }

  Future<void> _fetchDriverName(String? driverId) async {
    if (driverId == null) return;
    final response = await _supabase
        .from('users')
        .select('username')
        .eq('userid', driverId)
        .maybeSingle();
    if (response != null && mounted) {
      setState(() => driverName = response['username']);
    }
  }

  Future<void> _fetchCarName(String? carplate) async {
    if (carplate == null) return;
    final response = await _supabase
        .from('cars')
        .select('carname')
        .eq('carplate', carplate)
        .maybeSingle();
    if (response != null && mounted) {
      setState(() => carName = response['carname']);
    }
  }

  Future<void> _fetchFeeDetails(String? location) async {
    if (location == null) return;

    // Step 1: get feeid from carparks using location
    final carparkResponse = await _supabase
        .from('carparks')
        .select('feeid')
        .eq('location', location)
        .maybeSingle();

    if (carparkResponse == null) return;
    final feeId = carparkResponse['feeid'];
    if (feeId == null) return;

    // Step 2: get hourlyfee and graceperiod from parkingfee
    final feeResponse = await _supabase
        .from('parkingfee')
        .select('hourlyfee, graceperiod')
        .eq('feeid', feeId)
        .maybeSingle();

    if (feeResponse != null && mounted) {
      setState(() {
        hourlyFee = (feeResponse['hourlyfee'] as num).toDouble();
        gracePeriodMinutes = feeResponse['graceperiod'] as int;
      });
    }
  }

  // ─────────────────────────────────────────────
  // CALCULATIONS
  // ─────────────────────────────────────────────

  String get _formattedDuration {
    final h = _elapsed.inHours;
    final m = _elapsed.inMinutes % 60;
    final s = _elapsed.inSeconds % 60;
    return '${h}h ${m}m ${s}s';
  }

  double get _accumulatedFees {
    if (hourlyFee == null || gracePeriodMinutes == null) return 0;
    final billableSeconds =
        _elapsed.inSeconds - (gracePeriodMinutes! * 60);
    if (billableSeconds < 0) return 0;
    final completedHours = (billableSeconds / 3600).floor();
    return completedHours * hourlyFee!;
  }

  // ─────────────────────────────────────────────
  // ACTIONS
  // ─────────────────────────────────────────────

  Future<void> _endParking() async {
    _timer?.cancel();
    setState(() => isEndingParking = true);

    final now = DateTime.now().toIso8601String();
    final sessionId = _session['sessionid'];

    try {
      await _supabase.from('parkingsession').update({
        'parkingendtime': now,
        'currentfees': _accumulatedFees,
      }).eq('sessionid', sessionId);

      if (mounted) {
        setState(() {
          isOngoing = false;
          isEndingParking = false;
          _endTime = DateTime.now();
        });
      }
    } catch (e) {
      _startTimer();
      if (mounted) {
        setState(() => isEndingParking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to end session: $e')),
        );
      }
    }
  }

  Future<void> _uploadImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;
    final picked =
        await _picker.pickImage(source: source, imageQuality: 80);
    if (picked == null) return;

    setState(() => isUploadingImage = true);

    try {
      final sessionId = _session['sessionid'];
      final fileName =
          '$sessionId/${DateTime.now().millisecondsSinceEpoch}.jpg';

      final bytes = await picked.readAsBytes();

      await _supabase.storage
          .from('parking-images')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions:
                const FileOptions(contentType: 'image/jpeg'),
          );

      final publicUrl = _supabase.storage
          .from('parking-images')
          .getPublicUrl(fileName);

      final updatedImages = [...imageUrls, publicUrl];
      await _supabase.from('parkingsession').update({
        'images': updatedImages,
      }).eq('sessionid', sessionId);

      if (mounted) {
        setState(() {
          imageUrls = List<String>.from(updatedImages);
          isUploadingImage = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isUploadingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
    }
  }

  // ─────────────────────────────────────────────
  // DATE FORMATTING
  // ─────────────────────────────────────────────

  String _formatDateTime(dynamic raw) {
  if (raw == null) return '-';
    
    // 1. Add .toLocal() so UTC database times are converted back to the user's local time
    final dt = DateTime.tryParse(raw.toString())?.toLocal(); 
    if (dt == null) return raw.toString();

    // 2. Format for 12-hour clock
    int hour12 = dt.hour % 12;
    if (hour12 == 0) hour12 = 12; // Handle midnight and noon
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';

    return '${_weekday(dt.weekday)} ${dt.day.toString().padLeft(2, '0')} '
        '${_month(dt.month)} ${dt.year} '
        '${hour12.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')} '
        '$amPm';
  }

  String _weekday(int d) =>
      ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d - 1];

  String _month(int m) => [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m - 1];

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Show a loading spinner while the fresh session fetch is in flight
    if (isLoadingSession) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Parking Session',
              style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF6200EA),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parking Session',
            style: TextStyle(color: Colors.white)),
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
                    _detailRow('Session Name',
                        _session['sessionname'] ?? '-'),
                    _detailRow('Parking time',
                        _formatDateTime(_session['parkingstarttime'])),
                    _detailRow(
                      'Parking status',
                      isOngoing
                          ? 'Ongoing'
                          : 'Completed on ${_formatDateTime(_endTime?.toIso8601String() ?? _session['parkingendtime'])}',
                    ),
                    _detailRowWithIcon(
                      'Accumulated fees',
                      '\$${_accumulatedFees.toStringAsFixed(2)}',
                      icon: IconButton(
                        icon: const Icon(Icons.info_outline,
                            color: Colors.grey),
                        onPressed: () => showDialog(
                          context: context,
                          builder: (_) {
                            final billableSeconds = _elapsed.inSeconds -
                                ((gracePeriodMinutes ?? 0) * 60);
                            final billableMins = billableSeconds <= 0
                                ? 0
                                : (billableSeconds / 60).floor();
                            return AlertDialog(
                              title: const Text('Fee Breakdown'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  _feeBreakdownRow('Hourly rate',
                                      '\$${hourlyFee?.toStringAsFixed(2) ?? '-'}'),
                                  _feeBreakdownRow('Grace period',
                                      '${gracePeriodMinutes ?? '-'} mins'),
                                  _feeBreakdownRow('Billable time',
                                      '$billableMins mins'),
                                  const Divider(),
                                  _feeBreakdownRow(
                                    'Total',
                                    '\$${_accumulatedFees.toStringAsFixed(2)}',
                                    bold: true,
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context),
                                  child: const Text('OK'),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    _detailRow(
                        'Driver', driverName ?? 'Loading...'),
                    _detailRowWithIcon(
                      'Location',
                      _session['location'] ?? '-',
                      icon: const Icon(Icons.location_on_outlined,
                          color: Colors.grey),
                    ),
                    _buildPhotosSection(),
                    _detailRow(
                      'Car',
                      '${carName ?? 'Loading...'}, ${_session['carplate'] ?? '-'}',
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
          if (isOngoing) _buildBottomBar(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // PHOTO SECTION
  // ─────────────────────────────────────────────

  Widget _buildPhotosSection() {
    if (imageUrls.isEmpty && !isOngoing) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...imageUrls.map((url) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      url,
                      width: 150,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                          width: 150,
                          height: 120,
                          color: Colors.grey[200]),
                    ),
                  )),
              if (isOngoing)
                GestureDetector(
                  onTap: isUploadingImage ? null : _uploadImage,
                  child: Container(
                    width: 150,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: Colors.grey.shade300),
                    ),
                    child: isUploadingImage
                        ? const Center(
                            child: CircularProgressIndicator())
                        : const Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined,
                                  color: Colors.grey, size: 32),
                              SizedBox(height: 6),
                              Text('Add photo',
                                  style:
                                      TextStyle(color: Colors.grey)),
                            ],
                          ),
                  ),
                ),
            ],
          ),
          const Divider(height: 24),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BOTTOM BAR
  // ─────────────────────────────────────────────

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Parking duration: $_formattedDuration',
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
              onPressed: isEndingParking ? null : _endParking,
              child: isEndingParking
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('END PARKING',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // DETAIL ROW WIDGETS
  // ─────────────────────────────────────────────

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          Text(value,
              style:
                  const TextStyle(fontSize: 14, color: Colors.grey)),
          const Divider(),
        ],
      ),
    );
  }

  Widget _detailRowWithIcon(String label, String value,
      {Widget? icon}) {
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
                      style: const TextStyle(
                          fontSize: 14, color: Colors.grey)),
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

  Widget _feeBreakdownRow(String label, String value,
      {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 14, color: Colors.grey[700])),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      bold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}