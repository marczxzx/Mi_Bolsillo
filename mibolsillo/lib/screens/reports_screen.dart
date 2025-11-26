import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<TransactionProvider>(context);
    // ejemplo: totales del mes actual
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);
    final monthItems = prov.filterLocal(desde: monthStart, hasta: monthEnd);
    double ingresos = 0, gastos = 0;
    for (var t in monthItems) {
      if (t.tipo == 'ingreso') ingresos += t.monto;
      else gastos += t.monto;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Reportes')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(child: ListTile(title: const Text('Resumen mensual'), subtitle: Text('${DateFormat.yMMMM().format(now)}'))),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(children: [const Text('Ingresos'), Text('\$${ingresos.toStringAsFixed(2)}')]),
                Column(children: [const Text('Gastos'), Text('\$${gastos.toStringAsFixed(2)}')]),
                Column(children: [const Text('Balance'), Text('\$${(ingresos - gastos).toStringAsFixed(2)}')]),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Exportar PDF (próximo paso)'),
              onPressed: () {
                // aquí llamaremos al módulo de generación de PDF más adelante
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exportar PDF: pendiente (siguiente paso)')));
              },
            ),
          ],
        ),
      ),
    );
  }
}
