import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../models/message_model.dart';

class DatabaseService {
  final DatabaseReference _messagesRef =
      FirebaseDatabase.instance.ref().child('messages');
  
  // Controladores para streams broadcast
  final StreamController<DatabaseEvent> _newMessageController = 
      StreamController<DatabaseEvent>.broadcast();
  final StreamController<DatabaseEvent> _editMessageController = 
      StreamController<DatabaseEvent>.broadcast();
  final StreamController<DatabaseEvent> _deleteMessageController = 
      StreamController<DatabaseEvent>.broadcast();

  // Suscripciones internas
  StreamSubscription<DatabaseEvent>? _internalNewMessageSub;
  StreamSubscription<DatabaseEvent>? _internalEditMessageSub;
  StreamSubscription<DatabaseEvent>? _internalDeleteMessageSub;

  DatabaseService() {
    // Configurar los listeners internos una sola vez
    _setupInternalListeners();
  }

  void _setupInternalListeners() {
    // Listener para nuevos mensajes
    _internalNewMessageSub = _messagesRef
        .orderByChild('timestamp')
        .limitToLast(1)
        .onChildAdded
        .listen((event) {
          if (!_newMessageController.isClosed) {
            _newMessageController.add(event);
          }
        });

    // Listener para ediciones
    _internalEditMessageSub = _messagesRef
        .onChildChanged
        .listen((event) {
          if (!_editMessageController.isClosed) {
            _editMessageController.add(event);
          }
        });

    // Listener para eliminaciones
    _internalDeleteMessageSub = _messagesRef
        .onChildRemoved
        .listen((event) {
          if (!_deleteMessageController.isClosed) {
            _deleteMessageController.add(event);
          }
        });
  }

  // Streams públicos como broadcast
  Stream<DatabaseEvent> get newMessageStream => _newMessageController.stream;
  Stream<DatabaseEvent> get messageEditStream => _editMessageController.stream;
  Stream<DatabaseEvent> get messageDeleteStream => _deleteMessageController.stream;

  // Obtener los últimos N mensajes
  Future<List<Message>> getLastMessages({int limit = 30}) async {
    final snapshot = await _messagesRef
        .orderByChild('timestamp')
        .limitToLast(limit)
        .get();

    return _snapshotToMessages(snapshot);
  }

  // Cargar más mensajes anteriores a cierto timestamp
  Future<List<Message>> loadMoreMessages(int startBefore, {int limit = 30}) async {
    final snapshot = await _messagesRef
        .orderByChild('timestamp')
        .endAt(startBefore - 1)
        .limitToLast(limit)
        .get();

    return _snapshotToMessages(snapshot);
  }

  List<Message> _snapshotToMessages(DataSnapshot snapshot) {
    final List<Message> messages = [];
    if (snapshot.value != null) {
      final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
      data.forEach((key, value) {
        messages.add(Message.fromMap(
          key.toString(),
          Map<String, dynamic>.from(value as Map),
        ));
      });
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }
    return messages;
  }

  Future<void> sendMessage(
    String sender,
    String text, {
    String? replyTo,
    String? imageUrl,
  }) async {
    final newMessageRef = _messagesRef.push();
    await newMessageRef.set({
      'sender': sender,
      'text': text,
      'timestamp': ServerValue.timestamp,
      'edited': false,
      'replyTo': replyTo,
      'imageUrl': imageUrl,
      'isSeen': false,
      'reactions': [],
    });
  }

  Future<void> editMessage(String messageId, String newText) async {
    await _messagesRef.child(messageId).update({
      'text': newText,
      'edited': true,
    });
  }

  Future<void> deleteMessage(String messageId) async {
    await _messagesRef.child(messageId).remove();
  }

  Future<Message?> getMessage(String messageId) async {
    final snapshot = await _messagesRef.child(messageId).get();
    if (snapshot.exists) {
      return Message.fromMap(
        messageId,
        Map<String, dynamic>.from(snapshot.value as Map),
      );
    }
    return null;
  }

  Future<void> markMessageAsSeen(String messageId, String recipientUsername) async {
    final userRef = FirebaseDatabase.instance.ref().child('users').child(recipientUsername);
    final snapshot = await userRef.child('online').get();

    if (snapshot.exists && snapshot.value == true) {
      await _messagesRef.child(messageId).update({
        'isSeen': true,
      });
    }
  }

  Future<void> updateMessageReactions(String messageId, List<String> reactions) async {
    await _messagesRef.child(messageId).update({
      'reactions': reactions,
    });
  }

  void dispose() {
    _internalNewMessageSub?.cancel();
    _internalEditMessageSub?.cancel();
    _internalDeleteMessageSub?.cancel();
    
    _newMessageController.close();
    _editMessageController.close();
    _deleteMessageController.close();
    
    _internalNewMessageSub = null;
    _internalEditMessageSub = null;
    _internalDeleteMessageSub = null;
  }
}