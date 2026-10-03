import 'package:catacroket/core/models/cata.dart';
import 'package:catacroket/core/models/corte.dart';
import 'package:catacroket/core/models/sabor.dart';
import 'package:catacroket/core/providers/nube_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// Una cata ya no vive en un sitio: vive en tu diario y se enseña donde tú
/// quieras.
///
/// Lo que había antes obligaba a elegir entre guardar la croqueta para ti o
/// enseñarla, y la gente apuntaba la cata, se iba a la libreta y su mesa no
/// la veía nunca.
Cata _cata({
  String id = 'c1',
  List<String> mesas = const <String>[],
  String? autorUid,
  DateTime? fecha,
}) =>
    Cata(
      id: id,
      sitio: 'Bar',
      ciudad: 'Sevilla',
      corte: const Corte.media(),
      sabores: const <Sabor>[Sabor(rellenoId: 'jamon')],
      autorId: 'tu',
      autorUid: autorUid,
      mesas: mesas,
      fecha: fecha ?? DateTime(2026),
    );

void main() {
  group('en qué mesas está', () {
    test('sin mesas, sólo la ves tú', () {
      final Cata c = _cata();
      expect(c.esSoloMia, isTrue);
      expect(c.estaEn('m1'), isFalse);
    });

    test('puede estar en varias a la vez', () {
      final Cata c = _cata(mesas: <String>['m1', 'm2']);
      expect(c.esSoloMia, isFalse);
      expect(c.estaEn('m1'), isTrue);
      expect(c.estaEn('m2'), isTrue);
      expect(c.estaEn('m3'), isFalse);
    });

    test('al viajar a una mesa no lleva las otras', () {
      // En qué más mesas la tienes puesta es cosa tuya: la gente de ésta no
      // tiene por qué enterarse.
      final Cata c = _cata(mesas: <String>['m1', 'secreta']);
      expect(c.soloEnLaMesa('m1').mesas, <String>['m1']);
    });
  });

  group('leer lo guardado antes', () {
    Map<String, dynamic> base(Map<String, dynamic> extra) => <String, dynamic>{
          'id': 'c1',
          'sitio': 'Bar',
          'ciudad': 'Sevilla',
          'corte': const Corte.media().toJson(),
          'sabores': <Map<String, dynamic>>[
            const Sabor(rellenoId: 'jamon').toJson(),
          ],
          'autorId': 'tu',
          'fecha': DateTime(2026).toIso8601String(),
          ...extra,
        };

    test('lo que estaba en la libreta pasa a no estar en ninguna mesa', () {
      expect(Cata.fromJson(base(<String, dynamic>{'mesaId': 'libreta'})).mesas,
          isEmpty);
    });

    test('lo que estaba en una mesa se queda en esa', () {
      expect(
        Cata.fromJson(base(<String, dynamic>{'mesaId': 'cunados'})).mesas,
        <String>['cunados'],
      );
    });

    test('sin nada apuntado, sólo tuya', () {
      expect(Cata.fromJson(base(<String, dynamic>{})).mesas, isEmpty);
    });

    test('el formato nuevo manda sobre el viejo', () {
      expect(
        Cata.fromJson(base(<String, dynamic>{
          'mesaId': 'cunados',
          'mesas': <String>['a', 'b'],
        })).mesas,
        <String>['a', 'b'],
      );
    });

    test('«libreta» colada en la lista nueva no cuenta como mesa', () {
      expect(
        Cata.fromJson(base(<String, dynamic>{
          'mesas': <String>['libreta', 'a'],
        })).mesas,
        <String>['a'],
      );
    });

    test('ida y vuelta por el guardado', () {
      final Cata c = _cata(mesas: <String>['a', 'b']);
      expect(Cata.fromJson(c.toJson()).mesas, <String>['a', 'b']);
    });
  });

  group('juntar lo tuyo con lo de tu gente', () {
    test('la misma cata por dos mesas se queda en las dos', () {
      // Si estás en dos mesas donde la misma persona puso la misma croqueta,
      // cada copia llega diciendo que está sólo en la suya. Quedándose con
      // la última, desaparecía de la otra sin motivo.
      final List<Cata> juntas = juntarCatas(
        const <Cata>[],
        <Cata>[
          _cata(autorUid: 'otra', mesas: <String>['m1']),
          _cata(autorUid: 'otra', mesas: <String>['m2']),
        ],
      );

      expect(juntas, hasLength(1));
      expect(juntas.single.mesas, containsAll(<String>['m1', 'm2']));
    });

    test('la tuya manda sobre la copia del servidor', () {
      final List<Cata> juntas = juntarCatas(
        <Cata>[_cata(mesas: <String>['m1', 'm2'])],
        <Cata>[_cata(mesas: <String>['m1'])],
      );

      expect(juntas.single.mesas, <String>['m1', 'm2']);
    });
  });
}
