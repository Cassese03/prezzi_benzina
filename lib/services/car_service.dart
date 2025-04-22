import 'package:flutter/services.dart';
import '../models/gas_station.dart';

class CarService {
  static const platform = MethodChannel('com.lorenzo.fueltank/car');

  // Inizializza il servizio per auto
  static Future<void> initialize() async {
    try {
      await platform.invokeMethod('initializeCarService');
    } catch (e) {
      // print('Errore inizializzazione car service: $e');
    }
  }

  // Check if running on car interface or mobile
  static Future<bool> isRunningInCar() async {
    try {
      final result = await platform.invokeMethod('isRunningInCar');
      return result ?? false;
    } catch (e) {
      //print('Error checking car interface: $e');
      return false;
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
      //print('Errore invio dati a car interface: $e');
    }
  }
}
