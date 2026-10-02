import 'package:catacroket/core/models/mesa.dart';
import 'package:catacroket/core/providers/cuenta_provider.dart';
import 'package:catacroket/features/mesas/widgets/hoja_codigo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// La hoja de entrar con un código.
///
/// Es la primera pantalla que ve alguien invitado a una mesa, y hasta ahora
/// le pedía la cuenta por sorpresa después de teclear las seis letras.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Future<void> abrir(WidgetTester tester, {required bool conSesion}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          haySesionProvider.overrideWithValue(conSesion),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (BuildContext context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => hojaCodigo(context),
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('sin sesión avisa del correo antes de teclear', (
    WidgetTester tester,
  ) async {
    await abrir(tester, conSesion: false);
    expect(find.textContaining('Te pediremos un correo'), findsOneWidget);
  });

  testWidgets('con sesión no enseña ese aviso', (WidgetTester tester) async {
    await abrir(tester, conSesion: true);
    expect(find.textContaining('Te pediremos un correo'), findsNothing);
  });

  testWidgets('un código con una letra imposible se avisa sin ir al servidor', (
    WidgetTester tester,
  ) async {
    await abrir(tester, conSesion: true);

    await tester.enterText(find.byType(TextField).first, 'NGZYVO');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.textContaining('no llevan O'), findsOneWidget);
  });

  testWidgets('el aviso se va al corregir', (WidgetTester tester) async {
    await abrir(tester, conSesion: true);

    await tester.enterText(find.byType(TextField).first, 'NGZYVO');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('no llevan O'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'NGZYV8');
    await tester.pumpAndSettle();
    expect(find.textContaining('no llevan O'), findsNothing);
  });

  test('el alfabeto de los códigos no tiene letras que se confundan', () {
    for (final String mala in <String>['I', 'L', 'O', '0', '1']) {
      expect(Mesa.alfabetoCodigo.contains(mala), isFalse, reason: mala);
    }
    expect(Mesa.nuevoCodigo().length, 6);
  });
}
