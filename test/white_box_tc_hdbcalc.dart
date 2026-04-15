import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:park_buddy/utils/hdb_fee_calculator.dart';

// Central and non-central positions used across tests.
const LatLng centralPosition    = LatLng(1.2900, 103.8500); // within central area
const LatLng nonCentralPosition = LatLng(1.3800, 103.7600); // outside central area

// Helper to build a DateTime obj on a specific weekday and hour.
DateTime onDay(int weekday, int hour) {
  // Find the next date that matches the desired weekday
  var dt = DateTime(2026, 1, 1, hour, 0, 0); // Monday Jan 1 2024
  while (dt.weekday != weekday) {
    dt = dt.add(const Duration(days: 1));
  }
  return dt;
}


void main() {
  // TC-01 | Baseline path 
  test('HDBcalc - TC-01',
      () {
    final startTime = onDay(DateTime.monday, 10);     // Mon 10:00
    final elapsedTime   = const Duration(minutes: 60);

    final result = HdbFeeCalculator.calculate(
      elapsedTime:          elapsedTime,
      startTime:        startTime,
      carparkPosition:  centralPosition,
    );

    expect(result.isCentral,       isTrue);
    expect(result.completedBlocks, equals(2));
    expect(result.totalFee,        closeTo(2.40, 0.001));
  });

  // TC-02 | Path P2 
  test('HDBcalc - TC-02', () {
    final startTime = onDay(DateTime.monday, 10);
    final elapsedTime   = const Duration(minutes: 10);

    final result = HdbFeeCalculator.calculate(
      elapsedTime:         elapsedTime,
      startTime:       startTime,
      carparkPosition: centralPosition,
    );

    expect(result.totalFee,        equals(0.0));
    expect(result.completedBlocks, equals(0));
    expect(result.isCentral,       isFalse);
  });

  
  // TC-03 | Path P3
  test('HDBcalc - TC-03', () {
    final startTime = onDay(DateTime.monday, 10);
    final elapsedTime   = const Duration(minutes: 60);

    final result = HdbFeeCalculator.calculate(
      elapsedTime:         elapsedTime,
      startTime:       startTime,
      carparkPosition: nonCentralPosition,
    );

    expect(result.isCentral,       isFalse);
    expect(result.completedBlocks, equals(2));
    expect(result.totalFee,        closeTo(1.20, 0.001));
  });

  // TC-04 | Path P4
  test('HDBcalc - TC-04', () {
    final startTime = onDay(DateTime.sunday, 10);     // Sun 10:00
    final elapsedTime   = const Duration(minutes: 60);

    final result = HdbFeeCalculator.calculate(
      elapsedTime:         elapsedTime,
      startTime:       startTime,
      carparkPosition: centralPosition,
    );

    expect(result.isCentral,       isTrue);
    expect(result.completedBlocks, equals(2));
    expect(result.totalFee,        closeTo(1.20, 0.001));
  });

  // TC-05 | Path P5 
  test('HDBcalc - TC-05',
      () {
    final startTime = onDay(DateTime.monday, 20);     // Mon 20:00 (8pm)
    final elapsedTime   = const Duration(minutes: 60);

    final result = HdbFeeCalculator.calculate(
      elapsedTime:         elapsedTime,
      startTime:       startTime,
      carparkPosition: centralPosition,
    );

    expect(result.isCentral,       isTrue);
    expect(result.completedBlocks, equals(2));
    expect(result.totalFee,        closeTo(1.20, 0.001));
  });
}