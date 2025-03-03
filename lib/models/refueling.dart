class Refueling {
  final String id;
  final DateTime date;
  final double liters;
  final double pricePerLiter;
  final double kilometers;
  final double totalAmount;
  final String fuelType;
  final String? notes;
  final String vehicleId; // Aggiunto campo vehicleId

  Refueling({
    required this.id,
    required this.date,
    required this.liters,
    required this.pricePerLiter,
    required this.kilometers,
    required this.totalAmount,
    required this.fuelType,
    required this.vehicleId, // Aggiunto parametro richiesto
    this.notes,
  });

  factory Refueling.fromJson(Map<String, dynamic> json) {
    return Refueling(
      id: json['id'],
      date: DateTime.parse(json['date']),
      liters: json['liters'].toDouble(),
      pricePerLiter: json['pricePerLiter'].toDouble(),
      kilometers: json['kilometers'].toDouble(),
      totalAmount: json['totalAmount'].toDouble(),
      fuelType: json['fuelType'],
      vehicleId: json['vehicleId'] ?? '', // Aggiunto parsing vehicleId
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'liters': liters,
      'pricePerLiter': pricePerLiter,
      'kilometers': kilometers,
      'totalAmount': totalAmount,
      'fuelType': fuelType,
      'vehicleId': vehicleId, // Aggiunto vehicleId al JSON
      'notes': notes,
    };
  }

  double get consumption => kilometers > 0 ? liters / (kilometers / 100) : 0;

  double getKmDriven(double? lastKm) {
    if (lastKm == null) return 0;
    return kilometers - lastKm;
  }
}
