import '../models/car_park.dart';
import '../providers/car_park_provider.dart';
import '../providers/hdb_car_park_provider.dart';

class ApiController {
  ApiController({
    List<CarParkProvider>? providers,
  }) : _providers = providers ?? <CarParkProvider>[HdbCarParkProvider()];

  final List<CarParkProvider> _providers;

  Future<List<CarPark>> fetchAllCarParks() async {
    final List<CarPark> allCarParks = <CarPark>[];

    for (final CarParkProvider provider in _providers) {
      final List<CarPark> carParks = await provider.fetchCarParks();
      allCarParks.addAll(carParks);
    }

    return allCarParks;
  }

  Future<List<CarPark>> searchCarParks(String query) async {
    final String normalizedQuery = query.trim().toLowerCase();
    final List<CarPark> allCarParks = await fetchAllCarParks();

    if (normalizedQuery.isEmpty) {
      return allCarParks;
    }

    return allCarParks.where((CarPark carPark) {
      final String searchable = <String>[
        carPark.id,
        carPark.name,
        carPark.address,
        carPark.postalCode ?? '',
      ].join(' ').toLowerCase();

      return searchable.contains(normalizedQuery);
    }).toList(growable: false);
  }

  double calculateEstimatedParkingFee({
    required CarPark carPark,
    required int durationMinutes,
  }) {
    if (carPark.rates.isEmpty || durationMinutes <= 0) {
      return 0;
    }

    final double hourlyRate = carPark.rates.first.hourlyRate;
    return (durationMinutes / 60) * hourlyRate;
  }
}
