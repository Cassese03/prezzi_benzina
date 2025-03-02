import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _currencyKey = 'currency';
  static const String _fuelTypeKey = 'fuelType';

  static const List<String> availableCurrencies = ['EUR', 'USD', 'GBP'];
  static const List<String> availableFuelTypes = ['Benzina', 'Diesel', 'GPL'];

  Future<void> setCurrency(String currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, currency);
  }

  Future<String> getCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currencyKey) ?? 'EUR';
  }

  Future<void> setPreferredFuelType(String fuelType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fuelTypeKey, fuelType);
  }

  Future<String> getPreferredFuelType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_fuelTypeKey) ?? 'Benzina';
  }

  // Conversione semplificata delle valute (in produzione usare API real-time)
  double convertCurrency(double priceInEur, String toCurrency) {
    switch (toCurrency) {
      case 'USD':
        return priceInEur * 1.09;
      case 'GBP':
        return priceInEur * 0.86;
      default:
        return priceInEur;
    }
  }
}
