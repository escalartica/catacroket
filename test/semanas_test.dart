import 'package:catacroket/core/models/semanas.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Lunes 21 de septiembre de 2026, a media mañana. Fijo a propósito: el
  // fallo que se arregla aquí sólo aparecía los lunes.
  final DateTime lunes = DateTime(2026, 9, 21, 11);
  DateTime haceSemanas(int n, {int dias = 0}) =>
      lunes.subtract(Duration(days: 7 * n - dias));

  group('racha', () {
    test('sin catas no hay racha', () {
      expect(Semanas.racha(const <DateTime>[], hoy: lunes), 0);
    });

    test('catando esta semana cuenta esta semana', () {
      expect(Semanas.racha(<DateTime>[lunes], hoy: lunes), 1);
    });

    test('un lunes sin catar todavía NO borra la racha', () {
      // Tres semanas seguidas catando y hoy, lunes, aún no ha catado.
      // Antes esto devolvía 0 y el usuario veía su racha apagada de golpe.
      final List<DateTime> tres = <DateTime>[
        haceSemanas(1),
        haceSemanas(2),
        haceSemanas(3),
      ];
      expect(Semanas.racha(tres, hoy: lunes), 3);
    });

    test('la semana en curso suma encima de las anteriores', () {
      expect(
        Semanas.racha(
          <DateTime>[lunes, haceSemanas(1), haceSemanas(2), haceSemanas(3)],
          hoy: lunes,
        ),
        4,
      );
    });

    test('se corta en el primer hueco', () {
      expect(
        Semanas.racha(
          <DateTime>[lunes, haceSemanas(1), haceSemanas(3)],
          hoy: lunes,
        ),
        2,
      );
    });

    test('una semana entera sin catar sí la apaga', () {
      // Lo último fue hace dos semanas: ni esta ni la pasada tienen nada.
      expect(Semanas.racha(<DateTime>[haceSemanas(2)], hoy: lunes), 0);
    });

    test('varias catas en la misma semana cuentan como una', () {
      expect(
        Semanas.racha(
          <DateTime>[lunes, lunes.add(const Duration(days: 2))],
          hoy: lunes,
        ),
        1,
      );
    });
  });

  group('últimas semanas', () {
    test('siete casillas, de la más vieja a la de hoy', () {
      final List<bool> h = Semanas.ultimas(<DateTime>[lunes], hoy: lunes);
      expect(h.length, 7);
      expect(h.last, isTrue);
      expect(h.sublist(0, 6), everyElement(isFalse));
    });

    test('enseña los huecos en vez de disimularlos', () {
      expect(
        Semanas.ultimas(
          <DateTime>[lunes, haceSemanas(1), haceSemanas(3)],
          hoy: lunes,
        ),
        <bool>[false, false, false, true, false, true, true],
      );
    });

    test('con racha larga no se sale de las siete', () {
      final List<DateTime> muchas = <DateTime>[
        for (int i = 0; i < 20; i++) haceSemanas(i),
      ];
      expect(Semanas.ultimas(muchas, hoy: lunes), everyElement(isTrue));
      expect(Semanas.racha(muchas, hoy: lunes), 20);
    });
  });

  test('el lunes de cualquier día de la semana es el mismo', () {
    final DateTime domingo = DateTime(2026, 9, 27, 23, 30);
    expect(Semanas.lunesDe(domingo), DateTime(2026, 9, 21));
    expect(Semanas.lunesDe(DateTime(2026, 9, 21, 0, 1)), DateTime(2026, 9, 21));
  });
}
