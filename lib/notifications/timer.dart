import 'dart:async';
import 'notification_service.dart';

class PeriodicNotifier {
  static Timer? _timer;
  static int _currentIntervalInSeconds = 300; // Valor por defecto: 5 minutos (300 segundos)

  static void start(int seconds) {
    _currentIntervalInSeconds = seconds;
    _timer?.cancel();
    _timer = Timer.periodic(
      Duration(seconds: _currentIntervalInSeconds),
      (_) {
        NotificationService.showReminderNotification(
          "Todo bajo control 👌",
          "La app sigue atenta por si llega algún mensajito 📬",
        );
      },
    );
    //debugPrint("⏰ Timer configurado cada $_currentIntervalInSeconds segundos");
  }

  static void update(int seconds) {
    start(seconds);
  }

  static void stop() {
    _timer?.cancel();
    //debugPrint("⏰ Timer detenido");
  }
}