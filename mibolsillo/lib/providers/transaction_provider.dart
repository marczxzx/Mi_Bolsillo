// lib/providers/transaction_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/transaccion.dart';
import '../models/categoria.dart';

class TransactionProvider with ChangeNotifier {
  // Lee url y key desde .env (ya lo cargas en main.dart)
  final String _supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final String _anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  // Endpoints REST
  String get _baseRest => '$_supabaseUrl/rest/v1';

  // Datos en memoria
  List<Categoria> _categorias = [];
  List<Transaccion> _transacciones = [];

  bool loading = false;

  // Usuario por defecto (temporal)
  final int _defaultUsuarioId = 1;

  List<Categoria> get categorias => List.unmodifiable(_categorias);
  List<Transaccion> get transacciones => List.unmodifiable(_transacciones);

  // Balance calculado (ingresos - gastos)
  double get balance {
    double ingresos = 0;
    double gastos = 0;
    for (var t in _transacciones) {
      if (t.tipo == 'ingreso') ingresos += t.monto;
      else gastos += t.monto;
    }
    return ingresos - gastos;
  }

  TransactionProvider() {
    _init();
  }

  Map<String, String> get _headers => {
    'apikey': _anonKey,
    'Authorization': 'Bearer $_anonKey',
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<void> _init() async {
    loading = true;
    notifyListeners();
    await Future.wait([fetchCategorias(), fetchTransacciones()]);
    loading = false;
    notifyListeners();
  }

  // --------------------
  // Categorias (REST)
  // --------------------
  Future<void> fetchCategorias() async {
    if (_supabaseUrl.isEmpty || _anonKey.isEmpty) {
      debugPrint('fetchCategorias: claves Supabase faltantes');
      return;
    }

    final uri = Uri.parse('$_baseRest/categorias?usuario_id=eq.$_defaultUsuarioId&order=nombre.asc');
    try {
      final resp = await http.get(uri, headers: _headers);
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final List<dynamic> data = json.decode(resp.body);
        _categorias = data.map((e) => Categoria.fromMap(Map<String, dynamic>.from(e))).toList();
        notifyListeners();
      } else {
        debugPrint('fetchCategorias HTTP ${resp.statusCode}: ${resp.body}');
      }
    } catch (e) {
      debugPrint('fetchCategorias error: $e');
    }
  }

  Future<Categoria?> createCategoria(String nombre, String tipo) async {
    final uri = Uri.parse('$_baseRest/categorias');
    final body = json.encode({
      'usuario_id': _defaultUsuarioId,
      'nombre': nombre,
      'tipo': tipo,
      // created_at se genera por Postgres si tiene default ahora()
    });

    try {
      final resp = await http.post(uri, headers: {
        ..._headers,
        'Prefer': 'return=representation',
      }, body: body);

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final List<dynamic> data = json.decode(resp.body);
        if (data.isNotEmpty) {
          final cat = Categoria.fromMap(Map<String, dynamic>.from(data.first));
          _categorias.add(cat);
          notifyListeners();
          return cat;
        }
      } else {
        debugPrint('createCategoria HTTP ${resp.statusCode}: ${resp.body}');
      }
    } catch (e) {
      debugPrint('createCategoria error: $e');
    }
    return null;
  }

  // --------------------
  // Transacciones (REST)
  // --------------------
  Future<void> fetchTransacciones({DateTime? desde, DateTime? hasta, int? categoriaId}) async {
    if (_supabaseUrl.isEmpty || _anonKey.isEmpty) {
      debugPrint('fetchTransacciones: claves Supabase faltantes');
      return;
    }

    // Construye query string
    final params = <String>[];
    params.add('usuario_id=eq.$_defaultUsuarioId');
    if (desde != null) params.add('fecha=gte.${_dateOnly(desde)}');
    if (hasta != null) params.add('fecha=lte.${_dateOnly(hasta)}');
    if (categoriaId != null) params.add('categoria_id=eq.$categoriaId');
    params.add('order=fecha.desc');

    final uri = Uri.parse('$_baseRest/transacciones?${params.join('&')}');

    try {
      final resp = await http.get(uri, headers: _headers);
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final List<dynamic> data = json.decode(resp.body);
        _transacciones = data.map((e) => Transaccion.fromMap(Map<String, dynamic>.from(e))).toList();
        notifyListeners();
      } else {
        debugPrint('fetchTransacciones HTTP ${resp.statusCode}: ${resp.body}');
      }
    } catch (e) {
      debugPrint('fetchTransacciones error: $e');
    }
  }

  Future<bool> addTransaction(Transaccion tx) async {
    if (!tx.isValid) return false;
    if (_supabaseUrl.isEmpty || _anonKey.isEmpty) return false;

    final uri = Uri.parse('$_baseRest/transacciones');
    final body = json.encode({
      'usuario_id': _defaultUsuarioId,
      'categoria_id': tx.categoriaId,
      'tipo': tx.tipo,
      'monto': tx.monto,
      'fecha': _dateOnly(tx.fecha),
      'nota': tx.nota,
    });

    try {
      final resp = await http.post(uri, headers: {
        ..._headers,
        'Prefer': 'return=representation',
      }, body: body);

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final List<dynamic> data = json.decode(resp.body);
        if (data.isNotEmpty) {
          final created = Transaccion.fromMap(Map<String, dynamic>.from(data.first));
          _transacciones.insert(0, created);
          notifyListeners();
          return true;
        }
      } else {
        debugPrint('addTransaction HTTP ${resp.statusCode}: ${resp.body}');
      }
    } catch (e) {
      debugPrint('addTransaction error: $e');
    }
    return false;
  }

  Future<bool> updateTransaction(Transaccion tx) async {
    if (_supabaseUrl.isEmpty || _anonKey.isEmpty) return false;

    final uri = Uri.parse('$_baseRest/transacciones?id=eq.${tx.id}');
    final body = json.encode({
      'categoria_id': tx.categoriaId,
      'tipo': tx.tipo,
      'monto': tx.monto,
      'fecha': _dateOnly(tx.fecha),
      'nota': tx.nota,
    });

    try {
      final resp = await http.patch(uri, headers: {
        ..._headers,
        'Prefer': 'return=representation',
      }, body: body);

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final List<dynamic> data = json.decode(resp.body);
        if (data.isNotEmpty) {
          final updated = Transaccion.fromMap(Map<String, dynamic>.from(data.first));
          final idx = _transacciones.indexWhere((t) => t.id == updated.id);
          if (idx >= 0) {
            _transacciones[idx] = updated;
            notifyListeners();
          }
          return true;
        }
      } else {
        debugPrint('updateTransaction HTTP ${resp.statusCode}: ${resp.body}');
      }
    } catch (e) {
      debugPrint('updateTransaction error: $e');
    }
    return false;
  }

  Future<bool> deleteTransaction(int id) async {
    if (_supabaseUrl.isEmpty || _anonKey.isEmpty) return false;

    final uri = Uri.parse('$_baseRest/transacciones?id=eq.$id');
    try {
      final resp = await http.delete(uri, headers: _headers);
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        _transacciones.removeWhere((t) => t.id == id);
        notifyListeners();
        return true;
      } else {
        debugPrint('deleteTransaction HTTP ${resp.statusCode}: ${resp.body}');
      }
    } catch (e) {
      debugPrint('deleteTransaction error: $e');
    }
    return false;
  }

  // Helper local filter (UI usa esto en reports)
  List<Transaccion> filterLocal({DateTime? desde, DateTime? hasta, int? categoriaId, String? query}) {
    return _transacciones.where((t) {
      if (desde != null && t.fecha.isBefore(desde)) return false;
      if (hasta != null && t.fecha.isAfter(hasta)) return false;
      if (categoriaId != null && t.categoriaId != categoriaId) return false;
      if (query != null && query.isNotEmpty && !(t.nota ?? '').toLowerCase().contains(query.toLowerCase())) return false;
      return true;
    }).toList();
  }

  // Util
  String _dateOnly(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
