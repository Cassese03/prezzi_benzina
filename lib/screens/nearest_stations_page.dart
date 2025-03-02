import 'package:flutter/material.dart';
import '../models/gas_station.dart';
import '../services/preferences_service.dart';

class NearestStationsPage extends StatefulWidget {
  final List<GasStation> stations;
  final Function(GasStation) onStationSelected;

  const NearestStationsPage({
    Key? key,
    required this.stations,
    required this.onStationSelected,
  }) : super(key: key);

  @override
  State<NearestStationsPage> createState() => _NearestStationsPageState();
}

class _NearestStationsPageState extends State<NearestStationsPage> {
  final PreferencesService _prefsService = PreferencesService();
  String _currentFuelType = 'Benzina';
  String _currentCurrency = 'EUR';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final fuelType = await _prefsService.getPreferredFuelType();
    final currency = await _prefsService.getCurrency();
    setState(() {
      _currentFuelType = fuelType;
      _currentCurrency = currency;
    });
  }

  String _formatPrice(GasStation station) {
    double? price = station.fuelPrices[_currentFuelType];
    if (price == null) return 'N/D';

    if (_currentCurrency != 'EUR') {
      price = _prefsService.convertCurrency(price, _currentCurrency);
    }

    return '${_currentCurrency == 'EUR' ? '€' : _currentCurrency} ${price.toStringAsFixed(3)}';
  }

  @override
  Widget build(BuildContext context) {
    final sortedStations = List<GasStation>.from(widget.stations)
      ..sort((a, b) => (a.latitude - b.latitude)
          .abs()
          .compareTo((b.latitude - b.latitude).abs()));

    return ListView.builder(
      itemCount: sortedStations.length,
      itemBuilder: (context, index) {
        final station = sortedStations[index];
        return Card(
          margin: const EdgeInsets.all(8.0),
          child: ListTile(
            title: Text(station.name),
            subtitle: Text(station.address),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_currentFuelType),
                Text(
                  _formatPrice(station),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            onTap: () => widget.onStationSelected(station),
          ),
        );
      },
    );
  }
}
