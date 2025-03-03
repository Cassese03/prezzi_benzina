import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/gas_station.dart';
import 'csv_gas_station_service.dart';

class GasStationService {
  final CsvGasStationService _csvService = CsvGasStationService();

  // Widget per mostrare il progresso del download
  Widget? _progressWidget;

  // Variabile per memorizzare funzioni di callback di progresso
  Function(String, String)? _progressCallback;

  // Callback per aggiornare la percentuale di download
  Function(double)? _downloadProgressCallback;

  Future<List<GasStation>> getGasStations(
      double lat, double lng, int distance) async {
    try {
      _reportProgress('Avvio', 'Inizializzazione del servizio dati...');

      // Coordinate esatte fornite
      final double fixedLatitude = 40.93219998333439;
      final double fixedLongitude = 14.528259514051589;

      _reportProgress('Coordinate',
          'Utilizzo coordinate specificate: $fixedLatitude, $fixedLongitude');
      print(
          'DEBUG: Utilizzo coordinate fisse: $fixedLatitude, $fixedLongitude');

      // Scarica sempre i file CSV più recenti
      _reportProgress('Download', 'Scaricamento dei file CSV in corso...');

      // Imposta il callback per il progresso del download
      _csvService.setProgressCallback((progress) {
        if (_downloadProgressCallback != null) {
          _downloadProgressCallback!(progress);
        }
      });

      // Forza il download dei file CSV
      try {
        await _csvService.forceUpdate();
        _reportProgress(
            'Download', 'Download dei file CSV completato con successo');
        print('DEBUG: Download CSV completato');
      } catch (e) {
        _reportProgress('Errore',
            'Errore durante il download dei file CSV: ${e.toString()}');
        print('DEBUG: Errore durante il download CSV: $e');
        // Continuiamo con i dati esistenti
      }

      // Caricamento e filtraggio dei dati CSV
      _reportProgress('Caricamento', 'Caricamento stazioni dal file CSV...');
      final stations = await _csvService.getGasStations(
          fixedLatitude, fixedLongitude, distance);

      if (stations.isNotEmpty) {
        _reportProgress(
            'Successo', 'Trovate ${stations.length} stazioni nei file CSV');
        print('DEBUG: Recuperate ${stations.length} stazioni dai file CSV');
        return stations;
      }

      // Se non ci sono stazioni nei file CSV, mostriamo un messaggio e usiamo dati fallback solo in questo caso
      _reportProgress('Avviso', 'Nessuna stazione trovata nei file CSV');
      print('DEBUG: Nessuna stazione trovata nei file CSV');

      return [];
    } catch (e) {
      _reportProgress('Errore', 'Errore generale: ${e.toString()}');
      print('DEBUG: Errore generale nel servizio: $e');
      return [];
    }
  }

  // Nuovo metodo per ottenere le prime 10 stazioni senza filtri
  Future<List<GasStation>> getFirst10StationsFromCSV() async {
    try {
      _reportProgress(
          'Lettura CSV', 'Recupero delle prime 10 stazioni dai file CSV...');

      final stations = await _csvService.getFirst10Stations();

      if (stations.isEmpty) {
        _reportProgress('Avviso', 'Nessuna stazione trovata nei file CSV');
      } else {
        _reportProgress(
            'Successo', 'Trovate ${stations.length} stazioni nei file CSV');
      }

      return stations;
    } catch (e) {
      _reportProgress(
          'Errore', 'Errore nel recupero delle stazioni: ${e.toString()}');
      print('ERROR: Errore nel recupero delle prime 10 stazioni: $e');
      return [];
    }
  }

  // Aggiungi un metodo per utilizzare file CSV personalizzati
  Future<bool> useCustomCsvFiles(
      String stationsFilePath, String pricesFilePath) async {
    try {
      _reportProgress(
          'Importazione', 'Importazione file CSV personalizzati...');

      final result =
          await _csvService.useCustomCsvFiles(stationsFilePath, pricesFilePath);

      if (result) {
        _reportProgress(
            'Completato', 'File CSV personalizzati importati con successo');
      } else {
        _reportProgress(
            'Errore', 'Impossibile importare i file CSV personalizzati');
      }

      return result;
    } catch (e) {
      _reportProgress('Errore', 'Errore nell\'importazione: ${e.toString()}');
      print('ERROR: Errore nell\'importazione dei file CSV personalizzati: $e');
      return false;
    }
  }

  // Nuovo metodo per configurare lo storage alternativo come predefinito
  Future<bool> setupAlternativeStorage(
      String basePath, String stationsPath, String pricesPath) async {
    try {
      _reportProgress(
          'Configurazione', 'Configurazione storage alternativo...');

      // Crea le directory se non esistono
      final baseDir = Directory(basePath);
      if (!baseDir.existsSync()) {
        baseDir.createSync(recursive: true);
      }

      // Verifica se i file esistono già
      final stationsFile = File(stationsPath);
      final pricesFile = File(pricesPath);

      // Se i file non esistono, scaricali
      if (!stationsFile.existsSync() || !pricesFile.existsSync()) {
        _reportProgress(
            'Download', 'Download dei file CSV in storage alternativo...');

        try {
          await _csvService.downloadToCustomLocation(
              'https://www.mise.gov.it/images/exportCSV/anagrafica_impianti_attivi.csv',
              stationsPath);

          await _csvService.downloadToCustomLocation(
              'https://www.mise.gov.it/images/exportCSV/prezzo_alle_8.csv',
              pricesPath);
        } catch (e) {
          _reportProgress('Errore', 'Errore nel download dei file CSV: $e');
          print('ERROR: Download file CSV fallito: $e');
          return false;
        }
      }

      // Configura il servizio CSV per utilizzare questi file
      final success =
          await _csvService.useCustomCsvFiles(stationsPath, pricesPath);

      if (success) {
        _reportProgress(
            'Completato', 'Storage alternativo configurato con successo');
      } else {
        _reportProgress('Errore',
            'Impossibile utilizzare i file CSV in storage alternativo');
      }

      return success;
    } catch (e) {
      _reportProgress('Errore',
          'Errore nella configurazione dello storage alternativo: $e');
      print('ERROR: Configurazione storage alternativo fallita: $e');
      return false;
    }
  }

  // Metodo per verificare e debuggare i file CSV
  Future<Map<String, dynamic>> debugCsvFiles() async {
    try {
      // Risultato del debug
      final debugResult = {
        'filesExist': false,
        'stationsPath': '',
        'pricesPath': '',
        'stationsSize': 0,
        'pricesSize': 0,
        'stationsFirstLine': '',
        'pricesFirstLine': '',
        'error': '',
      };

      // Ottiene i percorsi dei file CSV
      final paths = await _csvService.getFilePaths();
      debugResult['stationsPath'] = paths['stations'] ?? 'non disponibile';
      debugResult['pricesPath'] = paths['prices'] ?? 'non disponibile';

      // Verifica se i file esistono
      final stationsFile = File(debugResult['stationsPath'] as String);
      final pricesFile = File(debugResult['pricesPath'] as String);

      if (stationsFile.existsSync() && pricesFile.existsSync()) {
        debugResult['filesExist'] = true;
        debugResult['stationsSize'] = stationsFile.lengthSync();
        debugResult['pricesSize'] = pricesFile.lengthSync();

        // Legge la prima riga di ogni file
        try {
          final stationsContent = await stationsFile.readAsString();
          final pricesContent = await pricesFile.readAsString();

          final stationsLines = stationsContent.split('\n');
          final pricesLines = pricesContent.split('\n');

          if (stationsLines.isNotEmpty) {
            debugResult['stationsFirstLine'] = stationsLines[0];
          }

          if (pricesLines.isNotEmpty) {
            debugResult['pricesFirstLine'] = pricesLines[0];
          }
        } catch (e) {
          debugResult['error'] = 'Errore nella lettura dei file: $e';
        }
      } else {
        debugResult['error'] = 'Uno o entrambi i file CSV non esistono';
      }

      return debugResult;
    } catch (e) {
      return {
        'filesExist': false,
        'error': 'Errore durante il debug: $e',
      };
    }
  }

  // Metodo per correggere problemi comuni con i file CSV
  Future<bool> repairCsvFiles() async {
    try {
      _reportProgress(
          'Riparazione', 'Tentativo di riparazione dei file CSV...');

      // Forzare un nuovo download
      await forceUpdate();

      return true;
    } catch (e) {
      _reportProgress('Errore', 'Errore durante la riparazione: $e');
      return false;
    }
  }

  // Imposta un widget per mostrare il progresso
  void setProgressWidget(Widget widget) {
    _progressWidget = widget;
  }

  // Cancella il widget di progresso
  void clearProgressWidget() {
    _progressWidget = null;
  }

  // Widget per mostrare il progresso
  Widget? getProgressWidget() {
    return _progressWidget;
  }

  // Imposta un callback per il progresso
  void setProgressCallback(Function(String, String) callback) {
    _progressCallback = callback;
  }

  // Rimuove il callback
  void clearProgressCallback() {
    _progressCallback = null;
  }

  // Imposta il callback per il progresso del download
  void setDownloadProgressCallback(Function(double) callback) {
    _downloadProgressCallback = callback;
  }

  // Rimuove il callback per il progresso del download
  void clearDownloadProgressCallback() {
    _downloadProgressCallback = null;
  }

  // Reporta il progresso
  void _reportProgress(String title, String message) {
    if (_progressCallback != null) {
      _progressCallback!(title, message);
    }

    // Aggiungiamo sempre un log per debugging
    print('PROGRESS: $title - $message');
  }

  // Forza l'aggiornamento dei dati
  Future<bool> forceUpdate() async {
    try {
      _reportProgress(
          'Aggiornamento', 'Download forzato dei dati CSV in corso...');
      await _csvService.forceUpdate();
      _reportProgress('Completato', 'Download forzato completato con successo');
      return true;
    } catch (e) {
      _reportProgress(
          'Errore', 'Errore nell\'aggiornamento forzato: ${e.toString()}');
      print('Errore nell\'aggiornamento forzato: $e');
      return false;
    }
  }

  // Metodo per ottenere il servizio CSV sottostante
  CsvGasStationService getCsvService() {
    return _csvService;
  }

  // Metodo per verificare se è necessario un aggiornamento
  // Poiché usiamo sempre forceUpdate, questo può semplicemente restituire sempre true
  Future<bool> needsUpdate() async {
    return true;
  }

  // Metodo per download robusto (wrapper per forceUpdate)
  Future<bool> robustForceUpdate() async {
    try {
      await forceUpdate();
      return true;
    } catch (e) {
      print('Errore in robustForceUpdate: $e');
      return false;
    }
  }

  // Ottieni le prime 10 stazioni senza filtri (alias)
  Future<List<GasStation>> getFirst10Stations() async {
    return await getFirst10StationsFromCSV();
  }
}
