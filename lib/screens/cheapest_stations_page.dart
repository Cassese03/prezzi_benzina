import 'package:flutter/material.dart';
import '../models/gas_station.dart';
import '../services/preferences_service.dart';

class CheapestStationsPage extends StatefulWidget {
  final List<GasStation> stations;
  final Function(GasStation) onStationSelected;

  const CheapestStationsPage({
    super.key,
    required this.stations,
    required this.onStationSelected,
  });

  @override
  State<CheapestStationsPage> createState() => _CheapestStationsPageState();
}

class _CheapestStationsPageState extends State<CheapestStationsPage> {
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

    final sortedStations = List<GasStation>.from(widget.stations)
      ..sort((a, b) {
        final priceA = a.getLowestPrice(_currentFuelType) ?? double.infinity;
        final priceB = b.getLowestPrice(_currentFuelType) ?? double.infinity;
        return priceA.compareTo(priceB);
      });

    return ListView.builder(
      itemCount: sortedStations.length,
      itemBuilder: (context, index) {
        final station = sortedStations[index];
        final priceInfo = station.fuelPrices[_currentFuelType];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: ListTile(
            leading: const Icon(Icons.local_gas_station),
            title: Text(
              station.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 16,
                      color: Color(0xFFE67E22),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(station.address),
                    ),
                  ],
                ),
                if (station.gestore.isNotEmpty)
                  Text(
                    station.gestore,
                    style: const TextStyle(fontSize: 12),
                  ),
                if (priceInfo != null) ...[
                  if (priceInfo.self > 0)
                    Text(
                      'Self: €${priceInfo.self.toStringAsFixed(3)}',
                      style: TextStyle(
                        color: priceInfo.self < 1.8
                            ? const Color(0xFF2C3E50) // Blu petrolio
                            : priceInfo.self < 2.0
                                ? const Color(0xFFE67E22) // Arancione
                                : const Color(0xFFE74C3C), // Rosso
                      ),
                    ),
                  if (priceInfo.servito > 0)
                    Text(
                      'Servito: €${priceInfo.servito.toStringAsFixed(3)}',
                      style: const TextStyle(color: Colors.blue),
                    ),
                ],
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
