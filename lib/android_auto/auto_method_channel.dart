import 'package:carmate/services/gas_station_service.dart';
import 'package:carmate/services/preferences_service.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

/// Gestisce la comunicazione con Android Auto
class AndroidAutoChannel {
  static const _channel = MethodChannel('com.example.carmate/auto');

  static Future<void> initialize() async {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  /// Gestisce le chiamate in arrivo da Android Auto
  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    print('Ricevuta chiamata da Android Auto: ${call.method}');

    switch (call.method) {
      case 'getAveragePrices':
        return _getAveragePrices();
      case 'getNearestStations':
        return _getNearestStations();
      default:
        throw PlatformException(
            code: 'not_implemented',
            message: '1. Metodo ${call.method} non implementato');
    }
  }

  /// Restituisce i prezzi medi dei carburanti
  /// Questa funzione dovrebbe essere implementata per recuperare i dati reali
  static Future<Object> _getNearestStations() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Permesso di geolocalizzazione negato');
      }
    }
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    final PreferencesService _prefsService = PreferencesService();
    final GasStationService _service = GasStationService();

    final fuelType = await _prefsService.getPreferredFuelType();
    int distance = await _prefsService.getSearchRadius();

    final stations = await _service.getGasStations(
      position.latitude,
      position.longitude,
      distance,
    );

    return stations
        .map((entry) => {
              'name': entry.name,
              'address': entry.address,
              'self': entry.fuelPrices[fuelType]?.self ?? 0.00,
              'servito': entry.fuelPrices[fuelType]?.servito ?? 0.00,
              'fuelType': fuelType,
              'lat': entry.latitude,
              'lon': entry.longitude,
            })
        .toList();
  }

  static Future<Object> _getAveragePrices() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Permesso di geolocalizzazione negato');
      }
    }

    // Ottieni la posizione corrente
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    final PreferencesService _prefsService = PreferencesService();
    final GasStationService _service = GasStationService();

    int distance = await _prefsService.getSearchRadius();
    // Qui dovresti recuperare i dati dai tuoi servizi o dal database
    var stations = await _service.getGasStations(
      position.latitude,
      position.longitude,
      distance,
    );

    Map<String, double> sums = {};
    Map<String, int> counts = {};

    // Calcola le somme e conta solo i prezzi validi
    for (var station in stations) {
      station.fuelPrices.forEach((fuelType, priceInfo) {
        final price = priceInfo.self > 0 ? priceInfo.self : priceInfo.servito;
        if (price > 0) {
          // Conta solo se il prezzo è valido
          sums[fuelType] = (sums[fuelType] ?? 0) + price;
          counts[fuelType] = (counts[fuelType] ?? 0) + 1;
        }
      });
    }

    // Calcola le medie solo per i tipi di carburante con prezzi validi
    Map<String, double> averages = {};
    sums.forEach((fuelType, total) {
      if (counts[fuelType]! > 0) {
        averages[fuelType] = total / counts[fuelType]!;
      }
    });

    return averages.entries
        .map((entry) => {
              'fuelType': entry.key,
              'price': entry.value,
              'date': DateTime.now()
                  .toString()
                  .split(' ')[0]
                  .split('-')
                  .reversed
                  .join('-'),
              'region': 'Media nazionale',
            })
        .toList();
  }
}
