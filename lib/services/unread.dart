import 'dart:async';

import 'package:chatapp/models/user_model.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:universal_html/html.dart' as html;
import 'package:chatapp/models/message_model.dart';
import 'package:chatapp/services/auth_service.dart';

class UnreadMessageService {
  final AuthService _authService;
  final UserService _userService;
  final DatabaseReference _messagesRef;
  StreamSubscription<DatabaseEvent>? _unreadMessagesSub;
  StreamSubscription<List<User>>? _onlineUsersSub;
  String _currentUsername = '';
  int _unreadCount = 0;
  bool _isOnline = false;

  UnreadMessageService(this._authService, this._userService)
    : _messagesRef = FirebaseDatabase.instance.ref().child('messages') {
    _init();
  }

  void _init() async {
    final username = await _authService.getCurrentUsername();
    if (username != null) {
      _currentUsername = username;
      _startListening();
      _setupOnlineStatusListener();
    }
  }

  void _setupOnlineStatusListener() {
    _onlineUsersSub = _userService.getOnlineUsers(_currentUsername).listen((
      users,
    ) {
      _userService.getUser(_currentUsername).then((user) {
        if (user != null) {
          _isOnline = user.online;
          if (_isOnline) {
            _updatePageTitle();
          }
        }
      });
    });
  }

  void _startListening() {
    _unreadMessagesSub = _messagesRef
        .orderByChild('timestamp')
        .limitToLast(15)
        .onValue
        .listen((event) {
          _updateUnreadCount(event.snapshot);
        });
  }

  void _updateUnreadCount(DataSnapshot snapshot) {
    if (snapshot.value == null || !_isOnline) return;

    final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
    int count = 0;

    data.forEach((key, value) {
      final message = Message.fromMap(
        key.toString(),
        Map<String, dynamic>.from(value as Map),
      );

      if (message.sender != _currentUsername && !message.isSeen) {
        count++;
      }
    });

    _unreadCount = count;
    _updatePageTitle();
  }

  void _updatePageTitle() {
    if (!_isOnline) return;

    if (_unreadCount > 0) {
      html.document.title = '($_unreadCount) Chat App';
    } else {
      html.document.title = 'Chat App';
    }
  }

  Future<void> checkUnreadMessages() async {
    final snapshot = await _messagesRef
        .orderByChild('timestamp')
        .limitToLast(15)
        .get();
    _updateUnreadCount(snapshot);
  }

  void dispose() {
    _unreadMessagesSub?.cancel();
    _onlineUsersSub?.cancel();
    html.document.title = 'Chat App';
  }
}
