import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'screens/home_page.dart';
import 'utils/permission_handler.dart';
import 'dart:developer' as developer;

// Funzione di log globale
void log(String message) {
  developer.log('\x1B[32m$message\x1B[0m', name: 'APP_MAIN');
}

void main() async {
  // Assicura che Flutter sia inizializzato
  WidgetsFlutterBinding.ensureInitialized();

  // Imposta l'orientamento preferito
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Log informativo di avvio
  log('Avvio applicazione...');

  // Se necessario, richiedi i permessi all'avvio (per Android)
  if (Platform.isAndroid) {
    await StoragePermissionHandler.requestPermissions();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trova Benzina Economica',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
