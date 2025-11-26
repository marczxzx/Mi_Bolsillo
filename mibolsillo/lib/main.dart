// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

import 'providers/transaction_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/add_transaction_screen.dart';
import 'screens/history_screen.dart';
import 'screens/reports_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar .env (lo declaraste como asset en pubspec.yaml)
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('Advertencia: no se pudo cargar .env: $e');
  }

  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  if (supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty) {
    try {
      await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
      debugPrint('Supabase inicializado correctamente');
    } catch (e) {
      debugPrint('Error inicializando Supabase: $e');
    }
  } else {
    debugPrint('Claves Supabase no encontradas en .env — continuando sin inicializar Supabase');
  }

  runApp(const AppRoot());
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TransactionProvider>(
      create: (_) => TransactionProvider(),
      child: MaterialApp(
        title: 'MiBolsillo',
        initialRoute: '/',
        debugShowCheckedModeBanner: false,
        routes: {
          '/': (ctx) => DashboardScreen(),
          '/add': (ctx) => AddTransactionScreen(),
          '/history': (ctx) => HistoryScreen(),
          '/reports': (ctx) => ReportsScreen(),
        },
      ),
    );
  }
}
