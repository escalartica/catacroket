import 'dart:math' as math;

import 'package:catacroket/core/models/cata.dart';
import 'package:catacroket/core/models/corte.dart';
import 'package:catacroket/core/models/sabor.dart';
import 'package:catacroket/features/ruta/agrupacion.dart';
import 'package:flutter_test/flutter_test.dart';

Cata cata({
  required String id,
  double? lat,
  double? lon,
  int crujiente = 7,
}) =>
    Cata(
      id: id,
      sitio: 'Bar $id',
      ciudad: 'Sevilla',
      corte: Corte(crujiente: crujiente, cremosidad: 7, sabor: 7, relleno: 7),
      sabores: const <Sabor>[Sabor(rellenoId: 'jamon')],
      autorId: 'tu',
      mesaId: 'libreta',
      fecha: DateTime(2026),
      lat: lat,
      lon: lon,
    );

void main() {
  group('agruparCatas', () {
    test('dos bares en la misma esquina van juntos con el mapa alejado', () {
      // Cuarenta metros de separación, vistos desde el zoom de una ciudad.
      final List<Grupo> grupos = agruparCatas(
        <Cata>[
          cata(id: 'a', lat: 37.3831, lon: -6.0055),
          cata(id: 'b', lat: 37.3834, lon: -6.0053),
        ],
        12,
      );

      expect(grupos, hasLength(1));
      expect(grupos.first.catas, hasLength(2));
      expect(grupos.first.esUna, isFalse);
    });

    test('esos mismos dos se separan al acercarse', () {
      final List<Cata> dos = <Cata>[
        cata(id: 'a', lat: 37.3831, lon: -6.0055),
        cata(id: 'b', lat: 37.3834, lon: -6.0053),
      ];

      expect(agruparCatas(dos, 12), hasLength(1));
      expect(agruparCatas(dos, 19), hasLength(2));
    });

    test('dos ciudades distintas nunca se juntan a zoom de calle', () {
      final List<Grupo> grupos = agruparCatas(
        <Cata>[
          cata(id: 'sevilla', lat: 37.3831, lon: -6.0055),
          cata(id: 'lisboa', lat: 38.7139, lon: -9.1334),
        ],
        13,
      );

      expect(grupos, hasLength(2));
      expect(grupos.every((Grupo g) => g.esUna), isTrue);
    });

    test('no se pierde ni se duplica ninguna cata', () {
      final List<Cata> muchas = <Cata>[
        for (int i = 0; i < 12; i++)
          cata(id: '$i', lat: 37.38 + i * 0.0004, lon: -6.00 + i * 0.0004),
      ];

      for (final double zoom in <double>[4, 8, 12, 15, 18]) {
        final List<Grupo> grupos = agruparCatas(muchas, zoom);
        final List<String> ids = <String>[
          for (final Grupo g in grupos) ...g.catas.map((Cata c) => c.id),
        ];
        expect(ids, hasLength(muchas.length), reason: 'al zoom $zoom');
        expect(ids.toSet(), hasLength(muchas.length), reason: 'al zoom $zoom');
      }
    });

    test('las catas sin punto no salen al mapa', () {
      final List<Grupo> grupos = agruparCatas(
        <Cata>[
          cata(id: 'con', lat: 37.38, lon: -6.0),
          cata(id: 'sin'),
        ],
        14,
      );

      expect(grupos, hasLength(1));
      expect(grupos.first.unica.id, 'con');
    });

    test('con la lista vacía devuelve vacío', () {
      expect(agruparCatas(<Cata>[], 14), isEmpty);
    });

    test('una sola cata es un grupo de una, en su sitio exacto', () {
      final List<Grupo> grupos =
          agruparCatas(<Cata>[cata(id: 'x', lat: 37.38, lon: -6.0)], 14);

      expect(grupos.single.esUna, isTrue);
      expect(grupos.single.lat, 37.38);
      expect(grupos.single.lon, -6.0);
    });

    test('el grupo enseña la mejor nota de las suyas', () {
      final List<Grupo> grupos = agruparCatas(
        <Cata>[
          cata(id: 'floja', lat: 37.3831, lon: -6.0055, crujiente: 2),
          cata(id: 'buena', lat: 37.3832, lon: -6.0054, crujiente: 10),
        ],
        12,
      );

      expect(grupos.single.catas, hasLength(2));
      expect(
        grupos.single.mejorNota,
        grupos.single.catas
            .map((Cata c) => c.puntuacion)
            .reduce((double a, double b) => a > b ? a : b),
      );
    });

    test('el resultado no depende del orden de la lista', () {
      final List<Cata> catas = <Cata>[
        cata(id: 'a', lat: 37.3831, lon: -6.0055),
        cata(id: 'b', lat: 37.3832, lon: -6.0054),
        cata(id: 'c', lat: 37.4000, lon: -5.9800),
      ];

      List<int> tamanos(List<Cata> orden) =>
          agruparCatas(orden, 13).map((Grupo g) => g.catas.length).toList()
            ..sort();

      expect(tamanos(catas), tamanos(catas.reversed.toList()));
    });

    test('ningún par de marcadores acaba pisándose', () {
      // Ésta es LA garantía: la rejilla sola dejaba pasar dos grupos a ambos
      // lados de una linde, y en pantalla se solapaban igual. Si esto falla,
      // vuelven los números en muñones.
      const double radio = 104;
      final List<Cata> muchas = <Cata>[
        for (int i = 0; i < 25; i++)
          cata(
            id: '$i',
            lat: 37.37 + (i % 5) * 0.0025,
            lon: -6.01 + (i ~/ 5) * 0.0025,
          ),
      ];

      for (final double zoom in <double>[10, 12, 13, 14, 15, 16, 17]) {
        final List<Grupo> grupos = agruparCatas(muchas, zoom, radioPx: radio);
        final double mundo = 256 * math.pow(2, zoom).toDouble();

        for (int i = 0; i < grupos.length; i++) {
          for (int j = i + 1; j < grupos.length; j++) {
            expect(
              _pixelesEntre(grupos[i], grupos[j], mundo),
              greaterThanOrEqualTo(radio),
              reason: 'al zoom $zoom, dos marcadores se solapan',
            );
          }
        }
      }
    });

    test('fundir dos no deja un tercero pisando al resultado', () {
      // Tres en fila, cada uno cerca del siguiente pero no del último: al
      // fundir los dos primeros, el centro se mueve hacia el tercero.
      final List<Cata> tres = <Cata>[
        cata(id: 'a', lat: 37.3800, lon: -6.0000),
        cata(id: 'b', lat: 37.3803, lon: -6.0000),
        cata(id: 'c', lat: 37.3806, lon: -6.0000),
      ];

      const double radio = 104;
      const double zoom = 15;
      final List<Grupo> grupos = agruparCatas(tres, zoom, radioPx: radio);
      final double mundo = 256 * math.pow(2, zoom).toDouble();

      for (int i = 0; i < grupos.length; i++) {
        for (int j = i + 1; j < grupos.length; j++) {
          expect(
            _pixelesEntre(grupos[i], grupos[j], mundo),
            greaterThanOrEqualTo(radio),
          );
        }
      }
    });

    test('el centro del grupo cae entre sus catas, no fuera', () {
      final List<Grupo> grupos = agruparCatas(
        <Cata>[
          cata(id: 'a', lat: 37.3830, lon: -6.0060),
          cata(id: 'b', lat: 37.3834, lon: -6.0050),
        ],
        12,
      );

      final Grupo g = grupos.single;
      expect(g.lat, greaterThanOrEqualTo(37.3830));
      expect(g.lat, lessThanOrEqualTo(37.3834));
      expect(g.lon, greaterThanOrEqualTo(-6.0060));
      expect(g.lon, lessThanOrEqualTo(-6.0050));
    });
  });
}

/// Píxeles entre los centros de dos grupos, como los ve el mapa.
double _pixelesEntre(Grupo a, Grupo b, double mundo) {
  (double, double) aMundo(double lat, double lon) {
    final double x = (lon + 180) / 360 * mundo;
    final double s = math.sin(lat * math.pi / 180).clamp(-0.9999, 0.9999);
    final double y =
        (0.5 - math.log((1 + s) / (1 - s)) / (4 * math.pi)) * mundo;
    return (x, y);
  }

  final (double ax, double ay) = aMundo(a.lat, a.lon);
  final (double bx, double by) = aMundo(b.lat, b.lon);
  return math.sqrt(math.pow(ax - bx, 2) + math.pow(ay - by, 2));
}
