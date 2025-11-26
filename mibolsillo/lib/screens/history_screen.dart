// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/transaction_item.dart';
import 'edit_transaction_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<TransactionProvider>(context);
    final items = prov.filterLocal(query: _query);

    return Scaffold(
      appBar: AppBar(title: const Text('Historial')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Buscar por nota...'),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? RefreshIndicator(
              onRefresh: () async => await prov.fetchTransacciones(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 60),
                  Center(child: Text('No hay transacciones. Pulsa + para crear.')),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: () async => await prov.fetchTransacciones(),
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (ctx, i) {
                  final tx = items.reversed.toList()[i];
                  return GestureDetector(
                    onTap: () async {
                      // Navegar a pantalla de edición
                      await Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => EditTransactionScreen(tx: tx),
                      ));
                      // Al volver refrescamos lista
                      await prov.fetchTransacciones();
                    },
                    child: TransactionItem(
                      tx: tx,
                      onDelete: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Confirmar'),
                            content: const Text('¿Eliminar esta transacción?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
                              TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Eliminar')),
                            ],
                          ),
                        );
                        if (confirm != true) return;

                        final ok = await Provider.of<TransactionProvider>(context, listen: false).deleteTransaction(tx.id);
                        if (ok) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transacción eliminada')));
                        } else {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al eliminar')));
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
