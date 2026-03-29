import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../models/parking_session.dart';
import '../services/parking_session_service.dart';
import '../services/storage_service.dart';
import '../utils/hdb_fee_calculator.dart';
import '../utils/central_area_checker.dart';

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
  Duration elapsed = Duration.zero;
  Timer? _timer;
  CalculationResult? _lastResult;

  // ── Removed: hourlyFee, gracePeriodMinutes ────
  // Fee is now calculated entirely by HdbFeeCalculator

  // ── Derived state ─────────────────────────────
  bool get isOngoing => session?.isOngoing ?? true;
  List<String> get imageUrls => session?.images ?? [];

  // Grace period exposed for UI display only
  int get gracePeriodMinutes => HdbFeeCalculator.gracePeriodMinutes;
  int get completedBlocks {
    if (session?.startTime == null) return 0;
    
    // Use integer math: (seconds + 1799) ~/ 1800
    final int billableSeconds = elapsed.inSeconds - (gracePeriodMinutes * 60);
    if (billableSeconds <= 0) return 0;
    
    return (billableSeconds + 1799) ~/ 1800;
  }  double get accumulatedFees => _lastResult?.totalFee ?? 0.0;

    // Whether this carpark is in the central area — exposed for UI
  bool get isInCentralArea => _lastResult?.isCentral ?? false;

  // Current applicable half-hour rate — exposed for fee breakdown UI
  double get currentHalfHourRate {
    if (!isInCentralArea) return HdbFeeCalculator.rateOutside;
    return HdbFeeCalculator.isPeakNow() 
        ? HdbFeeCalculator.rateCentralPeak
        : HdbFeeCalculator.rateCentralOffPeak;
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

      if (!session!.isOngoing &&
          session!.endTime != null &&
          session!.startTime != null) {
        elapsed = session!.endTime!.difference(session!.startTime!);
      }

      _updateFees();
      isLoadingSession = false;
      notifyListeners();

      if (session!.isOngoing) _startTimer();

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
    elapsed = DateTime.now().toUtc().difference(start.toUtc());
    _updateFees();
    
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      elapsed = DateTime.now().toUtc().difference(start.toUtc());
      _updateFees(); // Recalculate fees and blocks every second
      notifyListeners();
    });
  }
  // ── Private loaders ───────────────────────────
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

  void _updateFees() {
    if (session?.carparkPosition == null || session?.startTime == null) return;
    
    _lastResult = HdbFeeCalculator.calculate(
      elapsed: elapsed,
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
          session!.sessionId, bytes);

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
      );
      session = session!.copyWith(
        sessionName: sessionName,
        sessionDescription: sessionDescription,
        rateThreshold: rateThreshold,
        location: location,
        carparkPosition: carparkPosition,
      );
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
    super.dispose();
  }
}