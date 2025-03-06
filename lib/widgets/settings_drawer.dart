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

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final fuelType = await _prefsService.getPreferredFuelType();
    setState(() {
      _selectedFuelType = fuelType;
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
}
