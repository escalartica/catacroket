import 'package:catacroket/core/models/cata.dart';
import 'package:catacroket/core/models/corte.dart';
import 'package:catacroket/core/models/recuento.dart';
import 'package:catacroket/core/models/sabor.dart';
import 'package:flutter_test/flutter_test.dart';

/// Cuántas croquetas de cada clase.
void main() {
  Cata cata(List<String> rellenos) => Cata(
        id: 'c${rellenos.join()}',
        sitio: 'Bar',
        ciudad: 'Sevilla',
        corte: const Corte(crujiente: 7, cremosidad: 7, sabor: 7, relleno: 7),
        sabores: <Sabor>[
          for (final String r in rellenos) Sabor(rellenoId: r),
        ],
        autorId: 'tu',
        mesas: const <String>[],
        fecha: DateTime(2026, 3, 14),
      );

  test('un surtido de seis son seis croquetas, no una', () {
    // Lo importante de contar sabores y no catas. Un surtido es UNA cata y
    // SEIS croquetas: contar catas diría que esa noche probaste una.
    final List<Recuento> r = Recuento.de(<Cata>[
      cata(<String>['jamon', 'calamar', 'pollo', 'bacalao', 'setas', 'queso']),
    ]);

    expect(r.length, 6);
    expect(r.fold<int>(0, (int s, Recuento x) => s + x.cuantas), 6);
  });

  test('manda la más catada', () {
    final List<Recuento> r = Recuento.de(<Cata>[
      cata(<String>['jamon']),
      cata(<String>['jamon']),
      cata(<String>['calamar']),
    ]);

    expect(r.first.rellenoId, 'jamon');
    expect(r.first.cuantas, 2);
  });

  test('con empate el orden no baila entre dos aperturas', () {
    // Sin desempate por nombre, dos pantallas seguidas podrían enseñar el
    // mismo empate en distinto orden y parecer que algo cambió.
    final List<Cata> mismas = <Cata>[
      cata(<String>['jamon']),
      cata(<String>['calamar']),
    ];

    final List<String> una =
        Recuento.de(mismas).map((Recuento r) => r.rellenoId).toList();
    final List<String> otra =
        Recuento.de(mismas.reversed).map((Recuento r) => r.rellenoId).toList();

    expect(una, otra);
  });

  test('una croqueta de dos cosas cuenta una vez, no dos', () {
    // Si sumara a los dos rellenos, el total no cuadraría con las croquetas
    // que de verdad os comisteis.
    final List<Recuento> r = Recuento.de(<Cata>[
      cata(<String>['jamon']),
    ]);

    expect(r.fold<int>(0, (int s, Recuento x) => s + x.cuantas), 1);
  });

  test('sin catas no hay recuento', () {
    expect(Recuento.de(const <Cata>[]), isEmpty);
  });
}
