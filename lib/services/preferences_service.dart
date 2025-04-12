import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vehicle.dart';

class PreferencesService {
  static const String _fuelTypeKey = 'fuelType';
  static const String _vehiclesKey = 'vehicles';
  static const String _selectedVehicleKey = 'selected_vehicle';
  static const String _searchRadiusKey = 'search_radius';
  static const String _isElectricModeOnlyKey =
      'is_electric_mode_only'; // Nuova chiave

  static const List<String> availableFuelTypes = [
    'Benzina',
    'Gasolio',
    'GPL',
    'Metano',
    'Elettrica'
  ];

  static const List<int> availableRadiusValues = [5, 10, 20, 30, 50];

  Future<void> setPreferredFuelType(String fuelType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fuelTypeKey, fuelType);
  }

  Future<String> getPreferredFuelType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_fuelTypeKey) ?? 'Benzina';
  }

  Future<List<Vehicle>> getVehicles() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_vehiclesKey);
    if (data == null) return [];

    final List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((json) => Vehicle.fromJson(json)).toList();
  }

  Future<void> saveVehicle(Vehicle vehicle) async {
    final prefs = await SharedPreferences.getInstance();
    final vehicles = await getVehicles();
    final index = vehicles.indexWhere((v) => v.id == vehicle.id);

    if (index >= 0) {
      vehicles[index] = vehicle;
    } else {
      vehicles.add(vehicle);
    }

    await prefs.setString(
        _vehiclesKey, jsonEncode(vehicles.map((v) => v.toJson()).toList()));
  }

  Future<void> deleteVehicle(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final vehicles = await getVehicles();
    vehicles.removeWhere((v) => v.id == id);
    await prefs.setString(
        _vehiclesKey, jsonEncode(vehicles.map((v) => v.toJson()).toList()));

    // Se il veicolo eliminato era quello selezionato, deseleziona
    final selectedId = await getSelectedVehicleId();
    if (selectedId == id) {
      await prefs.remove(_selectedVehicleKey);
    }
  }

  Future<String?> getSelectedVehicleId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedVehicleKey);
  }

  Future<void> setSelectedVehicleId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedVehicleKey, id);
  }

  Future<void> setSearchRadius(int radius) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_searchRadiusKey, radius);
  }

  Future<int> getSearchRadius() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_searchRadiusKey) ?? 5; // Default 5km
  }

  Future<bool> getIsElectricModeOnly() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isElectricModeOnlyKey) ?? false;
  }

  Future<void> setIsElectricModeOnly(bool isElectricModeOnly) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isElectricModeOnlyKey, isElectricModeOnly);

    // Se attivata la modalità elettrica, imposta anche il tipo di carburante su Elettrica
    if (isElectricModeOnly) {
      await setPreferredFuelType('Elettrica');
    }
  }
}
