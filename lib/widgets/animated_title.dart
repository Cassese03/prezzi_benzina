import 'package:flutter/material.dart';

class AnimatedTitle extends StatefulWidget {
  const AnimatedTitle({Key? key}) : super(key: key);

  @override
  State<AnimatedTitle> createState() => _AnimatedTitleState();
}

class _AnimatedTitleState extends State<AnimatedTitle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-2.0, 0.0), // Inizia da fuori schermo a sinistra
      end: const Offset(2.0, 0.0), // Finisce fuori schermo a destra
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // Avvia l'animazione in loop
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Testo statico CARMATE
        const Text(
          'CARMATE',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontFamily: 'Orbitron',
          ),
        ),
        // Macchina animata con opacità
        Positioned(
          top: -8, // Aggiunto questo per spostare l'auto più in alto
          child: SlideTransition(
            position: _slideAnimation,
            child: Opacity(
              opacity:
                  0.7, // Puoi regolare questo valore tra 0.0 (trasparente) e 1.0 (opaco)
              child: SizedBox(
                width: 60,
                height: 40,
                child: Image.asset(
                  'assets/videos/title_animation.gif',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
