import 'package:flutter/material.dart';
import 'screens/home_page.dart';
import 'package:carmate/android_auto/auto_method_channel.dart';
import 'services/ad_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inizializza AdMob
  await AdService.initialize();

  // Inizializza il canale di comunicazione con Android Auto
  await AndroidAutoChannel.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '| TankFuel |',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF2C3E50), // Blu petrolio
        scaffoldBackgroundColor: const Color(0xFFECF0F1), // Grigio chiaro
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFF2C3E50),
          onPrimary: Colors.white,
          secondary: Color(0xFFE67E22), // Arancione chiaro
          onSecondary: Colors.white,
          surface: Colors.white,
          onSurface: Color(0xFF2C3E50),
          error: Color(0xFFE74C3C), // Rosso
          onError: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2C3E50),
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFE67E22),
          foregroundColor: Colors.white,
        ),
        cardTheme: const CardTheme(
          color: Colors.white,
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(color: Color(0xFF2C3E50)),
          titleMedium: TextStyle(color: Color(0xFF2C3E50)),
          bodyLarge: TextStyle(color: Color(0xFF2C3E50)),
          bodyMedium: TextStyle(color: Color(0xFF2C3E50)),
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
