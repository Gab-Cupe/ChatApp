import 'package:chatapp/models/message_model.dart';
import 'package:chatapp/services/database_service.dart';

class ChatMessageService {
  final DatabaseService databaseService;

  ChatMessageService(this.databaseService);

  Future<void> sendMessage({
    required String sender,
    required String text,
    String? replyTo,
    String? imageUrl,
  }) async {
    await databaseService.sendMessage(
      sender,
      text,
      replyTo: replyTo,
      imageUrl: imageUrl,
    );
  }

  Future<List<Message>> getInitialMessages({int limit = 30}) {
    return databaseService.getLastMessages(limit: limit);
  }

  Future<List<Message>> loadMoreMessages(
    int beforeTimestamp, {
    int limit = 30,
  }) {
    return databaseService.loadMoreMessages(beforeTimestamp, limit: limit);
  }

  Future<void> markMessageAsSeen(
    String messageId,
    String recipientUsername,
    String senderUsername,
  ) async {
    // Verificar que el mensaje no sea del mismo usuario
    if (recipientUsername != senderUsername) {
      await databaseService.markMessageAsSeen(messageId, recipientUsername);
    } else {
      //
    }
  }

  void dispose() {
    databaseService.dispose();
  }
}
