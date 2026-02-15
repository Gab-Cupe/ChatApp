import 'dart:async';

import 'package:chatapp/models/user_model.dart';

class TypingDetector {
  Timer? _typingTimer;
  bool _isTyping = false;

  void userStartedTyping(String username, UserService userService) {
    if (!_isTyping) {
      _isTyping = true;
      userService.setUserWritingStatus(username, true);
    }
    _resetTypingTimer(username, userService);
  }

  void userStoppedTyping(String username, UserService userService) {
    if (_isTyping) {
      _isTyping = false;
      userService.setUserWritingStatus(username, false);
      _typingTimer?.cancel();
    }
  }

  void _resetTypingTimer(String username, UserService userService) {
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      userService.setUserWritingStatus(username, false);
      _isTyping = false;
    });
  }

  void dispose() {
    _typingTimer?.cancel();
  }
}
