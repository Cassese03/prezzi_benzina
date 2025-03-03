import 'dart:developer' as developer;

/// Classe che fornisce funzioni per il logging con colori e formattazione
class Logger {
  final String tag;

  // Colori ANSI per console
  static const String _resetColor = '\x1B[0m';
  static const String _yellowColor = '\x1B[33m'; // Info
  static const String _redColor = '\x1B[31m'; // Error
  static const String _greenColor = '\x1B[32m'; // Success
  static const String _blueColor = '\x1B[34m'; // Debug
  static const String _purpleColor = '\x1B[35m'; // Warning

  /// Costruttore che accetta un tag per distinguere i log
  Logger(this.tag);

  /// Log generico con colore personalizzato
  void log(String message, {String color = ''}) {
    developer.log('$color$message$_resetColor', name: tag);
  }

  /// Log di informazioni (giallo)
  void info(String message) {
    log(message, color: _yellowColor);
  }

  /// Log di errori (rosso)
  void error(String message) {
    log(message, color: _redColor);
  }

  /// Log di successo (verde)
  void success(String message) {
    log(message, color: _greenColor);
  }

  /// Log di debug (blu)
  void debug(String message) {
    log(message, color: _blueColor);
  }

  /// Log di avviso (viola)
  void warning(String message) {
    log(message, color: _purpleColor);
  }

  /// Log del contenuto CSV formattato
  void logCsvContent(List<String> lines, {String title = 'CSV CONTENT'}) {
    info('====== $title ======');
    if (lines.isEmpty) {
      warning('Il file è vuoto');
    } else {
      info('HEADER: ${lines[0]}');
      final dataLines = lines.length > 1
          ? lines.sublist(1, lines.length > 5 ? 5 : lines.length)
          : [];
      for (int i = 0; i < dataLines.length; i++) {
        info('RIGA ${i + 1}: ${dataLines[i]}');
      }
      info('Totale righe: ${lines.length}');
    }
    info('===================');
  }
}

/// Funzioni globali per accesso rapido al logger

/// Crea un logger con il tag specificato
Logger getLogger(String tag) => Logger(tag);

/// Log info veloce con tag 'APP'
void logInfo(String message) {
  Logger('APP').info(message);
}

/// Log error veloce con tag 'ERROR'
void logError(String message) {
  Logger('ERROR').error(message);
}

/// Log debug veloce con tag 'DEBUG'
void logDebug(String message) {
  Logger('DEBUG').debug(message);
}

/// Log di successo veloce con tag 'SUCCESS'
void logSuccess(String message) {
  Logger('SUCCESS').success(message);
}

/// Log di avviso veloce con tag 'WARNING'
void logWarning(String message) {
  Logger('WARNING').warning(message);
}
