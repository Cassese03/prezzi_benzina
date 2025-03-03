import 'dart:developer' as developer;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

/// Servizio per centralizzare e gestire i log dell'applicazione
class LogService {
  // Singleton
  static final LogService _instance = LogService._internal();
  factory LogService() => _instance;
  LogService._internal();

  // Buffer per i log
  final List<LogEntry> _logBuffer = [];
  static const int _maxBufferSize = 1000;

  // Livelli di log
  static const int DEBUG = 0;
  static const int INFO = 1;
  static const int WARNING = 2;
  static const int ERROR = 3;

  // Colori ANSI per i log nella console
  static const String _resetColor = '\x1B[0m';
  static const String _debugColor = '\x1B[36m'; // Ciano
  static const String _infoColor = '\x1B[32m'; // Verde
  static const String _warningColor = '\x1B[33m'; // Giallo
  static const String _errorColor = '\x1B[31m'; // Rosso

  /// Log di debug (verbose)
  void d(String message, {String tag = 'APP_DEBUG'}) {
    _log(DEBUG, message, tag: tag);
  }

  /// Log informativo
  void i(String message, {String tag = 'APP_INFO'}) {
    _log(INFO, message, tag: tag);
  }

  /// Log di avviso
  void w(String message, {String tag = 'APP_WARNING'}) {
    _log(WARNING, message, tag: tag);
  }

  /// Log di errore
  void e(String message,
      {String tag = 'APP_ERROR', Object? error, StackTrace? stackTrace}) {
    String fullMessage = message;
    if (error != null) {
      fullMessage += '\nErrore: $error';
    }
    if (stackTrace != null) {
      fullMessage += '\nStackTrace: $stackTrace';
    }

    _log(ERROR, fullMessage, tag: tag);
  }

  /// Metodo centrale per gestire i log
  void _log(int level, String message, {required String tag}) {
    String coloredMessage;

    // Colore in base al livello
    switch (level) {
      case DEBUG:
        coloredMessage = '$_debugColor$message$_resetColor';
        break;
      case INFO:
        coloredMessage = '$_infoColor$message$_resetColor';
        break;
      case WARNING:
        coloredMessage = '$_warningColor$message$_resetColor';
        break;
      case ERROR:
        coloredMessage = '$_errorColor$message$_resetColor';
        break;
      default:
        coloredMessage = message;
    }

    // Log nella console di debug
    developer.log(coloredMessage, name: tag);

    // Salva nel buffer interno
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      tag: tag,
      message: message,
    );

    _addToBuffer(entry);

    // In modalità debug, stampa anche con print per la console del simulatore
    if (kDebugMode && level >= WARNING) {
      print('[$tag] $coloredMessage');
    }
  }

  /// Aggiungi una voce al buffer, rimuovendo le più vecchie se necessario
  void _addToBuffer(LogEntry entry) {
    _logBuffer.add(entry);
    if (_logBuffer.length > _maxBufferSize) {
      _logBuffer.removeAt(0);
    }
  }

  /// Ottieni tutti i log dal buffer
  List<LogEntry> getLogs() {
    return List.unmodifiable(_logBuffer);
  }

  /// Ottieni i log filtrati per livello
  List<LogEntry> getLogsByLevel(int minimumLevel) {
    return _logBuffer.where((log) => log.level >= minimumLevel).toList();
  }

  /// Salva i log su file
  Future<String> saveLogsToFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final now = DateTime.now();
      final fileName =
          'logs_${now.year}-${now.month}-${now.day}_${now.hour}-${now.minute}.txt';
      final file = File('${directory.path}/$fileName');

      final buffer = StringBuffer();
      for (final log in _logBuffer) {
        buffer.writeln(
            '${log.timestamp.toIso8601String()} [${_getLevelName(log.level)}] ${log.tag}: ${log.message}');
      }

      await file.writeAsString(buffer.toString());
      return file.path;
    } catch (e) {
      developer.log('Errore nel salvataggio dei log: $e', name: 'LOG_SERVICE');
      return '';
    }
  }

  /// Pulisci il buffer dei log
  void clearLogs() {
    _logBuffer.clear();
  }

  /// Ottieni il nome del livello di log
  String _getLevelName(int level) {
    switch (level) {
      case DEBUG:
        return 'DEBUG';
      case INFO:
        return 'INFO';
      case WARNING:
        return 'WARNING';
      case ERROR:
        return 'ERROR';
      default:
        return 'UNKNOWN';
    }
  }
}

/// Classe che rappresenta una voce di log
class LogEntry {
  final DateTime timestamp;
  final int level;
  final String tag;
  final String message;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
  });
}
