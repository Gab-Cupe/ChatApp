import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');

    await _notificationsPlugin.initialize(
      const InitializationSettings(android: androidSettings),
    );

    // Canal para mensajes urgentes
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          'urgent_channel',
          'Notificaciones urgentes',
          description: 'Para mensajes nuevos importantes',
          importance: Importance.max,
        ));

    // Canal para recordatorios de actividad
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          'reminder_channel',
          'Recordatorios de actividad',
          description: 'Notifica que la app sigue corriendo',
          importance: Importance.low,
        ));
  }

  static Future<void> showNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'urgent_channel',
      'Notificaciones urgentes',
      importance: Importance.max,
      priority: Priority.high,
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
      colorized: true,
      color: Color.fromARGB(255, 255, 132, 50),
    );

    await _notificationsPlugin.show(
      0,
      title,
      body,
      const NotificationDetails(android: androidDetails),
    );
  }

  static Future<void> showReminderNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'reminder_channel',
      'Recordatorios de actividad',
      importance: Importance.low,
      priority: Priority.low,
      icon: '@mipmap/launcher_icon',
    );

    await _notificationsPlugin.show(
      2,
      title,
      body,
      const NotificationDetails(android: androidDetails),
    );
  }
}
