import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/gas_station.dart';

class GasStationService {
  static const String baseUrl = 'https://gas-stations-api.vercel.app';

  Future<List<GasStation>> getGasStations(
      double lat, double lng, int distance) async {
    try {
      final url = '$baseUrl/gas-stations?lat=$lat&lng=$lng&distance=$distance';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['stations'] as List)
            .map((json) => GasStation.fromJson(json))
            .toList();
      }

      throw Exception('Errore API: ${response.statusCode}');
    } catch (e) {
      print('Errore nel recupero stazioni: $e');
      return [];
    }
  }

  Future<List<GasStation>> getFirst10Stations() async {
    // Usa le coordinate fisse e una distanza di 5km
    return getGasStations(
        40.9322765492642, // Latitudine fissa
        14.528412503688312, // Longitudine fissa
        5 // Distanza in km
        );
  }
}
