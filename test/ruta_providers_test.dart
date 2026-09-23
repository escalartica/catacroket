import 'package:catacroket/core/data/datos_demo.dart';
import 'package:catacroket/core/models/cata.dart';
import 'package:catacroket/core/models/corte.dart';
import 'package:catacroket/core/models/dieta.dart';
import 'package:catacroket/core/models/sabor.dart';
import 'package:catacroket/core/providers/catas_provider.dart';
import 'package:catacroket/features/ruta/ruta_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Cata cata({
  required String id,
  String autorId = DatosDemo.yo,
  double? lat,
  double? lon,
  Set<Dieta> aptas = const <Dieta>{},
  int crujiente = 7,
}) =>
    Cata(
      id: id,
      sitio: 'Bar $id',
      ciudad: 'Sevilla',
      corte: Corte(crujiente: crujiente, cremosidad: 7, sabor: 7, relleno: 7),
      sabores: const <Sabor>[Sabor(rellenoId: 'jamon')],
      autorId: autorId,
      mesaId: 'libreta',
      fecha: DateTime(2026),
      lat: lat,
      lon: lon,
      aptas: aptas,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('filtrarRuta', () {
    final Cata mia = cata(id: 'mia');
    final Cata ajena = cata(id: 'ajena', autorId: 'otra-persona');
    final Cata apta = cata(id: 'apta', aptas: <Dieta>{Dieta.vegana});
    final List<Cata> todas = <Cata>[mia, ajena, apta];

    test('"todas" no quita nada', () {
      expect(filtrarRuta(todas, FiltroRuta.todas), todas);
    });

    test('"mías" deja sólo las tuyas', () {
      final List<Cata> salen = filtrarRuta(todas, FiltroRuta.mias);
      expect(salen.every((Cata c) => c.autorId == DatosDemo.yo), isTrue);
      expect(salen.map((Cata c) => c.id), isNot(contains('ajena')));
    });

    test('"barra libre" deja sólo las que valen para alguna dieta', () {
      final List<Cata> salen = filtrarRuta(todas, FiltroRuta.libres);
      expect(salen.map((Cata c) => c.id), contains('apta'));
      expect(salen.every((Cata c) => c.tieneDietas), isTrue);
    });

    test('con la lista vacía cualquier filtro devuelve vacío', () {
      for (final FiltroRuta f in FiltroRuta.values) {
        expect(filtrarRuta(<Cata>[], f), isEmpty);
      }
    });
  });

  group('grupoMayoritario', () {
    Cata en(String ciudad, {String id = 'x', DateTime? fecha}) => Cata(
          id: id,
          sitio: 'Bar $id',
          ciudad: ciudad,
          corte: const Corte(crujiente: 7, cremosidad: 7, sabor: 7, relleno: 7),
          sabores: const <Sabor>[Sabor(rellenoId: 'jamon')],
          autorId: DatosDemo.yo,
          mesaId: 'libreta',
          fecha: fecha ?? DateTime(2026),
          lat: 37.0,
          lon: -5.0,
        );

    test('devuelve el grupo de la ciudad con más catas', () {
      final List<Cata> todas = <Cata>[
        en('Sevilla', id: 's1'),
        en('Sevilla', id: 's2'),
        en('Sevilla', id: 's3'),
        en('Buenos Aires', id: 'ba'),
      ];

      final List<Cata> grupo = grupoMayoritario(todas);

      expect(grupo, hasLength(3));
      expect(grupo.every((Cata c) => c.ciudad == 'Sevilla'), isTrue);
    });

    test('la cata lejana no arrastra el encuadre', () {
      // El caso que motivó todo esto: una sola cata en otro continente hacía
      // que el mapa abriera enseñando el Atlántico.
      final List<Cata> todas = <Cata>[
        en('Sevilla', id: 's1'),
        en('Sevilla', id: 's2'),
        en('Buenos Aires', id: 'ba'),
      ];

      expect(
        grupoMayoritario(todas).map((Cata c) => c.id),
        isNot(contains('ba')),
      );
    });

    test('en empate manda donde has catado más recientemente', () {
      final List<Cata> todas = <Cata>[
        en('Sevilla', id: 's1', fecha: DateTime(2024)),
        en('Sevilla', id: 's2', fecha: DateTime(2024, 2)),
        en('Lisboa', id: 'l1', fecha: DateTime(2026)),
        en('Lisboa', id: 'l2', fecha: DateTime(2026, 2)),
      ];

      final List<Cata> grupo = grupoMayoritario(todas);

      expect(grupo.every((Cata c) => c.ciudad == 'Lisboa'), isTrue);
    });

    test('con una sola cata la devuelve tal cual', () {
      final List<Cata> una = <Cata>[en('Sevilla')];
      expect(grupoMayoritario(una), una);
    });

    test('con la lista vacía no revienta', () {
      expect(grupoMayoritario(<Cata>[]), isEmpty);
    });

    test('si todas son de la misma ciudad no quita ninguna', () {
      final List<Cata> todas = <Cata>[
        en('Sevilla', id: 'a'),
        en('Sevilla', id: 'b'),
      ];
      expect(grupoMayoritario(todas), hasLength(2));
    });
  });

  group('Providers derivados de la ruta', () {
    late ProviderContainer contenedor;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      contenedor = ProviderContainer();
      await Future<void>.delayed(Duration.zero);
      await contenedor.read(catasProvider.notifier).restablecer();
    });

    tearDown(() => contenedor.dispose());

    test('al mapa sólo llegan las catas con punto', () async {
      await contenedor
          .read(catasProvider.notifier)
          .anadir(cata(id: 'con-sitio', lat: 37.38, lon: -5.99));
      await contenedor
          .read(catasProvider.notifier)
          .anadir(cata(id: 'sin-sitio'));

      final List<Cata> conSitio = contenedor.read(catasConSitioProvider);

      expect(conSitio.every((Cata c) => c.tieneUbicacion), isTrue);
      expect(conSitio.map((Cata c) => c.id), contains('con-sitio'));
      expect(conSitio.map((Cata c) => c.id), isNot(contains('sin-sitio')));
    });

    test('las que se quedan fuera se cuentan, no se esconden', () async {
      await contenedor
          .read(catasProvider.notifier)
          .anadir(cata(id: 'sin-sitio'));

      final int total = contenedor.read(catasProvider).length;
      final int conSitio = contenedor.read(catasConSitioProvider).length;
      final int sinSitio = contenedor.read(catasSinSitioProvider);

      expect(conSitio + sinSitio, total);
      expect(sinSitio, greaterThan(0));
    });

    test('la hoja va de mejor a peor nota', () async {
      await contenedor
          .read(catasProvider.notifier)
          .anadir(cata(id: 'floja', lat: 37.0, lon: -5.0, crujiente: 1));
      await contenedor
          .read(catasProvider.notifier)
          .anadir(cata(id: 'buena', lat: 37.1, lon: -5.1, crujiente: 10));

      final List<Cata> ordenadas = contenedor.read(catasRutaOrdenadasProvider);

      for (int i = 1; i < ordenadas.length; i++) {
        expect(
          ordenadas[i - 1].puntuacion,
          greaterThanOrEqualTo(ordenadas[i].puntuacion),
        );
      }
      expect(
        ordenadas.indexWhere((Cata c) => c.id == 'buena'),
        lessThan(ordenadas.indexWhere((Cata c) => c.id == 'floja')),
      );
    });

    test('ordenar no revuelve la lista de la que sale', () async {
      await contenedor
          .read(catasProvider.notifier)
          .anadir(cata(id: 'x', lat: 37.0, lon: -5.0, crujiente: 1));
      await contenedor
          .read(catasProvider.notifier)
          .anadir(cata(id: 'y', lat: 37.1, lon: -5.1, crujiente: 10));

      final List<Cata> visibles = contenedor.read(catasVisiblesProvider);
      final List<String> antes = visibles.map((Cata c) => c.id).toList();

      contenedor.read(catasRutaOrdenadasProvider);

      expect(visibles.map((Cata c) => c.id).toList(), antes);
    });

    test('cambiar el filtro cambia lo que se ve', () async {
      await contenedor
          .read(catasProvider.notifier)
          .anadir(cata(id: 'ajena', autorId: 'otra', lat: 37.0, lon: -5.0));

      contenedor.read(filtroRutaProvider.notifier).state = FiltroRuta.mias;
      final List<Cata> mias = contenedor.read(catasVisiblesProvider);

      expect(mias.every((Cata c) => c.autorId == DatosDemo.yo), isTrue);
      expect(mias.map((Cata c) => c.id), isNot(contains('ajena')));
    });

    test('el resumen cuenta ciudades y países sin repetir', () async {
      final List<Cata> conSitio = contenedor.read(catasConSitioProvider);
      final ResumenRuta resumen = contenedor.read(resumenRutaProvider);

      expect(
        resumen.ciudades,
        conSitio
            .map((Cata c) => c.ciudad)
            .where((String c) => c.isNotEmpty)
            .toSet()
            .length,
      );
      expect(
        resumen.paises,
        conSitio.map((Cata c) => c.pais).toSet().length,
      );
      expect(resumen.ciudades, lessThanOrEqualTo(conSitio.length));
    });
  });
}
