import 'package:flutter_test/flutter_test.dart';
import 'package:abi_frotend_nd/main.dart';

void main() {
  testWidgets('CraftHub arranca sin errores', (WidgetTester tester) async {
    // Construye la app completa
    await tester.pumpWidget(const CraftHubApp());
    await tester.pumpAndSettle();

    // Verifica que la pantalla de inicio carga
    expect(find.text('CRAFTHUB'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Continuar con Google'), findsOneWidget);
    expect(find.text('¿No tienes una cuenta?'), findsOneWidget);
  });
}