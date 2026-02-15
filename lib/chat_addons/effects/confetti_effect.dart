// lib/chat_addons/confetti_effect.dart
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

class ConfettiEffect extends StatefulWidget {
  final String message;

  const ConfettiEffect({super.key, required this.message});

  @override
  State<ConfettiEffect> createState() => _ConfettiEffectState();
}

class _ConfettiEffectState extends State<ConfettiEffect> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: ConfettiWidget(
          confettiController: _confettiController,
          blastDirection: -1.0,
          emissionFrequency: 0.05,
          numberOfParticles: 50,
          gravity: 0.2,
          shouldLoop: false,
          colors: const [
            Colors.pink,
            Colors.red,
            Colors.white,
            Colors.pinkAccent,
          ],
          child: Center(
            child: Text(
              widget.message,
              style: const TextStyle(
                fontSize: 30,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    blurRadius: 10,
                    color: Colors.pink,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}