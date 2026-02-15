// lib/chat_addons/love_message_generator.dart
import 'dart:math';

class LoveMessageGenerator {
  static String getRandom() {
    final messages = [
      'Eres el sol que ilumina mis días más oscuros',
      'Mi corazón late más fuerte cuando estás cerca',
      'No hay nada en este mundo que me haga más feliz que tu sonrisa',
      'Eres mi pensamiento favorito en el día',
      'El amor que siento por ti crece más cada mañana',
      'Eres la razón por la que creo en el destino',
      'Contigo hasta el fin del universo',
    ];
    return messages[Random().nextInt(messages.length)];
  }
}