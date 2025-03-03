class Vehicle {
  final String id;
  final String name;
  final String brand;
  final String model;
  final String fuelType;
  final int year;
  final String licensePlate;

  Vehicle({
    required this.id,
    required this.name,
    required this.brand,
    required this.model,
    required this.fuelType,
    required this.year,
    this.licensePlate = '',
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'],
      name: json['name'],
      brand: json['brand'],
      model: json['model'],
      fuelType: json['fuelType'],
      year: json['year'],
      licensePlate: json['licensePlate'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'model': model,
      'fuelType': fuelType,
      'year': year,
      'licensePlate': licensePlate,
    };
  }
}
