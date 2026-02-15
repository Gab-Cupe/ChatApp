// lib/screens/chat_screen.dart
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:chatapp/chat_addons/display/chat_bubble.dart';
import 'package:chatapp/chat_addons/effects/confetti_effect.dart';
import 'package:chatapp/chat_addons/logic/image_service.dart';
import 'package:chatapp/chat_addons/effects/love_message_dialog.dart';
import 'package:chatapp/chat_addons/input/message_input.dart';
import 'package:chatapp/chat_addons/display/scroll.dart';
import 'package:chatapp/models/message_model.dart';
import 'package:chatapp/models/user_model.dart';
import 'package:chatapp/notifications/timer_menu.dart';
import 'package:chatapp/screens/login_screen.dart';
import 'package:chatapp/services/auth_service.dart';
import 'package:chatapp/services/chat_message_service.dart';
import 'package:chatapp/services/database_service.dart';
import 'package:chatapp/services/unread.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;

class ChatScreen extends StatefulWidget {
  final User user;
  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final UserService _userService = UserService();
  List<User> _onlineUsers = [];
  List<User> _typingUsers = [];
  final AuthService _authService = AuthService();
  StreamSubscription<bool>? _onlineStatusSub; // Nuevo

  StreamSubscription<List<User>>? _onlineUsersSub;
  StreamSubscription<DatabaseEvent>? _newMessageSub;
  StreamSubscription<DatabaseEvent>? _editMessageSub;
  StreamSubscription<DatabaseEvent>? _deleteMessageSub;
  StreamSubscription<List<User>>? _typingUsersSub;

  final TextEditingController _messageController = TextEditingController();
  final ChatMessageService _messageService = ChatMessageService(
    DatabaseService(),
  );
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  late AnimationController _typingAnimationController;
  late List<Animation<double>> _dotAnimations = [];
  late UnreadMessageService _unreadMessageService;

  List<Message> _messages = [];
  bool _isLoadingMore = false;
  bool _hasMore = true;
  Message? _replyingTo;
  dynamic _selectedImage;
  String? _imagePreviewUrl;
  bool _isWeb = false;
  Timer? _typingTimer;
  bool _isTyping = false;
  bool _showScrollToBottomButton = false;

  @override
  void initState() {
    super.initState();

    _onlineStatusSub = _userService.onOnlineStatusChanged.listen((isOnline) {
      if (mounted && isOnline) {
        // Solo si el usuario está online
        refreshMessages();
      }
    });

    _unreadMessageService = UnreadMessageService(_authService, _userService);

    _typingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _dotAnimations = List.generate(3, (index) {
      return Tween(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(
          parent: _typingAnimationController,
          curve: Interval(0.2 * index, 1.0, curve: Curves.easeInOut),
        ),
      );
    });

    WidgetsBinding.instance.addObserver(this);

    _isWeb = kIsWeb;
    _loadInitialMessages();
    enableScrollWithKeyboard(_scrollController);

    _userService.setUserOnline(widget.user.username, true);

    _messageController.addListener(_handleTyping);

    _onlineUsersSub = _userService.getOnlineUsers(widget.user.username).listen((
      users,
    ) {
      if (mounted) {
        setState(() {
          _onlineUsers = users;
          _typingUsers = users.where((user) => user.isWriting).toList();
        });
      }
    });

    final db = _messageService.databaseService;

    _newMessageSub = db.newMessageStream.listen((event) {
      if (!mounted) return;
      if (event.snapshot.value != null) {
        final newMessage = Message.fromMap(
          event.snapshot.key!,
          Map<String, dynamic>.from(event.snapshot.value as Map),
        );
        final exists = _messages.any((m) => m.id == newMessage.id);
        if (!exists) {
          setState(() => _messages.add(newMessage));
          if (_scrollController.hasClients &&
              _scrollController.position.pixels >=
                  _scrollController.position.maxScrollExtent - 50) {
            _markVisibleMessagesAsSeen();
          }
          scrollToBottom();
        }
      }
    });

    _editMessageSub = db.messageEditStream.listen((event) {
      if (!mounted) return;
      if (event.snapshot.value != null) {
        final updated = Message.fromMap(
          event.snapshot.key!,
          Map<String, dynamic>.from(event.snapshot.value as Map),
        );
        final index = _messages.indexWhere((m) => m.id == updated.id);
        if (index != -1) setState(() => _messages[index] = updated);
      }
    });

    _deleteMessageSub = db.messageDeleteStream.listen((event) {
      if (!mounted) return;
      setState(() => _messages.removeWhere((m) => m.id == event.snapshot.key));
    });

    _scrollController.addListener(_scrollListener);
  }

  void _handleTyping() {
    if (_messageController.text.isNotEmpty && !_isTyping) {
      setState(() => _isTyping = true);
      _userService.setUserWritingStatus(widget.user.username, true);
      _startTypingTimer();
    } else if (_messageController.text.isEmpty && _isTyping) {
      _stopTyping();
    }
  }

  void _startTypingTimer() {
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 5), _stopTyping);
  }

  void _stopTyping() {
    if (_isTyping) {
      setState(() => _isTyping = false);
      _userService.setUserWritingStatus(widget.user.username, false);
      _typingTimer?.cancel();
    }
  }

  void refreshMessages() {
    _unreadMessageService.checkUnreadMessages();
    _loadInitialMessages();
  }

  Widget _buildTypingIndicator() {
    if (_typingUsers.isEmpty) return const SizedBox.shrink();

    return Positioned(
      bottom: 70,
      left: 16,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Container(
          key: ValueKey(_typingUsers.length),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6a11cb), Color(0xFF2575fc)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 1,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 32,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    return AnimatedBuilder(
                      animation: _dotAnimations[index],
                      builder: (context, child) {
                        return Opacity(
                          opacity: _dotAnimations[index].value,
                          child: Transform.scale(
                            scale: _dotAnimations[index].value,
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _typingUsers.length == 1
                    ? '${_typingUsers.first.displayName} está escribiendo...'
                    : '${_typingUsers.length} personas están escribiendo...',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _scrollListener() {
    if (_scrollController.position.pixels <=
            _scrollController.position.minScrollExtent + 50 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMoreMessages();
    }

    // Mostrar u ocultar el botón de scroll to bottom
    if (_scrollController.hasClients) {
      final isAtBottom =
          _scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 100;
      if (_showScrollToBottomButton == isAtBottom) {
        setState(() {
          _showScrollToBottomButton = !isAtBottom;
        });
      }
    }

    _markVisibleMessagesAsSeen();
  }

  void _markVisibleMessagesAsSeen() {
    if (_scrollController.hasClients) {
      for (var message in _messages) {
        if (!message.isSeen) {
          _messageService.markMessageAsSeen(
            message.id,
            widget.user.username,
            message.sender,
          );
        }
      }
    }
  }

  Future<void> _loadInitialMessages() async {
    final messages = await _messageService.getInitialMessages();
    if (mounted) {
      setState(() {
        _messages = messages;
      });
    }
    scrollToBottom();

    for (var message in messages) {
      if (!message.isSeen) {
        _messageService.markMessageAsSeen(
          message.id,
          widget.user.username,
          message.sender,
        );
      }
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_messages.isEmpty) return;
    _isLoadingMore = true;

    final before = _scrollController.position.pixels;
    final oldest = _messages.first;
    final moreMessages = await _messageService.loadMoreMessages(
      oldest.timestamp.millisecondsSinceEpoch,
    );

    if (mounted) {
      setState(() {
        if (moreMessages.isEmpty) {
          _hasMore = false;
        } else {
          _messages = [...moreMessages, ..._messages];
        }
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(_scrollController.position.pixels + before);
    });

    _isLoadingMore = false;
    _markVisibleMessagesAsSeen();
  }

  Future<void> _sendMessage() async {
    _stopTyping();
    final text = _messageController.text.trim();

    if (text.isNotEmpty || _selectedImage != null) {
      String? imageUrl;

      if (_selectedImage is String &&
          (_selectedImage as String).startsWith('http')) {
        imageUrl = _selectedImage as String;
      } else if (_selectedImage != null) {
        if (_isWeb && _selectedImage is Uint8List) {
          imageUrl = await ImageService.uploadImageFromBytes(_selectedImage);
        } else if (!_isWeb && _selectedImage is String) {
          imageUrl = await ImageService.uploadImage(_selectedImage);
        }
      }

      await _messageService.sendMessage(
        sender: widget.user.displayName,
        text: text.isNotEmpty
            ? text
            : (imageUrl != null ? '[contenido multimedia]' : ''),
        replyTo: _replyingTo?.id,
        imageUrl: imageUrl,
      );

      _messageController.clear();
      if (mounted) {
        setState(() {
          _selectedImage = null;
          if (_isWeb && _imagePreviewUrl != null) {
            html.Url.revokeObjectUrl(_imagePreviewUrl!);
            _imagePreviewUrl = null;
          }
        });
      }
      _cancelReply();
    }
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
        setState(() {
          _showScrollToBottomButton = false;
        });
      }
    });
  }

  void _startReply(Message message) {
    setState(() {
      _replyingTo = message;
    });
    _focusNode.requestFocus();
  }

  void _cancelReply() {
    if (mounted) {
      setState(() {
        _replyingTo = null;
      });
    }
  }

  void _handleImageSelected(dynamic imageData) {
    if (_isWeb && imageData is Uint8List) {
      final blob = html.Blob([imageData]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      setState(() {
        _selectedImage = imageData;
        _imagePreviewUrl = url;
      });
    } else if (!_isWeb && imageData is String) {
      setState(() {
        _selectedImage = imageData;
      });
    }
  }

  Widget _buildImagePreview() {
    if (_selectedImage == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.75 - 16,
                  ),
                  child: _isWeb
                      ? Image.network(
                          _imagePreviewUrl!,
                          width: double.infinity,
                          fit: BoxFit.contain,
                          frameBuilder:
                              (context, child, frame, wasSynchronouslyLoaded) {
                                return AnimatedOpacity(
                                  opacity: frame == null ? 0 : 1,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOut,
                                  child: child,
                                );
                              },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 150,
                              alignment: Alignment.center,
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                                color: Colors.white70,
                              ),
                            );
                          },
                        )
                      : Image.file(
                          File(_selectedImage!),
                          width: double.infinity,
                          fit: BoxFit.contain,
                          frameBuilder:
                              (context, child, frame, wasSynchronouslyLoaded) {
                                return AnimatedOpacity(
                                  opacity: frame == null ? 0 : 1,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOut,
                                  child: child,
                                );
                              },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 150,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.error_outline,
                                color: Colors.white70,
                                size: 40,
                              ),
                            );
                          },
                        ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: Material(
                color: Colors.black.withOpacity(0.7),
                shape: const CircleBorder(),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    setState(() {
                      if (_isWeb && _imagePreviewUrl != null) {
                        html.Url.revokeObjectUrl(_imagePreviewUrl!);
                      }
                      _selectedImage = null;
                      _imagePreviewUrl = null;
                    });
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.close,
                      size: 20,
                      color: Colors.white,
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

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      reverse: false,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMe = message.sender == widget.user.displayName;

        return ChatBubble(
          message: message,
          isMe: isMe,
          onStartReply: _startReply,
          dbService: DatabaseService(),
        );
      },
    );
  }

  Widget _buildScrollToBottomButton() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      right: 16,
      bottom: _showScrollToBottomButton ? 70 : -50,
      child: FloatingActionButton(
        mini: true,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: scrollToBottom,
        child: const Icon(Icons.arrow_downward, size: 20),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chat App',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Row(
            children: [
              Container(
                width: 10,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.lightGreenAccent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.lightGreenAccent.withOpacity(0.5),
                      blurRadius: 4,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _onlineUsers.isNotEmpty
                    ? '${_onlineUsers.map((user) => user.displayName).join(', ')} • En línea'
                    : 'Nadie en línea',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ],
      ),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Color(0xFFeb3af3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      elevation: 10,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: refreshMessages,
          tooltip: 'Actualizar mensajes',
        ),
        const TimerMenu(),
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) =>
                  LoveMessageDialog(onConfetti: () => _showConfetti()),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          tooltip: 'Cerrar sesión',
          onPressed: _logout,
        ),
      ],
    );
  }

  void _showConfetti() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const ConfettiEffect(message: '❤ TE AMO JANDYSITA❤'),
    ).then((_) => Navigator.pop(context));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFfff4fc), Color(0xFFfff4fc)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: _buildMessageList(),
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
          _buildTypingIndicator(),
          _buildScrollToBottomButton(),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 3213913),
                child: Column(
                  children: [
                    _buildImagePreview(),
                    MessageInput(
                      focusNode: _focusNode,
                      controller: _messageController,
                      replyingTo: _replyingTo,
                      onCancelReply: _cancelReply,
                      onSend: _sendMessage,
                      onImageSelected: _handleImageSelected,
                      onStickerSelected: (stickerUrl) {
                        if (!mounted) return;
                        _messageService
                            .sendMessage(
                              sender: widget.user.displayName,
                              text: '[sticker]',
                              imageUrl: stickerUrl,
                              replyTo: _replyingTo?.id,
                            )
                            .then((_) {
                              if (mounted) {
                                _cancelReply();
                              }
                            })
                            .catchError((error) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Error al enviar sticker: $error',
                                    ),
                                  ),
                                );
                              }
                            });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _onlineStatusSub?.cancel(); // Limpieza

    _unreadMessageService.dispose();

    _typingAnimationController.dispose();
    _onlineUsersSub?.cancel();
    _newMessageSub?.cancel();
    _editMessageSub?.cancel();
    _deleteMessageSub?.cancel();
    _typingUsersSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _authService.handleAppClose(widget.user.username);
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _typingTimer?.cancel();
    _messageController.removeListener(_handleTyping);

    if (_isWeb && _imagePreviewUrl != null) {
      html.Url.revokeObjectUrl(_imagePreviewUrl!);
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _authService.handleAppClose(widget.user.username);
    } else if (state == AppLifecycleState.resumed) {
      _userService.setUserOnline(widget.user.username, true);
    }
  }

  void _logout() async {
    await _authService.logout(widget.user.username);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }
}
