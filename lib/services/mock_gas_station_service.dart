import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/gas_station.dart';

class MockGasStationService {
  final String apiUrl = 'https://gas-stations-api.vercel.app/top-stations';

  Future<List<GasStation>> getGasStations(
      double lat, double lng, double radius) async {
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['stations'] as List)
            .map((station) => GasStation.fromJson(station))
            .toList();
      } else {
        throw Exception('Errore nella richiesta API: ${response.statusCode}');
      }
    } catch (e) {
      //print('Errore nel recupero delle stazioni: $e');
      // Ritorna una lista vuota in caso di errore
      return [];
    }
  }

  // Metodo specifico per ottenere solo le prime 10 stazioni
  Future<List<GasStation>> getFirst10Stations() async {
    final stations = await getGasStations(
        0, 0, 0); // I parametri non sono usati per l'endpoint top-stations
    return stations.take(10).toList();
  }
}
