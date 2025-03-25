import 'package:flutter/material.dart';
import 'package:pompa_benzina/widgets/add_vehicle_dialog.dart';
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
  // ignore: unused_field
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

  void _showAddVehicleDialog() {
    if (_vehicles.isNotEmpty) {
      // Mostra popup versione premium
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Versione Standard'),
          content: const Text(
            'La versione standard permette di gestire un solo veicolo.\n\n'
            'Passa alla versione Premium per gestire più veicoli!',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () {
                // TODO: Implementare acquisto versione premium
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Versione Premium coming soon!'),
                  ),
                );
              },
              child: const Text(
                'OTTIENI PREMIUM',
                style: TextStyle(color: Colors.amber),
              ),
            ),
          ],
        ),
      );
      return;
    }

    // Mostra dialog per aggiungere il primo veicolo
    showDialog(
      context: context,
      builder: (context) => AddVehicleDialog(
        onVehicleAdded: (vehicle) async {
          await _prefsService.saveVehicle(vehicle);
          if (!mounted) return;
          Navigator.pop(context);
          _loadVehicles();
        },
      ),
    );
  }

  void _showEditVehicleDialog(Vehicle vehicle) {
    final nameController = TextEditingController(text: vehicle.name);
    final brandController = TextEditingController(text: vehicle.brand);
    final modelController = TextEditingController(text: vehicle.model);
    final yearController = TextEditingController(text: vehicle.year.toString());
    final plateController = TextEditingController(text: vehicle.licensePlate);
    String fuelType = vehicle.fuelType;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifica Veicolo'),
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
                items: ['Benzina', 'Gasolio', 'GPL', 'Metano']
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
              final updatedVehicle = Vehicle(
                id: vehicle.id,
                name: nameController.text,
                brand: brandController.text,
                model: modelController.text,
                fuelType: fuelType,
                year: int.tryParse(yearController.text) ?? DateTime.now().year,
                licensePlate: plateController.text,
              );

              await _prefsService.saveVehicle(updatedVehicle);
              if (!mounted) return;
              Navigator.pop(context);
              _loadVehicles();
            },
            child: const Text('SALVA'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('I miei Veicoli'),
      ),
      body: _vehicles.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Nessun veicolo registrato'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _showAddVehicleDialog,
                    child: const Text('Aggiungi Veicolo'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _vehicles.length,
              itemBuilder: (context, index) {
                final vehicle = _vehicles[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: const Icon(Icons.directions_car),
                    title: Text(vehicle.name),
                    subtitle: Text(
                      '${vehicle.brand} ${vehicle.model} (${vehicle.year})',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showEditVehicleDialog(vehicle),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          color: Colors.red,
                          onPressed: () => _showDeleteConfirmation(vehicle),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddVehicleDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDeleteConfirmation(Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina Veicolo'),
        content: Text('Vuoi davvero eliminare ${vehicle.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ANNULLA'),
          ),
          TextButton(
            onPressed: () async {
              await _prefsService.deleteVehicle(vehicle.id);
              if (!mounted) return;
              Navigator.pop(context);
              _loadVehicles();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Veicolo eliminato')),
              );
            },
            child: const Text('ELIMINA', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
