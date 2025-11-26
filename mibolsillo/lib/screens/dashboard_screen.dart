// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../models/transaccion.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<TransactionProvider>(context);

    // Copia de la lista en orden descendente (más reciente primero)
    final List<Transaccion> items = prov.transacciones.reversed.toList();

    // Cálculo rápido de ingresos y gastos (del proveedor en memoria)
    double ingresos = 0;
    double gastos = 0;
    for (var t in prov.transacciones) {
      if (t.tipo == 'ingreso') ingresos += t.monto;
      else gastos += t.monto;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('MiBolsillo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Tarjeta resumen: saldo, ingresos, gastos
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Saldo actual', style: TextStyle(fontSize: 14)),
                        const SizedBox(height: 4),
                        Text('\$${prov.balance.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      children: [
                        const Text('Ingresos', style: TextStyle(fontSize: 12)),
                        const SizedBox(height: 4),
                        Text('\$${ingresos.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green)),
                      ],
                    ),
                    Column(
                      children: [
                        const Text('Gastos', style: TextStyle(fontSize: 12)),
                        const SizedBox(height: 4),
                        Text('\$${gastos.toStringAsFixed(2)}', style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Nueva transacción'),
                  onPressed: () => Navigator.pushNamed(context, '/add'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.list),
                  label: const Text('Historial'),
                  onPressed: () => Navigator.pushNamed(context, '/history'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Reportes'),
                  onPressed: () => Navigator.pushNamed(context, '/reports'),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Últimas transacciones', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),

            // Contenido principal: loader, mensaje vacío o lista con pull-to-refresh
            Expanded(
              child: prov.loading
                  ? const Center(child: CircularProgressIndicator())
                  : items.isEmpty
                  ? RefreshIndicator(
                onRefresh: () async {
                  await prov.fetchTransacciones();
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 60),
                    Center(child: Text('No hay transacciones aún.\nPulsa + para crear una.', textAlign: TextAlign.center)),
                  ],
                ),
              )
                  : RefreshIndicator(
                onRefresh: () async {
                  await prov.fetchTransacciones();
                },
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final tx = items[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: tx.tipo == 'ingreso' ? Colors.green[200] : Colors.red[200],
                        child: Text(tx.tipo == 'ingreso' ? '+' : '-'),
                      ),
                      title: Text('\$${tx.monto.toStringAsFixed(2)}'),
                      subtitle: Text(tx.nota ?? ''),
                      trailing: Text(
                        '${tx.fecha.year}-${tx.fecha.month.toString().padLeft(2, '0')}-${tx.fecha.day.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onTap: () {
                        // futuro: navegar a detalle/editar
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
