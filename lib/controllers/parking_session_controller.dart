import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../models/parking_session.dart';
import '../services/parking_alert_service.dart';
import '../services/parking_session_service.dart';
import '../services/storage_service.dart';
import '../utils/hdb_fee_calculator.dart';
class ParkingSessionController extends ChangeNotifier {
  final ParkingSessionService _sessionService;
  final StorageService _storageService;
  final Map<String, dynamic> initialSession;

  ParkingSessionController({
    required this.initialSession,
    ParkingSessionService? sessionService,
    StorageService? storageService,
  })  : _sessionService = sessionService ?? ParkingSessionService(),
        _storageService = storageService ?? StorageService();

  // ── State ─────────────────────────────────────
  ParkingSession? session;
  String? driverName;
  String? carName;
  bool isLoadingSession = true;
  bool isEndingParking = false;
  bool isUploadingImage = false;
  bool isSavingDetails = false;
  String? errorMessage;
  Duration elapsedTime = Duration.zero;
  Timer? _timer;
  CalculationResult? _lastResult;
  final ParkingAlertService _alertService = ParkingAlertService();

  // ── Derived state ─────────────────────────────
  bool get isOngoing => session?.isOngoing ?? true;
  List<String> get imageUrls => session?.images ?? [];

  int get gracePeriodMinutes => HdbFeeCalculator.gracePeriodMinutes;
  int get completedBlocks {
    if (session?.startTime == null) return 0;
    
    final int billableSeconds = elapsedTime.inSeconds - (gracePeriodMinutes * 60);
    if (billableSeconds <= 0) return 0;
    
    return (billableSeconds + 1799) ~/ 1800;
  }  double get accumulatedFees => _lastResult?.totalFee ?? 0.0;

  bool get isInCentralArea => _lastResult?.isCentral ?? false;

  double get currentHalfHourRate {
    if (!isInCentralArea) return HdbFeeCalculator.rateOutside;
    return HdbFeeCalculator.isPeakNow() 
        ? HdbFeeCalculator.rateCentralPeak
        : HdbFeeCalculator.rateCentralOffPeak;
  }

  String get formattedDuration {
    final h = elapsedTime.inHours;
    final m = elapsedTime.inMinutes % 60;
    final s = elapsedTime.inSeconds % 60;
    return '${h}h ${m}m ${s}s';
  }

  // ── Init ──────────────────────────────────────
  Future<void> init() async {
    final sessionId = initialSession['sessionid'] as String;

    try {
      session = await _sessionService.fetchSession(sessionId);

      if (!session!.isOngoing &&
          session!.endTime != null &&
          session!.startTime != null) {
        elapsedTime = session!.endTime!.difference(session!.startTime!);
      }

      _updateFees();
      isLoadingSession = false;
      notifyListeners();

      if (session!.isOngoing) {
        _startTimer();
        await _scheduleThresholdAlert();
      }

      await Future.wait([
        _loadDriverName(),
        _loadCarName(),
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
    
    // Ensure UTC consistency
    elapsedTime = DateTime.now().toUtc().difference(start.toUtc());
    _updateFees();
    
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      elapsedTime = DateTime.now().toUtc().difference(start.toUtc());
      _updateFees(); // Recalculate fees and blocks every second
      notifyListeners();
    });
  }
  // ── Loaders ───────────────────────────
  Future<void> _loadDriverName() async {
    if (session?.driverId == null) return;
    try {
      driverName =
          await _sessionService.fetchDriverName(session!.driverId!);
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

  // ── Actions ───────────────────────────────────
  Future<void> endParking() async {
    _timer?.cancel();
    isEndingParking = true;
    notifyListeners();

    final now = DateTime.now();
    try {
      await _sessionService.endParking(
          session!.sessionId, now, accumulatedFees);
      await _alertService.cancelThresholdAlert(session!.sessionId);
      session = session!.copyWith(
        endTime: now,
        currentFees: accumulatedFees,
      );
    } catch (e) {
      _startTimer();
      isEndingParking = false;
      notifyListeners();
      rethrow;
    }

    isEndingParking = false;
    notifyListeners();
  }

  // ── Alert scheduling ──────────────────────────────────────────────────────
  Future<void> _scheduleThresholdAlert() async {
    final sess = session;
    if (sess == null || !sess.isOngoing || sess.startTime == null) return;

    final threshold = sess.rateThreshold;
    if (threshold == null) {
      await _alertService.cancelThresholdAlert(sess.sessionId);
      return;
    }

    final alertTime = HdbFeeCalculator.calculateThresholdTime(
      startTime: sess.startTime!,
      threshold: threshold,
      carparkPosition: sess.carparkPosition,
    );

    if (alertTime == null) {
      // Threshold too high to ever be exceeded — cancel any stale alert.
      await _alertService.cancelThresholdAlert(sess.sessionId);
      return;
    }

    await _alertService.scheduleThresholdAlert(
      sessionId: sess.sessionId,
      carparkName: sess.carparkName,
      threshold: threshold,
      alertTime: alertTime,
    );
  }

  void _updateFees() {
    if (session?.carparkPosition == null || session?.startTime == null) return;
    
    _lastResult = HdbFeeCalculator.calculate(
      elapsedTime: elapsedTime,
      startTime: session!.startTime!,
      carparkPosition: session!.carparkPosition!,
    );
  }

  Future<void> uploadImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: source, imageQuality: 80);
    if (picked == null) return;

    isUploadingImage = true;
    notifyListeners();

    try {
      final bytes = await picked.readAsBytes();
      final url = await _storageService.uploadImage(
        bucket: "parking-images",
        folder: session!.sessionId,
        bytes: bytes,
      );

      final updatedImages = [...imageUrls, url];
      await _sessionService.updateSessionImages(
          session!.sessionId, updatedImages);

      session = session!.copyWith(images: updatedImages);
    } catch (e) {
      isUploadingImage = false;
      notifyListeners();
      rethrow;
    }

    isUploadingImage = false;
    notifyListeners();
  }

  Future<void> saveDetails({
    required String? sessionName,
    required String? sessionDescription,
    required double? rateThreshold,
    required String? location,
    String? carparkName,
    LatLng? carparkPosition,
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
        carparkName: carparkName,
      );
      session = session!.copyWith(
        sessionName: sessionName,
        sessionDescription: sessionDescription,
        rateThreshold: rateThreshold,
        location: location,
        carparkName: carparkName,
        carparkPosition: carparkPosition,
      );
      await _scheduleThresholdAlert();
    } catch (e) {
      isSavingDetails = false;
      notifyListeners();
      rethrow;
    }

    isSavingDetails = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    // Note: we intentionally do NOT cancel the scheduled OS notification here.
    // The notification should still fire even after the user leaves the screen,
    // so they are alerted while the app is in the background.
    super.dispose();
  }
}