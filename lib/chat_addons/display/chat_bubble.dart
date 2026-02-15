import 'dart:math';
import 'package:chatapp/chat_addons/logic/dialog_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:gif/gif.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../models/message_model.dart';
import '../../services/database_service.dart';
import 'reply_bubble.dart';
import '../input/message_menu.dart';

class ChatBubble extends StatefulWidget {
  final Message message;
  final bool isMe;
  final Function(Message) onStartReply;
  final DatabaseService dbService;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.onStartReply,
    required this.dbService,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> with TickerProviderStateMixin {
  late GifController _gifController;
  late AnimationController _heartController;
  late Animation<double> _heartAnimation;
  YoutubePlayerController? _ytController;
  WebViewController? _tiktokController;
  bool _isYoutubeUrl = false;
  bool _isTiktokUrl = false;
  String? _videoId;
  bool _showHeartParticles = false;

  @override
  void initState() {
    super.initState();
    _gifController = GifController(vsync: this);
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _heartAnimation = CurvedAnimation(
      parent: _heartController,
      curve: Curves.easeOut,
    );
    _initializeVideoPlayers();
  }

  @override
  void didUpdateWidget(ChatBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.text != widget.message.text) {
      _initializeVideoPlayers();
    }
    if (oldWidget.message.reactions != widget.message.reactions) {
      _checkForHeartReaction(oldWidget.message.reactions);
    }
  }

  void _checkForHeartReaction(List<String> oldReactions) {
    if (widget.message.reactions.isEmpty) return;

    final hasHeart = widget.message.reactions.any((r) => r.endsWith('❤️'));
    final hadHeart = oldReactions.any((r) => r.endsWith('❤️'));

    if (hasHeart && !hadHeart) {
      setState(() {
        _showHeartParticles = true;
      });
      _heartController.forward().then((_) {
        if (mounted) {
          setState(() {
            _showHeartParticles = false;
          });
          _heartController.reset();
        }
      });
    }
  }

  void _initializeVideoPlayers() {
    final url = widget.message.text;
    if (url.isEmpty) return;

    _isYoutubeUrl = url.contains('youtube.com') || url.contains('youtu.be');
    _isTiktokUrl = url.contains('tiktok.com');

    if (_isYoutubeUrl) {
      _videoId = YoutubePlayerController.convertUrlToId(url);
      if (_videoId != null && _videoId!.isNotEmpty) {
        _ytController?.close();
        _ytController = YoutubePlayerController.fromVideoId(
          videoId: _videoId!,
          params: YoutubePlayerParams(
            showControls: true,
            showFullscreenButton: true,
          ),
        );
      } else {
        _isYoutubeUrl = false;
      }
    }

    if (_isTiktokUrl) {
      final embedUrl = _getTiktokEmbedUrl(url);
      _tiktokController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.black)
        ..setNavigationDelegate(
          NavigationDelegate(
            onNavigationRequest: (request) {
              if (!request.url.contains('tiktok.com/embed')) {
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadRequest(Uri.parse(embedUrl));
    }
  }

  String _getTiktokEmbedUrl(String url) {
    final regex = RegExp(r'https?://(www\.)?tiktok\.com/@[^/]+/video/(\d+)');
    final match = regex.firstMatch(url);

    if (match != null) {
      return "https://www.tiktok.com/embed/v2/${match.group(2)}?lang=es";
    }

    if (url.contains('vm.tiktok.com') || url.contains('vt.tiktok.com')) {
      return "https://www.tiktok.com/oembed?url=$url";
    }

    return url;
  }

  @override
  void dispose() {
    _gifController.dispose();
    _heartController.dispose();
    _ytController?.close();
    _tiktokController = null;
    super.dispose();
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Expanded(
              child: InteractiveViewer(
                panEnabled: true,
                boundaryMargin: const EdgeInsets.all(20),
                minScale: 0.1,
                maxScale: 4.0,
                child: Center(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Text(
                        'Error al cargar imagen',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTiktokPlayer(BuildContext context) {
    return Consumer<DialogState>(
      builder: (context, dialogState, child) {
        if (dialogState.isDialogOpen || _tiktokController == null) {
          return GestureDetector(
            onLongPress: () => _showMessageMenu(context),
            child: Container(
              width: 320,
              height: 580,
              color: Colors.black,
              child: const Center(
                child: Icon(
                  Icons.play_circle_filled,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ),
          );
        }

        return GestureDetector(
          onLongPress: () => _showMessageMenu(context),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 300,
              maxWidth: 500,
              minHeight: 300,
              maxHeight: 580,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  WebViewWidget(controller: _tiktokController!),
                  Positioned.fill(child: Container(color: Colors.transparent)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showMessageMenu(BuildContext context) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      items: [
        PopupMenuItem(
          value: 'reply',
          child: Row(
            children: [
              const Icon(Icons.reply),
              const SizedBox(width: 8),
              Text('Responder'),
            ],
          ),
        ),
        if (widget.isMe) ...[
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                const Icon(Icons.edit),
                const SizedBox(width: 8),
                Text('Editar'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                const Icon(Icons.delete, color: Colors.red),
                const SizedBox(width: 8),
                Text('Eliminar', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
      ],
    ).then((value) {
      if (value == 'reply') {
        widget.onStartReply(widget.message);
      } else if (value == 'edit') {
        // Lógica para editar
      } else if (value == 'delete') {
        // Lógica para eliminar
      }
    });
  }

  Widget _buildYoutubePlayer(BuildContext context) {
    return Consumer<DialogState>(
      builder: (context, dialogState, child) {
        if (dialogState.isDialogOpen || _ytController == null) {
          return Container(
            width: 500,
            height: 280,
            color: Colors.black,
            child: const Center(
              child: Icon(
                Icons.play_circle_filled,
                color: Colors.white,
                size: 50,
              ),
            ),
          );
        }

        return ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 300,
            maxWidth: 500,
            minHeight: 200,
            maxHeight: 280,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: YoutubePlayer(
              key: ValueKey(widget.message.id),
              controller: _ytController!,
              aspectRatio: 16 / 9,
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageOrSticker(BuildContext context) {
    final isSticker =
        widget.message.imageUrl!.contains('sticker') ||
        widget.message.imageUrl!.contains('ibb.co');

    if (isSticker) {
      final isGif = widget.message.imageUrl!.endsWith('.gif');
      return SizedBox(
        width: 120,
        height: 120,
        child: isGif
            ? Gif(
                image: NetworkImage(widget.message.imageUrl!),
                controller: _gifController,
                autostart: Autostart.loop,
                placeholder: (context) => Container(
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                onFetchCompleted: () {
                  _gifController.reset();
                  _gifController.forward();
                },
                fit: BoxFit.cover,
              )
            : GestureDetector(
                onTap: () => _showFullImage(context, widget.message.imageUrl!),
                child: Image.network(
                  widget.message.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.error_outline, color: Colors.red),
                  ),
                ),
              ),
      );
    } else {
      return GestureDetector(
        onTap: () => _showFullImage(context, widget.message.imageUrl!),
        child: Image.network(
          widget.message.imageUrl!,
          height: 500,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.grey[200],
            child: const Icon(Icons.error_outline, color: Colors.red),
          ),
        ),
      );
    }
  }

  Widget _buildReactions(BuildContext context) {
    if (widget.message.reactions.isEmpty) return const SizedBox.shrink();

    final reactionCounts = <String, int>{};
    for (final reaction in widget.message.reactions) {
      final parts = reaction.split(':');
      final emoji = parts.length > 1 ? parts[1] : reaction;
      reactionCounts[emoji] = (reactionCounts[emoji] ?? 0) + 1;
    }

    return Positioned(
      right: widget.isMe ? null : -8,
      left: widget.isMe ? -8 : null,
      bottom: -8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: reactionCounts.entries.map((entry) {
            return GestureDetector(
              onTap: () => _handleReactionTap(context, entry.key),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  '${entry.key}${entry.value > 1 ? ' ${entry.value}' : ''}',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _handleReactionTap(BuildContext context, String emoji) {
    final userReaction = widget.message.reactions.firstWhere(
      (r) => r.startsWith('${widget.message.sender}:'),
      orElse: () => '',
    );

    if (userReaction.isNotEmpty && userReaction.endsWith(emoji)) {
      final updatedReactions = List<String>.from(widget.message.reactions)
        ..remove(userReaction);
      widget.dbService.updateMessageReactions(
        widget.message.id,
        updatedReactions,
      );
    } else if (userReaction.isNotEmpty) {
      final updatedReactions = List<String>.from(widget.message.reactions)
        ..[widget.message.reactions.indexOf(userReaction)] =
            '${widget.message.sender}:$emoji';
      widget.dbService.updateMessageReactions(
        widget.message.id,
        updatedReactions,
      );
    } else {
      final updatedReactions = List<String>.from(widget.message.reactions)
        ..add('${widget.message.sender}:$emoji');
      widget.dbService.updateMessageReactions(
        widget.message.id,
        updatedReactions,
      );
    }
  }

  Widget _buildHeartParticles() {
    if (!_showHeartParticles) return const SizedBox.shrink();

    return Positioned.fill(
      child: OverflowBox(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
        child: AnimatedBuilder(
          animation: _heartAnimation,
          builder: (context, child) {
            return Stack(
              children: List.generate(5, (index) {
                final rng = Random(index);
                final size = 16.0 + rng.nextDouble() * 16;
                final left = rng.nextDouble() * 100;

                return Positioned(
                  left: left,
                  bottom: 0,
                  child: Opacity(
                    opacity: 1 - _heartAnimation.value,
                    child: Transform.translate(
                      offset: Offset(0, -100 * _heartAnimation.value),
                      child: Transform.scale(
                        scale: 1 + _heartAnimation.value,
                        child: Icon(
                          Icons.favorite,
                          color: Colors.red,
                          size: size,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: Column(
        crossAxisAlignment: widget.isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (widget.message.replyTo != null)
            ReplyBubble(
              messageId: widget.message.replyTo!,
              isMe: widget.isMe,
              onTap: widget.onStartReply,
            ),

          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                constraints: BoxConstraints(
                  minWidth: widget.message.text.length < 5 ? 80 : 0,
                  maxWidth: (_isYoutubeUrl || _isTiktokUrl)
                      ? 320.0
                      : MediaQuery.of(context).size.width * 0.75,
                ),
                padding: (_isYoutubeUrl || _isTiktokUrl)
                    ? const EdgeInsets.all(0)
                    : const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                decoration: BoxDecoration(
                  gradient: (_isYoutubeUrl || _isTiktokUrl)
                      ? null
                      : LinearGradient(
                          colors: widget.isMe
                              ? [
                                  Colors.blueAccent.shade700,
                                  Colors.lightBlue.shade400,
                                ]
                              : [
                                  Colors.white,
                                  const Color.fromARGB(255, 252, 254, 255),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  color: (_isYoutubeUrl || _isTiktokUrl) ? Colors.black : null,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(widget.isMe ? 16 : 4),
                    bottomRight: Radius.circular(widget.isMe ? 4 : 16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!widget.isMe &&
                            !_isYoutubeUrl &&
                            !_isTiktokUrl) ...[
                          Text(
                            widget.message.sender,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: widget.isMe
                                  ? Colors.white
                                  : Colors.black87,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],

                        if (_isYoutubeUrl && _ytController != null)
                          _buildYoutubePlayer(context)
                        else if (_isTiktokUrl && _tiktokController != null)
                          _buildTiktokPlayer(context)
                        else if (widget.message.imageUrl != null)
                          _buildImageOrSticker(context)
                        else
                          Text(
                            widget.message.text,
                            style: TextStyle(
                              color: widget.isMe
                                  ? Colors.white
                                  : Colors.black87,
                              fontSize: 16,
                            ),
                          ),

                        if (!_isYoutubeUrl && !_isTiktokUrl)
                          const SizedBox(height: 4),
                        if (!_isTiktokUrl)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.message.edited)
                                Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: Text(
                                    'Editado',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontStyle: FontStyle.italic,
                                      color: widget.isMe
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                  ),
                                ),
                              Text(
                                '${widget.message.timestamp.hour > 12 ? widget.message.timestamp.hour - 12 : widget.message.timestamp.hour}:'
                                '${widget.message.timestamp.minute.toString().padLeft(2, '0')} '
                                '${widget.message.timestamp.hour >= 12 ? "PM" : "AM"}'
                                ' '
                                '${widget.message.timestamp.day}/${widget.message.timestamp.month}/${widget.message.timestamp.year.toString().substring(2)}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: widget.isMe
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                              ),
                              if (widget.isMe)
                                Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Icon(
                                    widget.message.isSeen
                                        ? Icons.done_all
                                        : Icons.done,
                                    size: 18,
                                    color: widget.message.isSeen
                                        ? Colors.lightBlueAccent
                                        : Colors.blueGrey[400]!,
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                    if (!_isTiktokUrl)
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: MessageMenu(
                          message: widget.message,
                          isMe: widget.isMe,
                          onReply: widget.onStartReply,
                          dbService: widget.dbService,
                        ),
                      ),
                    _buildHeartParticles(),
                  ],
                ),
              ),
              _buildReactions(context),
            ],
          ),
        ],
      ),
    );
  }
}
