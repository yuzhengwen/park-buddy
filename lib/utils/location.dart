// source: https://pub.dev/packages/geolocator#example
import 'dart:async';
import 'package:geolocator/geolocator.dart';

class LocationService {
  StreamSubscription<Position>? _subscription;

  Future<void> assessPermissions() async {
    final isLocationEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isLocationEnabled) {
      return Future.error('Location services are disabled.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    if (permission == LocationPermission.unableToDetermine) {
      return Future.error('Unable to determine location permissions.');
    }
  }

  Future<void> beginLocationTracking({
    required void Function(Position) onLocationUpdate,
    void Function(Object)? onError,
    int distanceFilter = 10,
  }) async {
    try {
      await assessPermissions();
    } catch (e) {
      onError?.call(e);
      return;
    }

    final settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: distanceFilter,
      timeLimit: Duration(seconds: 5),
    );

    _subscription = Geolocator
        .getPositionStream(locationSettings: settings)
        .listen(
          onLocationUpdate,
          onError: onError,
        );

    final initialPosition = await Geolocator
        .getCurrentPosition(locationSettings: settings);

    onLocationUpdate(initialPosition);
  }

  void dispose() {
    _subscription?.cancel();
  }
}
