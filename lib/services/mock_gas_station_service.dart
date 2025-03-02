import '../models/gas_station.dart';

class MockGasStationService {
  Future<List<GasStation>> getGasStations(
      double lat, double lng, double radius) async {
    await Future.delayed(const Duration(milliseconds: 800));

    // Genera stazioni nelle vicinanze delle coordinate fornite
    return [
      GasStation(
        id: "1",
        name: "Q8",
        latitude: lat + 0.001,
        longitude: lng + 0.001,
        address: "Via Example 1",
        fuelPrices: {"Benzina": 1.799, "Diesel": 1.699, "GPL": 0.799},
      ),
      GasStation(
        id: "2",
        name: "ENI",
        latitude: lat - 0.001,
        longitude: lng - 0.001,
        address: "Via Example 2",
        fuelPrices: {"Benzina": 1.789, "Diesel": 1.689, "Metano": 1.999},
      ),
      GasStation(
        id: "3",
        name: "ESSO",
        latitude: lat + 0.002,
        longitude: lng - 0.002,
        address: "Via Example 3",
        fuelPrices: {"Benzina": 1.809, "Diesel": 1.709},
      ),
    ];
  }
}
