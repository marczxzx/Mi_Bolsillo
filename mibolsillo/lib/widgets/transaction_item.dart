import 'package:flutter/material.dart';
import '../models/transaccion.dart';
import 'package:intl/intl.dart';

class TransactionItem extends StatelessWidget {
  final Transaccion tx;
  final VoidCallback? onDelete;

  const TransactionItem({super.key, required this.tx, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    return ListTile(
      leading: CircleAvatar(child: Text(tx.tipo == 'ingreso' ? '+' : '-')),
      title: Text(fmt.format(tx.monto)),
      subtitle: Text('${DateFormat.yMMMd().format(tx.fecha)} · ${tx.nota ?? ''}'),
      trailing: IconButton(icon: const Icon(Icons.delete), onPressed: onDelete),
    );
  }
}
