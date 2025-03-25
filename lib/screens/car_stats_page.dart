import 'package:flutter/material.dart';
import 'package:pompa_benzina/widgets/refueling_list_view.dart';
import 'dart:core';
import '../models/refueling.dart';
import '../services/car_stats_service.dart';
import 'package:intl/intl.dart';
import '../widgets/fuel_statistics_charts.dart';
import '../services/preferences_service.dart';
import '../models/vehicle.dart';

class CarStatsPage extends StatefulWidget {
  const CarStatsPage({Key? key}) : super(key: key);

  @override
  State<CarStatsPage> createState() => _CarStatsPageState();
}

class _CarStatsPageState extends State<CarStatsPage> {
  final CarStatsService _service = CarStatsService();
  final PreferencesService _prefsService = PreferencesService();
  List<Refueling> _refuelings = [];
  Vehicle? _selectedVehicle;
  List<Vehicle> _vehicles = [];
  Map<String, double> _statistics = {
    'totalSpent': 0,
    'averageConsumption': 0,
    'averagePrice': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    final vehicles = await _prefsService.getVehicles();
    setState(() {
      if (vehicles.isNotEmpty) {
        _selectedVehicle = vehicles.first;
        _loadData();
      }
    });
  }

  Future<void> _loadData() async {
    if (_selectedVehicle == null) return;

    final refuelings =
        await _service.getRefuelingsByVehicle(_selectedVehicle!.id);

    final statistics =
        await _service.getStatisticsByVehicle(_selectedVehicle!.id);

    setState(() {
      _refuelings = refuelings;
      _statistics = statistics;
    });
  }

  void _showAddRefuelingDialog() {
    if (_selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleziona prima un veicolo dalle impostazioni'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AddRefuelingForm(
          selectedVehicle: _selectedVehicle!, // Passa il veicolo selezionato
          onSubmit: (refueling) async {
            await _service.addRefueling(refueling);
            _loadData();
          },
        ),
      ),
    );
  }

  void _showRefuelingDetails(Refueling refueling) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Dettaglio Rifornimento',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        Navigator.pop(context);
                        _showEditRefuelingDialog(refueling);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _showDeleteConfirmation(refueling),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text('Data'),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(refueling.date)),
            ),
            ListTile(
              leading: const Icon(Icons.local_gas_station),
              title: Text('Carburante'),
              subtitle: Text(
                  '${refueling.liters.toStringAsFixed(2)} L di ${refueling.fuelType}'),
            ),
            ListTile(
              leading: const Icon(Icons.euro),
              title: Text('Prezzo'),
              subtitle:
                  Text('€${refueling.pricePerLiter.toStringAsFixed(3)}/L'),
            ),
            ListTile(
              leading: const Icon(Icons.speed),
              title: Text('Chilometri'),
              subtitle: Text('${refueling.kilometers.toStringAsFixed(0)} km'),
            ),
            ListTile(
              leading: const Icon(Icons.assessment),
              title: Text('Consumo'),
              subtitle:
                  Text('${refueling.consumption.toStringAsFixed(1)} L/100km'),
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: Text('Totale'),
              subtitle: Text('€${refueling.totalAmount.toStringAsFixed(2)}'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditRefuelingDialog(Refueling refueling) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AddRefuelingForm(
          selectedVehicle: _selectedVehicle!,
          initialRefueling: refueling,
          onSubmit: (updatedRefueling) async {
            await _service.updateRefueling(updatedRefueling);
            _loadData();
          },
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Refueling refueling) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conferma eliminazione'),
        content: const Text('Vuoi davvero eliminare questo rifornimento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ANNULLA'),
          ),
          TextButton(
            onPressed: () async {
              await _service.deleteRefueling(refueling.id);
              if (!mounted) return;
              Navigator.pop(context); // Chiude il dialog
              Navigator.pop(context); // Chiude il bottom sheet
              _loadData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Rifornimento eliminato')),
              );
            },
            child: const Text('ELIMINA', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: Column(
          children: [
            // Aggiungi il selettore del veicolo qui
            if (_vehicles.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.directions_car, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Vehicle>(
                          isExpanded: true,
                          value: _selectedVehicle,
                          items: _vehicles.map((Vehicle vehicle) {
                            return DropdownMenuItem<Vehicle>(
                              value: vehicle,
                              child: Text(
                                '${vehicle.brand} ${vehicle.model}',
                                style: const TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (Vehicle? newValue) {
                            setState(() {
                              _selectedVehicle = newValue;
                              _loadData(); // Ricarica i dati quando cambia il veicolo
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // TabBar esistente
            TabBar(
              labelColor: Theme.of(context).primaryColor,
              tabs: const [
                Tab(text: 'Riepilogo'),
                Tab(text: 'Rifornimenti'),
                Tab(text: 'Grafici'),
              ],
            ),

            // TabBarView esistente
            Expanded(
              child: TabBarView(
                children: [
                  // Riepilogo
                  _buildSummaryTab(),
                  // Lista rifornimenti
                  RefuelingListView(
                    refuelings: _refuelings,
                    onTap: _showRefuelingDetails,
                  ),
                  // Grafici
                  SingleChildScrollView(
                    child: FuelStatisticsCharts(
                      refuelings: _refuelings,
                      selectedVehicle: _selectedVehicle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddRefuelingDialog,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildSummaryTab() {
    final totalKmDriven = _refuelings.isNotEmpty
        ? _refuelings.last.kilometers - _refuelings.first.kilometers
        : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectedVehicle != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.directions_car),
                title: Text(_selectedVehicle!.name),
                subtitle: Text(
                  '${_selectedVehicle!.brand} ${_selectedVehicle!.model} (${_selectedVehicle!.year})',
                ),
              ),
            ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _StatCard(
                    title: 'Spesa Totale',
                    value: '€${_statistics['totalSpent']?.toStringAsFixed(2)}',
                    icon: Icons.euro,
                  ),
                  const Divider(),
                  _StatCard(
                    title: 'Consumo Medio',
                    value:
                        '${_statistics['averageConsumption']?.toStringAsFixed(1)} L/100km',
                    icon: Icons.local_gas_station,
                  ),
                  const Divider(),
                  _StatCard(
                    title: 'Prezzo Medio',
                    value:
                        '€${_statistics['averagePrice']?.toStringAsFixed(3)}/L',
                    icon: Icons.price_check,
                  ),
                  const Divider(),
                  _StatCard(
                    title: 'Chilometri Totali',
                    value: '${totalKmDriven.toStringAsFixed(0)} km',
                    icon: Icons.route,
                  ),
                ],
              ),
            ),
          ),
          if (_refuelings.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Nessun rifornimento registrato.\nPremi + per aggiungerne uno.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildRefuelingsTab() {
    if (_refuelings.isEmpty) {
      return const Center(
        child: Text('Nessun rifornimento registrato'),
      );
    }

    return ListView.builder(
      itemCount: _refuelings.length,
      itemBuilder: (context, index) {
        final refueling = _refuelings[index];
        final date = DateFormat('dd/MM/yyyy').format(refueling.date);
        final lastKm = index > 0 ? _refuelings[index - 1].kilometers : null;
        final kmDriven = refueling.getKmDriven(lastKm);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: InkWell(
            onTap: () => _showRefuelingDetails(refueling),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        date,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '€${refueling.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${refueling.liters.toStringAsFixed(2)} litri'),
                          Text(
                              '€${refueling.pricePerLiter.toStringAsFixed(3)}/L'),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              if (kmDriven > 0) ...[
                                const Icon(Icons.trending_up,
                                    size: 16, color: Colors.blue),
                                Text(
                                  ' +${kmDriven.toStringAsFixed(0)} km',
                                  style: const TextStyle(color: Colors.blue),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                  'Tot: ${refueling.kilometers.toStringAsFixed(0)} km'),
                            ],
                          ),
                          Text(
                            '${refueling.consumption.toStringAsFixed(1)} L/100km',
                            style: TextStyle(
                              color: refueling.consumption > 10
                                  ? Colors.red
                                  : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ignore: unused_element
  Widget _buildChartsTab() {
    if (_refuelings.isEmpty) {
      return const Center(
        child: Text('Nessun dato disponibile per i grafici'),
      );
    }
    return FuelStatisticsCharts(
        refuelings: _refuelings, selectedVehicle: _selectedVehicle);
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Theme.of(context).primaryColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AddRefuelingForm extends StatefulWidget {
  final Function(Refueling) onSubmit;
  final Refueling? initialRefueling;
  final Vehicle selectedVehicle; // Aggiunto parametro richiesto

  const AddRefuelingForm({
    Key? key,
    required this.onSubmit,
    required this.selectedVehicle, // Aggiunto parametro richiesto
    this.initialRefueling,
  }) : super(key: key);

  @override
  State<AddRefuelingForm> createState() => _AddRefuelingFormState();
}

class _AddRefuelingFormState extends State<AddRefuelingForm> {
  final _formKey = GlobalKey<FormState>();
  final _litersController = TextEditingController();
  final _priceController = TextEditingController();
  final _kmController = TextEditingController();
  final _totalController = TextEditingController();
  String _fuelType = 'Benzina';
  double _total = 0;
  double _lastKm = 0;
  double _kmDriven = 0;
  bool _isCalculatingFromTotal = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialRefueling != null) {
      _litersController.text =
          widget.initialRefueling!.liters.toStringAsFixed(2);
      _priceController.text =
          widget.initialRefueling!.pricePerLiter.toStringAsFixed(3);
      _kmController.text =
          widget.initialRefueling!.kilometers.toStringAsFixed(0);
      _totalController.text =
          widget.initialRefueling!.totalAmount.toStringAsFixed(2);
      _fuelType = widget.initialRefueling!.fuelType;
      _total = widget.initialRefueling!.totalAmount;
      _calculateValues();
    } else {
      _loadLastRefueling();
    }
  }

  Future<void> _loadLastRefueling() async {
    final service = CarStatsService();
    final refuelings = await service.getRefuelings();
    if (refuelings.isNotEmpty) {
      final last = refuelings.last;
      setState(() {
        _priceController.text = last.pricePerLiter.toStringAsFixed(3);
        _fuelType = last.fuelType;
        _lastKm = last.kilometers;
        _kmController.text = _lastKm.toStringAsFixed(0);
      });
    }
  }

  void _calculateValues() {
    if (_isCalculatingFromTotal) {
      // Calcola litri dal totalge
      final total = double.tryParse(_totalController.text) ?? 0;
      final price = double.tryParse(_priceController.text) ?? 0;
      if (price > 0) {
        setState(() {
          _total = total;
          _litersController.text = (total / price).toStringAsFixed(2);
        });
      }
    } else {
      // Calcola totale dai litri
      final liters = double.tryParse(_litersController.text) ?? 0;
      final price = double.tryParse(_priceController.text) ?? 0;
      setState(() {
        _total = liters * price;
        _totalController.text = _total.toStringAsFixed(2);
      });
    }

    // Calcola km percorsi in ogni caso
    final newKm = double.tryParse(_kmController.text) ?? _lastKm;
    setState(() {
      _kmDriven = newKm - _lastKm;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.initialRefueling != null
                  ? 'Modifica Rifornimento'
                  : 'Nuovo Rifornimento',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Inserisci per:'),
                const SizedBox(width: 16),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: false,
                      label: Text('Litri'),
                      icon: Icon(Icons.local_gas_station),
                    ),
                    ButtonSegment(
                      value: true,
                      label: Text('Totale €'),
                      icon: Icon(Icons.euro),
                    ),
                  ],
                  selected: {_isCalculatingFromTotal},
                  onSelectionChanged: (Set<bool> newSelection) {
                    setState(() {
                      _isCalculatingFromTotal = newSelection.first;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isCalculatingFromTotal)
              TextFormField(
                controller: _totalController,
                decoration: const InputDecoration(
                  labelText: 'Totale in Euro',
                  prefixIcon: Icon(Icons.euro),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) {
                  _calculateValues();
                },
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Campo richiesto' : null,
              )
            else
              TextFormField(
                controller: _litersController,
                decoration: const InputDecoration(
                  labelText: 'Litri',
                  prefixIcon: Icon(Icons.local_gas_station),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) {
                  _calculateValues();
                },
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Campo richiesto' : null,
              ),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Prezzo al litro',
                prefixIcon: Icon(Icons.euro),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) {
                _calculateValues();
              },
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Campo richiesto' : null,
            ),
            TextFormField(
              controller: _kmController,
              decoration: InputDecoration(
                labelText: 'Chilometri totali',
                prefixIcon: const Icon(Icons.speed),
                helperText: 'Ultimo: ${_lastKm.toStringAsFixed(0)} km',
                suffixText: _kmDriven > 0
                    ? '(+${_kmDriven.toStringAsFixed(0)} km)'
                    : null,
                suffixStyle: const TextStyle(color: Colors.blue),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Inserisci il totale dei chilometri mostrati dal contachilometri'),
                      duration: Duration(seconds: 3),
                    ),
                  ),
                ),
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => _calculateValues(),
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Campo richiesto';
                final km = double.tryParse(value!) ?? 0;
                if (km <= _lastKm) {
                  return 'I chilometri devono essere maggiori dell\'ultimo rifornimento';
                }
                return null;
              },
            ),
            DropdownButtonFormField<String>(
              value: _fuelType,
              items: ['Benzina', 'Gasolio', 'GPL', 'Metano']
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _fuelType = value!),
              decoration: const InputDecoration(
                labelText: 'Tipo carburante',
                prefixIcon: Icon(Icons.local_gas_station),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Chilometri percorsi:',
                          style: TextStyle(fontSize: 16)),
                      Text(
                        '${_kmDriven.toStringAsFixed(0)} km',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Litri:', style: TextStyle(fontSize: 16)),
                      Text(
                        _litersController.text,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Totale:', style: TextStyle(fontSize: 18)),
                      Text(
                        '€${_total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    final liters = double.parse(_litersController.text);
                    final price = double.parse(_priceController.text);
                    widget.onSubmit(Refueling(
                      id: widget.initialRefueling?.id ??
                          DateTime.now().toIso8601String(),
                      date: widget.initialRefueling?.date ?? DateTime.now(),
                      liters: liters,
                      pricePerLiter: price,
                      kilometers: double.parse(_kmController.text),
                      totalAmount: _total,
                      fuelType: _fuelType,
                      vehicleId:
                          widget.selectedVehicle.id, // Aggiunto vehicleId
                    ));
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: Text(
                    widget.initialRefueling != null ? 'Aggiorna' : 'Salva'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _litersController.dispose();
    _priceController.dispose();
    _kmController.dispose();
    _totalController.dispose();
    super.dispose();
  }
}
