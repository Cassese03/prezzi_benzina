import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/gas_station_service.dart';

class CustomCsvPage extends StatefulWidget {
  final Function onFilesImported;

  const CustomCsvPage({Key? key, required this.onFilesImported})
      : super(key: key);

  @override
  _CustomCsvPageState createState() => _CustomCsvPageState();
}

class _CustomCsvPageState extends State<CustomCsvPage> {
  final GasStationService _service = GasStationService();

  String? _stationsFilePath;
  String? _pricesFilePath;
  bool _isLoading = false;

  Future<void> _pickStationsFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        setState(() {
          _stationsFilePath = result.files.single.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore nella selezione del file: $e')),
      );
    }
  }

  Future<void> _pickPricesFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        setState(() {
          _pricesFilePath = result.files.single.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore nella selezione del file: $e')),
      );
    }
  }

  Future<void> _importFiles() async {
    if (_stationsFilePath == null || _pricesFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleziona entrambi i file CSV')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await _service.useCustomCsvFiles(
          _stationsFilePath!, _pricesFilePath!);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File CSV importati con successo')),
        );
        widget.onFilesImported();
        // Torna alla pagina precedente
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossibile importare i file CSV')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante l\'importazione: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Visualizza il contenuto del file CSV selezionato
  Widget _buildFilePreview(String path) {
    return FutureBuilder<String>(
      future: _getFilePreview(path),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        if (snapshot.hasError) {
          return Text('Errore: ${snapshot.error}');
        }

        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
          height: 100,
          child: SingleChildScrollView(
            child: Text(
              snapshot.data ?? 'Impossibile leggere il file',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        );
      },
    );
  }

  Future<String> _getFilePreview(String path) async {
    try {
      final file = File(path);
      if (!file.existsSync()) {
        return 'File non trovato';
      }

      final lines = await file.readAsLines();
      // Restituisci le prime 5 righe
      return lines.take(5).join('\n');
    } catch (e) {
      return 'Errore nella lettura del file: $e';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Importa File CSV'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Seleziona i file CSV che hai scaricato manualmente',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                      '1. File delle stazioni (anagrafica_impianti_attivi.csv):'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _stationsFilePath ?? 'Nessun file selezionato',
                          style: TextStyle(
                            color: _stationsFilePath == null
                                ? Colors.grey
                                : Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _pickStationsFile,
                        child: const Text('Seleziona File'),
                      ),
                    ],
                  ),
                  if (_stationsFilePath != null) ...[
                    const SizedBox(height: 8),
                    _buildFilePreview(_stationsFilePath!),
                  ],
                  const SizedBox(height: 24),
                  const Text('2. File dei prezzi (prezzo_alle_8.csv):'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _pricesFilePath ?? 'Nessun file selezionato',
                          style: TextStyle(
                            color: _pricesFilePath == null
                                ? Colors.grey
                                : Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _pickPricesFile,
                        child: const Text('Seleziona File'),
                      ),
                    ],
                  ),
                  if (_pricesFilePath != null) ...[
                    const SizedBox(height: 8),
                    _buildFilePreview(_pricesFilePath!),
                  ],
                  const SizedBox(height: 32),
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.file_upload),
                      label: const Text('Importa File CSV'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 12),
                      ),
                      onPressed: _importFiles,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Note:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text('• I file devono essere in formato CSV'),
                          Text('• Il separatore deve essere ";"'),
                          Text(
                              '• Il formato deve corrispondere ai file ufficiali del MISE'),
                          Text(
                              '• Verranno copiati nella directory dell\'app e utilizzati al posto di quelli scaricati automaticamente'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
