// test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mibolsillo/main.dart';

void main() {
  testWidgets('App carga y muestra texto', (WidgetTester tester) async {
    await tester.pumpWidget(const AppRoot());

    // Verifica que se muestre el texto inicial
    expect(find.text('MiBolsillo funcionando'), findsOneWidget);
  });
}
