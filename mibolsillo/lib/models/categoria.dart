// lib/models/categoria.dart
class Categoria {
  final int id;
  final String nombre;
  final String tipo; // 'ingreso' | 'gasto'
  final DateTime createdAt;

  Categoria({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.createdAt,
  });

  factory Categoria.fromMap(Map<String, dynamic> m) {
    return Categoria(
      id: m['id'] as int,
      nombre: (m['nombre'] ?? '') as String,
      tipo: (m['tipo'] ?? 'gasto') as String,
      createdAt: DateTime.tryParse(m['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'tipo': tipo,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isValid => nombre.trim().isNotEmpty && (tipo == 'ingreso' || tipo == 'gasto');
}
