import 'dart:async';
import '../models/user_model.dart';

class AuthService {
  final UserService _userService = UserService();

  // Añadir este método en AuthService
  Future<String?> getCurrentUsername() async {
    try {
      // En tu implementación actual, el username se maneja durante el login
      // Podemos almacenarlo durante la autenticación
      return _currentUsername; // Necesitaremos añadir esta variable
    } catch (e) {
      return null;
    }
  }

  // Y añadir esta variable de clase
  String? _currentUsername;

  // Modificar el método authenticate para guardar el username

  Future<User?> authenticate(String username, String password) async {
    try {
      _currentUsername = username; // Guardamos el username

      // Obtener el usuario desde Firebase
      final user = await _userService.getUser(username);

      if (user == null) {
        return null;
      }

      // Verificar credenciales
      if (!user.checkCredentials(username, password)) {
        return null;
      }

      // Marcar al usuario como en línea
      await _userService.setUserOnline(username, true);

      // Actualizar última actividad
      await _userService.updateLastActive(username);

      // Iniciar heartbeat

      return user;
    } catch (e) {
      return null;
    }
  }

  Future<void> logout(String username) async {
    try {
      await _userService.setUserOnline(username, false);
    } catch (e) {
      //Give me give me give me love
    }
  }

  Future<void> handleAppClose(String username) async {
    try {
      await _userService.setUserOnline(username, false);
    } catch (e) {
      //Give me give me give me love
    }
  }

  void dispose() {}
}
