// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../services/preferences_service.dart';
import 'vehicles_page.dart';

class SettingsPage extends StatefulWidget {
  final Function() onSettingsChanged;

  const SettingsPage({super.key, required this.onSettingsChanged});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final PreferencesService _prefsService = PreferencesService();
  String _selectedFuelType = 'Benzina';
  int _searchRadius = 20;
  bool _isElectricModeOnly = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final fuelType = await _prefsService.getPreferredFuelType();
    final radius = await _prefsService.getSearchRadius();
    final isElectricModeOnly = await _prefsService.getIsElectricModeOnly();

    setState(() {
      _selectedFuelType = fuelType;
      _searchRadius = radius;
      _isElectricModeOnly = isElectricModeOnly;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostazioni'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(
              Icons.directions_car,
              color: Colors.orange,
            ),
            title: const Text('Gestisci veicoli'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const VehiclesPage()),
              ).then((_) => widget.onSettingsChanged());
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.electric_car,
              color: Colors.blue,
            ),
            title: const Text('Modalità solo Elettrico'),
            subtitle: Text(_isElectricModeOnly
                ? 'Attiva (verranno mostrate solo stazioni elettriche)'
                : 'Disattiva (verranno mostrate stazioni di tutti i tipi)'),
            trailing: Switch(
              value: _isElectricModeOnly,
              activeColor: Colors.blue,
              onChanged: (bool value) async {
                await _prefsService.setIsElectricModeOnly(value);
                setState(() {
                  _isElectricModeOnly = value;
                  if (value) {
                    _selectedFuelType = 'Elettrica';
                  }
                });

                widget.onSettingsChanged();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(value
                        ? 'Modalità solo Elettrico attivata'
                        : 'Modalità standard attivata'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.local_gas_station,
              color: Colors.orange,
            ),
            title: const Text('Tipo Carburante'),
            subtitle: Text('Attuale: $_selectedFuelType'),
            enabled: !_isElectricModeOnly,
            onTap:
                _isElectricModeOnly ? null : () => _showFuelTypePicker(context),
          ),
          ListTile(
            leading: const Icon(
              Icons.map,
              color: Colors.orange,
            ),
            title: const Text('Raggio di ricerca'),
            subtitle: Text('$_searchRadius km'),
            onTap: () => _showRadiusSelector(context),
          ),
        ],
      ),
    );
  }

  void _showFuelTypePicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleziona Carburante'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: PreferencesService.availableFuelTypes
              .map(
                (fuelType) => RadioListTile<String>(
                  title: Text(fuelType),
                  value: fuelType,
                  groupValue: _selectedFuelType,
                  onChanged: (value) async {
                    if (value != null) {
                      await _prefsService.setPreferredFuelType(value);
                      setState(() => _selectedFuelType = value);

                      Navigator.pop(context);
                      Navigator.pop(context);

                      widget.onSettingsChanged();

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('Tipo carburante cambiato in: $value'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _showRadiusSelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleziona raggio di ricerca'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: PreferencesService.availableRadiusValues
              .map(
                (radius) => RadioListTile<int>(
                  title: Text('$radius km'),
                  value: radius,
                  groupValue: _searchRadius,
                  onChanged: (value) async {
                    if (value != null) {
                      await _prefsService.setSearchRadius(value);
                      setState(() => _searchRadius = value);
                      widget.onSettingsChanged();
                      Navigator.pop(context);
                    }
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
