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

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final fuelType = await _prefsService.getPreferredFuelType();
    if (mounted) {
      setState(() {
        _currentFuelType = fuelType;
      });
    }
  }

  String _formatPrice(GasStation station) {
    final priceInfo = station.fuelPrices[_currentFuelType];
    if (priceInfo == null) return 'N/D';

    // Prendi il prezzo self service se disponibile, altrimenti servito
    final price = priceInfo.self > 0 ? priceInfo.self : priceInfo.servito;

    return '€${price.toStringAsFixed(3)}';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stations.isEmpty) {
      return const Center(
        child: Text('Nessuna stazione disponibile'),
      );
    }

    final sortedStations = List<GasStation>.from(widget.stations);

    return ListView.builder(
      itemCount: sortedStations.length,
      itemBuilder: (context, index) {
        final station = sortedStations[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: ListTile(
            title: Text(
              station.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(station.address),
                if (station.gestore.isNotEmpty)
                  Text(
                    station.gestore,
                    style: const TextStyle(fontSize: 12),
                  ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_currentFuelType),
                Text(
                  _formatPrice(station),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
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
