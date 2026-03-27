import '../models/parking_rate.dart';

class HdbRateRepository {
  const HdbRateRepository();

  List<ParkingRate> ratesForCarPark(String carParkType) {
    if (carParkType.toUpperCase().contains('SURFACE')) {
      return const <ParkingRate>[
        ParkingRate(
          label: 'Estimated HDB surface parking',
          hourlyRate: 1.20,
          description: 'Temporary placeholder until your team confirms the exact rate rules.',
        ),
      ];
    }

    return const <ParkingRate>[
      ParkingRate(
        label: 'Estimated HDB standard parking',
        hourlyRate: 0.60,
        description: 'Temporary placeholder until your team confirms the exact rate rules.',
      ),
    ];
  }
}
