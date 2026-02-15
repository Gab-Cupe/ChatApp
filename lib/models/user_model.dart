import 'dart:async';

import 'package:firebase_database/firebase_database.dart';

class User {
  final String username;
  final String password;
  final String displayName;
  final bool online; // Nueva clave
  final bool isWriting;
  final List<String> permissions; // Nueva clave para permisos
  final int lastActive;
  final bool isAdmin; // Nueva clave para administrador
  final String venecia; //Veneciaaaaa Veneciaaaaa Veneciaaaaa

  User copyWith({
    String? username,
    String? password,
    String? displayName,
    bool? online,
    bool? isWriting,
    List<String>? permissions,
    int? lastActive,
    bool? isAdmin,
    String? venecia,
  }) {
    return User(
      username: username ?? this.username,
      password: password ?? this.password,
      displayName: displayName ?? this.displayName,
      online: online ?? this.online,
      isWriting: isWriting ?? this.isWriting,
      permissions: permissions ?? this.permissions,
      lastActive: lastActive ?? this.lastActive,
      isAdmin: isAdmin ?? this.isAdmin,
      venecia: venecia ?? this.venecia,
    );
  }

  User({
    required this.username,
    required this.password,
    required this.displayName,
    required this.venecia,
    required this.lastActive,
    this.isWriting = false, //Veneciaaaaa Veneciaaaaa Veneciaaaaa
    this.online = false, // Por defecto es false
    this.permissions = const [], // Por defecto es una lista vacía
    this.isAdmin = false, // Por defecto no es administrador
  });

  // Método para verificar credenciales
  bool checkCredentials(String inputUsername, String inputPassword) {
    return username == inputUsername && password == inputPassword;
  }

  // Convertir un usuario a un mapa para Firebase
  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'password': password,
      'displayName': displayName,
      'online': online,
      'permissions': permissions,
      'isAdmin': isAdmin,
      'lastActive': lastActive, // Nuevo campo      
      'isWriting': isWriting, // Nueva propiedad

      };
  }

  // Crear un usuario desde un mapa de Firebase
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      venecia: map['venecia'] ?? 'Veneciaaaaa Veneciaaaaa Veneciaaaaa', // Valor por defecto  
      username: map['username'],
      password: map['password'],
      displayName: map['displayName'],
      online: map['online'] ?? false,
      isWriting: map['isWriting'] ?? false, // Nueva propiedad
      permissions: List<String>.from(map['permissions'] ?? []),
      lastActive: map['lastActive'] ?? 0, // Valor por defecto
      isAdmin: map['isAdmin'] ?? false,
    );
  }
}

// Clase para manejar usuarios en Firebase
class UserService {

  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref().child('users');
  final StreamController<bool> _onlineStatusController = StreamController<bool>.broadcast(); // Nuevo

  // Stream público para escuchar cambios
  Stream<bool> get onOnlineStatusChanged => _onlineStatusController.stream;



  Future<void> setUserOnline(String username, bool isOnline) async {
    await _usersRef.child(username).update({'online': isOnline});
      _onlineStatusController.add(isOnline); // Notifica a los listeners

  }
  Future<void> setUserWritingStatus(String username, bool isWriting) async {
    await _usersRef.child(username).update({'isWriting': isWriting});
  }

  Stream<List<User>> getOnlineUsersWithWritingStatus(String currentUsername) {
    return _usersRef.onValue.map((event) {
      final usersMap = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      return usersMap.entries.map((entry) {
        return User.fromMap(Map<String, dynamic>.from(entry.value));
      }).where((user) => 
        user.online && 
        user.username != currentUsername
      ).toList();
    });
  }
  Stream<List<User>> getOnlineUsers(String currentUsername) {
    return _usersRef.onValue.map((event) {
      final usersMap = Map<String, dynamic>.from(event.snapshot.value as Map);
      return usersMap.entries
          .map((entry) => User.fromMap(Map<String, dynamic>.from(entry.value)))
          .where((user) => user.online && user.username != currentUsername)
          .toList();
    });
  }

  Future<User?> getUser(String username) async {
    final snapshot = await _usersRef.child(username).get();
    if (snapshot.exists) {
      return User.fromMap(Map<String, dynamic>.from(snapshot.value as Map));
    }
    return null; // Retorna null si el usuario no existe
  }



  Future<void> updateLastActive(String username) async {
    await _usersRef.child(username).update({
      'lastActive': ServerValue.timestamp,
      'online': true, // También lo marcamos como online
    });
  }

  // Verifica usuarios inactivos (> 60 segundos)
  Stream<List<User>> getActiveUsers(String currentUsername) {
    return _usersRef.onValue.map((event) {
      final usersMap = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      return usersMap.entries.map((entry) {
        final user = User.fromMap(Map<String, dynamic>.from(entry.value));
        // Si lastActive es muy viejo, forzar offline
        final isActive = (DateTime.now().millisecondsSinceEpoch - user.lastActive) < 60000;
        return user.copyWith(online: isActive && user.online);
      }).where((user) => 
        user.online && 
        user.username != currentUsername
      ).toList();
    });
  }
  
}

User usuarioPrueba = User(
  lastActive: 1,
  username: 'bot',
  password: '1234',
  displayName: 'Bot TeATeI',
  venecia: 'Veneciaaaaa Veneciaaaaa Veneciaaaaa',
  online: true,
  permissions: ['chat', 'write'],
  isAdmin: true,
);
