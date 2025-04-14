import 'package:carmate/services/car_stats_service.dart';
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
    //print('Ricevuta chiamata da Android Auto: ${call.method}');

    switch (call.method) {
      case 'getAveragePrices':
        return _getAveragePrices();
      case 'getNearestStations':
        return _getNearestStations();
      case 'getRefuelings':
        return _getRefuelings();
      case 'getVehicles':
        return _getVehicles();
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
    final PreferencesService prefsService = PreferencesService();
    final GasStationService service = GasStationService();

    final fuelType = await prefsService.getPreferredFuelType();
    int distance = await prefsService.getSearchRadius();

    final stations = await service.getGasStations(
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
    final PreferencesService prefsService = PreferencesService();
    final GasStationService service = GasStationService();

    int distance = await prefsService.getSearchRadius();
    // Qui dovresti recuperare i dati dai tuoi servizi o dal database
    var stations = await service.getGasStations(
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

  /// Restituisce i rifornimenti dell'utente
  static Future<List<Map<String, dynamic>>> _getRefuelings() async {
    try {
      final PreferencesService prefsService = PreferencesService();

      final selectedVehicleId = await prefsService.getVehicles();

      if (selectedVehicleId.first.id.isNotEmpty) {
        try {
          final CarStatsService service = CarStatsService();
          final data =
              await service.getRefuelingsByVehicle(selectedVehicleId.first.id);
          if (data.isEmpty) return [];
          return data
              .map((refueling) => {
                    'id': refueling.id,
                    'date': refueling.date.toIso8601String(),
                    'liters': refueling.liters,
                    'pricePerLiter': refueling.pricePerLiter,
                    'kilometers': refueling.kilometers,
                    'totalAmount': refueling.totalAmount,
                    'fuelType': refueling.fuelType,
                    'notes': refueling.notes,
                    'vehicleId': refueling.vehicleId,
                  })
              .toList();
        } catch (e) {
          //print('Auto: Errore nel recupero dei rifornimenti dal repository: $e');
        }
      }
      return _createFallbackRefuelings();
    } catch (e) {
      //print('Auto: Errore nel metodo _getRefuelings: $e');
      return _createFallbackRefuelings();
    }
  }

  /// Converte un oggetto rifornimento nel formato Map per il canale
  // ignore: unused_element
  static Map<String, dynamic> _convertRefuelingToMap(dynamic refueling) {
    try {
      // Se l'oggetto è già una mappa, restituiscilo
      if (refueling is Map<String, dynamic>) {
        return refueling;
      }

      // Altrimenti verifica se ha un metodo toJson() o toMap()
      if (refueling != null) {
        if (refueling.toJson != null && refueling.toJson is Function) {
          return refueling.toJson();
        } else if (refueling.toMap != null && refueling.toMap is Function) {
          return refueling.toMap();
        } else {
          // Prova ad accedere alle proprietà direttamente
          return {
            'id': refueling.id?.toString() ?? '',
            'date':
                refueling.date?.toString() ?? DateTime.now().toIso8601String(),
            'liters': refueling.liters?.toDouble() ?? 0.0,
            'pricePerLiter': refueling.pricePerLiter?.toDouble() ?? 0.0,
            'kilometers': refueling.kilometers?.toDouble() ?? 0.0,
            'totalAmount': refueling.totalAmount?.toDouble() ?? 0.0,
            'fuelType': refueling.fuelType?.toString() ?? '',
            'vehicleId': refueling.vehicleId?.toString() ?? '',
            'notes': refueling.notes?.toString(),
          };
        }
      }

      // Fallback se tutto fallisce
      return {
        'id': '',
        'date': DateTime.now().toIso8601String(),
        'liters': 0.0,
        'pricePerLiter': 0.0,
        'kilometers': 0.0,
        'totalAmount': 0.0,
        'fuelType': '',
        'vehicleId': '',
        'notes': null,
      };
    } catch (e) {
      //print('Auto: Errore nella conversione del rifornimento: $e');
      return {
        'id': 'error',
        'date': DateTime.now().toIso8601String(),
        'liters': 0.0,
        'pricePerLiter': 0.0,
        'kilometers': 0.0,
        'totalAmount': 0.0,
        'fuelType': 'Errore',
        'vehicleId': '',
        'notes': 'Errore nella conversione: $e',
      };
    }
  }

  /// Crea dati di rifornimento di fallback
  static List<Map<String, dynamic>> _createFallbackRefuelings() {
    final now = DateTime.now();
    return [
      {
        'id': '1',
        'date': now.toIso8601String(),
        'liters': 45.0,
        'pricePerLiter': 1.789,
        'kilometers': 12500.0,
        'totalAmount': 80.50,
        'fuelType': 'Benzina',
        'vehicleId': '1',
        'notes': null,
      },
      {
        'id': '2',
        'date': now.subtract(const Duration(days: 7)).toIso8601String(),
        'liters': 40.0,
        'pricePerLiter': 1.795,
        'kilometers': 12200.0,
        'totalAmount': 71.80,
        'fuelType': 'Benzina',
        'vehicleId': '1',
        'notes': 'Autostrada',
      },
      {
        'id': '3',
        'date': now.subtract(const Duration(days: 15)).toIso8601String(),
        'liters': 50.0,
        'pricePerLiter': 1.659,
        'kilometers': 11850.0,
        'totalAmount': 82.95,
        'fuelType': 'Diesel',
        'vehicleId': '2',
        'notes': 'Viaggio lungo',
      },
    ];
  }

  /// Restituisce i veicoli dell'utente
  static Future<List<Map<String, dynamic>>> _getVehicles() async {
    try {
      final PreferencesService prefsService = PreferencesService();
      final vehicles = await prefsService.getVehicles();
      if (vehicles.isEmpty) {
        //print('Nessun veicolo trovato, utilizzo dati di esempio');
        return [];
      } else {
        return vehicles
            .map((vehicle) => {
                  'id': vehicle.id,
                  'name': vehicle.name,
                  'brand': vehicle.brand,
                  'model': vehicle.model,
                  'fuelType': vehicle.fuelType,
                  'year': vehicle.year,
                  'licensePlate': vehicle.licensePlate,
                })
            .toList();
      }
    } catch (e) {
      //print('Errore nel recupero dei veicoli: $e');
      return [];
    }
  }

  /// Aggiunge un nuovo rifornimento
  // ignore: unused_element
  static Future<bool> _addRefueling(Map<String, dynamic> data) async {
    return false;
  }
}
