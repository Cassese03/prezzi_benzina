import 'package:flutter/foundation.dart';

class GasStation {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String address;
  final Map<String, double> fuelPrices;

  GasStation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.fuelPrices,
  });

  factory GasStation.fromJson(Map<String, dynamic> json) {
    Map<String, double> prices = {};
    var prezzi = json['prezzi'];
    if (prezzi != null) {
      if (prezzi['benzina'] != null)
        prices['Benzina'] = double.parse(prezzi['benzina'].toString());
      if (prezzi['diesel'] != null)
        prices['Diesel'] = double.parse(prezzi['diesel'].toString());
      if (prezzi['gpl'] != null)
        prices['GPL'] = double.parse(prezzi['gpl'].toString());
    }

    return GasStation(
      id: json['_id'] ?? '',
      name: json['bandiera'] ?? 'Sconosciuto',
      latitude: json['coordinate']?['lat']?.toDouble() ?? 0.0,
      longitude: json['coordinate']?['lon']?.toDouble() ?? 0.0,
      address: '${json['indirizzo'] ?? ''}, ${json['comune'] ?? ''}',
      fuelPrices: prices,
    );
  }

  String getFormattedPrice(String fuelType) {
    final price = fuelPrices[fuelType];
    if (price == null) return 'N/D';
    return '€ ${price.toStringAsFixed(3)}';
  }

  bool hasValidPrice(String fuelType) {
    final price = fuelPrices[fuelType];
    return price != null && price > 0;
  }

  double? getLowestPrice() {
    if (fuelPrices.isEmpty) return null;
    return fuelPrices.values.reduce((curr, next) => curr < next ? curr : next);
  }

  String getBrandOrDefault() {
    return name.isEmpty ? 'Pompa Bianca' : name;
  }
}
