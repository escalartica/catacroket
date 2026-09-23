import 'package:catacroket/core/data/siembra.dart';
import 'package:catacroket/core/models/cata.dart';
import 'package:catacroket/core/models/corte.dart';
import 'package:catacroket/core/models/sabor.dart';
import 'package:catacroket/core/providers/catas_provider.dart';
import 'package:catacroket/features/detalle/detalle_page.dart';
import 'package:catacroket/features/libre/barra_libre_page.dart';
import 'package:catacroket/features/mesas/mesas_page.dart';
import 'package:catacroket/features/perfil/perfil_page.dart';
import 'package:catacroket/features/vitrina/vitrina_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Que cada pantalla se monte entera y sin desbordarse.
///
/// Sonaba a test de poca sustancia hasta que el de RutaPage encontró, a la
/// primera, que un racimo se salía 9,5 px de su marcador. Un RenderFlex
/// desbordado no lo ve el analizador, no lo ve `flutter test` si nadie monta
/// la pantalla, y en el móvil sale como franjas amarillas y negras.
///
/// Cada `expect(tester.takeException(), isNull)` cubre eso y cualquier
/// excepción de layout o de build de toda la pantalla.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  /// Monta una pantalla con lo mínimo que necesita para vivir.
  Future<void> montar(WidgetTester tester, Widget pantalla) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: Scaffold(body: pantalla)),
      ),
    );
    // Nada de pumpAndSettle: el mapa deja temporizadores que no acaban. Pero
    // sí hay que avanzar lo suficiente para que la cascada de entrada dispare
    // los suyos: `Entrada` escalona hasta ocho elementos a 55 ms, y si el
    // test acaba antes, el framework falla con `!timersPending`.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  group('La Vitrina', () {
    testWidgets('se monta sin excepciones', (WidgetTester tester) async {
      await montar(tester, const VitrinaPage());

      expect(tester.takeException(), isNull);
      expect(find.text('La Vitrina'), findsOneWidget);
    });

    testWidgets('enseña la racha y la croqueta del día', (
      WidgetTester tester,
    ) async {
      await montar(tester, const VitrinaPage());

      expect(find.text('CROQUETA DEL DÍA'), findsOneWidget);
      expect(find.textContaining('Racha'), findsWidgets);
    });

    testWidgets('los tres filtros del feed están puestos', (
      WidgetTester tester,
    ) async {
      await montar(tester, const VitrinaPage());

      expect(find.text('Todo'), findsOneWidget);
      expect(find.text('Mis mesas'), findsOneWidget);
      expect(find.text('Mías'), findsOneWidget);
    });
  });

  group('El primer día, sin una sola cata', () {
    /// Monta la Vitrina como la ve alguien que acaba de instalar la app.
    Future<void> montarVacia(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            catasProvider.overrideWith((Ref ref) => _CatasVacias()),
          ],
          child: const MaterialApp(
            home: Scaffold(body: VitrinaPage()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
    }

    testWidgets('dice qué hacer, y lo dice sin hacer scroll', (
      WidgetTester tester,
    ) async {
      await montarVacia(tester);

      final Finder invitacion = find.textContaining('Dale al botón rojo');
      expect(invitacion, findsOneWidget);

      // Lo que de verdad importa: que se vea. Estaba escrito, pero por debajo
      // del pliegue, así que había que hacer scroll para saber cómo empezar.
      final double abajo = tester.getBottomLeft(invitacion).dy;
      final double alto = tester.view.physicalSize.height /
          tester.view.devicePixelRatio;
      expect(
        abajo,
        lessThan(alto),
        reason: 'la instrucción de cómo empezar queda fuera de pantalla',
      );
    });

    testWidgets('no enseña un filtro que no filtra nada', (
      WidgetTester tester,
    ) async {
      await montarVacia(tester);

      expect(find.text('Mis mesas'), findsNothing);
      expect(find.text('Últimas catas'), findsNothing);
    });

    testWidgets('la racha invita en vez de decir cero', (
      WidgetTester tester,
    ) async {
      await montarVacia(tester);

      expect(find.textContaining('Sin racha'), findsOneWidget);
    });
  });

  group('Mesas', () {
    testWidgets('se monta sin excepciones', (WidgetTester tester) async {
      await montar(tester, const MesasPage());

      expect(tester.takeException(), isNull);
      expect(find.text('Mesas'), findsOneWidget);
    });

    testWidgets('la libreta siempre está, aunque no haya mesas', (
      WidgetTester tester,
    ) async {
      await montar(tester, const MesasPage());

      // La libreta no se puede borrar: es la mesa de uno mismo y por eso esta
      // pantalla nunca aparece del todo vacía.
      expect(find.text('Mi libreta'), findsOneWidget);
    });
  });

  group('Perfil', () {
    testWidgets('se monta sin excepciones', (WidgetTester tester) async {
      await montar(tester, const PerfilPage());

      expect(tester.takeException(), isNull);
      expect(find.text('Croquetómetro'), findsOneWidget);
    });

    testWidgets('enseña el rango y las cifras', (WidgetTester tester) async {
      await montar(tester, const PerfilPage());

      expect(find.text('CAMINO AL SIGUIENTE RANGO'), findsOneWidget);
      expect(find.text('catas'), findsWidgets);
    });
  });

  group('Barra Libre', () {
    testWidgets('se monta sin excepciones', (WidgetTester tester) async {
      await montar(tester, const BarraLibrePage());

      expect(tester.takeException(), isNull);
    });
  });

  group('Ficha de una cata', () {
    testWidgets('se monta sin excepciones', (WidgetTester tester) async {
      // La cata se saca del sembrado, que es síncrono. Montar un
      // ProviderContainer de verdad aquí dentro cuelga el test: testWidgets
      // usa un reloj falso y un `await Future.delayed` real no se resuelve
      // nunca si nadie adelanta ese reloj.
      final Cata alguna = Siembra.catas().first;

      await montar(tester, DetallePage(cataId: alguna.id));

      expect(tester.takeException(), isNull);
      expect(find.text(alguna.sitio), findsWidgets);
    });

    testWidgets('en la tuya puedes corregir y borrar', (
      WidgetTester tester,
    ) async {
      final Cata mia =
          Siembra.catas().firstWhere((Cata c) => c.autorId == 'tu');

      await montar(tester, DetallePage(cataId: mia.id));

      expect(find.text('Corregir esta cata'), findsOneWidget);
      expect(find.bySemanticsLabel('Borrar la cata'), findsOneWidget);
    });

    testWidgets('la cata de otro se lee, no se toca', (
      WidgetTester tester,
    ) async {
      // La regla está escrita en un comentario de detalle_page: "corregir y
      // borrar sólo en las tuyas; la de otro se lee, se comparte y se le da
      // un mordisco". Si `esMia` se rompe, cualquiera podría borrar la cata
      // de cualquiera y nada lo detectaría.
      final Cata ajena =
          Siembra.catas().firstWhere((Cata c) => c.autorId != 'tu');

      await montar(tester, DetallePage(cataId: ajena.id));

      expect(find.text('Corregir esta cata'), findsNothing);
      expect(find.bySemanticsLabel('Borrar la cata'), findsNothing);
    });

    testWidgets('un mordisco sí se le puede dar a la de cualquiera', (
      WidgetTester tester,
    ) async {
      final Cata ajena =
          Siembra.catas().firstWhere((Cata c) => c.autorId != 'tu');

      await montar(tester, DetallePage(cataId: ajena.id));

      expect(
        find.bySemanticsLabel(RegExp('Dar un mordisco')),
        findsOneWidget,
      );
    });

    testWidgets('una cata sin ciudad no enseña comas ni banderas sueltas', (
      WidgetTester tester,
    ) async {
      // La cabecera y la tarjeta del mapa montaban su texto a mano con
      // `cata.ciudad`, así que con la ciudad vacía salía " 🇪🇸 · BAR" y
      // ", España". Ahora lo decide el modelo, que ya sabía hacerlo.
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            catasProvider.overrideWith((Ref ref) => _UnaSinCiudad()),
          ],
          child: const MaterialApp(
            home: Scaffold(body: DetallePage(cataId: 'sin-ciudad')),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(tester.takeException(), isNull);
      expect(find.textContaining('SIN CIUDAD'), findsNothing);
      expect(find.textContaining('ESPAÑA · BAR ANÓNIMO'), findsOneWidget);
    });

    testWidgets('una cata que ya no existe no revienta la pantalla', (
      WidgetTester tester,
    ) async {
      // Pasa de verdad: borras una cata desde otro sitio y el enlace que
      // tenías abierto apunta a un identificador que ya no está.
      await montar(tester, const DetallePage(cataId: 'no-existe'));

      expect(tester.takeException(), isNull);
    });
  });
}

/// Una app recién instalada: ni una cata.
class _CatasVacias extends CatasNotifier {
  _CatasVacias() {
    state = const <Cata>[];
  }
}

/// Una cata en la que no se rellenó la ciudad.
class _UnaSinCiudad extends CatasNotifier {
  _UnaSinCiudad() {
    state = <Cata>[
      Cata(
        id: 'sin-ciudad',
        sitio: 'Bar Anónimo',
        ciudad: '',
        corte: const Corte(crujiente: 7, cremosidad: 7, sabor: 7, relleno: 7),
        sabores: const <Sabor>[Sabor(rellenoId: 'jamon')],
        autorId: 'tu',
        mesaId: 'libreta',
        fecha: DateTime(2026),
      ),
    ];
  }
}
