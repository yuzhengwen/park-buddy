import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/parking_session.dart';

class ParkingSessionService {
  final SupabaseClient _supabase;

  ParkingSessionService([SupabaseClient? client])
      : _supabase = client ?? Supabase.instance.client;

  // ── Validation ────────────────────────────────────────────────────────────

  /// Validates and parses raw rate threshold input from the user.
  ///
  /// - Empty string → returns null (valid boundary case, TC-08)
  /// - Non-numeric or negative → throws the UI error string (TC-06, TC-07)
  /// - Valid non-negative number → returns parsed double (TC-01, TC-08)
  static double? validateRateThreshold(String rawInput) {
    final trimmed = rawInput.trim();
    if (trimmed.isEmpty) return null;

    final parsed = double.tryParse(trimmed);
    if (parsed == null || parsed < 0) {
      throw 'Error: Input a positive numeric number for input threshold';
    }
    return parsed;
  }

  // ── Queries ───────────────────────────────────────────────────────────────

  /// Returns true if [carPlate] already has an ongoing parking session.
  Future<bool> hasActiveSession(String carPlate) async {
    final response = await _supabase
        .from('parkingsession')
        .select()
        .eq('carplate', carPlate)
        .isFilter('parkingendtime', null)
        .limit(1);
    return (response as List).isNotEmpty;
  }

  /// Fetches a single parking session by [sessionId].
  Future<ParkingSession> fetchSession(String sessionId) async {
    final response = await _supabase
        .from('parkingsession')
        .select()
        .eq('sessionid', sessionId)
        .single();
    return ParkingSession.fromMap(response);
  }

  /// Fetches the display name of the driver with [driverId].
  Future<String> fetchDriverName(String driverId) async {
    final response = await _supabase
        .from('users')
        .select('username')
        .eq('userid', driverId)
        .single();
    return response['username'] as String;
  }

  /// Fetches the display name of the car with [carPlate].
  Future<String> fetchCarName(String carPlate) async {
    final response = await _supabase
        .from('cars')
        .select('carname')
        .eq('carplate', carPlate)
        .single();
    return response['carname'] as String;
  }

  // ── Mutations ─────────────────────────────────────────────────────────────

  /// Creates a new parking session.
  ///
  /// Preconditions enforced here:
  /// - User must be authenticated.
  /// - [carPlate] must not already have an active session (TC-04).
  ///
  /// [rateThreshold] must be pre-validated with [validateRateThreshold]
  /// before calling this method.
  Future<ParkingSession> createParkingSession({
    required String carPlate,
    required LatLng carparkLocation,
    required String carparkName,
    String? sessionName,
    String? sessionDescription,
    double? rateThreshold,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw 'User not authenticated';

    // TC-04: reject if this car already has an ongoing session
    if (await hasActiveSession(carPlate)) {
      throw 'Error: Could not create session.';
    }

    final locationStr =
        '(${carparkLocation.latitude},${carparkLocation.longitude})';

    final response = await _supabase
        .from('parkingsession')
        .insert({
          'carplate': carPlate,
          'driverid': user.id,
          'parkingstarttime': DateTime.now().toUtc().toIso8601String(),
          'sessionname': sessionName,
          'sessiondescription': sessionDescription,
          'ratethreshold': rateThreshold,
          'location': locationStr,
          'carparkname': carparkName,
          'images': [],
        })
        .select()
        .single();

    return ParkingSession.fromMap(response);
  }

  /// Ends a parking session by setting its end time and final fee.
  Future<void> endParking(
      String sessionId, DateTime endTime, double fees) async {
    await _supabase
        .from('parkingsession')
        .update({
          'parkingendtime': endTime.toUtc().toIso8601String(),
          'currentfees': fees,
        })
        .eq('sessionid', sessionId);
  }

  /// Replaces the image URL list for a session.
  Future<void> updateSessionImages(
      String sessionId, List<String> imageUrls) async {
    await _supabase
        .from('parkingsession')
        .update({'images': imageUrls})
        .eq('sessionid', sessionId);
  }

  /// Updates editable session metadata (name, description, rate, location).
  Future<void> updateSessionDetails({
    required String sessionId,
    String? sessionName,
    String? sessionDescription,
    double? rateThreshold,
    String? location,
    String? carparkName,
  }) async {
    await _supabase
        .from('parkingsession')
        .update({
          'sessionname': sessionName,
          'sessiondescription': sessionDescription,
          'ratethreshold': rateThreshold,
          'location': location,
          'carparkname': carparkName,
        })
        .eq('sessionid', sessionId);
  }
}
