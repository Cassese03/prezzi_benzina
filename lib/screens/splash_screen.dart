import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final bool isLoading;

  const SplashScreen({Key? key, this.isLoading = false}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true); // Fa pulsare avanti e indietro

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2, // Scala massima della pulsazione
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logo.png', // Assicurati che il percorso sia corretto
                    width: 150,
                    height: 150,
                  ),
                  const SizedBox(height: 24),
                  if (widget.isLoading)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Caricamento...',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
