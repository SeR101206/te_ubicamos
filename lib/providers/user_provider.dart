import 'package:flutter/material.dart';
import '../models/user_model.dart'; // ajusta la ruta

class UserProvider extends ChangeNotifier {
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;

  bool get isLoggedIn => _currentUser != null;

  // Método para iniciar sesión / cargar usuario
  void setUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }

  // Método para actualizar solo algunos datos (ej: después de editar perfil)
  void updateUser({
    String? nombre,
    String? fotoUrl,
    List<String>? trabajos,
  }) {
    if (_currentUser == null) return;

    _currentUser = _currentUser!.copyWith(
      nombre: nombre,
      fotoUrl: fotoUrl,
      trabajos: trabajos,
    );
    notifyListeners();
  }

  // Cerrar sesión
  void logout() {
    _currentUser = null;
    notifyListeners();
    // Aquí también podrías limpiar SharedPreferences, Firebase signOut, etc.
  }

  // Ejemplo: agregar un trabajo nuevo
  void addTrabajo(String trabajoId) {
    if (_currentUser == null) return;

    final nuevosTrabajos = [..._currentUser!.trabajos, trabajoId];
    _currentUser = _currentUser!.copyWith(trabajos: nuevosTrabajos);
    notifyListeners();
  }
}