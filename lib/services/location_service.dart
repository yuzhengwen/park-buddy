import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

/// Provides user location information and events.
class LocationService extends ChangeNotifier {
  static const _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
  );

  Position? _location, _prevLocation;
  String _statusMessage = '';
  StreamSubscription<Position>? _locationStream;
  StreamSubscription<ServiceStatus>? _locationStatusStream;
  final _locationAvailableStream = StreamController<bool>.broadcast();

  /// Tracks the location of the user, or [null] if location is not available
  /// (location is disabled, no permissions, other errors, etc.).
  LatLng? get currentLocation => _location != null
      ? LatLng(_location!.latitude, _location!.longitude)
      : null;

  /// Stream that notifies when location services become available/unavailable.
  Stream<bool> get locationAvailableStream => _locationAvailableStream.stream;

  /// Relevant location debug messages.
  String get statusMessage => _statusMessage;

  @override
  void dispose() {
    _locationAvailableStream.close();
    super.dispose();
  }

  Future<bool> requestPermissions() async {
    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.deniedForever) {
      _statusMessage = 'Location permission is permanently denied. Open settings to allow it.';
      notifyListeners();
      return false;
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _statusMessage = 'Location permission denied.';
        notifyListeners();
        return false;
      }
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _statusMessage = 'Location services are turned off. Please enable GPS.';
      notifyListeners();
      return false;
    }

    return true;
  }

  Future<void> startLiveLocation() async {
    _statusMessage = 'Preparing live location...';
    notifyListeners();

    final isGranted = await requestPermissions();
    if (isGranted) {
      final location = await Geolocator.getCurrentPosition(
        locationSettings: _locationSettings,
      );
      _setLocation(location);
      notifyListeners();
    }

    await _locationStream?.cancel();
    _locationStream = Geolocator
        .getPositionStream(locationSettings: _locationSettings)
        .listen(
          (location) {
            _setLocation(location);
            notifyListeners();
          },
          onError: (error) {
            _statusMessage = 'Unable to track location: $error';
            notifyListeners();
          },
        );

    await _locationStatusStream?.cancel();
    _locationStatusStream = Geolocator
        .getServiceStatusStream()
        .listen(
          (status) {
            _setStatus(status);
            notifyListeners();
          },
          onError: (error) {
            _statusMessage = 'Unable to get location service status: $error';
            notifyListeners();
          },
        );
  }

  Future<void> _setStatus(ServiceStatus status) async {
    if (status == ServiceStatus.disabled) {
      _setLocation(null);
      notifyListeners();

    } else {
      final location = await Geolocator.getCurrentPosition(
        locationSettings: _locationSettings,
      );
      _setLocation(location);
      _statusMessage = 'Location enabled.';
      notifyListeners();
    }
  }

  void _setLocation(Position? location) {
    _location = location;
    _statusMessage = location != null
        ? 'Location updated.'
        : 'Location disabled.';

    if (_prevLocation == null && location != null) {
      _locationAvailableStream.add(true);
      _prevLocation = location;

    } else if (_prevLocation != null && location == null) {
      _locationAvailableStream.add(false);
      _prevLocation = location;
    }
  }
}
