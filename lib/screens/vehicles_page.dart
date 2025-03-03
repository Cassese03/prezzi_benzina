import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../services/preferences_service.dart';

class VehiclesPage extends StatefulWidget {
  const VehiclesPage({Key? key}) : super(key: key);

  @override
  State<VehiclesPage> createState() => _VehiclesPageState();
}

class _VehiclesPageState extends State<VehiclesPage> {
  final PreferencesService _prefsService = PreferencesService();
  List<Vehicle> _vehicles = [];
  String? _selectedVehicleId;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    final vehicles = await _prefsService.getVehicles();
    final selectedId = await _prefsService.getSelectedVehicleId();
    setState(() {
      _vehicles = vehicles;
      _selectedVehicleId = selectedId;
    });
  }

  void _showAddVehicleDialog([Vehicle? vehicle]) {
    final nameController = TextEditingController(text: vehicle?.name);
    final brandController = TextEditingController(text: vehicle?.brand);
    final modelController = TextEditingController(text: vehicle?.model);
    final yearController =
        TextEditingController(text: vehicle?.year.toString());
    final plateController = TextEditingController(text: vehicle?.licensePlate);
    String fuelType = vehicle?.fuelType ?? 'Benzina';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(vehicle == null ? 'Nuovo Veicolo' : 'Modifica Veicolo'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                    labelText: 'Nome (es. "La mia auto")'),
              ),
              TextField(
                controller: brandController,
                decoration: const InputDecoration(labelText: 'Marca'),
              ),
              TextField(
                controller: modelController,
                decoration: const InputDecoration(labelText: 'Modello'),
              ),
              TextField(
                controller: yearController,
                decoration: const InputDecoration(labelText: 'Anno'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: plateController,
                decoration:
                    const InputDecoration(labelText: 'Targa (opzionale)'),
              ),
              DropdownButtonFormField<String>(
                value: fuelType,
                items: ['Benzina', 'Diesel', 'GPL', 'Metano']
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (value) => fuelType = value!,
                decoration: const InputDecoration(labelText: 'Tipo carburante'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ANNULLA'),
          ),
          TextButton(
            onPressed: () async {
              final newVehicle = Vehicle(
                id: vehicle?.id ?? DateTime.now().toIso8601String(),
                name: nameController.text,
                brand: brandController.text,
                model: modelController.text,
                fuelType: fuelType,
                year: int.tryParse(yearController.text) ?? DateTime.now().year,
                licensePlate: plateController.text,
              );

              await _prefsService.saveVehicle(newVehicle);
              if (!mounted) return;
              Navigator.pop(context);
              _loadVehicles();
            },
            child: Text(vehicle == null ? 'AGGIUNGI' : 'SALVA'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('I miei veicoli'),
      ),
      body: ListView.builder(
        itemCount: _vehicles.length,
        itemBuilder: (context, index) {
          final vehicle = _vehicles[index];
          return ListTile(
            leading: Radio<String>(
              value: vehicle.id,
              groupValue: _selectedVehicleId,
              onChanged: (value) async {
                await _prefsService.setSelectedVehicleId(value!);
                _loadVehicles();
              },
            ),
            title: Text(vehicle.name),
            subtitle:
                Text('${vehicle.brand} ${vehicle.model} (${vehicle.year})'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showAddVehicleDialog(vehicle),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await _prefsService.deleteVehicle(vehicle.id);
                    _loadVehicles();
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddVehicleDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
