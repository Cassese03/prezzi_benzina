import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/gas_station.dart';
import 'preferences_service.dart';

class GasStationService {
  static const String baseUrl = 'https://gas-stations-api.vercel.app';
  final PreferencesService _prefsService = PreferencesService();

  Future<List<GasStation>> getGasStations(
      double lat, double lng, int distance) async {
    try {
      final isElectricModeOnly = await _prefsService.getIsElectricModeOnly();

      String url = '';
      if (isElectricModeOnly) {
        url = '$baseUrl/charge-stations?lat=$lat&lng=$lng&distance=$distance';
      } else {
        url = '$baseUrl/gas-stations?lat=$lat&lng=$lng&distance=$distance';
      }
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['stations'] as List)
            .map((json) => GasStation.fromJson(json))
            .toList();
      }

      throw Exception('Errore API: ${response.statusCode}');
    } catch (e) {
      //print('Errore nel recupero stazioni: $e');
      return [];
    }
  }

  Future<List<GasStation>> getFirst10Stations() async {
    final prefs = await SharedPreferences.getInstance();
    final searchRadius = prefs.getInt('search_radius') ?? 5;

    return getGasStations(40.9322765492642, 14.528412503688312, searchRadius);
  }
}
