import 'package:chatapp/chat_addons/input/enter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/message_model.dart';
import 'emoji.dart';
import 'sticker.dart';

class MessageInput extends StatefulWidget {
  final TextEditingController controller;
  final Message? replyingTo;
  final VoidCallback onCancelReply;
  final VoidCallback onSend;
  final Function(dynamic) onImageSelected;
  final Function(String) onStickerSelected;
  final FocusNode? focusNode;

  const MessageInput({
    super.key,
    required this.controller,
    this.replyingTo,
    required this.onCancelReply,
    required this.onSend,
    required this.onImageSelected,
    required this.onStickerSelected,
    this.focusNode,
  });

  @override
  _MessageInputState createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final ImagePicker _imagePicker = ImagePicker();
  final bool _isWeb = kIsWeb;
  bool _showEmojiMenu = false;
  int _currentTabIndex = 0;

  Future<void> _pickImage() async {
    try {
      if (_isWeb) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );
        if (result != null && result.files.isNotEmpty) {
          final bytes = result.files.single.bytes;
          if (bytes != null) widget.onImageSelected(bytes);
        }
      } else {
        final XFile? image = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );
        if (image != null) widget.onImageSelected(image.path);
      }
    } catch (e) {
      debugPrint('Error al seleccionar imagen: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al seleccionar imagen: ${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _insertEmoji(String emoji) {
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    final start = selection.start.clamp(0, text.length);
    final end = selection.end.clamp(0, text.length);

    final newText = text.replaceRange(start, end, emoji);

    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: (start + emoji.length).clamp(0, newText.length),
      ),
    );
  }

  void _handleStickerSelected(String stickerUrl) {
    if (mounted) {
      widget.onStickerSelected(stickerUrl); // Solo pasa el sticker hacia arriba
      setState(() => _showEmojiMenu = false); // Solo cierra el menú de stickers
      widget.focusNode?.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. Panel de emojis/stickers (encima de todo)
        if (_showEmojiMenu)
          Container(
            constraints: const BoxConstraints(maxWidth: 720),
            height: 250,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Barra de pestañas
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _buildTabButton('Emojis', 0),
                      _buildTabButton('Stickers', 1),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Contenido
                Expanded(
                  child: _currentTabIndex == 0
                      ? EmojiPickerWidget(onEmojiSelected: _insertEmoji)
                      : StickerPickerWidget(
                          onStickerSelected: _handleStickerSelected,
                        ),
                ),
              ],
            ),
          ),

        // 2. Reply Panel (si está respondiendo)
        if (widget.replyingTo != null)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Icon(Icons.reply, size: 18, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Respondiendo a ${widget.replyingTo!.sender}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                      Text(
                        widget.replyingTo!.text,
                        style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: widget.onCancelReply,
                ),
              ],
            ),
          ),

        // 3. Barra de entrada de mensaje
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.image_rounded),
                color: Colors.blueAccent,
                onPressed: _pickImage,
              ),
              IconButton(
                icon: const Icon(Icons.emoji_emotions_outlined),
                color: _showEmojiMenu ? Colors.orangeAccent : Colors.blueAccent,
                onPressed: () {
                  setState(() => _showEmojiMenu = !_showEmojiMenu);
                },
              ),
              Expanded(
                child: EnterAwareTextField(
                  focusNode: widget.focusNode,
                  controller: widget.controller,
                  hintText: widget.replyingTo != null
                      ? 'Escribe tu respuesta...'
                      : 'Escribe un mensaje...',
                  onSend: widget.onSend,
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: Colors.blueAccent,
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 20),
                  onPressed: widget.onSend,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton(String text, int index) {
    final isActive = _currentTabIndex == index;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _currentTabIndex = index),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isActive ? Colors.blueAccent : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isActive ? Colors.blueAccent : Colors.grey[600],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
