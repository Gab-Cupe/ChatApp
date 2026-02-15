// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

void enableScrollWithKeyboard(ScrollController controller, {double baseOffset = 10.0}) {
  Timer? repeatTimer;
  double currentOffset = baseOffset;
  bool isKeyDown = false;

  void scroll(int direction) {
    final target = controller.offset + direction * currentOffset;
    controller.animateTo(
      target.clamp(
        controller.position.minScrollExtent,
        controller.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 100),
      curve: Curves.linear,
    );
  }

  RawKeyboard.instance.addListener((RawKeyEvent event) {
    if (event is RawKeyDownEvent && !isKeyDown) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown || event.logicalKey == LogicalKeyboardKey.arrowUp) {
        isKeyDown = true;
        int direction = event.logicalKey == LogicalKeyboardKey.arrowDown ? 1 : -1;
        currentOffset = baseOffset;

        scroll(direction); // First scroll immediately

        repeatTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
          scroll(direction);
          currentOffset += 15; // accelerate scrolling
          if (currentOffset > 300) currentOffset = 300; // cap the speed
        });
      }
    } else if (event is RawKeyUpEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown || event.logicalKey == LogicalKeyboardKey.arrowUp) {
        repeatTimer?.cancel();
        repeatTimer = null;
        currentOffset = baseOffset;
        isKeyDown = false;
      }
    }
  });
}
