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

  group('Los cambios de hora no mueven la semana', () {
    // Una `Duration` son horas absolutas, no días de calendario. Restar siete
    // días a un lunes a medianoche cruzando un cambio de hora daba las 23:00
    // del domingo anterior, y la semana entera se corría una hora: una cata
    // apuntada un domingo por la noche pasaba a contar en la semana
    // siguiente, y la racha aparecía rota.
    //
    // Este test recorre dos años enteros. En un huso sin cambio de hora no
    // encontraría nada, y eso está bien: no prueba menos de lo que hay.

    test('todo lunes calculado cae a las cero horas de un lunes', () {
      final List<String> desviados = <String>[];

      for (DateTime d = DateTime(2025, 1, 1, 12);
          d.isBefore(DateTime(2027, 1, 1));
          d = DateTime(d.year, d.month, d.day + 1, 12)) {
        final DateTime lunes = Semanas.lunesDe(d);
        if (lunes.hour != 0 || lunes.weekday != DateTime.monday) {
          desviados.add('${d.toIso8601String()} -> ${lunes.toIso8601String()}');
        }

        for (int s = 1; s <= 8; s++) {
          final DateTime atras = Semanas.diasAntes(lunes, 7 * s);
          if (atras.hour != 0 || atras.weekday != DateTime.monday) {
            desviados.add('$s sem antes de $lunes -> $atras');
          }
        }
      }

      expect(
        desviados,
        isEmpty,
        reason: 'con `subtract(Duration(...))` salían 1008 desviados en estos '
            'mismos dos años. Primeros: ${desviados.take(3).toList()}',
      );
    });

    test('una cata del domingo por la noche cuenta en su semana', () {
      // El domingo 30 de marzo de 2025 fue el cambio de hora de primavera en
      // España. Una cata a las once y media de esa noche es de esa semana, no
      // de la siguiente, y la racha tiene que verlo así.
      final DateTime domingoTarde = DateTime(2025, 3, 30, 23, 30);
      final DateTime lunesSiguiente = DateTime(2025, 3, 31, 11);

      expect(
        Semanas.hayEn(<DateTime>[domingoTarde], Semanas.lunesDe(domingoTarde)),
        isTrue,
      );
      expect(
        Semanas.racha(<DateTime>[domingoTarde], hoy: lunesSiguiente),
        1,
        reason: 'catar el domingo mantiene viva la racha el lunes',
      );
    });

    test('la racha aguanta entera de un lado a otro del cambio', () {
      // Seis semanas seguidas catando, con el cambio de hora en medio.
      final DateTime hoy = DateTime(2025, 4, 21, 11);
      final List<DateTime> catas = <DateTime>[
        for (int s = 0; s < 6; s++)
          Semanas.diasAntes(Semanas.lunesDe(hoy), 7 * s).add(
            const Duration(days: 2, hours: 21),
          ),
      ];

      expect(Semanas.racha(catas, hoy: hoy), 6);
    });
  });

}
