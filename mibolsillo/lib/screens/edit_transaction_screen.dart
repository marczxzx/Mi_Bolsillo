// lib/screens/edit_transaction_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/transaccion.dart';
import '../providers/transaction_provider.dart';

class EditTransactionScreen extends StatefulWidget {
  final Transaccion tx;
  const EditTransactionScreen({super.key, required this.tx});

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _tipo;
  late double _monto;
  late DateTime _fecha;
  String? _nota;
  int? _categoriaId;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tipo = widget.tx.tipo;
    _monto = widget.tx.monto;
    _fecha = widget.tx.fecha;
    _nota = widget.tx.nota;
    _categoriaId = widget.tx.categoriaId;
  }

  Future<void> _selectDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _fecha = d);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final prov = Provider.of<TransactionProvider>(context, listen: false);

    final updatedTx = Transaccion(
      id: widget.tx.id,
      tipo: _tipo,
      monto: _monto,
      fecha: _fecha,
      categoriaId: _categoriaId,
      nota: _nota,
      createdAt: widget.tx.createdAt,
    );

    setState(() => _loading = true);

    final ok = await prov.updateTransaction(updatedTx);

    if (!mounted) return;
    setState(() => _loading = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transacción actualizada')));
      Navigator.of(context).pop(); // vuelve al historial/dashboard
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al actualizar')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<TransactionProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Editar transacción')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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
                initialValue: _monto.toStringAsFixed(2),
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
              DropdownButtonFormField<int>(
                value: _categoriaId,
                items: prov.categorias
                    .map((c) => DropdownMenuItem(value: c.id, child: Text(c.nombre)))
                    .toList(),
                onChanged: (v) => setState(() => _categoriaId = v),
                decoration: const InputDecoration(labelText: 'Categoría (opcional)'),
              ),
              TextFormField(
                initialValue: _nota ?? '',
                decoration: const InputDecoration(labelText: 'Nota'),
                onSaved: (v) => _nota = v,
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _submit, child: const Text('Guardar cambios')),
            ],
          ),
        ),
      ),
    );
  }
}
