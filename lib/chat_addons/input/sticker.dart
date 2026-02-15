import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class StickerPickerWidget extends StatefulWidget {
  final Function(String) onStickerSelected;

  const StickerPickerWidget({super.key, required this.onStickerSelected});

  @override
  State<StickerPickerWidget> createState() => _StickerPickerWidgetState();
}

class _StickerPickerWidgetState extends State<StickerPickerWidget> {
  final DatabaseReference _stickerRef = FirebaseDatabase.instance.ref().child(
    'stickers',
  );
  final List<String> _allStickers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStickersFromFirebase();
  }

  Future<void> _loadStickersFromFirebase() async {
    try {
      final snapshot = await _stickerRef.get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final stickers = <String>[];

        data.forEach((categoryKey, categoryData) {
          if (categoryData is Map && categoryData['items'] is List) {
            stickers.addAll(
              (categoryData['items'] as List).whereType<String>(),
            );
          }
        });

        if (mounted) {
          setState(() {
            _allStickers.addAll(stickers);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading stickers: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _isGif(String url) {
    return url.toLowerCase().endsWith(".gif");
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              childAspectRatio: 1,
            ),
            itemCount: _allStickers.length,
            itemBuilder: (context, index) {
              final url = _allStickers[index];
              return GestureDetector(
                onTap: () => widget.onStickerSelected(url),
                child: Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          url,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.error),
                        ),
                      ),
                    ),
                    if (_isGif(url))
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'GIF',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
  }
}
