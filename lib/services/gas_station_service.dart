import 'dart:async';
import '../models/gas_station.dart';

class GasStationService {
  Future<List<GasStation>> getGasStations(
      double lat, double lng, double radius) async {
    // Simuliamo un ritardo di rete
    await Future.delayed(const Duration(seconds: 1));

    // Restituiamo dati simulati
    return [
      GasStation(
        id: "1",
        name: "Q8",
        latitude: lat + 0.002,
        longitude: lng + 0.002,
        address: "Via Roma 123, Napoli",
        fuelPrices: {
          "Benzina": 1.859,
          "Diesel": 1.759,
          "GPL": 0.799,
        },
      ),
      GasStation(
        id: "2",
        name: "ENI",
        latitude: lat - 0.001,
        longitude: lng - 0.001,
        address: "Corso Umberto 45, Napoli",
        fuelPrices: {
          "Benzina": 1.849,
          "Diesel": 1.749,
          "GPL": 0.789,
        },
      ),
      GasStation(
        id: "3",
        name: "ESSO",
        latitude: lat + 0.003,
        longitude: lng - 0.002,
        address: "Via Napoli 78, Napoli",
        fuelPrices: {
          "Benzina": 1.869,
          "Diesel": 1.769,
          "GPL": 0.809,
        },
      ),
      GasStation(
        id: "4",
        name: "IP",
        latitude: lat - 0.002,
        longitude: lng + 0.003,
        address: "Via Vesuvio 15, Napoli",
        fuelPrices: {
          "Benzina": 1.839,
          "Diesel": 1.739,
          "GPL": 0.785,
        },
      ),
    ];
  }
}
