import '../models/car_park.dart';
import '../models/parking_rate.dart';

class SampleHdbCarParkRepository {
  const SampleHdbCarParkRepository();

  List<CarPark> getCarParks() {
    return const <CarPark>[
      CarPark(
        id: 'ACB',
        name: 'HDB Car Park ACB',
        address: 'BLK 270/271 ALBERT CENTRE BASEMENT CAR PARK',
        availableLots: 0,
        source: 'HDB',
        rates: <ParkingRate>[
          ParkingRate(label: 'Estimated HDB standard parking', hourlyRate: 0.60),
        ],
        latitude: 1.3016,
        longitude: 103.8547,
        xCoordinate: 30314.7936,
        yCoordinate: 31490.4942,
        type: 'BASEMENT CAR PARK',
        shortTermParking: 'WHOLE DAY',
        freeParking: 'NO',
        nightParking: 'YES',
      ),
      CarPark(
        id: 'HE12',
        name: 'HDB Car Park HE12',
        address: 'BLK 12 HOLLAND AVENUE',
        availableLots: 0,
        source: 'HDB',
        rates: <ParkingRate>[
          ParkingRate(label: 'Estimated HDB surface parking', hourlyRate: 1.20),
        ],
        latitude: 1.3119,
        longitude: 103.7969,
        xCoordinate: 23876.5432,
        yCoordinate: 32345.2231,
        type: 'SURFACE CAR PARK',
        shortTermParking: 'SUN-HOL',
        freeParking: 'SUN & PH FR 7AM/10.30PM',
        nightParking: 'YES',
      ),
      CarPark(
        id: 'BM29',
        name: 'HDB Car Park BM29',
        address: 'BLK 29 BENDEMEER ROAD',
        availableLots: 0,
        source: 'HDB',
        rates: <ParkingRate>[
          ParkingRate(label: 'Estimated HDB standard parking', hourlyRate: 0.60),
        ],
        latitude: 1.3238,
        longitude: 103.8625,
        xCoordinate: 33908.1201,
        yCoordinate: 32761.6641,
        type: 'MULTI-STOREY CAR PARK',
        shortTermParking: 'WHOLE DAY',
        freeParking: 'NO',
        nightParking: 'YES',
      ),
      CarPark(
        id: 'TP48',
        name: 'HDB Car Park TP48',
        address: 'BLK 48 TEBAN GARDENS ROAD',
        availableLots: 0,
        source: 'HDB',
        rates: <ParkingRate>[
          ParkingRate(label: 'Estimated HDB standard parking', hourlyRate: 0.60),
        ],
        latitude: 1.3214,
        longitude: 103.7392,
        xCoordinate: 16021.9044,
        yCoordinate: 31789.0035,
        type: 'MULTI-STOREY CAR PARK',
        shortTermParking: 'WHOLE DAY',
        freeParking: 'NO',
        nightParking: 'YES',
      ),
      CarPark(
        id: 'Y81M',
        name: 'HDB Car Park Y81M',
        address: 'BLK 81 MARINE PARADE CENTRAL',
        availableLots: 0,
        source: 'HDB',
        rates: <ParkingRate>[
          ParkingRate(label: 'Estimated HDB standard parking', hourlyRate: 0.60),
        ],
        latitude: 1.3028,
        longitude: 103.9066,
        xCoordinate: 37170.1134,
        yCoordinate: 31521.8455,
        type: 'MULTI-STOREY CAR PARK',
        shortTermParking: 'WHOLE DAY',
        freeParking: 'NO',
        nightParking: 'YES',
      ),
    ];
  }
}
