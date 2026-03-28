import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/parking_session.dart';
import '../services/parking_session_service.dart';
import '../services/storage_service.dart';
import 'dart:typed_data'; 

class ParkingSessionController extends ChangeNotifier {
  final ParkingSessionService _sessionService;
  final StorageService _storageService;
  final Map<String, dynamic> initialSession;

  ParkingSessionController({
    required this.initialSession,
    ParkingSessionService? sessionService,
    StorageService? storageService,
  })  : _sessionService =
            sessionService ?? ParkingSessionService(),
        _storageService = storageService ?? StorageService();

  // ── State ─────────────────────────────────────
  ParkingSession? session;
  String? driverName;
  String? carName;
  double? hourlyFee;
  int? gracePeriodMinutes;
  bool isLoadingSession = true;
  bool isEndingParking = false;
  bool isUploadingImage = false;
  String? errorMessage;
  Duration elapsed = Duration.zero;
  Timer? _timer;
  bool isSavingDetails = false;

  // ── Derived state ─────────────────────────────
  bool get isOngoing => session?.isOngoing ?? true;
  List<String> get imageUrls => session?.images ?? [];

  double get accumulatedFees {
    if (hourlyFee == null || gracePeriodMinutes == null) return 0;
    final billableSeconds =
        elapsed.inSeconds - (gracePeriodMinutes! * 60);
    if (billableSeconds < 0) return 0;
    return (billableSeconds / 3600).floor() * hourlyFee!;
  }

  String get formattedDuration {
    final h = elapsed.inHours;
    final m = elapsed.inMinutes % 60;
    final s = elapsed.inSeconds % 60;
    return '${h}h ${m}m ${s}s';
  }

  // ── Init ──────────────────────────────────────
  Future<void> init() async {
    final sessionId = initialSession['sessionid'] as String;

    try {
      session = await _sessionService.fetchSession(sessionId);

      if (!session!.isOngoing && session!.endTime != null
          && session!.startTime != null) {
        elapsed = session!.endTime!.difference(session!.startTime!);
      }

      isLoadingSession = false;
      notifyListeners();

      if (session!.isOngoing) _startTimer();

      // Fetch supplementary data in parallel
      await Future.wait([
        _loadDriverName(),
        _loadCarName(),
        _loadFeeDetails(),
      ]);
    } catch (e) {
      errorMessage = 'Failed to load session: $e';
      isLoadingSession = false;
      notifyListeners();
    }
  }

  // ── Timer ─────────────────────────────────────
  void _startTimer() {
    final start = session?.startTime;
    if (start == null) return;
    elapsed = DateTime.now().difference(start);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      elapsed = DateTime.now().difference(start);
      notifyListeners();
    });
  }

  // ── Private loaders ───────────────────────────
  Future<void> _loadDriverName() async {
    if (session?.driverId == null) return;
    try {
      driverName = await _sessionService
          .fetchDriverName(session!.driverId!);
      notifyListeners();
    } catch (_) {
      driverName = 'Unknown';
      notifyListeners();
    }
  }

  Future<void> _loadCarName() async {
    if (session?.carPlate == null) return;
    try {
      carName =
          await _sessionService.fetchCarName(session!.carPlate!);
      notifyListeners();
    } catch (_) {
      carName = 'Unknown';
      notifyListeners();
    }
  }

  Future<void> _loadFeeDetails() async {
    if (session?.location == null) return;
    try {
      final details = await _sessionService
          .fetchFeeDetails(session!.location!);
      if (details != null) {
        hourlyFee = details.hourlyFee;
        gracePeriodMinutes = details.gracePeriod;
        notifyListeners();
      }
    } catch (_) {} // Fee details failing is non-critical
  }

  // ── Actions ───────────────────────────────────
  Future<void> endParking() async {
    _timer?.cancel();
    isEndingParking = true;
    notifyListeners();

    final now = DateTime.now();
    try {
      await _sessionService.endParking(
          session!.sessionId, now, accumulatedFees);
      session = session!.copyWith(
        endTime: now,
        currentFees: accumulatedFees,
      );
    } catch (e) {
      _startTimer(); // Restart if failed
      isEndingParking = false;
      notifyListeners();
      rethrow; // Screen handles the snackbar
    }

    isEndingParking = false;
    notifyListeners();
  }

  Future<void> uploadImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: source, imageQuality: 80);
    if (picked == null) return;

    isUploadingImage = true;
    notifyListeners();

    try {
      final Uint8List bytes = await picked.readAsBytes();
      final url = await _storageService.uploadImage(
          session!.sessionId, bytes);

      final updatedImages = [...imageUrls, url];
      await _sessionService.updateSessionImages(
          session!.sessionId, updatedImages);

      session = session!.copyWith(images: updatedImages);
    } catch (e) {
      isUploadingImage = false;
      notifyListeners();
      rethrow; // Screen handles the snackbar
    }

    isUploadingImage = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  Future<void> saveDetails({
    required String? sessionName,
    required String? sessionDescription,
    required double? rateThreshold,
    required String? location,
  }) async {
    isSavingDetails = true;
    notifyListeners();

    try {
      await _sessionService.updateSessionDetails(
        sessionId: session!.sessionId,
        sessionName: sessionName,
        sessionDescription: sessionDescription,
        rateThreshold: rateThreshold,
        location: location,
      );
      session = session!.copyWith(
        sessionName: sessionName,
        sessionDescription: sessionDescription,
        rateThreshold: rateThreshold,
        location: location,
      );
    } catch (e) {
      isSavingDetails = false;
      notifyListeners();
      rethrow;
    }

    isSavingDetails = false;
    notifyListeners();
  }
}