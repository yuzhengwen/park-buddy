import 'dart:math' as math;

class Svy21Coordinate {
  const Svy21Coordinate({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}

class Svy21Converter {
  const Svy21Converter();

  static const double _a = 6378137;
  static const double _f = 1 / 298.257223563;
  static const double _originLat = 1.366666;
  static const double _originLon = 103.833333;
  static const double _falseNorthing = 38744.572;
  static const double _falseEasting = 28001.642;
  static const double _scaleFactor = 1.0;

  Svy21Coordinate toLatLng({
    required double northing,
    required double easting,
  }) {
    final double b = _a * (1 - _f);
    final double e2 = (2 * _f) - (_f * _f);
    final double e4 = e2 * e2;
    final double e6 = e4 * e2;
    final double n = (_a - b) / (_a + b);
    final double n2 = n * n;
    final double n3 = n2 * n;
    final double n4 = n2 * n2;
    final double g = _a * (1 - n) * (1 - n2) *
        (1 + (9 * n2 / 4) + (225 * n4 / 64)) *
        (math.pi / 180);

    final double lat0 = _originLat * math.pi / 180;
    final double lon0 = _originLon * math.pi / 180;
    final double m0 = _calcM(lat0, e2, e4, e6);

    final double northingPrime = northing - _falseNorthing;
    final double mPrime = m0 + (northingPrime / _scaleFactor);
    final double sigma = (mPrime * math.pi) / (180 * g);

    double latPrime = sigma +
        ((3 * n / 2) - (27 * n3 / 32)) * math.sin(2 * sigma) +
        ((21 * n2 / 16) - (55 * n4 / 32)) * math.sin(4 * sigma) +
        (151 * n3 / 96) * math.sin(6 * sigma) +
        (1097 * n4 / 512) * math.sin(8 * sigma);

    final double sinLatPrime = math.sin(latPrime);
    final double cosLatPrime = math.cos(latPrime);
    final double tanLatPrime = math.tan(latPrime);
    final double rhoPrime =
        _a * (1 - e2) / math.pow(1 - e2 * sinLatPrime * sinLatPrime, 1.5);
    final double vPrime =
        _a / math.sqrt(1 - e2 * sinLatPrime * sinLatPrime);
    final double psiPrime = vPrime / rhoPrime;
    final double tPrime = tanLatPrime;
    final double eastingPrime = easting - _falseEasting;
    final double x = eastingPrime / (_scaleFactor * vPrime);

    final double x2 = x * x;
    final double x3 = x2 * x;
    final double x5 = x3 * x2;
    final double x7 = x5 * x2;

    final double latFactor = tPrime / (_scaleFactor * rhoPrime);
    final double latTerm1 = latFactor * ((eastingPrime * x) / 2);
    final double latTerm2 = latFactor *
        ((eastingPrime * x3) / 24) *
        ((-4 * psiPrime * psiPrime) +
            (9 * psiPrime * (1 - tPrime * tPrime)) +
            (12 * tPrime * tPrime));
    final double latTerm3 = latFactor *
        ((eastingPrime * x5) / 720) *
        ((8 * math.pow(psiPrime, 4)) * (11 - 24 * tPrime * tPrime) -
            (12 * math.pow(psiPrime, 3)) * (21 - 71 * tPrime * tPrime) +
            (15 * psiPrime * psiPrime) *
                (15 - 98 * tPrime * tPrime + 15 * math.pow(tPrime, 4)) +
            180 * psiPrime * (5 * tPrime * tPrime - 3 * math.pow(tPrime, 4)) +
            360 * math.pow(tPrime, 4));
    final double latTerm4 = latFactor *
        ((eastingPrime * x7) / 40320) *
        (1385 +
            3633 * tPrime * tPrime +
            4095 * math.pow(tPrime, 4) +
            1575 * math.pow(tPrime, 6));

    latPrime = latPrime - latTerm1 + latTerm2 - latTerm3 + latTerm4;

    final double secLatPrime = 1 / cosLatPrime;
    final double lonTerm1 = x * secLatPrime;
    final double lonTerm2 =
        ((x3 * secLatPrime) / 6) * (psiPrime + (2 * tPrime * tPrime));
    final double lonTerm3 = ((x5 * secLatPrime) / 120) *
        ((-4 * math.pow(psiPrime, 3)) * (1 - 6 * tPrime * tPrime) +
            (psiPrime * psiPrime) * (9 - 68 * tPrime * tPrime) +
            72 * psiPrime * tPrime * tPrime +
            24 * math.pow(tPrime, 4));
    final double lonTerm4 = ((x7 * secLatPrime) / 5040) *
        (61 +
            662 * tPrime * tPrime +
            1320 * math.pow(tPrime, 4) +
            720 * math.pow(tPrime, 6));

    final double lon = lon0 + lonTerm1 - lonTerm2 + lonTerm3 - lonTerm4;

    return Svy21Coordinate(
      latitude: latPrime * 180 / math.pi,
      longitude: lon * 180 / math.pi,
    );
  }

  double _calcM(double lat, double e2, double e4, double e6) {
    return _a *
        ((1 - e2 / 4 - 3 * e4 / 64 - 5 * e6 / 256) * lat -
            (3 * e2 / 8 + 3 * e4 / 32 + 45 * e6 / 1024) * math.sin(2 * lat) +
            (15 * e4 / 256 + 45 * e6 / 1024) * math.sin(4 * lat) -
            (35 * e6 / 3072) * math.sin(6 * lat));
  }
}
