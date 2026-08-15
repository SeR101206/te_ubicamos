class UserModel {
  final String uid;           // ID único (de Firebase, Supabase, etc.)
  final String nombre;
  final String email;
  final String? fotoUrl;
  final List<String> trabajos;   // o List<TrabajoModel> si tienes un modelo más completo

  UserModel({
    required this.uid,
    required this.nombre,
    required this.email,
    this.fotoUrl,
    this.trabajos = const [],
  });

  // Método útil para copiar con cambios (inmutable)
  UserModel copyWith({
    String? uid,
    String? nombre,
    String? email,
    String? fotoUrl,
    List<String>? trabajos,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      trabajos: trabajos ?? this.trabajos,
    );
  }
}