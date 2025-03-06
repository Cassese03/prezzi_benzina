import 'package:flutter/material.dart';
import '../models/vehicle.dart';

class AddVehicleDialog extends StatefulWidget {
  final Function(Vehicle) onVehicleAdded;

  const AddVehicleDialog({
    Key? key,
    required this.onVehicleAdded,
  }) : super(key: key);

  @override
  State<AddVehicleDialog> createState() => _AddVehicleDialogState();
}

class _AddVehicleDialogState extends State<AddVehicleDialog> {
  final nameController = TextEditingController();
  final brandController = TextEditingController();
  final modelController = TextEditingController();
  final yearController = TextEditingController(
    text: DateTime.now().year.toString(),
  );
  final plateController = TextEditingController();
  String fuelType = 'Benzina';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuovo Veicolo'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nome (es. "La mia auto")',
              ),
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
              decoration: const InputDecoration(labelText: 'Targa (opzionale)'),
            ),
            DropdownButtonFormField<String>(
              value: fuelType,
              items: ['Benzina', 'Diesel', 'GPL', 'Metano']
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => fuelType = value!),
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
          onPressed: () {
            // Validazione campi obbligatori
            if (nameController.text.isEmpty ||
                brandController.text.isEmpty ||
                modelController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Compila i campi obbligatori'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            final newVehicle = Vehicle(
              id: DateTime.now().toIso8601String(), // ID univoco
              name: nameController.text,
              brand: brandController.text,
              model: modelController.text,
              fuelType: fuelType,
              year: int.tryParse(yearController.text) ?? DateTime.now().year,
              licensePlate: plateController.text,
            );

            widget.onVehicleAdded(newVehicle);
          },
          child: const Text('SALVA'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    brandController.dispose();
    modelController.dispose();
    yearController.dispose();
    plateController.dispose();
    super.dispose();
  }
}
