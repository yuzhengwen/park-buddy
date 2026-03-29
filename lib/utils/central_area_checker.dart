import 'package:latlong2/latlong.dart';

/// Determines if a given LatLng falls within Singapore's central area
/// for the purpose of HDB short-term parking fee calculation.
///
/// HOW TO MODIFY THE BOUNDARY:
/// The central area is defined by [_centralAreaPolygon] — a list of
/// LatLng points that form a closed polygon (the last point connects
/// back to the first automatically).
///
/// To ADD a new boundary zone (e.g. a future extended zone):
///   1. Create a new static const List<LatLng> with your new polygon points
///   2. Add it to [_allZones] list at the bottom
///   Any carpark inside ANY of the zones will be treated as central area.
///
/// To MODIFY the existing boundary:
///   1. Go to https://www.latlong.net/ to find coordinates of your boundary points
///   2. Replace or add points in [_centralAreaPolygon] in order (clockwise or
///      counter-clockwise, just be consistent)
///   3. You need at least 3 points to form a valid polygon

class CentralAreaChecker {
  CentralAreaChecker._(); // Static use only

  /// Main central area polygon covering:
  /// Orchard → Marina Bay → Tanjong Pagar → Outram → Rochor → back
  /// Based on URA's Central Area definition for parking charges
  static const List<LatLng> _centralAreaPolygon = [
    LatLng(1.3138, 103.8159), // Outram / Tiong Bahru
    LatLng(1.2972, 103.8345), // HarbourFront / Telok Blangah
    LatLng(1.2765, 103.8508), // Sentosa / Mt Faber fringe
    LatLng(1.2700, 103.8590), // Southern tip
    LatLng(1.2750, 103.8700), // Marina South
    LatLng(1.2795, 103.8780), // Marina East
    LatLng(1.2895, 103.8650), // Marina Bay Sands area
    LatLng(1.3030, 103.8620), // Raffles Place / CBD
    LatLng(1.3100, 103.8640), // Tanjong Pagar
    LatLng(1.3200, 103.8640), // Shenton Way
    LatLng(1.3300, 103.8600), // Chinatown / Clarke Quay
    LatLng(1.3370, 103.8500), // Fort Canning
    LatLng(1.3420, 103.8450), // Dhoby Ghaut
    LatLng(1.3090, 103.8190), // Orchard / Somerset fringe
    LatLng(1.3138, 103.8159), // Close polygon back to start
  ];

  // ── Add new zone polygons here ──────────────────
  // Example: if a new extended zone is gazetted in the future,
  // define it as a new list and add it to _allZones below.
  //
  // static const List<LatLng> _newZonePolygon = [
  //   LatLng(1.3500, 103.8700),
  //   LatLng(1.3600, 103.8800),
  //   LatLng(1.3700, 103.8700),
  //   LatLng(1.3500, 103.8700),
  // ];

  /// All zones that count as central area.
  /// Add new polygon lists here to include them automatically.
  static const List<List<LatLng>> _allZones = [
    _centralAreaPolygon,
    // _newZonePolygon, // ← uncomment when ready
  ];

  /// Returns true if the given position is inside any central area zone
  static bool isCentralArea(LatLng position) {
    return _allZones.any((zone) => _isInsidePolygon(position, zone));
  }  

  /// Ray-casting algorithm — counts how many times a ray from the point
  /// crosses the polygon boundary. Odd = inside, Even = outside.
  static bool _isInsidePolygon(LatLng point, List<LatLng> polygon) {
    int intersections = 0;
    final double lat = point.latitude;
    final double lng = point.longitude;
    final int n = polygon.length;

    for (int i = 0; i < n; i++) {
      final LatLng a = polygon[i];
      final LatLng b = polygon[(i + 1) % n];

      final bool longitudeInRange =
          (a.longitude <= lng && lng < b.longitude) ||
          (b.longitude <= lng && lng < a.longitude);

      if (longitudeInRange) {
        final double intersectLat =
            (b.latitude - a.latitude) *
                (lng - a.longitude) /
                (b.longitude - a.longitude) +
            a.latitude;

        if (lat < intersectLat) {
          intersections++;
        }
      }
    }

    return intersections % 2 == 1;
  }
}