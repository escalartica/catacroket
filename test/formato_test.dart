import 'package:catacroket/core/utils/formato.dart';
import 'package:flutter_test/flutter_test.dart';

/// Los textos de «hace cuánto».
///
/// No los probaba nadie y salen en cuatro pantallas. Se les pasa la hora a
/// mano: si no, cada test daría un resultado distinto según el día en que se
/// ejecutara.
void main() {
  group('Por debajo de un día se cuentan horas', () {
    final DateTime ahora = DateTime(2026, 3, 14, 20, 0);

    String hace(Duration d) =>
        Formato.relativo(ahora.subtract(d), ahora: ahora);

    test('recién apuntada', () {
      expect(hace(const Duration(seconds: 30)), 'ahora mismo');
    });

    test('minutos', () {
      expect(hace(const Duration(minutes: 20)), 'hace 20 min');
    });

    test('una hora se dice en singular', () {
      expect(hace(const Duration(hours: 1, minutes: 5)), 'hace 1 hora');
    });

    test('varias horas', () {
      expect(hace(const Duration(hours: 5)), 'hace 5 horas');
    });

    test('una fecha en el futuro no dice «hace -3 horas»', () {
      // No debería pasar, pero un móvil con la hora mal o una copia restaurada
      // de otro sí lo provocan.
      expect(Formato.relativo(ahora.add(const Duration(hours: 3)),
          ahora: ahora), 'ahora mismo');
    });
  });

  group('De un día en adelante se cuentan días de calendario', () {
    test('ayer es el día de calendario anterior', () {
      expect(
        Formato.relativo(
          DateTime(2026, 3, 13, 9),
          ahora: DateTime(2026, 3, 14, 20),
        ),
        'ayer',
      );
    });

    test('veinticinco horas cruzando dos medianoches NO son «ayer»', () {
      // El fallo que arregla esto. El lunes a las once de la noche, visto el
      // miércoles a las doce y media, son veinticinco horas: contando horas
      // decía «ayer», y fue anteayer.
      expect(
        Formato.relativo(
          DateTime(2026, 3, 9, 23, 0),
          ahora: DateTime(2026, 3, 11, 0, 30),
        ),
        'hace 2 días',
      );
    });

    test('una semana justa es una semana, no seis días', () {
      // Con dos medianoches locales y un cambio de hora en medio, la resta da
      // seis días y veintitrés horas, y truncaba a seis.
      expect(
        Formato.relativo(
          DateTime(2026, 3, 22, 12),
          ahora: DateTime(2026, 3, 29, 12),
        ),
        'hace 1 semana',
      );
    });

    test('semanas', () {
      expect(
        Formato.relativo(
          DateTime(2026, 2, 28, 12),
          ahora: DateTime(2026, 3, 21, 12),
        ),
        'hace 3 semanas',
      );
    });

    test('un mes', () {
      expect(
        Formato.relativo(
          DateTime(2026, 1, 20, 12),
          ahora: DateTime(2026, 3, 14, 12),
        ),
        'hace 1 mes',
      );
    });

    test('meses', () {
      expect(
        Formato.relativo(
          DateTime(2025, 9, 14, 12),
          ahora: DateTime(2026, 3, 14, 12),
        ),
        'hace 6 meses',
      );
    });

    test('más de un año se queda en viejo, sin precisar', () {
      expect(
        Formato.relativo(
          DateTime(2023, 3, 14, 12),
          ahora: DateTime(2026, 3, 14, 12),
        ),
        'hace más de un año',
      );
    });
  });

  group('Los números en español', () {
    test('la nota lleva coma, no punto', () {
      expect(Formato.nota(9.42), '9,4');
      expect(Formato.nota(10), '10,0');
    });

    test('el precio lleva coma y euro', () {
      expect(Formato.precio(2.2), '2,20 €');
    });

    test('el plural no dice «1 catas»', () {
      expect(Formato.plural(1, 'cata', 'catas'), '1 cata');
      expect(Formato.plural(0, 'cata', 'catas'), '0 catas');
      expect(Formato.plural(7, 'cata', 'catas'), '7 catas');
    });
  });
}
