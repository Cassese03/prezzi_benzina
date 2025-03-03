import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert' show latin1, utf8;
import 'dart:developer' as developer;
import '../utils/permission_handler.dart';
import 'package:flutter/services.dart'; // Aggiungi questa importazione

// Funzione helper per log colorati
void logInfo(String message) {
  developer.log('\x1B[33m$message\x1B[0m', name: 'CSV_VIEWER');
}

void logError(String message) {
  developer.log('\x1B[31m$message\x1B[0m', name: 'CSV_VIEWER_ERROR');
}

class CsvViewerPage extends StatefulWidget {
  const CsvViewerPage({Key? key}) : super(key: key);

  @override
  _CsvViewerPageState createState() => _CsvViewerPageState();
}

class _CsvViewerPageState extends State<CsvViewerPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _stationsFileContent = '';
  String _pricesFileContent = '';
  bool _isLoading = true;
  bool _hasCsvFiles = false;
  String _stationsFilePath = '';
  String _pricesFilePath = '';
  int _stationsFileSize = 0;
  int _pricesFileSize = 0;
  DateTime? _stationsLastModified;
  DateTime? _pricesLastModified;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCsvFiles();
  }

  // Metodo migliorato per trovare i file CSV con gestione errori robusta
  Future<Map<String, String>> _findCsvFilePaths() async {
    final result = <String, String>{
      'stations': '',
      'prices': '',
    };

    try {
      // Prima prova con la directory dell'app
      try {
        final directory = await getApplicationDocumentsDirectory();

        final stationsFile = File('${directory.path}/gas_stations.csv');
        final pricesFile = File('${directory.path}/gas_prices.csv');

        if (stationsFile.existsSync()) {
          result['stations'] = stationsFile.path;
          logInfo('Trovato file stazioni in: ${stationsFile.path}');
        }

        if (pricesFile.existsSync()) {
          result['prices'] = pricesFile.path;
          logInfo('Trovato file prezzi in: ${pricesFile.path}');
        }

        if (result['stations']!.isNotEmpty && result['prices']!.isNotEmpty) {
          return result;
        }
      } catch (e) {
        logError('Errore nella ricerca file nella directory dell\'app: $e');
      }

      // Se non trova i file, cerca in percorsi alternativi
      try {
        final writablePath = await StoragePermissionHandler.findWritablePath();
        if (writablePath != null) {
          final stationsFile = File('$writablePath/gas_stations.csv');
          final pricesFile = File('$writablePath/gas_prices.csv');

          if (stationsFile.existsSync() && result['stations']!.isEmpty) {
            result['stations'] = stationsFile.path;
          }

          if (pricesFile.existsSync() && result['prices']!.isEmpty) {
            result['prices'] = pricesFile.path;
          }
        }
      } catch (e) {
        logError('Errore nella ricerca di percorsi alternativi: $e');
      }

      // Cerca anche nella directory temporanea
      try {
        final tempDir = await getTemporaryDirectory();

        if (result['stations']!.isEmpty) {
          final tempStationsFile =
              File('${tempDir.path}/csv_temp/gas_stations.csv');
          if (tempStationsFile.existsSync()) {
            result['stations'] = tempStationsFile.path;
          }
        }

        if (result['prices']!.isEmpty) {
          final tempPricesFile =
              File('${tempDir.path}/csv_temp/gas_prices.csv');
          if (tempPricesFile.existsSync()) {
            result['prices'] = tempPricesFile.path;
          }
        }
      } catch (e) {
        logError('Errore nella ricerca file nella directory temporanea: $e');
      }

      return result;
    } catch (e) {
      logError('Errore durante la ricerca dei file CSV: $e');
      return result;
    }
  }

  Future<void> _loadCsvFiles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Trova i percorsi dei file
      final paths = await _findCsvFilePaths();
      _stationsFilePath = paths['stations'] ?? '';
      _pricesFilePath = paths['prices'] ?? '';

      logInfo('Percorso file stazioni: $_stationsFilePath');
      logInfo('Percorso file prezzi: $_pricesFilePath');

      // Verifica l'esistenza dei file
      final stationsFile =
          _stationsFilePath.isNotEmpty ? File(_stationsFilePath) : null;
      final pricesFile =
          _pricesFilePath.isNotEmpty ? File(_pricesFilePath) : null;

      if (stationsFile != null &&
          pricesFile != null &&
          stationsFile.existsSync() &&
          pricesFile.existsSync()) {
        try {
          // Ottieni le informazioni sui file
          _stationsFileSize = await stationsFile.length();
          _pricesFileSize = await pricesFile.length();
          _stationsLastModified = (await stationsFile.lastModified());
          _pricesLastModified = (await pricesFile.lastModified());

          logInfo(
              'File stazioni esistente: ${_formatFileSize(_stationsFileSize)}');
          logInfo('File prezzi esistente: ${_formatFileSize(_pricesFileSize)}');
          logInfo('Ultima modifica file stazioni: $_stationsLastModified');
          logInfo('Ultima modifica file prezzi: $_pricesLastModified');

          _hasCsvFiles = true;

          // Leggi le prime 100 righe dei file CSV
          await _readCsvFilesSafely(stationsFile, pricesFile);
        } catch (e) {
          _handleFileReadError(e);
        }
      } else {
        _handleMissingFilesError(stationsFile, pricesFile);
      }
    } catch (e) {
      _handleGeneralError(e);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Nuovo metodo per leggere i file CSV in modo sicuro
  Future<void> _readCsvFilesSafely(File stationsFile, File pricesFile) async {
    try {
      // Leggi le prime 100 righe dei file CSV
      final stationsLines = await _readLinesWithFallback(stationsFile);
      final pricesLines = await _readLinesWithFallback(pricesFile);

      _stationsFileContent = stationsLines.take(100).join('\n');
      _pricesFileContent = pricesLines.take(100).join('\n');

      logInfo('Lettura di ${stationsLines.length} righe dal file stazioni');
      logInfo('Lettura di ${pricesLines.length} righe dal file prezzi');

      // Log delle prime righe
      logInfo(
          'HEADER STAZIONI: ${stationsLines.isNotEmpty ? stationsLines[0] : "Vuoto"}');
      logInfo(
          'PRIMA RIGA DATI STAZIONI: ${stationsLines.length > 1 ? stationsLines[1] : "Non disponibile"}');
      logInfo(
          'HEADER PREZZI: ${pricesLines.isNotEmpty ? pricesLines[0] : "Vuoto"}');
      logInfo(
          'PRIMA RIGA DATI PREZZI: ${pricesLines.length > 1 ? pricesLines[1] : "Non disponibile"}');
    } catch (e) {
      logError('Errore nella lettura sicura dei file: $e');
      throw e; // Rilancia l'errore per gestirlo nel metodo chiamante
    }
  }

  // Nuovo metodo per leggere i file con diversi encoding e gestione errori
  Future<List<String>> _readLinesWithFallback(File file) async {
    List<String> encodings = ['latin1', 'utf8', 'ascii'];
    Exception? lastException;

    for (var encoding in encodings) {
      try {
        switch (encoding) {
          case 'latin1':
            return await file.readAsLines(encoding: latin1);
          case 'utf8':
            return await file
                .readAsBytes()
                .then((bytes) => utf8.decode(bytes, allowMalformed: true))
                .then((content) => content.split('\n'));
          case 'ascii':
            return await file
                .readAsString()
                .then((content) => content.split('\n'));
        }
      } catch (e) {
        lastException = e as Exception;
        logError('Errore lettura con encoding $encoding: $e');
        // Prova il prossimo encoding
      }
    }

    // Se siamo arrivati qui, tutti i metodi di lettura hanno fallito
    // Tenta un approccio più diretto leggendo come bytes e convertendo manualmente
    try {
      final bytes = await file.readAsBytes();
      // Prova a decodificare i primi 100 KB solo (per limitare problemi di memoria)
      final limitedBytes =
          bytes.length > 102400 ? bytes.sublist(0, 102400) : bytes;

      // Prova a interpretare i byte in modo sicuro carattere per carattere
      StringBuffer buffer = StringBuffer();
      for (var byte in limitedBytes) {
        if (byte >= 32 && byte <= 126) {
          // ASCII printable
          buffer.write(String.fromCharCode(byte));
        } else if (byte == 10 || byte == 13) {
          // Line feed or carriage return
          buffer.write('\n');
        } else {
          buffer.write('.'); // Placeholder per caratteri non stampabili
        }
      }
      return buffer.toString().split('\n');
    } catch (e) {
      logError('Anche il fallback di lettura ha fallito: $e');
      throw lastException ?? Exception('Impossibile leggere il file');
    }
  }

  // Nuovo metodo per gestire errori di lettura file
  void _handleFileReadError(dynamic e) {
    logError('Errore nella lettura dei file: $e');

    // Se l'errore è PlatformException di tipo channel-error, gestiscilo specificamente
    if (e is PlatformException && e.code == 'channel-error') {
      _stationsFileContent =
          'Errore di comunicazione con la piattaforma nativa.\n'
          'Questo può verificarsi a causa di problemi di permessi o accesso ai file.\n'
          'Dettagli: ${e.message}';
      _pricesFileContent = _stationsFileContent;
      _errorMessage =
          'Impossibile accedere ai file CSV: problema di comunicazione con la piattaforma nativa';
    } else {
      _stationsFileContent = 'Errore nella lettura del file: $e\n'
          'È possibile che i file siano in un formato non supportato o corrotti.';
      _pricesFileContent = _stationsFileContent;
      _errorMessage = 'Errore nella lettura dei file CSV';
    }

    _hasCsvFiles = false;
  }

  // Nuovo metodo per gestire errori di file mancanti
  void _handleMissingFilesError(File? stationsFile, File? pricesFile) {
    _hasCsvFiles = false;

    if (stationsFile == null || !stationsFile.existsSync()) {
      logError('File stazioni non trovato');
      _stationsFileContent =
          'File non trovato: ${_stationsFilePath.isNotEmpty ? _stationsFilePath : "Percorso non disponibile"}';
    } else {
      _stationsFileContent =
          'File esistente ma non leggibile: $_stationsFilePath';
    }

    if (pricesFile == null || !pricesFile.existsSync()) {
      logError('File prezzi non trovato');
      _pricesFileContent =
          'File non trovato: ${_pricesFilePath.isNotEmpty ? _pricesFilePath : "Percorso non disponibile"}';
    } else {
      _pricesFileContent = 'File esistente ma non leggibile: $_pricesFilePath';
    }

    _errorMessage =
        'File CSV non trovati. Prova a scaricare i dati dalla schermata principale.';
  }

  // Nuovo metodo per gestire errori generali
  void _handleGeneralError(dynamic e) {
    logError('Errore durante il caricamento dei file: $e');
    _stationsFileContent = 'Errore durante il caricamento del file: $e';
    _pricesFileContent = 'Errore durante il caricamento del file: $e';
    _errorMessage =
        'Si è verificato un errore durante il caricamento dei file: $e';
    _hasCsvFiles = false;
  }

  // Aggiungiamo un metodo per salvare i file in modo sicuro
  Future<bool> _saveFileLocally(
      String sourceFilePath, String destinationFileName) async {
    try {
      final sourceFile = File(sourceFilePath);
      if (!sourceFile.existsSync()) {
        logError('File sorgente non trovato: $sourceFilePath');
        return false;
      }

      // Tenta di salvare nella directory dell'app
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final destPath = '${appDir.path}/$destinationFileName';

        await sourceFile.copy(destPath);
        logInfo('File copiato con successo in $destPath');
        return true;
      } catch (e) {
        logError('Errore nel salvataggio in app directory: $e');

        // Fallback alla directory temporanea
        try {
          final tempDir = await getTemporaryDirectory();
          final destPath = '${tempDir.path}/$destinationFileName';

          await sourceFile.copy(destPath);
          logInfo(
              'File copiato con successo nella directory temporanea: $destPath');
          return true;
        } catch (e2) {
          logError('Errore nel salvataggio anche in directory temporanea: $e2');
          return false;
        }
      }
    } catch (e) {
      logError('Errore generale durante il salvataggio: $e');
      return false;
    }
  }

  // Metodo per esportare i file CSV
  Future<void> _exportCsvFiles() async {
    if (!_hasCsvFiles) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nessun file CSV da esportare')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final tempDir = await getTemporaryDirectory();
      final exportDir = Directory('${tempDir.path}/csv_export');

      if (!exportDir.existsSync()) {
        await exportDir.create(recursive: true);
      }

      // Copia i file nella directory di esportazione
      final stationsFile = File(_stationsFilePath);
      final pricesFile = File(_pricesFilePath);

      final stationsExportPath = '${exportDir.path}/gas_stations_export.csv';
      final pricesExportPath = '${exportDir.path}/gas_prices_export.csv';

      await stationsFile.copy(stationsExportPath);
      await pricesFile.copy(pricesExportPath);

      setState(() => _isLoading = false);

      // Mostra un dialogo con i percorsi dei file esportati
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('File esportati con successo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('File CSV esportati in:'),
              const SizedBox(height: 8),
              SelectableText(stationsExportPath,
                  style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 4),
              SelectableText(pricesExportPath,
                  style: const TextStyle(fontSize: 12)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Chiudi'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante l\'esportazione: $e')),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Formatta la dimensione del file in KB o MB
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes bytes';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visualizza File CSV'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Stazioni'),
            Tab(text: 'Prezzi'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Ricarica file',
            onPressed: _loadCsvFiles,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? _buildErrorView()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildFileViewer(
                      'Dati Stazioni (anagrafica_impianti_attivi.csv)',
                      _stationsFileContent,
                      path: _stationsFilePath,
                      size: _stationsFileSize,
                      lastModified: _stationsLastModified,
                    ),
                    _buildFileViewer(
                      'Dati Prezzi (prezzo_alle_8.csv)',
                      _pricesFileContent,
                      path: _pricesFilePath,
                      size: _pricesFileSize,
                      lastModified: _pricesLastModified,
                    ),
                  ],
                ),
    );
  }

  // Nuovo metodo per costruire la vista di errore
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Column(
              children: [
                ElevatedButton(
                  onPressed: _loadCsvFiles,
                  child: const Text('Riprova'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Torna alla Home'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileViewer(
    String title,
    String content, {
    required String path,
    required int size,
    DateTime? lastModified,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.blueGrey.shade50,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              if (_hasCsvFiles) ...[
                SelectableText('Path: $path',
                    style: const TextStyle(fontSize: 12)),
                Text('Dimensione: ${_formatFileSize(size)}',
                    style: const TextStyle(fontSize: 12)),
                if (lastModified != null)
                  Text(
                    'Ultima modifica: ${lastModified.toLocal()}',
                    style: const TextStyle(fontSize: 12),
                  ),
              ] else
                const Text('File non disponibile',
                    style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Contenuto del file (prime 100 righe):',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.grey.shade100,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SelectableText(
                      content,
                      style: const TextStyle(
                          fontFamily: 'monospace', fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
