// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';

class EmojiPickerWidget extends StatefulWidget {
  final Function(String) onEmojiSelected;

  const EmojiPickerWidget({super.key, required this.onEmojiSelected});

  @override
  State<EmojiPickerWidget> createState() => _EmojiPickerWidgetState();
}

class _EmojiPickerWidgetState extends State<EmojiPickerWidget> {
  final List<String> _loadedEmojis = [];
  final ScrollController _scrollController = ScrollController();
  Timer? _repeatTimer;
  double _currentOffset = 10.0;
  bool _isKeyDown = false;
  final DatabaseReference _emojiRef = FirebaseDatabase.instance.ref().child('emojis');

  @override
  void initState() {
    super.initState();
    _loadEmojisFromFirebase();
    _enableScrollWithKeyboard();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _repeatTimer?.cancel();
    RawKeyboard.instance.removeListener(_handleKeyEvent);
    super.dispose();
  }

Future<void> _loadEmojisFromFirebase() async {
  try {
    final snapshot = await _emojiRef.get().timeout(const Duration(seconds: 5));
    if (snapshot.exists) {
      final data = snapshot.value;
      final allEmojis = <String>[];

      if (data is Map<dynamic, dynamic>) {
        data.forEach((category, categoryData) {
          if (categoryData is Map && categoryData['items'] != null) {
            final items = categoryData['items'];

            if (items is List) {
              allEmojis.addAll(items.whereType<String>());
            } else if (items is Map) {
              items.forEach((_, emoji) {
                if (emoji is String) {
                  allEmojis.add(emoji);
                }
              });
            }
          }
        });
      }

      if (mounted) {
        setState(() {
          _loadedEmojis.addAll(allEmojis);
        });
      }
    } else {
      debugPrint("No emojis found in Firebase.");
    }
  } on TimeoutException catch (_) {
    debugPrint("Timeout: Firebase did not respond in time.");
  } catch (e) {
    debugPrint("Error loading emojis: $e");
  }
}


  void _scroll(int direction) {
    if (!mounted || !_scrollController.hasClients) return;
    
    final target = _scrollController.offset + direction * _currentOffset;
    _scrollController.animateTo(
      target.clamp(
        _scrollController.position.minScrollExtent,
        _scrollController.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 100),
      curve: Curves.linear,
    );
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (!mounted) return;

    if (event is RawKeyDownEvent && !_isKeyDown) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown || 
          event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _isKeyDown = true;
        int direction = event.logicalKey == LogicalKeyboardKey.arrowDown ? 1 : -1;
        _currentOffset = 10.0;

        _scroll(direction);

        _repeatTimer?.cancel();
        _repeatTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
          if (!mounted) return;
          _scroll(direction);
          _currentOffset += 15;
          if (_currentOffset > 300) _currentOffset = 300;
        });
      }
    } else if (event is RawKeyUpEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown || 
          event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _repeatTimer?.cancel();
        _repeatTimer = null;
        _currentOffset = 10.0;
        _isKeyDown = false;
      }
    }
  }

  void _enableScrollWithKeyboard() {
    if (mounted) {
      RawKeyboard.instance.addListener(_handleKeyEvent);
    }
  }

@override
Widget build(BuildContext context) {
  return Container(
    height: 250,
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(12),
    ),
    child: _loadedEmojis.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : Center(  // <-- Envolvemos en Center para que el GridView no ocupe todo el ancho
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),  // <-- Máximo 700px
              child: GridView.builder(
                controller: _scrollController,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  childAspectRatio: 1.0,
                ),
                padding: const EdgeInsets.all(12),
                itemCount: _loadedEmojis.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => widget.onEmojiSelected(_loadedEmojis[index]),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      child: Center(
                        child: Text(
                          _loadedEmojis[index], 
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
  );
}
}