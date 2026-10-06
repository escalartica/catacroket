import 'package:catacroket/core/data/enlaces.dart';
import 'package:catacroket/features/perfil/perfil_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// La privacidad tiene que alcanzarse desde dentro de la app.
///
/// La App Store devuelve las apps que sólo ponen la política en App Store
/// Connect. Y pasó justo eso: las direcciones llevaban días escritas en
/// `Enlaces` y desplegadas en el hosting, pero no las enseñaba ninguna
/// pantalla. Escritas no es puestas, y este test es la diferencia.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('las direcciones son páginas de verdad', () {
    for (final String url in <String>[Enlaces.privacidad, Enlaces.soporte]) {
      expect(url, startsWith('https://'));
      expect(url, endsWith('.html'));
    }
  });

  testWidgets('el Perfil lleva a la privacidad y al soporte', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: PerfilPage())),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Están al pie, así que hay que bajar hasta ellos: que existan en el
    // árbol no basta, tienen que poder alcanzarse desplazándose.
    final Finder scroll = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Privacidad'),
      400,
      scrollable: scroll,
    );

    expect(find.text('Privacidad'), findsOneWidget);
    expect(find.text('Soporte'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
