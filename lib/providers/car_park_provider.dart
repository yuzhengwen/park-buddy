import '../models/car_park.dart';

abstract class CarParkProvider {
  Future<List<CarPark>> fetchCarParks();
}
