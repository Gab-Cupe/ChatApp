// ignore_for_file: use_super_parameters, deprecated_member_use

import 'package:flutter/material.dart';
import 'timer.dart';

class TimerMenu extends StatefulWidget {
  const TimerMenu({Key? key}) : super(key: key);

  @override
  State<TimerMenu> createState() => _TimerMenuState();
}

class _TimerMenuState extends State<TimerMenu> {
  int _selectedTimeInSeconds = 300;

  String _formatTime(int seconds) {
    if (seconds < 60) return '$seconds seg';
    return '${seconds ~/ 60} min';
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.timer, color: Colors.white), // Botón simple como antes
      onPressed: () => _showTimerDialog(context),
    );
  }

  void _showTimerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            insetPadding: const EdgeInsets.all(20), // Asegura espacio en móviles
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 400, // Máximo ancho para tablets
                maxHeight: 300, // Altura segura para móviles
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Configurar recordatorio',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        children: [
                          Text(
                            _formatTime(_selectedTimeInSeconds),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Slider(
                            value: _selectedTimeInSeconds.toDouble(),
                            min: 10,
                            max: 1200,
                            divisions: 119,
                            label: _formatTime(_selectedTimeInSeconds),
                            onChanged: (value) => setState(() {
                              _selectedTimeInSeconds = value.round();
                            }),
                          ),
                          const SizedBox(height: 8),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('10 seg', style: TextStyle(fontSize: 12)),
                              Text('20 min', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context, _selectedTimeInSeconds);
                            _showSnackbar(context);
                          },
                          child: const Text('Guardar', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ).then((value) {
      if (value != null) {
        setState(() => _selectedTimeInSeconds = value);
        PeriodicNotifier.update(value);
      }
    });
  }

void _showSnackbar(BuildContext context) {
  final theme = Theme.of(context);
  final isDarkMode = theme.brightness == Brightness.dark;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Icon(
              Icons.timer,
              key: ValueKey<int>(_selectedTimeInSeconds),
              color: Colors.blueAccent.shade200,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Recordatorio configurado',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.grey.shade800,
                  ),
                ),
                Text(
                  'Cada ${_formatTime(_selectedTimeInSeconds)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      duration: const Duration(seconds: 2),
      backgroundColor: isDarkMode 
          ? Colors.grey.shade900.withOpacity(0.9)
          : Colors.white,
      elevation: 6,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDarkMode ? Colors.blue.shade800 : Colors.blue.shade200,
          width: 1.5,
        ),
      ),
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      clipBehavior: Clip.antiAlias,
    ),
  );
}
}