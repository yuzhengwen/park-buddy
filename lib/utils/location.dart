import 'dart:async';
import 'package:geolocator/geolocator.dart';

class _TrackingCallbacks {
  final void Function(Position? location) onLocationUpdate;
  final void Function(Object error)? onError;
  final int distanceFilter;

  const _TrackingCallbacks({
    required this.onLocationUpdate,
    required this.onError,
    required this.distanceFilter,
  });
}

/// 
class LocationService {
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<ServiceStatus>? _statusSubscription;
  bool _disposed = false;

  /// Check for and handle location permissions.
  static Future<void> obtainPermissions() async {
    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied.');
      }
    }
  }

  /// Do the necessary setup for live location tracking, including handling
  /// permissions and setting up update streams. To be called from initState()
  /// or similar.
  ///
  /// onLocationUpdate is called with the new location whenever location
  /// changes. It is also called with null argument when location is disabled.
  Future<void> begin({
    required void Function(Position?) onLocationUpdate,
    void Function(Object)? onError,
    int distanceFilter = 10,
  }) async {
    // Don't set up anything if no permissions granted
    try {
      await obtainPermissions();
    } catch (e) {
      onError?.call(e);
      return;
    }

    final trackingCallbacks = _TrackingCallbacks(
      onLocationUpdate: onLocationUpdate,
      onError: onError,
      distanceFilter: distanceFilter,
    );

    _beginStatusTracking(trackingCallbacks);
    await _beginLocationTracking(trackingCallbacks);
  }

  /// Start listening to updates to location. No-op if already listening.
  Future<void> _beginLocationTracking(_TrackingCallbacks trackingCallbacks) async {
    if (_positionSubscription != null) return;

    // Bootstrap the first location update, otherwise the location tracker
    // callback isn't called until the position changes
    await _getInitialLocation(trackingCallbacks);

    // Register callbacks with position stream
    _positionSubscription = Geolocator
        .getPositionStream(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: trackingCallbacks.distanceFilter,
          ),
        )
        .listen(
          (position) {
            if (!_disposed) trackingCallbacks.onLocationUpdate(position);
          },
          onError: (e) {
            if (!_disposed) {
              trackingCallbacks.onError?.call(e);
            }
          },
        );
  }

  Future<void> _getInitialLocation(_TrackingCallbacks trackingCallbacks) async {
    if (_disposed) return;
    try {
      final initialPosition = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: trackingCallbacks.distanceFilter,
          timeLimit: const Duration(seconds: 20),
        ),
      );
      trackingCallbacks.onLocationUpdate(initialPosition);

    } on TimeoutException catch (e) {
      trackingCallbacks.onError?.call(e);
    }
  }

  /// Start listening for when location services are toggled on/off. No-op if
  /// already listening.
  void _beginStatusTracking(_TrackingCallbacks trackingCallbacks) {
    _statusSubscription ??= Geolocator
        .getServiceStatusStream()
        .listen(
          (status) {
            if (_disposed) return;

            // Cancel any leftover location trackers
            _stopLocationTracking();
            if (status == ServiceStatus.disabled) {
              trackingCallbacks.onLocationUpdate(null);
            } else {
              _beginLocationTracking(trackingCallbacks);
            }
          },
          onError: (e) {
            if (!_disposed) {
              trackingCallbacks.onError?.call(e);
            }
          },
        );
  }

  /// Stop tracking location. Location service status updates remain tracked
  /// so that the location tracker may be revived later.
  void _stopLocationTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  /// Fully tears down all streams. The instance cannot be reused after this.
  void dispose() {
    _disposed = true;
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _statusSubscription?.cancel();
    _statusSubscription = null;
  }
}
