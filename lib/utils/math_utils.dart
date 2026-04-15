import 'package:latlong2/latlong.dart';

class MathUtils {
  static const distance = Distance(roundResult: false);

  static double distanceKm(LatLng from, LatLng to) {
    return distance.as(LengthUnit.Kilometer, from, to);
  }
}
