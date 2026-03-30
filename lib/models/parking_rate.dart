class ParkingRate {
  const ParkingRate({
    required this.label,
    required this.hourlyRate,
    this.description,
  });

  final String label;
  final double hourlyRate;
  final String? description;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'label': label,
      'hourlyRate': hourlyRate,
      'description': description,
    };
  }
}
