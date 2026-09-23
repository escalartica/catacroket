import 'package:catacroket/app/concha.dart';
import 'package:catacroket/core/theme/components/campo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lo que un lector de pantalla tiene que poder decir.
///
/// Estas comprobaciones existen porque la interfaz decía cosas sólo con
/// color: la pestaña activa se pintaba de amarillo y ya está. Eso no llega a
/// quien no lo ve, y no hay analizador que lo detecte.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Future<void> montarConcha(WidgetTester tester, String ruta) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Concha(ruta: ruta, child: const SizedBox.shrink()),
        ),
      ),
    );
    await tester.pump();
  }

  /// Comprueba si una pestaña se anuncia (o no) como la activa.
  void anunciaActiva(
    WidgetTester tester,
    String etiqueta, {
    required bool activa,
    String? porque,
  }) {
    expect(
      tester.getSemantics(find.bySemanticsLabel(etiqueta)),
      isSemantics(isSelected: activa),
      reason: porque,
    );
  }

  group('Barra de pestañas', () {
    testWidgets('las cuatro se anuncian por su nombre', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await montarConcha(tester, '/');

      for (final String nombre in <String>[
        'La Vitrina',
        'Ruta',
        'Mesas',
        'Perfil',
      ]) {
        expect(
          find.bySemanticsLabel(nombre),
          findsOneWidget,
          reason: 'la pestaña "$nombre" no se anuncia',
        );
      }

      handle.dispose();
    });

    testWidgets('la activa dice que lo está', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await montarConcha(tester, '/ruta');

      anunciaActiva(
        tester,
        'Ruta',
        activa: true,
        porque: 'estando en /ruta, la pestaña Ruta debe anunciarse activa',
      );

      handle.dispose();
    });

    testWidgets('las demás no lo dicen', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await montarConcha(tester, '/ruta');

      for (final String otra in <String>['La Vitrina', 'Mesas', 'Perfil']) {
        anunciaActiva(
          tester,
          otra,
          activa: false,
          porque: '"$otra" no está activa y no debe decir que sí',
        );
      }

      handle.dispose();
    });

    testWidgets('una subpantalla hereda la pestaña de su sección', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      // Dentro de la ficha de una cata se sigue estando "en la Vitrina".
      await montarConcha(tester, '/cata/abc');

      anunciaActiva(tester, 'La Vitrina', activa: true);

      handle.dispose();
    });

    testWidgets('cambiar de sección mueve la marca de activa', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await montarConcha(tester, '/mesas');
      anunciaActiva(tester, 'Mesas', activa: true);
      anunciaActiva(tester, 'Perfil', activa: false);

      await montarConcha(tester, '/perfil');
      anunciaActiva(tester, 'Perfil', activa: true);
      anunciaActiva(tester, 'Mesas', activa: false);

      handle.dispose();
    });
  });

  group('Campo de texto', () {
    testWidgets('dice de qué es, no sólo lo que lleva escrito', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Campo(
              etiqueta: 'Sitio',
              valor: 'Bar Manoli',
              pista: 'Dónde catabas',
              onCambio: (String _) {},
            ),
          ),
        ),
      );
      await tester.pump();

      // Con algo escrito la pista ya no se anuncia. Si el nombre del campo
      // no estuviera puesto aparte, el lector leería "Bar Manoli" sin decir
      // nunca de qué campo se trata.
      expect(find.bySemanticsLabel('Sitio'), findsWidgets);

      handle.dispose();
    });
  });
}
