// ignore_for_file: prefer_is_not_operator

import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

class MessageListener {
  final DatabaseReference _messagesRef =
      FirebaseDatabase.instance.ref().child('messages');

  String? _lastSeenKey;
  final Set<String> _notifiedKeys = {};

  Future<void> _loadLastSeenKey() async {
    final prefs = await SharedPreferences.getInstance();
    _lastSeenKey = prefs.getString('lastSeenKey');
    //debugPrint("📌 Última clave cargada: $_lastSeenKey");
  }

  Future<void> _saveLastSeenKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastSeenKey', key);
    //debugPrint("💾 Guardada nueva clave: $key");
    _lastSeenKey = key;
  }

  Future<void> startListening() async {
    await _loadLastSeenKey();

    Query query = _messagesRef.orderByKey();
    if (_lastSeenKey != null) {
      query = _messagesRef.orderByKey().startAfter(_lastSeenKey);
    }

    query.onChildAdded.listen((event) async {
      final key = event.snapshot.key;
      if (key == null || _notifiedKeys.contains(key)) return;

      final data = event.snapshot.value;
      if (data == null || !(data is Map)) return;

      final messageData = Map<String, dynamic>.from(data);
      final sender = messageData['sender']?.toString() ?? 'Desconocido';
      final text = messageData['text']?.toString() ?? '';

      //debugPrint("📩 Nuevo mensaje detectado - Key: $key, Sender: $sender");

      await NotificationService.showNotification(
        "Nuevo mensaje de $sender",
        text.isNotEmpty ? text : "(Mensaje sin texto)",
      );

      _notifiedKeys.add(key);
      await _saveLastSeenKey(key);
    }, onError: (error) {
      //debugPrint("🔥 Error en listener: $error");
    });
  }
}
