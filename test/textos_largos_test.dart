import 'package:catacroket/core/models/cata.dart';
import 'package:catacroket/core/models/corte.dart';
import 'package:catacroket/core/models/persona.dart';
import 'package:catacroket/core/models/sabor.dart';
import 'package:catacroket/core/models/mesa.dart';
import 'package:catacroket/core/providers/catas_provider.dart';
import 'package:catacroket/core/providers/mesas_provider.dart';
import 'package:catacroket/features/detalle/detalle_page.dart';
import 'package:catacroket/features/mesas/mesas_page.dart';
import 'package:catacroket/features/vitrina/vitrina_page.dart';
import 'package:catacroket/features/vitrina/widgets/tarjeta_cata.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Qué pasa cuando alguien escribe mucho.
///
/// No hay ningún límite de longitud en la app: se puede pegar un párrafo
/// entero en el nombre del bar. Y no hace falta mala fe para llegar ahí —el
/// nombre real de un sitio puede ser «Restaurante y Tapería Casa Ricardo
/// Hermanos desde 1954»— ni para pegar sin querer lo que había en el
/// portapapeles.
///
/// Lo que no puede pasar es que una tarjeta se llene de rayas amarillas y
/// negras, que es lo que hace Flutter cuando algo no cabe.
///
/// Estos tests sólo valen desde que la suite carga las fuentes de verdad: con
/// una fuente de reemplazo los anchos no son los que ve nadie.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  /// Un nombre de bar que no cabe en ningún sitio.
  const String sitioLargo = 'Restaurante Marisquería y Tapería Casa Ricardo '
      'Hermanos Fundado en 1954 Sucursal de la Calle Betis';

  /// Un apunte de los que se escriben con ganas.
  const String notaLarga =
      'Estaba tremenda, de las mejores que he probado en mi vida, con una '
      'bechamel finísima que se deshacía en la boca y un rebozado que sonaba '
      'al morderlo, y encima el camarero nos contó que la receta es de la '
      'abuela del dueño y que la hacen cada mañana a las seis.';

  Cata cata({
    String sitio = sitioLargo,
    String ciudad = 'Sevilla',
    String nota = notaLarga,
    List<String> acompanantes = const <String>[],
  }) =>
      Cata(
        id: 'la-larga',
        sitio: sitio,
        ciudad: ciudad,
        corte: const Corte(crujiente: 9, cremosidad: 8, sabor: 9, relleno: 7),
        sabores: const <Sabor>[Sabor(rellenoId: 'jamon')],
        autorId: 'tu',
        mesaId: 'libreta',
        fecha: DateTime(2026, 3, 14),
        nota: nota,
        acompanantes: acompanantes,
      );

  /// Monta una pantalla en un móvil de verdad, con la cata dentro.
  Future<void> montar(
    WidgetTester tester,
    Widget pantalla, {
    required List<Cata> catas,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(440, 956);
    addTearDown(tester.view.reset);

    final ProviderContainer contenedor = ProviderContainer();
    addTearDown(contenedor.dispose);
    contenedor.read(catasProvider.notifier).state = catas;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: contenedor,
        child: MaterialApp(home: Scaffold(body: pantalla)),
      ),
    );
    // Sin pumpAndSettle: la cascada de entrada escalona hasta ocho elementos
    // a 55 ms y el mapa deja temporizadores que no acaban.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
  }

  /// Cuánto mide la tarjeta de [c] en la pantalla.
  Future<double> altoDe(WidgetTester tester, Cata c) async {
    await montar(
      tester,
      Padding(
        padding: const EdgeInsets.all(16),
        child: TarjetaCata(
          cata: c,
          autor: Persona.desconocida,
          onTap: () {},
        ),
      ),
      catas: <Cata>[c],
    );
    return tester.getSize(find.byType(TarjetaCata)).height;
  }

  group('En la tarjeta del feed', () {
    // Lo que se mide aquí es el alto, no si revienta.
    //
    // La primera versión de estos tests comprobaba `takeException()` y no
    // servía para nada: con un nombre de bar de ciento veinte letras la
    // tarjeta no lanza ninguna excepción, simplemente crece hasta cuatro
    // líneas y deja el feed hecho un acordeón. Lo comprobé quitando el
    // recorte del texto y los tests seguían pasando, así que no probaban
    // nada.
    //
    // Una tarjeta tiene que ocupar lo mismo diga lo que diga dentro: es lo
    // que hace que una lista se lea de un vistazo.

    testWidgets('un nombre de bar larguísimo no la hace crecer', (
      WidgetTester tester,
    ) async {
      final double corto = await altoDe(tester, cata(sitio: 'Bar Manoli'));
      final double largo = await altoDe(tester, cata());

      expect(largo, corto, reason: 'el nombre del bar tiene que recortarse');
    });

    testWidgets('ni una ciudad larguísima', (WidgetTester tester) async {
      final double corto =
          await altoDe(tester, cata(sitio: 'Bar', ciudad: 'Cádiz'));
      final double largo = await altoDe(
        tester,
        cata(sitio: 'Bar', ciudad: 'Santiago de Compostela de la Ribera'),
      );

      expect(largo, corto);
    });

    testWidgets('ni un apunte de tres párrafos', (WidgetTester tester) async {
      final double corto = await altoDe(tester, cata(nota: 'Buena'));
      final double largo = await altoDe(tester, cata(nota: notaLarga * 3));

      expect(largo, corto);
    });

    testWidgets('ni una palabra sola sin espacios, que es el caso peor', (
      WidgetTester tester,
    ) async {
      // Sin espacios no hay por dónde partir la línea. Es lo que se pega sin
      // querer desde el portapapeles: una URL, un código.
      final double corto = await altoDe(tester, cata(sitio: 'Bar'));
      final double largo = await altoDe(tester, cata(sitio: 'a' * 120));

      expect(largo, corto);
    });

    testWidgets('y no revienta con nada de eso', (WidgetTester tester) async {
      await altoDe(tester, cata(sitio: 'a' * 120, nota: notaLarga * 3));

      expect(tester.takeException(), isNull);
    });
  });

  group('Un relleno escrito a mano', () {
    // Lo demás sale del catálogo y no puede ser largo. Esto sí: es una caja
    // de texto donde el usuario escribe lo que lleva su croqueta, y no tiene
    // ningún límite.
    const String rellenoLargo = 'Bechamel de puerro confitado con boletus '
        'salteados y un toque de trufa negra de Teruel';

    testWidgets('tampoco hace crecer la tarjeta', (
      WidgetTester tester,
    ) async {
      final Cata c = Cata(
        id: 'la-larga',
        sitio: 'Casa Ricardo',
        ciudad: 'Sevilla',
        corte: const Corte(crujiente: 9, cremosidad: 8, sabor: 9, relleno: 7),
        sabores: const <Sabor>[
          Sabor(rellenoId: 'otro', propio: rellenoLargo),
        ],
        autorId: 'tu',
        mesaId: 'libreta',
        fecha: DateTime(2026, 3, 14),
      );

      final double largo = await altoDe(tester, c);
      final double corto = await altoDe(tester, cata(sitio: 'Casa Ricardo'));

      expect(largo, corto);
    });
  });

  group('En la ficha entera', () {
    testWidgets('con todo largo se monta sin romperse', (
      WidgetTester tester,
    ) async {
      await montar(
        tester,
        const DetallePage(cataId: 'la-larga'),
        catas: <Cata>[
          cata(acompanantes: const <String>['Maria del Carmen Fernández']),
        ],
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('En la lista de mesas', () {
    /// El nombre de una mesa lo escribe el usuario y tampoco tiene límite.
    Future<double> altoDelNombre(WidgetTester tester, String nombre) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(440, 956);
      addTearDown(tester.view.reset);

      final ProviderContainer contenedor = ProviderContainer();
      addTearDown(contenedor.dispose);
      contenedor.read(mesasProvider.notifier).state = <Mesa>[
        Mesa(
          id: 'la-mesa',
          nombre: nombre,
          descripcion: 'Los de siempre',
          colorHex: 0xFFFFC93C,
          miembros: const <String>['tu'],
          codigo: 'CROC12',
        ),
      ];

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: contenedor,
          child: const MaterialApp(home: Scaffold(body: MesasPage())),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      return tester.getSize(find.text(nombre).first).height;
    }

    testWidgets('un nombre de mesa larguísimo no crece a varias líneas', (
      WidgetTester tester,
    ) async {
      final double corto = await altoDelNombre(tester, 'Los de siempre');
      final double largo = await altoDelNombre(
        tester,
        'Los que quedamos los jueves para probar croquetas por Triana',
      );

      expect(largo, corto, reason: 'el nombre de la mesa tiene que recortarse');
    });
  });

  group('En La Vitrina', () {
    testWidgets('el feed con catas largas no se desborda', (
      WidgetTester tester,
    ) async {
      await montar(
        tester,
        const VitrinaPage(),
        catas: <Cata>[
          for (int i = 0; i < 4; i++)
            Cata(
              id: 'larga-$i',
              sitio: sitioLargo,
              ciudad: 'Santiago de Compostela',
              corte:
                  const Corte(crujiente: 9, cremosidad: 8, sabor: 9, relleno: 7),
              sabores: const <Sabor>[Sabor(rellenoId: 'boletus')],
              autorId: 'tu',
              mesaId: 'libreta',
              fecha: DateTime(2026, 3, 14),
              nota: notaLarga,
            ),
        ],
      );

      expect(tester.takeException(), isNull);
    });
  });
}
