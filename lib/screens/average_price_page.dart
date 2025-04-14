import 'package:flutter/material.dart';
import '../models/gas_station.dart';

class AveragePricePage extends StatelessWidget {
  final List<GasStation> stations;

  const AveragePricePage({
    super.key,
    required this.stations,
  });

  Map<String, double> _calculateAveragePrices() {
    Map<String, double> sums = {};
    Map<String, int> counts = {};

    // Calcola le somme e conta solo i prezzi validi
    for (var station in stations) {
      station.fuelPrices.forEach((fuelType, priceInfo) {
        final price = priceInfo.self > 0 ? priceInfo.self : priceInfo.servito;
        if (price > 0) {
          // Conta solo se il prezzo è valido
          sums[fuelType] = (sums[fuelType] ?? 0) + price;
          counts[fuelType] = (counts[fuelType] ?? 0) + 1;
        }
      });
    }

    // Calcola le medie solo per i tipi di carburante con prezzi validi
    Map<String, double> averages = {};
    sums.forEach((fuelType, total) {
      if (counts[fuelType]! > 0) {
        averages[fuelType] = total / counts[fuelType]!;
      }
    });

    return averages;
  }

  @override
  Widget build(BuildContext context) {
    if (stations.isEmpty) {
      return const Center(child: Text('Nessuna stazione disponibile'));
    }

    final averages = _calculateAveragePrices();
    final sortedFuelTypes = averages.keys.toList()
      ..sort((a, b) => averages[a]!.compareTo(averages[b]!));

    return ListView.builder(
      itemCount: sortedFuelTypes.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final fuelType = sortedFuelTypes[index];
        final average = averages[fuelType]!;

        return Card(
          child: ListTile(
            title: Text(fuelType),
            trailing: Text(
              '€${average.toStringAsFixed(3)}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        );
      },
    );
  }
}
