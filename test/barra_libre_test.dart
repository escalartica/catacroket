import 'package:catacroket/core/models/cata.dart';
import 'package:catacroket/core/models/corte.dart';
import 'package:catacroket/core/models/dieta.dart';
import 'package:catacroket/core/models/persona.dart';
import 'package:catacroket/core/models/receta.dart';
import 'package:catacroket/core/models/sabor.dart';
import 'package:catacroket/core/providers/catas_provider.dart';
import 'package:catacroket/core/providers/evitar_provider.dart';
import 'package:catacroket/core/providers/mi_dieta_provider.dart';
import 'package:catacroket/core/theme/components/pildoras_dieta.dart';
import 'package:catacroket/features/libre/barra_libre_page.dart';
import 'package:catacroket/features/vitrina/widgets/tarjeta_cata.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// La Barra Libre: la pantalla donde alguien decide qué se come.
///
/// Es la única de la app en la que equivocarse tiene consecuencias fuera del
/// teléfono, así que lo que se prueba aquí no es que se pinte: es que los
/// números no prometan nada que la lista no cumpla, y que un sitio de la
/// pantalla no contradiga a otro.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  /// Una cata con las dietas puestas a mano.
  ///
  /// Sin receta, `aptasCalculadas` es exactamente lo que se le pase, así que
  /// la prueba no depende de la tabla de rellenos ni de las reglas de
  /// deducción, que se prueban en su propio sitio.
  Cata cata(String id, Set<Dieta> dietas, {String relleno = 'jamon'}) => Cata(
        id: id,
        sitio: 'Bar $id',
        ciudad: 'Sevilla',
        corte: const Corte(crujiente: 7, cremosidad: 7, sabor: 7, relleno: 7),
        sabores: <Sabor>[Sabor(rellenoId: relleno)],
        autorId: 'tu',
        fecha: DateTime(2026, 3, 14),
        aptas: dietas,
      );

  /// La pastilla del filtro, y no la etiqueta de la misma dieta que lleva
  /// la tarjeta de abajo: las dos dicen «Sin frutos secos».
  Finder pastilla(String nombre) => find.descendant(
        of: find.byType(PildorasDieta),
        matching: find.text(nombre),
      );

  ProviderContainer conCatas(List<Cata> catas, {Set<String>? evitando}) {
    final ProviderContainer c = ProviderContainer(
      overrides: <Override>[
        catasProvider.overrideWith((Ref ref) => _Catas(ref, catas)),
        if (evitando != null)
          evitarProvider.overrideWith((Ref ref) => _Evitar(evitando)),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  group('los números de las pastillas', () {
    test('cuentan sobre el filtro que ya hay, no sobre el total', () {
      // El fallo que tapaban: «Sin lactosa 1» con «sin gluten» marcado, y al
      // tocarla salían cero, porque esa cata no era sin gluten. Un contador
      // al lado de un botón es una promesa de lo que pasa al pulsarlo.
      final ProviderContainer c = conCatas(<Cata>[
        cata('a', <Dieta>{Dieta.sinGluten, Dieta.sinLactosa}),
        cata('b', <Dieta>{Dieta.sinGluten}),
        cata('c', <Dieta>{Dieta.sinLactosa}),
      ]);

      Map<Dieta, int> recuento() => c.read(recuentoDietasProvider);

      expect(recuento()[Dieta.sinLactosa], 2, reason: 'sin filtro, las dos');

      c.read(filtroDietaProvider.notifier).state = <Dieta>{Dieta.sinGluten};

      expect(
        recuento()[Dieta.sinLactosa],
        1,
        reason: 'con «sin gluten» puesto, de las dos sin lactosa sólo una lo '
            'es también sin gluten',
      );
      expect(
        c.read(catasLibresProvider).length,
        2,
        reason: 'con «sin gluten» a secas quedan las dos que lo son',
      );

      // Y lo prometido es lo que sale: al añadir «sin lactosa», una.
      c.read(filtroDietaProvider.notifier).state = <Dieta>{
        Dieta.sinGluten,
        Dieta.sinLactosa,
      };
      expect(c.read(catasLibresProvider).length, 1);
    });

    test('lo que promete una pastilla es lo que sale al tocarla', () {
      final ProviderContainer c = conCatas(<Cata>[
        cata('a', <Dieta>{Dieta.sinGluten, Dieta.sinLactosa}),
        cata('b', <Dieta>{Dieta.sinGluten}),
        cata('c', <Dieta>{Dieta.vegana}),
      ]);

      for (final Dieta d in Dieta.values) {
        c.read(filtroDietaProvider.notifier).state = const <Dieta>{};
        final int prometido = c.read(recuentoDietasProvider)[d] ?? -1;

        c.read(filtroDietaProvider.notifier).state = <Dieta>{d};
        expect(
          c.read(catasLibresProvider).length,
          prometido,
          reason: 'la pastilla de ${d.nombre} prometía $prometido',
        );
      }
    });

    test('descuentan lo que has dicho que no quieres comer', () {
      // La lista de abajo ya lo descontaba. Si el número no lo descuenta, los
      // dos sitios de la misma pantalla dicen cosas distintas.
      SharedPreferences.setMockInitialValues(<String, Object>{
        'catacroket.evitar.v1': <String>['bacalao'],
      });
      final ProviderContainer c = conCatas(
        <Cata>[
          cata('a', <Dieta>{Dieta.sinGluten}, relleno: 'bacalao'),
          cata('b', <Dieta>{Dieta.sinGluten}),
        ],
        evitando: <String>{'bacalao'},
      );

      expect(c.read(recuentoDietasProvider)[Dieta.sinGluten], 1);
      expect(c.read(catasLibresProvider).length, 1);
      expect(c.read(totalLibresProvider), 1);
    });
  });

  group('la pantalla', () {
    Future<void> montar(
      WidgetTester tester,
      List<Cata> catas, {
      Set<Dieta> miDieta = const <Dieta>{},
      Set<Dieta> filtro = const <Dieta>{},
    }) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(440, 956); // iPhone 16 Pro Max
      addTearDown(tester.view.reset);

      // Con la explicación ya leída, que es como se ve a partir de la segunda
      // visita. La primera abre el panel y empuja la lista hacia abajo.
      SharedPreferences.setMockInitialValues(<String, Object>{
        'catacroket.visto.v1': <String>['pista.libre'],
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            catasProvider.overrideWith((Ref ref) => _Catas(ref, catas)),
            miDietaProvider.overrideWith((Ref ref) => _MiDieta(miDieta)),
            // Puesto a mano y no tocando pastillas: `initState` copia aquí la
            // dieta del perfil cuando el filtro está vacío, y eso haría que
            // cada prueba dependiera de ese automatismo en vez de probar lo
            // suyo.
            filtroDietaProvider.overrideWith((_) => filtro),
          ],
          child: const MaterialApp(
            home: Scaffold(body: BarraLibrePage()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
    }

    Future<void> tocar(WidgetTester tester, String nombre) async {
      await tester.ensureVisible(pastilla(nombre));
      await tester.pump();
      await tester.tap(pastilla(nombre), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
    }

    testWidgets('sin filtro no dice «aptas» sin decir para quién', (
      WidgetTester tester,
    ) async {
      await montar(tester, <Cata>[cata('a', <Dieta>{Dieta.sinGluten})]);

      expect(find.text('Con receta apuntada'), findsOneWidget);
      expect(find.text('Todas las aptas'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('bajo «Te valen» no sale ninguna tarjeta que no te valga', (
      WidgetTester tester,
    ) async {
      // La contradicción que se veía en pantalla: el título contestaba por el
      // filtro y la pastilla de la tarjeta por la dieta del perfil, que son
      // dos preguntas distintas. Salía «Te valen» con un «⛔ No te vale»
      // debajo, en la única pantalla donde eso no se puede permitir.
      await montar(
        tester,
        <Cata>[cata('a', <Dieta>{Dieta.sinFrutosSecos})],
        miDieta: <Dieta>{Dieta.sinGluten},
        filtro: <Dieta>{Dieta.sinFrutosSecos},
      );

      expect(find.text('Te valen'), findsOneWidget);
      expect(find.byType(TarjetaCata), findsOneWidget,
          reason: 'la cata tiene que estar listada para que esto pruebe algo');
      expect(find.text(Encaje.no.nombre), findsNothing);
      expect(
        find.text(Encaje.vale.nombre),
        findsNothing,
        reason: 'repetir «te vale» en cada tarjeta de una lista filtrada por '
            'eso mismo no informa de nada',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('una pastilla sin ninguna detrás no se puede pulsar', (
      WidgetTester tester,
    ) async {
      await montar(tester, <Cata>[cata('a', <Dieta>{Dieta.sinFrutosSecos})]);

      // «Vegana» está a cero: pulsarla sólo llevaría a una lista vacía.
      await tocar(tester, 'Vegana');

      expect(find.text('Te valen'), findsNothing);
      expect(find.text('Con receta apuntada'), findsOneWidget);
    });

    testWidgets('la marcada siempre se puede desmarcar, aunque dé cero', (
      WidgetTester tester,
    ) async {
      // Si se apagara por estar a cero no habría forma de salir del filtro:
      // te quedarías encerrado en una lista vacía.
      await montar(
        tester,
        <Cata>[cata('a', <Dieta>{Dieta.sinFrutosSecos})],
        filtro: <Dieta>{Dieta.sinFrutosSecos},
      );

      await tocar(tester, 'Sin frutos secos');

      expect(find.text('Con receta apuntada'), findsOneWidget);
    });

    testWidgets('la pastilla marcada no enseña un cero muerto', (
      WidgetTester tester,
    ) async {
      // Cinco encendidas poniendo «0» parecía la app rota. El número contesta
      // «cuántas saldrían si la pulso», y en una ya puesta eso lo dice el
      // título de la sección.
      //
      // Las que NO están marcadas sí lo llevan, y ahí el cero es información:
      // dice que tocarla no te daría nada, y por eso sale apagada.
      await montar(
        tester,
        <Cata>[cata('a', <Dieta>{Dieta.sinFrutosSecos})],
        filtro: <Dieta>{Dieta.vegana, Dieta.sinGluten},
      );

      expect(
        find.descendant(
          of: find.byType(PildorasDieta),
          matching: find.text('0'),
        ),
        findsNWidgets(Dieta.values.length - 2),
        reason: 'sólo las cuatro sin marcar llevan número; las dos marcadas, '
            'ninguno',
      );
    });

    testWidgets('el hueco dice qué quitar cuando quitar una cosa basta', (
      WidgetTester tester,
    ) async {
      await montar(
        tester,
        <Cata>[cata('a', <Dieta>{Dieta.sinGluten, Dieta.sinLactosa})],
        filtro: <Dieta>{Dieta.sinGluten, Dieta.sinLactosa, Dieta.sinHuevo},
      );

      expect(find.textContaining('Sin «sin huevo»'), findsOneWidget);

      await tester.ensureVisible(find.text('Quitar «sin huevo»'));
      await tester.pump();
      await tester.tap(find.text('Quitar «sin huevo»'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(TarjetaCata), findsOneWidget);
    });

    testWidgets('dice que el filtro lo puso tu perfil, no la app', (
      WidgetTester tester,
    ) async {
      await montar(
        tester,
        <Cata>[cata('a', <Dieta>{Dieta.sinFrutosSecos})],
        miDieta: <Dieta>{Dieta.sinFrutosSecos},
        filtro: <Dieta>{Dieta.sinFrutosSecos},
      );

      expect(find.textContaining('Cómo comes'), findsOneWidget);
      expect(find.text('Yo como así siempre'), findsNothing);
    });

    testWidgets('el filtro se puede guardar como la dieta del perfil', (
      WidgetTester tester,
    ) async {
      await montar(
        tester,
        <Cata>[cata('a', <Dieta>{Dieta.sinFrutosSecos})],
        filtro: <Dieta>{Dieta.sinFrutosSecos},
      );

      expect(find.text('Yo como así siempre'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('cuando no sale nada', () {
    test('señala cuál de las dietas que pides sobra', () {
      // El caso de verdad: el filtro se llena solo con lo de «Cómo comes»,
      // entras y ves cinco pastillas encendidas que no has tocado y cero
      // croquetas. Sin esto no hay forma de saber cuál de las cinco sobra.
      final ProviderContainer c = conCatas(<Cata>[
        cata('a', <Dieta>{Dieta.sinGluten, Dieta.sinLactosa}),
      ]);

      c.read(filtroDietaProvider.notifier).state = <Dieta>{
        Dieta.sinGluten,
        Dieta.sinLactosa,
        Dieta.sinHuevo,
      };

      expect(c.read(catasLibresProvider), isEmpty);
      final List<(Dieta, int)> culpables = c.read(culpablesDelVacioProvider);
      expect(culpables, hasLength(1));
      expect(culpables.first.$1, Dieta.sinHuevo);
      expect(culpables.first.$2, 1);
    });

    test('con una sola marcada no señala nada: quitarla es quitar el filtro', () {
      final ProviderContainer c = conCatas(<Cata>[
        cata('a', <Dieta>{Dieta.sinGluten}),
      ]);

      c.read(filtroDietaProvider.notifier).state = <Dieta>{Dieta.vegana};

      expect(c.read(catasLibresProvider), isEmpty);
      expect(c.read(culpablesDelVacioProvider), isEmpty);
    });

    test('si quitar cualquiera deja la lista igual de vacía, no promete nada', () {
      final ProviderContainer c = conCatas(<Cata>[
        cata('a', <Dieta>{Dieta.sinFrutosSecos}),
      ]);

      c.read(filtroDietaProvider.notifier).state = <Dieta>{
        Dieta.vegana,
        Dieta.sinGluten,
      };

      expect(c.read(culpablesDelVacioProvider), isEmpty);
    });

    test('manda la que más desbloquea', () {
      final ProviderContainer c = conCatas(<Cata>[
        cata('a', <Dieta>{Dieta.sinGluten}),
        cata('b', <Dieta>{Dieta.sinGluten}),
        cata('c', <Dieta>{Dieta.sinLactosa}),
      ]);

      c.read(filtroDietaProvider.notifier).state = <Dieta>{
        Dieta.sinGluten,
        Dieta.sinLactosa,
      };

      final List<(Dieta, int)> culpables = c.read(culpablesDelVacioProvider);
      expect(culpables.first.$1, Dieta.sinLactosa,
          reason: 'quitándola salen dos; quitando la otra, una');
      expect(culpables.first.$2, 2);
    });
  });

  group('la tarjeta', () {
    testWidgets('sin dieta de referencia enseña las dietas de la croqueta', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            miDietaProvider
                .overrideWith((Ref ref) => _MiDieta(<Dieta>{Dieta.sinGluten})),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: TarjetaCata(
                cata: cata('a', <Dieta>{Dieta.sinFrutosSecos}),
                autor: Persona.desconocida,
                segun: const <Dieta>{},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text(Encaje.no.nombre), findsNothing);
      expect(find.text(Dieta.sinFrutosSecos.corto), findsOneWidget);
    });

    testWidgets('sin pasarle nada sigue contestando por el perfil', (
      WidgetTester tester,
    ) async {
      // Con una receta que SÍ dice que lleva gluten: el «no» tiene que venir
      // de un hecho apuntado, no de que la cata no diga nada. Lo segundo es
      // «pregunta», y tiene su propia prueba en no_lo_se_no_es_no_test.
      final Cata conGluten = cata('a', const <Dieta>{}).copyWith(
        receta: const Receta(
          bechamel: Bechamel.leche,
          rebozadoConGluten: true,
          rebozadoConHuevo: true,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            miDietaProvider
                .overrideWith((Ref ref) => _MiDieta(<Dieta>{Dieta.sinGluten})),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: TarjetaCata(
                cata: conGluten,
                autor: Persona.desconocida,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text(Encaje.no.nombre), findsOneWidget);
    });
  });

  group('las pastillas, sueltas', () {
    testWidgets('sin recuento no se apaga ninguna', (
      WidgetTester tester,
    ) async {
      // En el formulario de una cata no hay números y todas tienen que
      // poderse marcar: allí se está describiendo la croqueta, no filtrando.
      final List<Dieta> tocadas = <Dieta>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PildorasDieta(
              marcadas: const <Dieta>{},
              onAlternar: tocadas.add,
            ),
          ),
        ),
      );

      for (final Dieta d in Dieta.values) {
        await tester.tap(find.text(d.nombre));
      }

      expect(tocadas.length, Dieta.values.length);
    });
  });
}

class _Catas extends CatasNotifier {
  _Catas(super.ref, List<Cata> catas) {
    state = catas;
  }
}

class _Evitar extends EvitarNotifier {
  _Evitar(Set<String> cosas) {
    state = cosas;
  }
}

class _MiDieta extends MiDietaNotifier {
  _MiDieta(Set<Dieta> dietas) {
    state = dietas;
  }
}
