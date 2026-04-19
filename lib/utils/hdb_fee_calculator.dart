import 'package:latlong2/latlong.dart';
import 'package:timezone/timezone.dart' as tz;
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

  static bool isPeakNow() => _isPeakTime(DateTime.now());

  static bool _isPeakTime(DateTime dt) {
    // Peak time is Mon-Sat from 7am to 5pm
    final bool isWeekday = dt.weekday >= 1 && dt.weekday <= 6;
    final bool isInHours = dt.hour >= 7 && dt.hour < 17;
    return isWeekday && isInHours;
  }

  /// Calculates the estimated time when parking fees will reach the given threshold.
  /// 
  /// [threshold] - The target fee amount to reach
  /// [startTime] - When the parking session started
  /// [carparkPosition] - Location of the carpark (determines central area rates)
  /// 
  /// Returns a [tz.TZDateTime] when the threshold will be reached, or null if
  /// the threshold cannot be reached (e.g., threshold is 0 or negative).
  static tz.TZDateTime? calculateThresholdTime({
    required double threshold,
    required DateTime startTime,
    required LatLng? carparkPosition,
  }) {
    if (threshold <= 0) return null;

    final bool isCentral = carparkPosition != null && 
                           CentralAreaChecker.isCentralArea(carparkPosition);

    // If not in central area, rate is flat $0.60 per half-hour block
    if (!isCentral) {
      // Calculate how many blocks needed to exceed threshold
      final int blocksNeeded = (threshold / rateOutside).ceil();
      // Total billable time = blocks * 30 minutes
      final Duration billableDuration = Duration(minutes: blocksNeeded * 30);
      // Add grace period to get actual elapsed time from start
      final Duration totalDuration = billableDuration + const Duration(minutes: gracePeriodMinutes);
      // Convert to TZDateTime
      return tz.TZDateTime.from(startTime.add(totalDuration), tz.local);
    }

    // For central area, we need to simulate block by block since rates vary
    double accumulatedFee = 0;
    int blocksCompleted = 0;

    while (accumulatedFee < threshold) {
      final blockStart = startTime
          .add(const Duration(minutes: gracePeriodMinutes))
          .add(Duration(minutes: 30 * blocksCompleted));

      accumulatedFee += _isPeakTime(blockStart) ? rateCentralPeak : rateCentralOffPeak;
      blocksCompleted++;
    }

    // Total billable time = blocks * 30 minutes
    final Duration billableDuration = Duration(minutes: blocksCompleted * 30);
    // Add grace period to get actual elapsed time from start
    final Duration totalDuration = billableDuration + const Duration(minutes: gracePeriodMinutes);
    // Convert to TZDateTime
    return tz.TZDateTime.from(startTime.add(totalDuration), tz.local);
  }
}
