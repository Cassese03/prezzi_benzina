import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:developer'
    as developer; // Importiamo il modulo developer per i log
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/gas_station.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert' show utf8, latin1;
import 'dart:math';

// Funzione helper per fare log con colore e formato uniforme
void logInfo(String message) {
  developer.log('\x1B[33m$message\x1B[0m', name: 'CSV_SERVICE');
}

void logError(String message) {
  developer.log('\x1B[31m$message\x1B[0m', name: 'CSV_SERVICE_ERROR');
}

void logDebug(String message) {
  developer.log('\x1B[36m$message\x1B[0m', name: 'CSV_DEBUG');
}

class CsvGasStationService {
  // URL del file CSV ufficiale del MISE
  final String _csvUrl =
      'https://www.mise.gov.it/images/exportCSV/anagrafica_impianti_attivi.csv';
  final String _pricesUrl =
      'https://www.mise.gov.it/images/exportCSV/prezzo_alle_8.csv';

  // Nome dei file locali
  final String _stationsFileName = 'gas_stations.csv';
  final String _pricesFileName = 'gas_prices.csv';

  // Chiavi per SharedPreferences
  final String _lastUpdateKey = 'last_csv_update';

  // Periodo di aggiornamento (in ore)
  final int _updateInterval = 24;

  // Callback per il progresso del download
  Function(double)? _progressCallback;

  // Imposta il callback per il progresso del download
  void setProgressCallback(Function(double) callback) {
    _progressCallback = callback;
  }

  // Rimuove il callback per il progresso del download
  void clearProgressCallback() {
    _progressCallback = null;
  }

  // Carica le stazioni di benzina usando sempre le coordinate fisse
  Future<List<GasStation>> getGasStations(
      double lat, double lng, int distance) async {
    // Utilizziamo sempre le coordinate specificate esattamente
    final fixedLat = 40.93219998333439;
    final fixedLng = 14.528259514051589;

    logInfo('Utilizzo coordinate specifiche: $fixedLat, $fixedLng');
    logInfo('Raggio di ricerca richiesto: $distance km');

    try {
      // Verifica che i file esistano e siano validi
      final directory = await getApplicationDocumentsDirectory();
      final stationsFile = File('${directory.path}/$_stationsFileName');
      final pricesFile = File('${directory.path}/$_pricesFileName');

      // Informa l'utente dei percorsi file per debug
      logInfo('Percorso file stazioni: ${stationsFile.path}');
      logInfo('Percorso file prezzi: ${pricesFile.path}');

      // Verifica esistenza file
      if (!stationsFile.existsSync()) {
        logInfo('File stazioni non trovato. Avvio download...');
        await forceUpdate();
      } else {
        logInfo(
            'File stazioni esistente: ${await stationsFile.length()} bytes');
      }

      if (!pricesFile.existsSync()) {
        logInfo('File prezzi non trovato. Avvio download...');
        await forceUpdate();
      } else {
        logInfo('File prezzi esistente: ${await pricesFile.length()} bytes');
      }

      // Log dettagliato del contenuto dei file
      await _logCsvFileContent(stationsFile, 'STAZIONI');
      await _logCsvFileContent(pricesFile, 'PREZZI');

      // Carica le stazioni dal file locale
      final stations = await _loadStationsFromLocal();
      logInfo(
          'Trovate ${stations.length} stazioni nei file CSV prima del filtro di distanza');

      if (stations.isEmpty) {
        logInfo(
            'Nessuna stazione trovata nei file CSV. Tentativo di re-download...');
        await forceUpdate();

        // Riprova a caricare dopo il download
        final retryStations = await _loadStationsFromLocal();
        logInfo('Dopo re-download: ${retryStations.length} stazioni caricate');

        // Se ancora non ci sono stazioni, restituisci lista vuota
        if (retryStations.isEmpty) {
          logError('Nessuna stazione trovata anche dopo il re-download');

          // Verifica il contenuto dei file scaricati
          _debugPrintCsvSample(stationsFile, pricesFile);

          return [];
        }
        return retryStations;
      }

      // IMPORTANTE: Disattiva temporaneamente il filtro di distanza per debug
      logInfo(
          '⚠️ Disattivando filtro distanza per debug e mostrando tutte le stazioni');
      // Commenta la riga successiva per vedere tutte le stazioni indipendentemente dalla distanza
      // return stations.take(50).toList(); // Restituisci le prime 50 stazioni senza filtro

      // Filtra le stazioni per distanza dalle coordinate specifiche
      var filteredStations =
          _filterStationsByDistance(stations, fixedLat, fixedLng, distance);
      logInfo(
          'Dopo filtro distanza, rimaste ${filteredStations.length} stazioni');

      // Se non ci sono stazioni entro il raggio specificato, aumentiamo il raggio significativamente
      if (filteredStations.isEmpty) {
        logInfo(
            'Nessuna stazione entro $distance km. Aumento raggio di ricerca a 100 km');
        filteredStations = _filterStationsByDistance(
            stations, fixedLat, fixedLng, 100); // Aumentato a 100 km!
        logInfo(
            'Con raggio esteso a 100 km, trovate ${filteredStations.length} stazioni');
      }

      // Se ancora non ci sono stazioni, restituisci le prime 20 indipendentemente dalla distanza
      if (filteredStations.isEmpty && stations.isNotEmpty) {
        logInfo(
            'Nessuna stazione entro 100 km. Mostro le prime 20 stazioni senza filtro di distanza');
        return stations.take(20).toList();
      }

      return filteredStations;
    } catch (e) {
      logError('Errore nel caricamento delle stazioni: $e');
      logError('Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  // Nuovo metodo per logging del contenuto del CSV
  Future<void> _logCsvFileContent(File file, String fileType) async {
    try {
      if (!file.existsSync()) {
        logError('File $fileType non esiste: ${file.path}');
        return;
      }

      final fileSize = await file.length();
      logInfo(
          '------ CONTENUTO FILE $fileType (${_formatSize(fileSize)}) ------');

      try {
        // Leggiamo solo le prime 5 righe per il log
        final lines = await file.readAsLines(encoding: latin1);
        logInfo('Numero totale righe: ${lines.length}');

        // Header
        if (lines.isNotEmpty) {
          logInfo('HEADER: ${lines[0]}');
        }

        // Prime 4 righe di dati
        final dataLines =
            lines.length > 1 ? lines.sublist(1, min(5, lines.length)) : [];
        for (int i = 0; i < dataLines.length; i++) {
          logInfo('RIGA ${i + 1}: ${dataLines[i]}');
        }
      } catch (e) {
        logError('Errore durante la lettura del file $fileType per il log: $e');
      }

      logInfo('------ FINE CONTENUTO FILE $fileType ------');
    } catch (e) {
      logError('Errore durante il logging del file $fileType: $e');
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes bytes';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  // Nuovo metodo per debug: stampa campioni dei file CSV
  Future<void> _debugPrintCsvSample(File stationsFile, File pricesFile) async {
    try {
      logInfo('======= DEBUG CONTENUTO CSV =======');

      // Verifica esistenza file
      if (stationsFile.existsSync()) {
        // Prendi le prime 5 righe del file stazioni
        final stationsLines = await stationsFile.readAsLines();
        logInfo('STAZIONI CSV - Prime 5 righe:');
        for (int i = 0; i < min(5, stationsLines.length); i++) {
          logInfo('${i + 1}: ${stationsLines[i]}');
        }
      } else {
        logInfo('File stazioni non trovato');
      }

      if (pricesFile.existsSync()) {
        // Prendi le prime 5 righe del file prezzi
        final pricesLines = await pricesFile.readAsLines();
        logInfo('PREZZI CSV - Prime 5 righe:');
        for (int i = 0; i < min(5, pricesLines.length); i++) {
          logInfo('${i + 1}: ${pricesLines[i]}');
        }
      } else {
        logInfo('File prezzi non trovato');
      }

      logInfo('===================================');
    } catch (e) {
      logError('Errore durante il debug dei file CSV: $e');
    }
  }

  // Nuovo metodo per recuperare le prime 10 stazioni CSV senza filtri
  Future<List<GasStation>> getFirst10Stations() async {
    try {
      logInfo('Caricamento delle prime 10 stazioni dal CSV senza filtri');

      // Ottieni la directory dove sono salvati i file
      final directory = await getApplicationDocumentsDirectory();
      final stationsFile = File('${directory.path}/$_stationsFileName');
      final pricesFile = File('${directory.path}/$_pricesFileName');

      // Verifica se i file esistono
      if (!stationsFile.existsSync()) {
        logInfo('File stazioni non trovato: ${stationsFile.path}');
        await forceUpdate(); // Tenta di scaricare i file se non esistono
      }

      if (!pricesFile.existsSync()) {
        logInfo('File prezzi non trovato: ${pricesFile.path}');
        await forceUpdate(); // Tenta di scaricare i file se non esistono
      }

      // Legge le prime 50 righe dei file per fare debug
      String stationsContent = '';
      String pricesContent = '';

      try {
        final stationsLines = await stationsFile.readAsLines(encoding: latin1);
        final pricesLines = await pricesFile.readAsLines(encoding: latin1);

        // Stampa alcune righe per debug
        logInfo('Prime righe del file stazioni:');
        for (int i = 0; i < min(5, stationsLines.length); i++) {
          logInfo('RIGA $i: ${stationsLines[i]}');
        }

        logInfo('Prime righe del file prezzi:');
        for (int i = 0; i < min(5, pricesLines.length); i++) {
          logInfo('RIGA $i: ${pricesLines[i]}');
        }

        // Ricostruisci il contenuto per il parsing
        stationsContent = stationsLines.join('\n');
        pricesContent = pricesLines.join('\n');
      } catch (e) {
        logError('Errore nella lettura delle righe: $e');
        // Tenta di leggere l'intero file se la lettura per righe fallisce
        stationsContent = await stationsFile.readAsString(encoding: latin1);
        pricesContent = await pricesFile.readAsString(encoding: latin1);
      }

      // Parsa i dati CSV
      final allStations =
          await _parseRawCSVData(stationsContent, pricesContent);

      // Restituisci solo le prime 10 stazioni
      final first10 = allStations.take(10).toList();

      logInfo('Estratte ${first10.length} stazioni dalle prime righe CSV');

      // Stampa dettagli delle stazioni trovate
      for (int i = 0; i < first10.length; i++) {
        final station = first10[i];
        logInfo('STAZIONE $i: ID=${station.id}, Nome=${station.name}, '
            'Coord=(${station.latitude}, ${station.longitude}), '
            'Prezzi=${station.fuelPrices}');
      }

      return first10;
    } catch (e) {
      logError('Errore nell\'estrazione delle prime 10 stazioni: $e');
      return [];
    }
  }

  // Metodo helper per parsare i dati CSV senza filtri
  Future<List<GasStation>> _parseRawCSVData(
      String stationsContent, String pricesContent) async {
    try {
      final stations = <String, Map<String, dynamic>>{};
      final prices = <String, Map<String, double>>{};

      // Parsa il file delle stazioni
      final List<List<dynamic>> stationsRows = const CsvToListConverter()
          .convert(stationsContent, fieldDelimiter: ';');

      logInfo('File stazioni ha ${stationsRows.length} righe');

      // Salta l'header e processa le righe
      for (int i = 1; i < min(100, stationsRows.length); i++) {
        final row = stationsRows[i];
        if (row.length < 6) {
          logInfo('Riga $i ha ${row.length} colonne (< 6), saltata');
          continue;
        }

        final id = row[0]?.toString() ?? '';
        if (id.isEmpty) continue;

        final lat = _parseCoordinate(row[4]?.toString() ?? '');
        final lng = _parseCoordinate(row[5]?.toString() ?? '');

        stations[id] = {
          'id': id,
          'name': row[1]?.toString() ?? 'Sconosciuto',
          'address': '${row[2] ?? ''}, ${row[3] ?? ''}',
          'latitude': lat,
          'longitude': lng,
        };
      }

      logInfo('Processate ${stations.length} stazioni valide');

      // Parsa il file dei prezzi
      final List<List<dynamic>> pricesRows = const CsvToListConverter()
          .convert(pricesContent, fieldDelimiter: ';');

      logInfo('File prezzi ha ${pricesRows.length} righe');

      // Salta l'header e processa le righe
      for (int i = 1; i < min(500, pricesRows.length); i++) {
        final row = pricesRows[i];
        if (row.length < 4) continue;

        final id = row[0]?.toString() ?? '';
        final fuelType = row[2]?.toString() ?? '';
        final priceStr = row[3]?.toString().replaceAll(',', '.') ?? '';

        if (id.isEmpty || fuelType.isEmpty || priceStr.isEmpty) continue;

        // Converti il prezzo in double
        double? price = double.tryParse(priceStr);
        if (price == null) continue;

        if (!prices.containsKey(id)) {
          prices[id] = {};
        }

        // Mappa i tipi di carburante
        switch (fuelType) {
          case 'Benzina':
          case 'Benzina SP 98':
            prices[id]!['Benzina'] = price;
            break;
          case 'Gasolio':
          case 'Gasolio Speciale':
            prices[id]!['Diesel'] = price;
            break;
          case 'GPL':
            prices[id]!['GPL'] = price;
            break;
          case 'Metano':
            prices[id]!['Metano'] = price;
            break;
        }
      }

      logInfo('Processati prezzi per ${prices.length} stazioni');

      // Combina i dati delle stazioni e dei prezzi
      final List<GasStation> result = [];

      stations.forEach((id, stationData) {
        final priceData = prices[id] ?? {};

        // Solo se ci sono prezzi disponibili
        if (priceData.isNotEmpty) {
          result.add(GasStation(
            id: id,
            name: stationData['name'],
            latitude: stationData['latitude'],
            longitude: stationData['longitude'],
            address: stationData['address'],
            fuelPrices: priceData,
          ));
        }
      });

      logInfo('Create ${result.length} istanze GasStation');
      return result;
    } catch (e) {
      logError('Errore nel parsing CSV raw: $e');
      return [];
    }
  }

  // Controlla se è necessario aggiornare i dati e, se sì, scarica il nuovo CSV
  Future<void> _checkAndUpdateData() async {
    final prefs = await SharedPreferences.getInstance();
    final lastUpdate = prefs.getInt(_lastUpdateKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Se sono passate più di _updateInterval ore dall'ultimo aggiornamento
    if (now - lastUpdate > _updateInterval * 3600 * 1000) {
      logInfo('Dati non aggiornati. Download in corso...');
      try {
        await _downloadCsvFiles();
        await prefs.setInt(_lastUpdateKey, now);
        logInfo('Download completato e dati aggiornati');
      } catch (e) {
        logError('Errore nel download dei file CSV: $e');
        // Continua con i dati vecchi se il download fallisce
      }
    } else {
      logInfo(
          'Utilizzo dati esistenti (aggiornati ${_formatTimeAgo(lastUpdate)})');
    }
  }

  // Controlla se è necessario aggiornare i dati
  Future<bool> needsUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    final lastUpdate = prefs.getInt(_lastUpdateKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Se sono passate più di _updateInterval ore dall'ultimo aggiornamento
    return (now - lastUpdate > _updateInterval * 3600 * 1000);
  }

  // Forza l'aggiornamento dei dati
  Future<void> forceUpdate() async {
    try {
      await _downloadCsvFiles();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      logError('Errore nell\'aggiornamento forzato: $e');
      rethrow;
    }
  }

  // Scarica i file CSV
  Future<void> _downloadCsvFiles() async {
    logInfo('Avvio download dei file CSV utilizzando solo URL primari');

    try {
      // Verifica la struttura delle directory prima di procedere
      await _checkDirectoryStructure();

      // Scarica prima il file delle stazioni
      await _downloadFile(_csvUrl, _stationsFileName, 0.0, 0.5);
      logInfo('Download file stazioni completato');

      // Poi scarica il file dei prezzi
      await _downloadFile(_pricesUrl, _pricesFileName, 0.5, 1.0);
      logInfo('Download file prezzi completato');

      // Verifica che i file esistano e siano validi
      final success = await _verifyDownloadedFiles();
      if (!success) {
        throw Exception('I file scaricati non sono validi o sono incompleti');
      }
    } catch (e) {
      logError('Errore durante il download dei file CSV: $e');

      // Non utilizziamo più metodi alternativi, semplicemente rilancia l'eccezione
      throw Exception('Impossibile scaricare i file CSV: $e');
    } finally {
      if (_progressCallback != null) {
        _progressCallback!(1.0);
      }
    }
  }

  // Scarica un singolo file con gestione errori migliorata
  Future<void> _downloadFile(String url, String fileName, double startProgress,
      double endProgress) async {
    try {
      // Notifica inizio download
      if (_progressCallback != null) {
        _progressCallback!(startProgress);
      }

      logInfo('Avvio download da $url');

      // Ottieni la directory dove salvare i file
      final filePath = await _getSafeFilePath(fileName);
      logInfo('Salvataggio file in $filePath');

      // Verifico che la directory esista e abbia permessi di scrittura
      final directory = Directory(filePath).parent;
      if (!directory.existsSync()) {
        logError('La directory non esiste');
        try {
          await directory.create(recursive: true);
          logInfo('Directory creata');
        } catch (e) {
          logError('Impossibile creare la directory: $e');
          throw Exception('Impossibile creare la directory di salvataggio');
        }
      }

      // Crea la richiesta HTTP
      final request = http.Request('GET', Uri.parse(url));

      // Imposta gli headers per simulare una richiesta da browser
      request.headers['User-Agent'] =
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36';
      request.headers['Accept'] =
          'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8';
      request.headers['Accept-Language'] =
          'it-IT,it;q=0.9,en-US;q=0.8,en;q=0.7';

      logInfo('Headers richiesta: ${request.headers}');

      // Invia la richiesta con timeout aumentato
      final httpClient = http.Client();
      final response = await httpClient.send(request).timeout(
        const Duration(minutes: 5), // Aumentato a 5 minuti
        onTimeout: () {
          httpClient.close();
          throw TimeoutException(
              'Timeout durante il download di $fileName (5 minuti)');
        },
      );

      // Verifica che la risposta sia OK
      logInfo('Status code risposta: ${response.statusCode}');
      logInfo('Headers risposta: ${response.headers}');

      if (response.statusCode == 200) {
        // Ottieni la dimensione totale del file
        final contentLength = response.contentLength ?? 0;
        logInfo('Content length dichiarato: $contentLength bytes');

        int downloadedBytes = 0;
        List<int> bytes = [];

        // Prepara il file in cui salvare i dati
        final file = File(filePath);

        // Se il file esiste già, lo eliminiamo
        if (file.existsSync()) {
          await file.delete();
          logInfo('File esistente eliminato');
        }

        final sink = file.openWrite();

        // Leggi i dati in streaming e aggiorna il progresso
        await response.stream.listen(
          (List<int> chunk) {
            // Scrivi il chunk nel file
            sink.add(chunk);
            bytes.addAll(chunk);

            // Aggiorna il progresso
            downloadedBytes += chunk.length;
            if (contentLength > 0 && _progressCallback != null) {
              final progress = startProgress +
                  ((downloadedBytes / contentLength) *
                      (endProgress - startProgress));
              _progressCallback!(progress);

              if (downloadedBytes % 524288 == 0) {
                // ~ 512 KB
                logInfo(
                    'Download in corso: ${(downloadedBytes / 1024).toStringAsFixed(0)}/${(contentLength / 1024).toStringAsFixed(0)} KB');
              }
            }
          },
          onDone: () async {
            await sink.flush();
            await sink.close();
            logInfo('Download completato: $downloadedBytes bytes');
          },
          onError: (error) {
            logError('Errore durante il download: $error');
            sink.close();
            throw error;
          },
          cancelOnError: true,
        ).asFuture();

        // Verifica che il file esista e non sia vuoto
        final savedFile = File(filePath);
        if (!savedFile.existsSync()) {
          throw Exception('Il file non è stato salvato correttamente');
        }

        final fileSize = await savedFile.length();
        logInfo(
            'File $fileName salvato con successo. Dimensione: ${(fileSize / 1024).toStringAsFixed(0)} KB');

        // Log del contenuto iniziale del file appena scaricato
        await _logCsvFileContent(savedFile, fileName.toUpperCase());

        if (fileSize < 100) {
          // Se il file è troppo piccolo (meno di 100 byte)
          throw Exception(
              'Il file scaricato è troppo piccolo e potrebbe essere corrotto (solo $fileSize bytes)');
        }

        // Notifica completamento
        if (_progressCallback != null) {
          _progressCallback!(endProgress);
        }
      } else {
        String errorBody = '';
        try {
          // Cerca di leggere il corpo dell'errore
          final errorBytes = await response.stream.toBytes();
          errorBody = utf8.decode(errorBytes, allowMalformed: true);
        } catch (e) {
          errorBody = 'Non è stato possibile leggere il corpo dell\'errore';
        }

        throw Exception(
            'Errore HTTP ${response.statusCode}: ${response.reasonPhrase}. Dettagli: $errorBody');
      }
    } catch (e) {
      logError('Errore durante il download di $fileName: $e');
      rethrow;
    }
  }

  // Nuovo metodo per scaricare un file in una posizione personalizzata
  Future<bool> downloadToCustomLocation(
      String url, String destinationPath) async {
    try {
      logInfo('Scaricamento file da $url a $destinationPath');

      // Crea la directory se non esiste
      final directory = Directory(File(destinationPath).parent.path);
      if (!directory.existsSync()) {
        await directory.create(recursive: true);
      }

      // Esegue la richiesta HTTP
      final request = http.Request('GET', Uri.parse(url));
      request.headers['User-Agent'] =
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36';

      final httpClient = http.Client();
      final response = await httpClient.send(request).timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          httpClient.close();
          throw TimeoutException('Timeout durante il download (5 minuti)');
        },
      );

      // Verifica la risposta
      if (response.statusCode != 200) {
        throw Exception('Errore HTTP ${response.statusCode}');
      }

      // Salva il file
      final file = File(destinationPath);
      if (file.existsSync()) await file.delete();

      final sink = file.openWrite();
      await response.stream.pipe(sink);
      await sink.flush();
      await sink.close();

      // Verifica che il file sia stato scaricato correttamente
      if (!file.existsSync() || await file.length() < 100) {
        logError('File scaricato non valido o troppo piccolo');
        return false;
      }

      logInfo(
          'Download completato: $destinationPath (${await file.length()} bytes)');
      return true;
    } catch (e) {
      logError('Errore durante il download personalizzato: $e');
      return false;
    }
  }

  // Carica le stazioni dal file locale
  Future<List<GasStation>> _loadStationsFromLocal() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final stationsFile = File('${directory.path}/$_stationsFileName');
      final pricesFile = File('${directory.path}/$_pricesFileName');

      // Verifica se i file esistono
      if (!stationsFile.existsSync()) {
        logError('File stazioni non trovato: ${stationsFile.path}');
        return [];
      }
      if (!pricesFile.existsSync()) {
        logError('File prezzi non trovato: ${pricesFile.path}');
        return [];
      }

      logInfo('Lettura file stazioni: ${stationsFile.path}');
      logInfo('Lettura file prezzi: ${pricesFile.path}');

      // Leggi i file CSV
      final stationsContent = await stationsFile.readAsString();
      final pricesContent = await pricesFile.readAsString();

      logInfo('Letto ${stationsContent.length} caratteri dal file stazioni');
      logInfo('Letto ${pricesContent.length} caratteri dal file prezzi');

      if (stationsContent.isEmpty || pricesContent.isEmpty) {
        logError('Uno dei file CSV è vuoto');
        return [];
      }

      try {
        // Parsare in modo asincrono per non bloccare la UI
        final result = await compute(_parseCSVData,
            {'stations': stationsContent, 'prices': pricesContent});

        logInfo('Parsing completato con ${result.length} stazioni');
        return result;
      } catch (parseError) {
        logError('Errore durante il parsing CSV: $parseError');
        // In caso di errore di parsing, proviamo a recuperare direttamente
        return _parseCSVDataDirect(stationsContent, pricesContent);
      }
    } catch (e) {
      logError('Errore nel caricamento dei dati locali: $e');
      return [];
    }
  }

  // Versione diretta del parsing CSV (non usa compute) per casi di errore
  List<GasStation> _parseCSVDataDirect(
      String stationsContent, String pricesContent) {
    try {
      logInfo('Tentativo di parsing diretto CSV');
      final stations = <String, Map<String, dynamic>>{};
      final prices = <String, Map<String, double>>{};

      // Verifica contenuto
      logInfo(
          'Dimensione contenuto stazioni: ${stationsContent.length} caratteri');
      logInfo('Dimensione contenuto prezzi: ${pricesContent.length} caratteri');

      // Mostra campioni di contenuto
      logInfo(
          'Prime 100 caratteri file stazioni: ${stationsContent.substring(0, min(100, stationsContent.length))}');
      logInfo(
          'Prime 100 caratteri file prezzi: ${pricesContent.substring(0, min(100, pricesContent.length))}');

      // Determina il separatore del CSV (potrebbe essere ; o ,)
      String delimiter = stationsContent.contains(';') ? ';' : ',';
      logInfo('Separatore rilevato: "$delimiter"');

      // Parsa il file delle stazioni
      List<List<dynamic>> stationsRows;
      try {
        stationsRows = const CsvToListConverter()
            .convert(stationsContent, fieldDelimiter: delimiter);
        logInfo('Parsing stazioni: ${stationsRows.length} righe trovate');
      } catch (e) {
        logError('Errore nel parsing del file stazioni: $e');
        logError('Tentativo con altri separatori...');
        // Prova con separatore alternativo
        delimiter = delimiter == ';' ? ',' : ';';
        stationsRows = const CsvToListConverter()
            .convert(stationsContent, fieldDelimiter: delimiter);
        logInfo(
            'Parsing stazioni con separatore "$delimiter": ${stationsRows.length} righe trovate');
      }

      // Analizza la prima riga per identificare le colonne
      if (stationsRows.isNotEmpty) {
        logInfo('Prima riga stazioni (intestazione): ${stationsRows[0]}');
      }

      // Logica di parsing stazioni...
      for (int i = 1; i < stationsRows.length; i++) {
        final row = stationsRows[i];
        if (row.length < 6)
          continue; // Serve id, nome, indirizzo, comune, lat, long

        final id = row[0]?.toString() ?? '';
        if (id.isEmpty) continue;

        final lat = _parseCoordinate(row[4]?.toString() ?? '');
        final lng = _parseCoordinate(row[5]?.toString() ?? '');

        // Se le coordinate non sono valide, salta
        if (lat == 0.0 || lng == 0.0) continue;

        stations[id] = {
          'id': id,
          'name': row[1]?.toString() ?? 'Sconosciuto',
          'address': '${row[2] ?? ''}, ${row[3] ?? ''}',
          'latitude': lat,
          'longitude': lng,
        };
      }
      logInfo(
          'Parsing stazioni completato. Trovate ${stations.length} stazioni valide');

      // Parsa il file dei prezzi
      List<List<dynamic>> pricesRows;
      try {
        pricesRows = const CsvToListConverter()
            .convert(pricesContent, fieldDelimiter: delimiter);
        logInfo('Parsing prezzi: ${pricesRows.length} righe trovate');
      } catch (e) {
        logError('Errore nel parsing del file prezzi: $e');
        return [];
      }

      // Logica di parsing prezzi...
      for (int i = 1; i < pricesRows.length; i++) {
        final row = pricesRows[i];
        if (row.length < 4)
          continue; // Servono almeno id, tipo carburante e prezzo

        final id = row[0]?.toString() ?? '';
        final fuelType = row[2]?.toString() ?? '';
        final priceStr = row[3]?.toString().replaceAll(',', '.') ?? '';

        if (id.isEmpty || fuelType.isEmpty || priceStr.isEmpty) continue;

        // Se la stazione non esiste nel file principale, salta
        if (!stations.containsKey(id)) continue;

        // Converti il prezzo in double
        double? price = double.tryParse(priceStr);
        if (price == null) continue;

        if (!prices.containsKey(id)) {
          prices[id] = {};
        }

        // Mappa i tipi di carburante
        switch (fuelType) {
          case 'Benzina':
          case 'Benzina SP 98':
            prices[id]!['Benzina'] = price;
            break;
          case 'Gasolio':
          case 'Gasolio Speciale':
            prices[id]!['Diesel'] = price;
            break;
          case 'GPL':
            prices[id]!['GPL'] = price;
            break;
          case 'Metano':
            prices[id]!['Metano'] = price;
            break;
        }
      }
      logInfo(
          'Parsing prezzi completato. Trovate prezzi per ${prices.length} stazioni');

      // Combina i dati delle stazioni e dei prezzi
      final List<GasStation> result = [];

      stations.forEach((id, stationData) {
        final priceData = prices[id] ?? {};

        // Solo se ci sono prezzi disponibili
        if (priceData.isNotEmpty) {
          result.add(GasStation(
            id: id,
            name: stationData['name'],
            latitude: stationData['latitude'],
            longitude: stationData['longitude'],
            address: stationData['address'],
            fuelPrices: priceData,
          ));
        }
      });

      logInfo(
          'Creazione oggetti GasStation completata. Restituite ${result.length} stazioni');
      return result;
    } catch (e) {
      logError('Errore nel parsing diretto CSV: $e');
      return [];
    }
  }

  // Verifica che i file scaricati esistano e non siano vuoti
  Future<bool> _verifyDownloadedFiles() async {
    final directory = await getApplicationDocumentsDirectory();
    final stationsFile = File('${directory.path}/$_stationsFileName');
    final pricesFile = File('${directory.path}/$_pricesFileName');

    if (!stationsFile.existsSync() || !pricesFile.existsSync()) {
      return false;
    }

    final stationsFileSize = await stationsFile.length();
    final pricesFileSize = await pricesFile.length();

    return stationsFileSize > 100 && pricesFileSize > 100;
  }

  // Filtra le stazioni per distanza
  List<GasStation> _filterStationsByDistance(
      List<GasStation> stations, double lat, double lng, int distanceKm) {
    logInfo(
        'Filtrando ${stations.length} stazioni per distanza massima di $distanceKm km');

    // Valida le coordinate
    if (lat == 0.0 || lng == 0.0) {
      logError('Coordinate non valide per il filtro: $lat, $lng');
      return [];
    }

    try {
      // Calcola la distanza per ogni stazione
      final List<MapEntry<GasStation, double>> stationsWithDistance = [];
      int invalidCoordinates = 0;
      int calculationErrors = 0;

      for (final station in stations) {
        try {
          if (station.latitude == 0.0 || station.longitude == 0.0) {
            invalidCoordinates++;
            continue; // Salta stazioni con coordinate non valide
          }

          // Stampa un campione delle coordinate per debug
          if (stationsWithDistance.length < 5) {
            logInfo(
                'Stazione ${station.id} coord: (${station.latitude}, ${station.longitude})');
          }

          final distance = Geolocator.distanceBetween(
                  lat, lng, station.latitude, station.longitude) /
              1000; // Converti in km

          stationsWithDistance.add(MapEntry(station, distance));
        } catch (e) {
          calculationErrors++;
          logError(
              'Errore nel calcolo distanza per stazione ${station.id}: $e');
        }
      }

      logInfo('Calcolata distanza per ${stationsWithDistance.length} stazioni');
      logInfo('Saltate $invalidCoordinates stazioni con coordinate non valide');
      logInfo('$calculationErrors errori nel calcolo delle distanze');

      // Filtra per distanza massima
      stationsWithDistance.removeWhere((entry) => entry.value > distanceKm);
      logInfo(
          'Dopo filtro distanza massima, rimaste ${stationsWithDistance.length} stazioni');

      // Stampa le distanze trovate per le prime 5 stazioni
      logInfo('Esempio distanze delle prime 5 stazioni filtrate:');
      for (int i = 0; i < min(5, stationsWithDistance.length); i++) {
        final entry = stationsWithDistance[i];
        logInfo('  - ${entry.key.name}: ${entry.value.toStringAsFixed(2)} km');
      }

      // Ordina per distanza
      stationsWithDistance.sort((a, b) => a.value.compareTo(b.value));

      // Prendi le prime 20 stazioni
      final result =
          stationsWithDistance.take(20).map((entry) => entry.key).toList();
      logInfo('Restituite ${result.length} stazioni filtrate');
      return result;
    } catch (e) {
      logError('Errore nel filtraggio per distanza: $e');
      return [];
    }
  }

  // Modifica il metodo per non restituire dati fittizi
  List<GasStation> _getFallbackData() {
    logInfo('Nessun dato disponibile per le stazioni di rifornimento');
    // Restituisce una lista vuota invece di dati fittizi
    return [];
  }

  // Formatta il tempo trascorso dall'ultimo aggiornamento
  String _formatTimeAgo(int lastUpdateMillis) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = now - lastUpdateMillis;

    if (diff < 3600 * 1000) {
      // Meno di un'ora
      return 'meno di un\'ora fa';
    } else if (diff < 24 * 3600 * 1000) {
      // Meno di un giorno
      final hours = diff ~/ (3600 * 1000);
      return '$hours ore fa';
    } else {
      final days = diff ~/ (24 * 3600 * 1000);
      return '$days giorni fa';
    }
  }

  // Nuovo metodo per utilizzare file CSV personalizzati
  Future<bool> useCustomCsvFiles(
      String stationsFilePath, String pricesFilePath) async {
    try {
      logInfo('Tentativo di utilizzare file CSV personalizzati');
      logInfo('File stazioni: $stationsFilePath');
      logInfo('File prezzi: $pricesFilePath');

      // Verifica che i file esistano
      final stationsFile = File(stationsFilePath);
      final pricesFile = File(pricesFilePath);

      if (!stationsFile.existsSync()) {
        logError('File stazioni personalizzato non trovato');
        return false;
      }

      if (!pricesFile.existsSync()) {
        logError('File prezzi personalizzato non trovato');
        return false;
      }

      // Ottieni la directory dell'app
      final appDir = await getApplicationDocumentsDirectory();
      final destStationsPath = '${appDir.path}/$_stationsFileName';
      final destPricesPath = '${appDir.path}/$_pricesFileName';

      logInfo('Copiando i file nella directory dell\'app:');
      logInfo('Da: $stationsFilePath');
      logInfo('A: $destStationsPath');

      // Copia i file nella directory dell'app
      await stationsFile.copy(destStationsPath);
      await pricesFile.copy(destPricesPath);

      logInfo('File CSV personalizzati copiati con successo');

      // Aggiorna la data dell'ultimo aggiornamento
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);

      return true;
    } catch (e) {
      logError('Errore durante l\'utilizzo dei file CSV personalizzati: $e');
      return false;
    }
  }

  // Metodo per debug avanzato: esporta un log dettagliato del contenuto CSV
  Future<Map<String, dynamic>> getDetailedCsvLog() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final stationsFile = File('${directory.path}/$_stationsFileName');
      final pricesFile = File('${directory.path}/$_pricesFileName');

      final result = <String, dynamic>{
        'timestamp': DateTime.now().toIso8601String(),
        'stationsFile': {
          'path': stationsFile.path,
          'exists': stationsFile.existsSync(),
        },
        'pricesFile': {
          'path': pricesFile.path,
          'exists': pricesFile.existsSync(),
        },
      };

      // Aggiungi informazioni sui file se esistono
      if (stationsFile.existsSync()) {
        result['stationsFile']['size'] = await stationsFile.length();
        result['stationsFile']['lastModified'] =
            (await stationsFile.lastModified()).toIso8601String();

        // Leggi un campione del contenuto
        try {
          final lines = await stationsFile.readAsLines(encoding: latin1);
          result['stationsFile']['totalLines'] = lines.length;
          result['stationsFile']['headerLine'] =
              lines.isNotEmpty ? lines[0] : null;
          result['stationsFile']['sampleLines'] = lines.length > 5
              ? lines.sublist(1, min(6, lines.length))
              : (lines.length > 1 ? lines.sublist(1) : []);
        } catch (e) {
          result['stationsFile']['readError'] = e.toString();
        }
      }

      if (pricesFile.existsSync()) {
        result['pricesFile']['size'] = await pricesFile.length();
        result['pricesFile']['lastModified'] =
            (await pricesFile.lastModified()).toIso8601String();

        // Leggi un campione del contenuto
        try {
          final lines = await pricesFile.readAsLines(encoding: latin1);
          result['pricesFile']['totalLines'] = lines.length;
          result['pricesFile']['headerLine'] =
              lines.isNotEmpty ? lines[0] : null;
          result['pricesFile']['sampleLines'] = lines.length > 5
              ? lines.sublist(1, min(6, lines.length))
              : (lines.length > 1 ? lines.sublist(1) : []);
        } catch (e) {
          result['pricesFile']['readError'] = e.toString();
        }
      }

      // Log di sistema completo
      logInfo('============ LOG DETTAGLIATO DEI FILE CSV ============');
      logInfo(result.toString());
      logInfo('====================================================');

      return result;
    } catch (e) {
      logError('Errore nella generazione del log CSV: $e');
      return {'error': e.toString()};
    }
  }

  // Ottieni la directory in modo sicuro, con gestione errori e fallback
  Future<Directory> _getSafeDirectory() async {
    try {
      // Prima opzione: directory documents dell'applicazione
      return await getApplicationDocumentsDirectory();
    } catch (e) {
      logError('Errore nell\'ottenere ApplicationDocumentsDirectory: $e');

      try {
        // Seconda opzione: directory temporanea (disponibile su più piattaforme)
        return await getTemporaryDirectory();
      } catch (e2) {
        logError('Errore anche con TemporaryDirectory: $e2');

        try {
          // Terza opzione: external storage (Android)
          final externalDir = await getExternalStorageDirectory();
          if (externalDir != null) return externalDir;
          throw Exception('External storage non disponibile');
        } catch (e3) {
          logError('Errore con tutti i percorsi di storage: $e3');

          // Ultima risorsa: crea una directory nel percorso corrente
          final currentDir = Directory.current;
          final appDir = Directory('${currentDir.path}/csv_data');

          if (!appDir.existsSync()) {
            await appDir.create(recursive: true);
          }

          logInfo('Usando directory di fallback: ${appDir.path}');
          return appDir;
        }
      }
    }
  }

  // Metodo per ottenere il percorso del file in modo sicuro
  Future<String> _getSafeFilePath(String fileName) async {
    try {
      final directory = await _getSafeDirectory();
      return '${directory.path}/$fileName';
    } catch (e) {
      logError('Impossibile ottenere il percorso sicuro del file: $e');
      // Fallback assoluto: tenta di salvare nella directory corrente
      return './$fileName';
    }
  }

  // Modifica il metodo per verificare la struttura delle directory
  Future<void> _checkDirectoryStructure() async {
    try {
      final directory = await _getSafeDirectory();

      // Verifica che la directory esista
      if (!directory.existsSync()) {
        await directory.create(recursive: true);
        logInfo('Directory creata: ${directory.path}');
      }

      // Verifica i permessi eseguendo un'operazione di test
      final testFile = File('${directory.path}/test_permissions.tmp');
      await testFile.writeAsString('test');
      await testFile.delete();
      logInfo('Test permessi superato per: ${directory.path}');
    } catch (e) {
      logError('Errore nella verifica della struttura directory: $e');
      // L'errore verrà gestito dai metodi che chiamano questa funzione
    }
  }

  // Versione robusta di forceUpdate che gestisce gli errori di piattaforma
  Future<bool> robustForceUpdate() async {
    try {
      // Verifica la struttura delle directory
      await _checkDirectoryStructure();

      // Tenta l'aggiornamento
      await forceUpdate();

      // Verifica che i file esistano effettivamente
      final stationsPath = await _getSafeFilePath(_stationsFileName);
      final pricesPath = await _getSafeFilePath(_pricesFileName);

      final stationsFile = File(stationsPath);
      final pricesFile = File(pricesPath);

      if (!stationsFile.existsSync() || !pricesFile.existsSync()) {
        logError('File non creati correttamente dopo il download');
        return false;
      }

      return true;
    } catch (e) {
      logError('Errore in robustForceUpdate: $e');
      return false;
    }
  }

  // Nuovo metodo di diagnostica completa per problemi di file
  Future<Map<String, dynamic>> diagnoseFileSystem() async {
    final results = <String, dynamic>{};

    try {
      results['currentDirectory'] = Directory.current.path;

      // Test ApplicationDocumentsDirectory
      try {
        final appDocsDir = await getApplicationDocumentsDirectory();
        results['applicationDocumentsDirectory'] = {
          'path': appDocsDir.path,
          'exists': appDocsDir.existsSync(),
          'canWrite': await _testWriteAccess(appDocsDir.path),
        };
      } catch (e) {
        results['applicationDocumentsDirectory'] = {'error': e.toString()};
      }

      // Test TemporaryDirectory
      try {
        final tempDir = await getTemporaryDirectory();
        results['temporaryDirectory'] = {
          'path': tempDir.path,
          'exists': tempDir.existsSync(),
          'canWrite': await _testWriteAccess(tempDir.path),
        };
      } catch (e) {
        results['temporaryDirectory'] = {'error': e.toString()};
      }

      // Test ExternalStorageDirectory (Android only)
      try {
        final externalDir = await getExternalStorageDirectory();
        results['externalStorageDirectory'] = {
          'path': externalDir?.path ?? 'null',
          'exists': externalDir?.existsSync() ?? false,
          'canWrite': externalDir != null
              ? await _testWriteAccess(externalDir.path)
              : false,
        };
      } catch (e) {
        results['externalStorageDirectory'] = {'error': e.toString()};
      }

      // Info sui file CSV
      final safeDir = await _getSafeDirectory();
      final stationsPath = '${safeDir.path}/$_stationsFileName';
      final pricesPath = '${safeDir.path}/$_pricesFileName';

      results['csvFiles'] = {
        'stationsPath': stationsPath,
        'stationsExists': File(stationsPath).existsSync(),
        'stationsSize': File(stationsPath).existsSync()
            ? await File(stationsPath).length()
            : 0,
        'pricesPath': pricesPath,
        'pricesExists': File(pricesPath).existsSync(),
        'pricesSize':
            File(pricesPath).existsSync() ? await File(pricesPath).length() : 0,
      };

      return results;
    } catch (e) {
      return {'diagnosticError': e.toString()};
    }
  }

  // Testa se è possibile scrivere in una directory
  Future<bool> _testWriteAccess(String path) async {
    try {
      final testFile = File('$path/write_test.tmp');
      await testFile.writeAsString('test');
      await testFile.delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Metodo per ottenere i percorsi dei file CSV
  Future<Map<String, String>> getFilePaths() async {
    final result = <String, String>{};

    try {
      final tempDir = await getTemporaryDirectory();
      final csvTempPath = '${tempDir.path}/csv_temp';

      result['stations'] = '$csvTempPath/gas_stations.csv';
      result['prices'] = '$csvTempPath/gas_prices.csv';
    } catch (e) {
      print('Errore nel recupero dei percorsi dei file CSV: $e');
    }

    return result;
  }

  // Miglioriamo la gestione dell'encoding per i file CSV
  Future<Object> readCsvLinesWithEncodingFallback(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw Exception('Il file CSV non esiste: $filePath');
    }

    // Prova con diversi encoding
    List<String> encodings = ['latin1', 'utf8', 'ascii'];
    List<Exception> errors = [];

    for (var encoding in encodings) {
      try {
        switch (encoding) {
          case 'latin1':
            return await file.readAsLines(encoding: latin1);
          case 'utf8':
            return utf8.decoder.convert(await file.readAsBytes()).split('\n');
          case 'ascii':
            return await file.readAsString();
        }
      } catch (e) {
        errors.add(Exception('Errore con encoding $encoding: $e'));
      }
    }

    // Se arriva qui, nessun encoding ha funzionato
    throw Exception(
        'Impossibile leggere il file con nessun encoding. Errori: $errors');
  }
}

// Funzione isolata per parsare il CSV in background
List<GasStation> _parseCSVData(Map<String, String> csvData) {
  try {
    final stations = <String, Map<String, dynamic>>{};
    final prices = <String, Map<String, double>>{};

    // Parsa il file delle stazioni
    final List<List<dynamic>> stationsRows = const CsvToListConverter()
        .convert(csvData['stations']!, fieldDelimiter: ';');

    // Salta l'header
    for (int i = 1; i < stationsRows.length; i++) {
      final row = stationsRows[i];
      // Verifica che la riga abbia abbastanza colonne
      if (row.length < 5) continue;

      final id = row[0]?.toString() ?? '';
      if (id.isEmpty) continue;

      stations[id] = {
        'id': id,
        'name': row[1]?.toString() ?? 'Sconosciuto',
        'address': '${row[2] ?? ''}, ${row[3] ?? ''}',
        'latitude': _parseCoordinate(row[4]?.toString() ?? ''),
        'longitude': _parseCoordinate(row[5]?.toString() ?? ''),
      };
    }

    // Parsa il file dei prezzi
    final List<List<dynamic>> pricesRows = const CsvToListConverter()
        .convert(csvData['prices']!, fieldDelimiter: ';');

    // Salta l'header
    for (int i = 1; i < pricesRows.length; i++) {
      final row = pricesRows[i];
      // Verifica che la riga abbia abbastanza colonne
      if (row.length < 5) continue;

      final id = row[0]?.toString() ?? '';
      final fuelType = row[2]?.toString() ?? '';
      final priceStr = row[3]?.toString().replaceAll(',', '.') ?? '';

      if (id.isEmpty || fuelType.isEmpty || priceStr.isEmpty) continue;

      // Converti il prezzo in double
      double? price = double.tryParse(priceStr);
      if (price == null) continue;

      if (!prices.containsKey(id)) {
        prices[id] = {};
      }

      // Mappa i tipi di carburante
      switch (fuelType) {
        case 'Benzina':
        case 'Benzina SP 98':
          prices[id]!['Benzina'] = price;
          break;
        case 'Gasolio':
        case 'Gasolio Speciale':
          prices[id]!['Diesel'] = price;
          break;
        case 'GPL':
          prices[id]!['GPL'] = price;
          break;
        case 'Metano':
          prices[id]!['Metano'] = price;
          break;
      }
    }

    // Combina i dati delle stazioni e dei prezzi
    final List<GasStation> result = [];

    stations.forEach((id, stationData) {
      final priceData = prices[id] ?? {};

      // Solo se ci sono prezzi disponibili
      if (priceData.isNotEmpty) {
        result.add(GasStation(
          id: id,
          name: stationData['name'],
          latitude: stationData['latitude'],
          longitude: stationData['longitude'],
          address: stationData['address'],
          fuelPrices: priceData,
        ));
      }
    });

    return result;
  } catch (e) {
    logError('Errore nel parsing CSV: $e');
    return [];
  }
}

// Converte le coordinate dal formato italiano (con virgola) a double
double _parseCoordinate(String coord) {
  if (coord.isEmpty) return 0.0;
  return double.tryParse(coord.replaceAll(',', '.')) ?? 0.0;
}
