class Message {
  final String id;
  final String sender;
  final String text;
  final DateTime timestamp;
  final bool edited;
  final String? replyTo;
  final String? imageUrl;
  final String? audioUrl;
  final bool isSeen;
  final List<String> reactions;

  Message({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
    this.edited = false,
    this.replyTo,
    this.imageUrl,
    this.audioUrl,
    this.isSeen = false,
    this.reactions = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'sender': sender,
      'text': text,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'edited': edited,
      'replyTo': replyTo,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'isSeen': isSeen,
      'reactions': reactions,
    };
  }

  factory Message.fromMap(String id, Map<String, dynamic> map) {
    return Message(
      id: id,
      sender: map['sender'],
      text: map['text'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      edited: map['edited'] ?? false,
      replyTo: map['replyTo'],
      imageUrl: map['imageUrl'],
      audioUrl: map['audioUrl'],
      isSeen: map['isSeen'] ?? false,
      reactions: List<String>.from(map['reactions'] ?? []),
    );
  }
}