import 'package:latlong2/latlong.dart';
import 'central_area_checker.dart';

class CalculationResult {
  final double totalFee;
  final int completedBlocks;
  final bool isCentral;

  CalculationResult({
    required this.totalFee,
    required this.completedBlocks,
    required this.isCentral,
  });
}

class HdbFeeCalculator {
  HdbFeeCalculator._();

  static const double rateOutside = 0.60;
  static const double rateCentralPeak = 1.20;
  static const double rateCentralOffPeak = 0.60;
  static const int gracePeriodMinutes = 15;

  static CalculationResult calculate({
    required Duration elapsedTime,
    required DateTime startTime,
    required LatLng? carparkPosition,
  }) {
    final int billableSeconds = elapsedTime.inSeconds - (gracePeriodMinutes * 60);

    if (billableSeconds <= 0) {
      return CalculationResult(totalFee: 0, completedBlocks: 0, isCentral: false);
    }

    final int blocks = (billableSeconds / 1800).ceil();
    
    final bool isCentral = carparkPosition != null && 
                           CentralAreaChecker.isCentralArea(carparkPosition);

    if (!isCentral) {
      return CalculationResult(
        totalFee: blocks * rateOutside,
        completedBlocks: blocks,
        isCentral: false,
      );
    }

    double totalFee = 0;
    for (int i = 0; i < blocks; i++) {
      // Each block starts 30 mins after the previous one
      final blockStart = startTime
          .add(const Duration(minutes: gracePeriodMinutes))
          .add(Duration(minutes: 30 * i));

      totalFee += _isPeakTime(blockStart) ? rateCentralPeak : rateCentralOffPeak;
    }

    return CalculationResult(
      totalFee: totalFee,
      completedBlocks: blocks,
      isCentral: true,
    );
  }

  /// Returns the [DateTime] when the accumulated parking fee is expected to
  /// first equal or exceed [threshold], or null if the threshold cannot be
  /// reached within a reasonable number of blocks (~500 hours).
  ///
  /// The returned time is the start of the billing block that pushes the
  /// cumulative fee over the threshold — schedule an alert for this instant.
  static DateTime? calculateThresholdTime({
    required DateTime startTime,
    required double threshold,
    required LatLng? carparkPosition,
  }) {
    if (threshold <= 0) {
      return startTime.add(const Duration(minutes: gracePeriodMinutes));
    }

    final bool isCentral = carparkPosition != null &&
        CentralAreaChecker.isCentralArea(carparkPosition);

    double cumulativeFee = 0;

    for (int i = 0; i < 1000; i++) {
      // Mirror the same block-start calculation used in calculate()
      final blockStart = startTime
          .add(const Duration(minutes: gracePeriodMinutes))
          .add(Duration(minutes: 30 * i));

      final double blockRate = isCentral
          ? (_isPeakTime(blockStart) ? rateCentralPeak : rateCentralOffPeak)
          : rateOutside;

      cumulativeFee += blockRate;

      if (cumulativeFee >= threshold) {
        return blockStart;
      }
    }

    return null; // threshold unreachably high
  }

  static bool isPeakNow() => _isPeakTime(DateTime.now());

  static bool _isPeakTime(DateTime dt) {
    // Peak time is Mon-Sat from 7am to 5pm
    final bool isWeekday = dt.weekday >= 1 && dt.weekday <= 6;
    final bool isInHours = dt.hour >= 7 && dt.hour < 17;
    return isWeekday && isInHours;
  }
}