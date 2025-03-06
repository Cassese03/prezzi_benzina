import 'package:flutter/material.dart';
import '../services/preferences_service.dart';
import '../screens/vehicles_page.dart';

class SettingsDrawer extends StatefulWidget {
  final Function() onSettingsChanged;

  const SettingsDrawer({Key? key, required this.onSettingsChanged})
      : super(key: key);

  @override
  State<SettingsDrawer> createState() => _SettingsDrawerState();
}

class _SettingsDrawerState extends State<SettingsDrawer> {
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
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Impostazioni',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Personalizza la tua esperienza',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
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
            title: const Text('Tipo Carburante'),
            subtitle: Text('Attuale: $_selectedFuelType'),
            trailing: const Icon(Icons.local_gas_station),
            onTap: () => _showFuelTypePicker(context),
          ),
          ListTile(
            title: const Text('Raggio di ricerca'),
            subtitle: Text('$_searchRadius km'),
            trailing: const Icon(Icons.map),
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
