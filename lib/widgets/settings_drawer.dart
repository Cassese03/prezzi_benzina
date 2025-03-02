import 'package:flutter/material.dart';
import '../services/preferences_service.dart';

class SettingsDrawer extends StatefulWidget {
  final Function() onSettingsChanged;

  const SettingsDrawer({Key? key, required this.onSettingsChanged})
      : super(key: key);

  @override
  State<SettingsDrawer> createState() => _SettingsDrawerState();
}

class _SettingsDrawerState extends State<SettingsDrawer> {
  final PreferencesService _prefsService = PreferencesService();
  String _selectedCurrency = 'EUR';
  String _selectedFuelType = 'Benzina';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final currency = await _prefsService.getCurrency();
    final fuelType = await _prefsService.getPreferredFuelType();
    setState(() {
      _selectedCurrency = currency;
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
            title: const Text('Valuta'),
            subtitle: Text('Attuale: $_selectedCurrency'),
            trailing: const Icon(Icons.currency_exchange),
            onTap: () => _showCurrencyPicker(context),
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

  void _showCurrencyPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleziona Valuta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: PreferencesService.availableCurrencies
              .map(
                (currency) => RadioListTile<String>(
                  title: Text(currency),
                  value: currency,
                  groupValue: _selectedCurrency,
                  onChanged: (value) async {
                    if (value != null) {
                      await _prefsService.setCurrency(value);
                      setState(() => _selectedCurrency = value);
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
