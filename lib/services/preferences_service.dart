import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vehicle.dart';

class PreferencesService {
  static const String _fuelTypeKey = 'fuelType';
  static const String _vehiclesKey = 'vehicles';
  static const String _selectedVehicleKey = 'selected_vehicle';

  static const List<String> availableFuelTypes = [
    'Benzina',
    'Diesel',
    'GPL',
    'Metano'
  ];

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
}
