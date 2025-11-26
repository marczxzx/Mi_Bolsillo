// lib/models/transaccion.dart
class Transaccion {
  final int id;
  final String tipo; // 'ingreso' | 'gasto'
  final double monto;
  final DateTime fecha;
  final int? categoriaId;
  final String? nota;
  final DateTime createdAt;

  Transaccion({
    required this.id,
    required this.tipo,
    required this.monto,
    required this.fecha,
    this.categoriaId,
    this.nota,
    required this.createdAt,
  });

  factory Transaccion.fromMap(Map<String, dynamic> m) {
    return Transaccion(
      id: m['id'] is int ? m['id'] as int : int.parse(m['id'].toString()),
      tipo: (m['tipo'] ?? '') as String,
      monto: (m['monto'] is double) ? m['monto'] as double : double.parse(m['monto'].toString()),
      fecha: DateTime.tryParse(m['fecha']?.toString() ?? '') ?? DateTime.now(),
      categoriaId: m['categoria_id'] == null ? null : (m['categoria_id'] as int),
      nota: m['nota'] as String?,
      createdAt: DateTime.tryParse(m['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap({required int usuarioId}) {
    return {
      'usuario_id': usuarioId,
      'categoria_id': categoriaId,
      'tipo': tipo,
      'monto': monto,
      'fecha': fecha.toIso8601String().substring(0, 10), // date only
      'nota': nota,
    };
  }

  bool get isValid => monto > 0 && (tipo == 'ingreso' || tipo == 'gasto');
}

