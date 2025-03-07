import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Forza l'orientamento verticale
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CarMate',
      theme: ThemeData(
        // Colori principali basati sul logo
        primaryColor: const Color(0xFF3498DB), // Blu del logo
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3498DB),
          // Colori secondari
          secondary: const Color(0xFF2ECC71), // Verde per i prezzi bassi
          tertiary: const Color(0xFFE74C3C), // Rosso per i prezzi alti
          surface: Colors.white,
          background: const Color(0xFFF8F9FA),
        ),
        // Stile AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF3498DB),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        // Stile Card
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        // Stile BottomNavigationBar
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF3498DB),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
