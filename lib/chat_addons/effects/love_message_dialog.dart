// lib/chat_addons/love_message_dialog.dart
import 'package:flutter/material.dart';
import 'package:chatapp/chat_addons/logic/love_message_generator.dart';

class LoveMessageDialog extends StatelessWidget {
  final VoidCallback onConfetti;

  const LoveMessageDialog({super.key, required this.onConfetti});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFCDD2), Color(0xFFF8BBD0)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.pink.withOpacity(0.3),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.favorite, color: Colors.white, size: 80),
                    Icon(
                      Icons.favorite_border,
                      color: Colors.pink[300],
                      size: 80,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Para mi amor',
                  style: TextStyle(
                    fontSize: 24,
                    color: Color(0xFF880E4F),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  LoveMessageGenerator.getRandom(),
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFFC2185B),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 25),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink[400],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    onConfetti();
                  },
                  child: const Text(
                    'Cerrar con amor',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
