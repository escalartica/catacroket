import 'package:catacroket/core/models/cata.dart';
import 'package:catacroket/core/models/corte.dart';
import 'package:catacroket/core/models/persona.dart';
import 'package:catacroket/core/models/sabor.dart';
import 'package:catacroket/features/compartir/compartir_cata.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// La hoja de compartir.
///
/// Ningún test la montaba porque es un modal y no una pantalla, y por eso un
/// desbordamiento de 32 píxeles llegó hasta el móvil: las rayas amarillas y
/// negras de Flutter tapaban el último botón. Un modal sin test es una
/// pantalla sin test.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Cata cata({
    String sitio = 'Bar Manoli',
    String ciudad = 'Sevilla',
    String nota = '',
    List<Sabor> sabores = const <Sabor>[Sabor(rellenoId: 'jamon')],
    List<String> acompanantes = const <String>[],
  }) =>
      Cata(
        id: 'x',
        sitio: sitio,
        ciudad: ciudad,
        corte: const Corte(crujiente: 9, cremosidad: 5, sabor: 5, relleno: 5),
        sabores: sabores,
        autorId: 'tu',
        mesaId: 'libreta',
        fecha: DateTime(2026),
        nota: nota,
        acompanantes: acompanantes,
      );

  /// Abre la hoja sobre una pantalla del tamaño que se le diga.
  Future<void> abrir(
    WidgetTester tester, {
    required Cata laCata,
    Size pantalla = const Size(402, 874),
  }) async {
    // El orden importa y me costó una tarde: multiplicar por el
    // devicePixelRatio ANTES de ponerlo a 1 deja una pantalla de 1206x2622
    // puntos, donde no se desborda nada y el test pasa sin probar nada.
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = pantalla;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Builder(
            builder: (BuildContext context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => compartirCata(
                    context,
                    cata: laCata,
                    autor: const Persona(
                      id: 'tu',
                      nombre: 'Tú',
                      color: Color(0xFFFFC93C),
                    ),
                  ),
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  group('No se sale de la pantalla', () {
    testWidgets('en un móvil normal', (WidgetTester tester) async {
      await abrir(tester, laCata: cata());

      // takeException recoge el "BOTTOM OVERFLOWED BY N PIXELS", que es un
      // error de layout y no una excepción que reviente la app: sin montarla
      // en un test, llega al usuario tal cual.
      expect(tester.takeException(), isNull);
    });

    testWidgets('en una pantalla pequeña, que es donde aprieta', (
      WidgetTester tester,
    ) async {
      // Un iPhone SE. Si la vista previa no se encoge, aquí no cabe nada.
      await abrir(tester, laCata: cata(), pantalla: const Size(320, 568));

      expect(tester.takeException(), isNull);
    });

    testWidgets('en una pantalla muy alta tampoco pasa nada', (
      WidgetTester tester,
    ) async {
      await abrir(tester, laCata: cata(), pantalla: const Size(430, 932));

      expect(tester.takeException(), isNull);
    });
  });

  group('Lo que se enseña antes de mandarla', () {
    testWidgets('dice que es una vista previa', (WidgetTester tester) async {
      await abrir(tester, laCata: cata());

      expect(find.text('Así se va a ver'), findsOneWidget);
    });

    testWidgets('las tres salidas están puestas', (WidgetTester tester) async {
      await abrir(tester, laCata: cata());

      expect(find.textContaining('Compartir la estampa'), findsOneWidget);
      expect(find.textContaining('Ahora no'), findsOneWidget);
    });

    testWidgets('un nombre de bar larguísimo no la rompe', (
      WidgetTester tester,
    ) async {
      await abrir(
        tester,
        laCata: cata(sitio: 'Restaurante Casa Manoli Hermanos y Sobrinos S.L.'),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('un relleno escrito a mano larguísimo tampoco', (
      WidgetTester tester,
    ) async {
      // El nombre del bar sale de una caja de texto, pero el relleno propio
      // también, y ése no lo probaba nadie. La estampa es un lienzo de 360x450
      // clavados —tiene que pesar igual en un SE que en un Max—, así que aquí
      // lo que no cabe no crece: se sale.
      await abrir(
        tester,
        laCata: cata(
          sabores: const <Sabor>[
            Sabor(
              rellenoId: 'otro',
              propio: 'Bechamel de puerro confitado con boletus salteados y '
                  'un toque de trufa negra de Teruel',
            ),
          ],
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('un apunte de tres párrafos tampoco', (
      WidgetTester tester,
    ) async {
      await abrir(
        tester,
        laCata: cata(
          nota: 'Estaba tremenda, de las mejores que he probado en mi vida, '
              'con una bechamel finísima que se deshacía en la boca y un '
              'rebozado que sonaba al morderlo, y encima el camarero nos '
              'contó que la receta es de la abuela del dueño.',
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('con media mesa de acompañantes tampoco', (
      WidgetTester tester,
    ) async {
      await abrir(
        tester,
        laCata: cata(
          acompanantes: const <String>[
            'María del Carmen',
            'Juan Antonio',
            'Rosa',
            'Paco',
            'Inmaculada Concepción',
            'Fernando',
          ],
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('todo largo a la vez, en un iPhone SE', (
      WidgetTester tester,
    ) async {
      await abrir(
        tester,
        pantalla: const Size(320, 568),
        laCata: cata(
          sitio: 'Restaurante Marisquería y Tapería Casa Ricardo Hermanos '
              'Fundado en 1954',
          ciudad: 'Santiago de Compostela',
          nota: 'De las mejores que he probado en toda mi vida, sin ninguna '
              'duda, y mira que he probado croquetas.',
          sabores: const <Sabor>[
            Sabor(rellenoId: 'otro', propio: 'Boletus con trufa negra'),
          ],
          acompanantes: const <String>['María del Carmen', 'Juan Antonio'],
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('sin ciudad enseña el país y no un hueco', (
      WidgetTester tester,
    ) async {
      await abrir(tester, laCata: cata(ciudad: ''));

      expect(tester.takeException(), isNull);
      expect(find.textContaining('España'), findsWidgets);
    });
  });
}
