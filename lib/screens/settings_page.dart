import 'package:flutter/material.dart';
import '../services/preferences_service.dart';
import 'vehicles_page.dart';

class SettingsPage extends StatefulWidget {
  final Function() onSettingsChanged;

  const SettingsPage({Key? key, required this.onSettingsChanged})
      : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final PreferencesService _prefsService = PreferencesService();
  String _selectedFuelType = 'Benzina';
  int _searchRadius = 5;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final fuelType = await _prefsService.getPreferredFuelType();
    final radius = await _prefsService.getSearchRadius();
    setState(() {
      _selectedFuelType = fuelType;
      _searchRadius = radius;
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
            leading: const Icon(Icons.directions_car),
            title: const Text('Gestisci veicoli'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const VehiclesPage()),
              ).then((_) => widget.onSettingsChanged());
            },
          ),
          ListTile(
            leading: const Icon(Icons.local_gas_station),
            title: const Text('Tipo Carburante'),
            subtitle: Text('Attuale: $_selectedFuelType'),
            onTap: () => _showFuelTypePicker(context),
          ),
          ListTile(
            leading: const Icon(Icons.map),
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

                      // Chiudi il dialog
                      Navigator.pop(context);
                      // Chiudi il drawer
                      Navigator.pop(context);

                      // Trigger del refresh completo
                      widget.onSettingsChanged();

                      // Mostra feedback all'utente
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
