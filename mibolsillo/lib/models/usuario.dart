// lib/models/usuario.dart
class Usuario {
  final int id;
  final String nombre;
  final String? email;
  final DateTime createdAt;

  Usuario({required this.id, required this.nombre, this.email, required this.createdAt});

  factory Usuario.fromMap(Map<String, dynamic> m) {
    return Usuario(
      id: m['id'] as int,
      nombre: (m['nombre'] ?? '') as String,
      email: m['email'] as String?,
      createdAt: DateTime.tryParse(m['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'nombre': nombre, 'email': email, 'created_at': createdAt.toIso8601String()};
  }
}
