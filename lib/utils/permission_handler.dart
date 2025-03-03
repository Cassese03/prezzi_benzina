import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:developer' as developer;

class StoragePermissionHandler {
  // Funzione helper per log colorati
  static void _log(String message) {
    developer.log('\x1B[33m$message\x1B[0m', name: 'PERMISSION_HANDLER');
  }

  // Richiedi i permessi di archiviazione con gestione errori migliorata
  static Future<bool> requestStoragePermission() async {
    _log('Richiesta permessi di archiviazione...');

    try {
      // Su Android 13+ (API 33+) serve gestire diversi tipi di permessi
      if (Platform.isAndroid) {
        // Verifica la versione di Android e richiedi i permessi appropriati
        final status = await Permission.storage.status;

        _log('Stato attuale permessi: $status');

        if (status.isGranted) {
          _log('Permessi già concessi');
          return true;
        }

        if (status.isPermanentlyDenied) {
          _log(
              'Permessi negati permanentemente. L\'utente deve abilitarli manualmente.');
          return false;
        }

        // Permessi aggiuntivi per Android 13+
        bool allGranted = true;

        // Richiedi permessi generali di archiviazione
        final storageStatus = await Permission.storage.request();
        _log('Stato permessi storage: $storageStatus');
        allGranted = allGranted && storageStatus.isGranted;

        // Su versioni recenti di Android potrebbero servire altri permessi
        try {
          if (await Permission.manageExternalStorage.status.isGranted) {
            final externalStatus =
                await Permission.manageExternalStorage.request();
            _log('Stato permessi external storage: $externalStatus');
            allGranted = allGranted && externalStatus.isGranted;
          }
        } catch (e) {
          _log('Errore durante la richiesta di permessi esterni: $e');
        }

        // Prova anche con altri permessi di media
        try {
          if (await Permission.mediaLibrary.status.isGranted) {
            final mediaStatus = await Permission.mediaLibrary.request();
            _log('Stato permessi media: $mediaStatus');
          }
        } catch (e) {
          _log('Errore durante la richiesta di permessi media: $e');
        }

        return allGranted;
      } else if (Platform.isIOS) {
        // iOS non richiede permessi specifici per l'archiviazione interna all'app
        return true;
      } else {
        // Altre piattaforme
        _log(
            'Piattaforma non gestita specificamente: ${Platform.operatingSystem}');
        return true;
      }
    } catch (e) {
      _log('Errore nella richiesta permessi: $e');
      // In caso di errore, proviamo a continuare comunque
      return true;
    }
  }

  // Mostra un dialogo che spiega perché servono i permessi
  static Future<void> showPermissionDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permessi necessari'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'Questa app ha bisogno di accedere allo storage del dispositivo per:'),
              const SizedBox(height: 8),
              const Text('• Salvare i file CSV con i dati delle stazioni'),
              const Text('• Caricare le informazioni sui distributori'),
              const Text('• Mantenere i dati aggiornati'),
              const SizedBox(height: 8),
              const Text(
                  'Senza questi permessi, l\'app non funzionerà correttamente.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Apri Impostazioni'),
          ),
        ],
      ),
    );
  }

  // Verifica i permessi e mostra il dialogo se necessario
  static Future<bool> checkAndRequestPermissions(BuildContext context) async {
    final hasPermission = await requestStoragePermission();

    if (!hasPermission) {
      await showPermissionDialog(context);
      return false;
    }

    return true;
  }

  // Verifica percorsi alternativi in caso di problemi di permessi
  static Future<String?> findWritablePath() async {
    _log('Cercando un percorso scrivibile...');

    try {
      // Prova la directory dei documenti dell'applicazione
      try {
        final appDir = await getApplicationDocumentsDirectory();
        if (await _isWritable(appDir.path)) {
          _log('Directory documenti app scrivibile: ${appDir.path}');
          return appDir.path;
        }
      } catch (e) {
        _log('Errore con app documents directory: $e');
      }

      // Prova la directory temporanea
      try {
        final tempDir = await getTemporaryDirectory();
        if (await _isWritable(tempDir.path)) {
          _log('Directory temporanea scrivibile: ${tempDir.path}');
          return tempDir.path;
        }
      } catch (e) {
        _log('Errore con temp directory: $e');
      }

      // Prova la directory di storage esterno (solo Android)
      if (Platform.isAndroid) {
        try {
          final externalDir = await getExternalStorageDirectory();
          if (externalDir != null && await _isWritable(externalDir.path)) {
            _log('Directory esterna scrivibile: ${externalDir.path}');
            return externalDir.path;
          }
        } catch (e) {
          _log('Errore con external storage directory: $e');
        }
      }

      // Nessun percorso scrivibile trovato
      _log('Nessun percorso scrivibile trovato');
      return null;
    } catch (e) {
      _log('Errore nella ricerca di percorsi scrivibili: $e');
      return null;
    }
  }

  // Verifica se una directory è scrivibile
  static Future<bool> _isWritable(String path) async {
    try {
      final testFile = File('$path/write_test.tmp');
      await testFile.writeAsString('test');
      await testFile.delete();
      return true;
    } catch (e) {
      _log('Percorso $path non scrivibile: $e');
      return false;
    }
  }

  // Aggiungi questo metodo per integrazione con main.dart
  static Future<void> requestPermissions() async {
    try {
      if (Platform.isAndroid) {
        _log('Inizializzazione: Richiesta automatica permessi storage');
        final storageStatus = await Permission.storage.request();
        _log('Status permessi storage iniziale: $storageStatus');

        // Su Android 11+ prova anche manage external storage
        if (await Permission.manageExternalStorage.status.isGranted) {
          final externalStatus =
              await Permission.manageExternalStorage.request();
          _log('Status permessi external storage iniziale: $externalStatus');
        }
      }
    } catch (e) {
      _log('Errore richiesta permessi all\'avvio: $e');
    }
  }
}
