import 'package:catacroket/core/models/cata.dart';
import 'package:catacroket/core/providers/catas_provider.dart';
import 'package:catacroket/features/ruta/ruta_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// La pantalla de la ruta se compone de widgets sueltos (_CapaMapa, _Filtros,
/// _HojaResultados...) en vez de un `build()` de trescientas líneas. Todos
/// ellos devuelven un `Positioned` desde dentro de un `StatelessWidget`, que
/// es legal pero no evidente: si alguno dejara de serlo, el `Stack` lo
/// colocaría mal o reventaría en tiempo de ejecución, y el analizador no
/// diría nada. Esto lo monta de verdad para comprobarlo.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Future<void> montar(WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: RutaPage())),
      ),
    );
    // `pumpAndSettle` no vale: el mapa deja temporizadores vivos y la cascada
    // de entrada tiene retrasos propios. Basta con dejar pasar unos frames.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('la pantalla se monta entera y sin excepciones', (
    WidgetTester tester,
  ) async {
    await montar(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Ruta croquetera'), findsOneWidget);
  });

  group('El primer día, sin una cata con sitio', () {
    Future<void> montarVacia(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            catasProvider.overrideWith((Ref ref) => _CatasVacias()),
          ],
          child: const ProviderScope(
            child: MaterialApp(home: Scaffold(body: RutaPage())),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
    }

    testWidgets('no enseña filtros que no filtran nada', (
      WidgetTester tester,
    ) async {
      await montarVacia(tester);

      // Tres pastillas para filtrar el vacío: ninguna va a enseñar nada
      // nunca, porque no hay ni una cata con punto en el mapa.
      expect(find.text('Mías'), findsNothing);
      expect(find.text('Barra Libre'), findsNothing);
    });

    testWidgets('no dice "ordenadas por nota" encima de nada', (
      WidgetTester tester,
    ) async {
      await montarVacia(tester);

      expect(find.text('ORDENADAS POR NOTA'), findsNothing);
    });

    testWidgets('sí dice qué hacer para que salga algo', (
      WidgetTester tester,
    ) async {
      await montarVacia(tester);

      expect(find.textContaining('Aún no hay catas'), findsOneWidget);
    });
  });

  testWidgets('las tres pastillas de filtro están puestas', (
    WidgetTester tester,
  ) async {
    await montar(tester);

    expect(find.text('Todas'), findsOneWidget);
    expect(find.text('Mías'), findsOneWidget);
    expect(find.text('Barra Libre'), findsOneWidget);
  });

  testWidgets('la hoja de resultados está debajo del mapa', (
    WidgetTester tester,
  ) async {
    await montar(tester);

    expect(find.text('ORDENADAS POR NOTA'), findsOneWidget);
  });

  testWidgets('el mapa y la hoja conviven en el mismo Stack', (
    WidgetTester tester,
  ) async {
    await montar(tester);

    // Si un Positioned hubiera quedado fuera de su Stack, Flutter habría
    // lanzado al hacer el layout y takeException lo habría recogido.
    expect(find.byType(Stack), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tocar un filtro no rompe nada', (WidgetTester tester) async {
    await montar(tester);

    await tester.tap(find.text('Mías'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(find.text('Mías'), findsOneWidget);
  });

  testWidgets('plegar y desplegar la hoja no rompe nada', (
    WidgetTester tester,
  ) async {
    await montar(tester);

    // El tirador es lo único con esa etiqueta de accesibilidad.
    final Finder tirador = find.bySemanticsLabel('Plegar la lista de catas');
    expect(tirador, findsOneWidget);

    await tester.tap(tirador, warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
    expect(find.bySemanticsLabel('Abrir la lista de catas'), findsOneWidget);
  });
}

/// Una app recién instalada: ni una cata, y por tanto ningún punto.
class _CatasVacias extends CatasNotifier {
  _CatasVacias() {
    state = const <Cata>[];
  }
}
