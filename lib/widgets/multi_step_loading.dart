import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

enum LoadingStep {
  checkingPermissions,
  fetchingData,
  processingData,
  completed
}

class MultiStepLoading extends StatefulWidget {
  final Future<void> Function() onLocationPermissionGranted;
  final Future<void> Function(Position position) onFetchData;
  final Function() onCompleted;

  const MultiStepLoading({
    super.key,
    required this.onLocationPermissionGranted,
    required this.onFetchData,
    required this.onCompleted,
  });

  @override
  State<MultiStepLoading> createState() => _MultiStepLoadingState();
}

class _MultiStepLoadingState extends State<MultiStepLoading>
    with SingleTickerProviderStateMixin {
  LoadingStep _currentStep = LoadingStep.checkingPermissions;
  double _step1Progress = 0.0;
  double _step2Progress = 0.0;
  double _step3Progress = 0.0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Animazione pulsante
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _pulseAnimation =
        Tween<double>(begin: 0.95, end: 1.05).animate(_pulseController);

    // Inizia il processo di caricamento
    _startLoadingProcess();
  }

  Future<void> _startLoadingProcess() async {
    try {
      // Step 1: Verificare i permessi della posizione
      setState(() {
        _currentStep = LoadingStep.checkingPermissions;
        _step1Progress = 0.0;
      });

      // Simula progresso del primo step
      for (int i = 0; i < 5; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        if (!mounted) return;
        setState(() {
          _step1Progress = (i + 1) / 5;
        });
      }

      // Verifica permessi di posizione
      final status = await _checkLocationPermission();
      if (!status) {
        // Permessi negati, mostra errore
        if (mounted) {
          _showPermissionError();
          return;
        }
      }

      // Permessi concessi, avanza
      if (mounted) {
        setState(() {
          _step1Progress = 1.0;
        });

        // Notifica il callback che i permessi sono stati concessi
        await widget.onLocationPermissionGranted();
      }

      // Step 2: Ottenere i dati in base alla posizione
      if (mounted) {
        setState(() {
          _currentStep = LoadingStep.fetchingData;
          _step2Progress = 0.0;
        });
      }

      // Ottieni la posizione attuale
      final position = await _getCurrentPosition();

      // Simula progresso del secondo step mentre si caricano i dati
      for (int i = 0; i < 5; i++) {
        if (!mounted) return;
        await Future.delayed(const Duration(milliseconds: 300));
        setState(() {
          _step2Progress = (i + 1) / 5;
        });
      }

      // Caricamento dati
      if (mounted) {
        setState(() {
          _step2Progress = 1.0;
        });

        // Notifica il callback con la posizione ottenuta
        await widget.onFetchData(position);
      }

      // Step 3: Elaborazione dei dati
      if (mounted) {
        setState(() {
          _currentStep = LoadingStep.processingData;
          _step3Progress = 0.0;
        });
      }

      // Simula progresso dell'elaborazione dati
      for (int i = 0; i < 5; i++) {
        if (!mounted) return;
        await Future.delayed(const Duration(milliseconds: 150));
        setState(() {
          _step3Progress = (i + 1) / 5;
        });
      }

      // Completa
      if (mounted) {
        setState(() {
          _step3Progress = 1.0;
          _currentStep = LoadingStep.completed;
        });

        // Breve ritardo prima di chiamare onCompleted
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          widget.onCompleted();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore durante il caricamento: $e')),
        );
      }
    }
  }

  Future<bool> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<Position> _getCurrentPosition() async {
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  void _showPermissionError() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Permessi Posizione'),
        content: const Text(
            'Questa app ha bisogno dei permessi di posizione per mostrarti i distributori più vicini. '
            'Vai nelle impostazioni dell\'app per abilitare i permessi.'),
        actions: [
          TextButton(
            onPressed: () {
              Geolocator.openLocationSettings();
            },
            child: const Text('IMPOSTAZIONI'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startLoadingProcess(); // Riprova
            },
            child: const Text('RIPROVA'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          color: Colors.white,
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo animato
                Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 150,
                    height: 150,
                  ),
                ),
                const SizedBox(height: 48),

                // Titolo
                const Text(
                  'TankMap',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'La tua app per i distributori e i rifornimenti',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF7F8C8D),
                  ),
                ),
                const SizedBox(height: 48),

                // Step 1
                _buildLoadingStep(
                  title: 'Controllo permessi posizione',
                  progress: _step1Progress,
                  isActive: _currentStep == LoadingStep.checkingPermissions,
                  isCompleted: _currentStep.index >
                      LoadingStep.checkingPermissions.index,
                ),
                const SizedBox(height: 24),

                // Step 2
                _buildLoadingStep(
                  title: 'Ricerca distributori vicini',
                  progress: _step2Progress,
                  isActive: _currentStep == LoadingStep.fetchingData,
                  isCompleted:
                      _currentStep.index > LoadingStep.fetchingData.index,
                ),
                const SizedBox(height: 24),

                // Step 3
                _buildLoadingStep(
                  title: 'Elaborazione dati',
                  progress: _step3Progress,
                  isActive: _currentStep == LoadingStep.processingData,
                  isCompleted:
                      _currentStep.index > LoadingStep.processingData.index,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingStep({
    required String title,
    required double progress,
    required bool isActive,
    required bool isCompleted,
  }) {
    return Opacity(
      opacity: isActive || isCompleted ? 1.0 : 0.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isCompleted)
                const Icon(Icons.check_circle, color: Colors.green, size: 20)
              else if (isActive)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFFE67E22)),
                  ),
                )
              else
                const Icon(Icons.circle_outlined, color: Colors.grey, size: 20),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? const Color(0xFF2C3E50) : Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Barra di progresso
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              isCompleted ? Colors.green : const Color(0xFFE67E22),
            ),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}
