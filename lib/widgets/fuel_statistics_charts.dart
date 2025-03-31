import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/refueling.dart';
import 'package:intl/intl.dart';
import '../models/vehicle.dart';

class FuelStatisticsCharts extends StatefulWidget {
  final List<Refueling> refuelings;
  final Vehicle? selectedVehicle;

  const FuelStatisticsCharts({
    Key? key,
    required this.refuelings,
    required this.selectedVehicle,
  }) : super(key: key);

  @override
  State<FuelStatisticsCharts> createState() => _FuelStatisticsChartsState();
}

class _FuelStatisticsChartsState extends State<FuelStatisticsCharts> {
  DateTime? _startDate;
  DateTime? _endDate;

  final colors = [
    const Color(0xFF2C3E50), // Blu petrolio
    const Color(0xFFE67E22), // Arancione
    const Color(0xFFE74C3C), // Rosso
    const Color(0xFFECF0F1), // Grigio chiaro
  ];

  List<Refueling> get filteredRefuelings {
    return widget.refuelings.where((refueling) {
      if (_startDate == null || _endDate == null) return true;
      return refueling.date.isAfter(_startDate!) &&
          refueling.date.isBefore(_endDate!.add(const Duration(days: 1)));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Veicolo selezionato:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (widget.selectedVehicle != null) ...[
                  Text(
                    widget.selectedVehicle!.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    '${widget.selectedVehicle!.brand} ${widget.selectedVehicle!.model} (${widget.selectedVehicle!.year})',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ] else
                  const Text(
                    'Nessun veicolo selezionato',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: Text(_startDate != null
                        ? DateFormat('dd/MM/yyyy').format(_startDate!)
                        : 'Data inizio'),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _startDate = date);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: Text(_endDate != null
                        ? DateFormat('dd/MM/yyyy').format(_endDate!)
                        : 'Data fine'),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _endDate = date);
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() {
                    _startDate = null;
                    _endDate = null;
                  }),
                ),
              ],
            ),
          ),

          // Spesa totale nel tempo
          _ChartContainer(
            title: 'Spesa Totale nel Tempo',
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text('€${value.toInt()}');
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < filteredRefuelings.length) {
                          return Padding(
                            padding: const EdgeInsets.all(4),
                            child: Text(
                              DateFormat('dd/MM').format(
                                  filteredRefuelings[value.toInt()].date),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: _getCumulativeSpending(),
                    isCurved: true,
                    color: Colors.blue,
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),

          // Consumo medio
          _ChartContainer(
            title: 'Consumo Medio (L/100km)',
            height: 200,
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text('${value.toStringAsFixed(1)}L');
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < filteredRefuelings.length) {
                          return Padding(
                            padding: const EdgeInsets.all(4),
                            child: Text(
                              DateFormat('dd/MM').format(
                                  filteredRefuelings[value.toInt()].date),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: true),
                barGroups: _getConsumptionData(),
              ),
            ),
          ),

          // Chilometri totali
          _ChartContainer(
            title: 'Chilometri Percorsi',
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text('${value.toInt()}km');
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < filteredRefuelings.length) {
                          return Padding(
                            padding: const EdgeInsets.all(4),
                            child: Text(
                              DateFormat('dd/MM').format(
                                  filteredRefuelings[value.toInt()].date),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: _getTotalKilometers(),
                    isCurved: true,
                    color: Colors.green,
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _getCumulativeSpending() {
    double total = 0;
    return List.generate(filteredRefuelings.length, (index) {
      total += filteredRefuelings[index].totalAmount;
      return FlSpot(index.toDouble(), total);
    });
  }

  List<BarChartGroupData> _getConsumptionData() {
    return List.generate(filteredRefuelings.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: filteredRefuelings[index].consumption,
            color: Colors.orange,
          ),
        ],
      );
    });
  }

  List<FlSpot> _getTotalKilometers() {
    if (filteredRefuelings.isEmpty) return [];
    double initialKm = filteredRefuelings.first.kilometers;
    return List.generate(filteredRefuelings.length, (index) {
      return FlSpot(
        index.toDouble(),
        filteredRefuelings[index].kilometers - initialKm,
      );
    });
  }
}

class _ChartContainer extends StatelessWidget {
  final String title;
  final Widget child;
  final double height;

  const _ChartContainer({
    required this.title,
    required this.child,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: height,
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
