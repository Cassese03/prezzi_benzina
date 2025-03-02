import 'package:flutter/material.dart';
import '../models/gas_station.dart';

class AveragePricePage extends StatelessWidget {
  final List<GasStation> stations;

  const AveragePricePage({
    Key? key,
    required this.stations,
  }) : super(key: key);

  Map<String, double> _calculateAveragePrices() {
    Map<String, double> averages = {};
    Map<String, int> counts = {};

    for (var station in stations) {
      station.fuelPrices.forEach((fuelType, price) {
        averages[fuelType] = (averages[fuelType] ?? 0) + price;
        counts[fuelType] = (counts[fuelType] ?? 0) + 1;
      });
    }

    averages.forEach((fuelType, total) {
      averages[fuelType] = total / (counts[fuelType] ?? 1);
    });

    return averages;
  }

  @override
  Widget build(BuildContext context) {
    final averagePrices = _calculateAveragePrices();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Prezzi medi',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                ...averagePrices.entries
                    .map((e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(e.key),
                              Text('€${e.value.toStringAsFixed(3)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ))
                    .toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
