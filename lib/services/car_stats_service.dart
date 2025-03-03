import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/refueling.dart';

class CarStatsService {
  static const String _storageKey = 'refuelings';

  Future<void> addRefueling(Refueling refueling) async {
    final prefs = await SharedPreferences.getInstance();
    final refuelings = await getRefuelings();
    refuelings.add(refueling);
    await prefs.setString(
        _storageKey, jsonEncode(refuelings.map((r) => r.toJson()).toList()));
  }

  Future<List<Refueling>> getRefuelings() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);
    if (data == null) return [];

    final List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((json) => Refueling.fromJson(json)).toList();
  }

  Future<void> updateRefueling(Refueling refueling) async {
    final prefs = await SharedPreferences.getInstance();
    final refuelings = await getRefuelings();
    final index = refuelings.indexWhere((r) => r.id == refueling.id);
    if (index != -1) {
      refuelings[index] = refueling;
      await prefs.setString(
          _storageKey, jsonEncode(refuelings.map((r) => r.toJson()).toList()));
    }
  }

  Future<void> deleteRefueling(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final refuelings = await getRefuelings();
    refuelings.removeWhere((r) => r.id == id);
    await prefs.setString(
        _storageKey, jsonEncode(refuelings.map((r) => r.toJson()).toList()));
  }

  Future<Map<String, double>> getStatistics() async {
    final refuelings = await getRefuelings();
    if (refuelings.isEmpty) {
      return {
        'totalSpent': 0,
        'averageConsumption': 0,
        'averagePrice': 0,
      };
    }

    double totalSpent = 0;
    double totalLiters = 0;
    double totalKm = 0;

    for (var refueling in refuelings) {
      totalSpent += refueling.totalAmount;
      totalLiters += refueling.liters;
      totalKm += refueling.kilometers;
    }

    return {
      'totalSpent': totalSpent,
      'averageConsumption': totalKm > 0 ? (totalLiters * 100) / totalKm : 0,
      'averagePrice': totalLiters > 0 ? totalSpent / totalLiters : 0,
    };
  }

  Future<List<Refueling>> getRefuelingsByVehicle(String vehicleId) async {
    final refuelings = await getRefuelings();
    return refuelings.where((r) => r.vehicleId == vehicleId).toList();
  }

  Future<Map<String, double>> getStatisticsByVehicle(String vehicleId) async {
    final refuelings = await getRefuelingsByVehicle(vehicleId);
    if (refuelings.isEmpty) {
      return {
        'totalSpent': 0,
        'averageConsumption': 0,
        'averagePrice': 0,
      };
    }

    double totalSpent = 0;
    double totalLiters = 0;
    double totalKm = 0;

    for (var refueling in refuelings) {
      totalSpent += refueling.totalAmount;
      totalLiters += refueling.liters;
      totalKm += refueling.kilometers;
    }

    return {
      'totalSpent': totalSpent,
      'averageConsumption': totalKm > 0 ? (totalLiters * 100) / totalKm : 0,
      'averagePrice': totalLiters > 0 ? totalSpent / totalLiters : 0,
    };
  }
}
