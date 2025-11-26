// lib/screens/add_transaction_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/transaccion.dart';
import '../providers/transaction_provider.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  String _tipo = 'gasto';
  double? _monto;
  DateTime _fecha = DateTime.now();
  String? _nota;
  int? _categoriaId;
  bool _loading = false;
  bool _loadingCategorias = false;

  @override
  void initState() {
    super.initState();
    // Si no hay categorías cargadas, solicitamos al provider que las traiga.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prov = Provider.of<TransactionProvider>(context, listen: false);
      if (prov.categorias.isEmpty) {
        setState(() => _loadingCategorias = true);
        await prov.fetchCategorias();
        setState(() => _loadingCategorias = false);
      }
    });
  }

  Future<void> _selectDate() async {
    final d = await showDatePicker(context: context, initialDate: _fecha, firstDate: DateTime(2000), lastDate: DateTime(2100));
    if (d != null) setState(() => _fecha = d);
  }

  Future<void> _showCreateCategoryDialog() async {
    final prov = Provider.of<TransactionProvider>(context, listen: false);
    final _catFormKey = GlobalKey<FormState>();
    String nombre = '';
    String tipo = 'gasto';

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Crear categoría'),
        content: Form(
          key: _catFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa un nombre' : null,
                onSaved: (v) => nombre = v!.trim(),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: tipo,
                items: const [
                  DropdownMenuItem(value: 'gasto', child: Text('Gasto')),
                  DropdownMenuItem(value: 'ingreso', child: Text('Ingreso')),
                ],
                onChanged: (v) => tipo = v ?? 'gasto',
                decoration: const InputDecoration(labelText: 'Tipo'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              if (!_catFormKey.currentState!.validate()) return;
              _catFormKey.currentState!.save();
              // Crear categoría en la BD (provider tiene createCategoria)
              final cat = await prov.createCategoria(nombre, tipo);
              if (cat != null) {
                // seleccionamos la nueva categoría
                setState(() => _categoriaId = cat.id);
                // cerramos dialog con success
                Navigator.of(ctx).pop(true);
              } else {
                // mostrar error
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error creando categoría')));
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );

    if (created == true) {
      // ya quedó seleccionada por setState dentro del dialog
      // refrescamos UI por si acaso
      setState(() {});
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final prov = Provider.of<TransactionProvider>(context, listen: false);

    final newTx = Transaccion(
      id: 0,
      tipo: _tipo,
      monto: _monto!,
      fecha: _fecha,
      categoriaId: _categoriaId,
      nota: _nota,
      createdAt: DateTime.now(),
    );

    setState(() => _loading = true);
    final ok = await prov.addTransaction(newTx);
    setState(() => _loading = false);

    if (ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transacción guardada')));
      Navigator.pop(context);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error guardando transacción')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<TransactionProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar transacción')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _tipo,
                items: const [
                  DropdownMenuItem(value: 'gasto', child: Text('Gasto')),
                  DropdownMenuItem(value: 'ingreso', child: Text('Ingreso')),
                ],
                onChanged: (v) => setState(() => _tipo = v ?? 'gasto'),
                decoration: const InputDecoration(labelText: 'Tipo'),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Monto', prefixText: '\$'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Ingresa el monto';
                  final parsed = double.tryParse(v.replaceAll(',', '.'));
                  if (parsed == null || parsed <= 0) return 'Monto inválido';
                  return null;
                },
                onSaved: (v) => _monto = double.parse(v!.replaceAll(',', '.')),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('Fecha: ${DateFormat.yMMMd().format(_fecha)}'),
                  const SizedBox(width: 12),
                  TextButton(onPressed: _selectDate, child: const Text('Cambiar')),
                ],
              ),

              // Categoría: si se están cargando, mostramos loader
              if (_loadingCategorias) const CircularProgressIndicator(),

              // Si no hay categorías, mostramos botón para crear una
              if (!_loadingCategorias && prov.categorias.isEmpty)
                Column(
                  children: [
                    const SizedBox(height: 8),
                    const Text('No hay categorías.'),
                    TextButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Crear categoría'),
                      onPressed: _showCreateCategoryDialog,
                    ),
                  ],
                )
              else
              // Dropdown con categorías (si existen)
                DropdownButtonFormField<int>(
                  value: _categoriaId,
                  items: prov.categorias.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nombre))).toList(),
                  onChanged: (v) => setState(() => _categoriaId = v),
                  decoration: const InputDecoration(labelText: 'Categoría (opcional)'),
                ),

              TextFormField(
                decoration: const InputDecoration(labelText: 'Nota'),
                onSaved: (v) => _nota = v,
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _submit, child: const Text('Guardar')),
            ],
          ),
        ),
      ),
    );
  }
}
