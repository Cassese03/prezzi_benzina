import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/gas_station.dart';

class CarService {
  static const platform = MethodChannel('com.example.carmate/car');

  // Inizializza il servizio per auto
  static Future<void> initialize() async {
    try {
      await platform.invokeMethod('initializeCarService');
    } catch (e) {
      print('Errore inizializzazione car service: $e');
    }
  }

  // Invia i dati della stazione all'interfaccia auto
  static Future<void> showStationInCar(GasStation station) async {
    try {
      await platform.invokeMethod('showStation', {
        'name': station.name,
        'address': station.address,
        'latitude': station.latitude,
        'longitude': station.longitude,
        'fuelPrices': station.fuelPrices.map((key, value) =>
            MapEntry(key, {'self': value.self, 'servito': value.servito})),
      });
    } catch (e) {
      print('Errore invio dati a car interface: $e');
    }
  }
}
