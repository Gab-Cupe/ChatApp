import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../services/database_service.dart';
import '../../models/message_model.dart';
import 'image_viewer.dart'; // Añadir esta importación

class ReplyBubble extends StatelessWidget {
  final String messageId;
  final bool isMe;
  final Function(Message) onTap;

  const ReplyBubble({
    super.key,
    required this.messageId,
    required this.isMe,
    required this.onTap,
  });

  void _handleTap(BuildContext context, Message repliedMessage) {
    // Si es una imagen o sticker, abrir el visor
    if (repliedMessage.imageUrl != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: Center(
              child: ImageViewer(imageUrl: repliedMessage.imageUrl!),
            ),
          ),
        ),
      );
    } else {
      // Si es texto normal, mantener comportamiento de respuesta
      onTap(repliedMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final databaseService = DatabaseService();

    return FutureBuilder<Message?>(
      future: databaseService.getMessage(messageId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Shimmer.fromColors(
            baseColor: isMe ? Colors.blue[100]! : Colors.grey[300]!,
            highlightColor: isMe ? Colors.blue[50]! : Colors.grey[100]!,
            child: Container(
              padding: const EdgeInsets.all(6),
              margin: const EdgeInsets.only(bottom: 4),
              constraints: const BoxConstraints(maxWidth: 200),
              decoration: BoxDecoration(
                color: isMe ? Colors.blue[50] : Colors.grey[200],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isMe ? Colors.blue[100]! : Colors.grey[300]!,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blue[100] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blue[100] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox();
        }

        final repliedMessage = snapshot.data!;
        return GestureDetector(
          onTap: () =>
              _handleTap(context, repliedMessage), // Usamos el nuevo manejador
          child: Container(
            padding: const EdgeInsets.all(6),
            margin: const EdgeInsets.only(bottom: 4),
            constraints: const BoxConstraints(maxWidth: 200),
            decoration: BoxDecoration(
              color: isMe ? Colors.blue[50] : Colors.grey[200],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isMe ? Colors.blue[100]! : Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Respondiendo a ${repliedMessage.sender}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isMe ? Colors.blue[800] : Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 2),
                repliedMessage.imageUrl != null
                    ? const Text(
                        '[Imagen]',
                        style: TextStyle(
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    : Text(
                        repliedMessage.text,
                        style: TextStyle(
                          fontSize: 10,
                          color: isMe ? Colors.blue[800] : Colors.grey[800],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
              ],
            ),
          ),
        );
      },
    );
  }
}
