import 'package:catacroket/core/capturas.dart';
import 'package:catacroket/core/data/siembra.dart';
import 'package:catacroket/core/models/cata.dart';
import 'package:catacroket/core/models/mesa.dart';
import 'package:catacroket/core/models/persona.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lo que se publica en la tienda tiene que salir vacío.
///
/// Esto no es una comprobación de diseño: alguien que se baja la app no puede
/// encontrarse croquetas que no ha comido ni mesas con gente que no conoce.
void main() {
  group('la app publicada arranca vacía', () {
    test('sin ninguna cata', () {
      expect(Siembra.catasCon(false), isEmpty);
    });

    test('sin recuerdos de mesas ajenas', () {
      expect(Siembra.recuerdosCon(false), isEmpty);
    });

    test('con una sola mesa, y es la libreta', () {
      final List<Mesa> mesas = Siembra.mesasCon(false);
      expect(mesas, hasLength(1));
      expect(mesas.single.esLibreta, isTrue);
    });

    test('en la libreta no hay nadie más que tú', () {
      expect(Siembra.libreta.miembros, hasLength(1));
    });

    test('ninguna mesa trae código de invitación de otro grupo', () {
      // Un código suelto dejaría al usuario dentro de una mesa que no es suya.
      for (final Mesa m in Siembra.mesasCon(false)) {
        expect(m.codigo, anyOf(isNull, isEmpty), reason: 'mesa ${m.nombre}');
      }
    });

    test('sin gente inventada: sólo tú', () {
      final List<Persona> gente = Siembra.personasCon(false);
      expect(gente, hasLength(1));
      expect(gente.single.id, Siembra.libreta.miembros.single);
    });
  });

  group('en desarrollo sí hay con qué trabajar', () {
    test('hay catas de ejemplo', () {
      expect(Siembra.catasCon(true), isNotEmpty);
      expect(Siembra.catasCon(true), everyElement(isA<Cata>()));
    });

    test('hay más de una mesa', () {
      expect(Siembra.mesasCon(true).length, greaterThan(1));
    });
  });

  group('El modo capturas', () {
    test('apagado si nadie lo pide', () {
      // Lo importante de todo este fichero: que nadie se baje la app y se
      // encuentre dieciocho croquetas que no ha comido. El interruptor nuevo
      // no puede abrir esa puerta por descuido, y hay que escribirlo entero
      // en la línea de órdenes para encenderlo.
      expect(paraCapturas, isFalse);
    });

    test('encendido, hay con qué llenar una captura', () {
      expect(Siembra.catasCon(true), isNotEmpty);
      expect(Siembra.mesasCon(true).length, greaterThan(1));
    });
  });

  test('las dos ramas no comparten la libreta por accidente', () {
    // Misma id en las dos, que es lo que permite que una app que ya tenía
    // datos de ejemplo no se quede sin libreta al actualizar.
    expect(
      Siembra.mesasCon(true).firstWhere((Mesa m) => m.esLibreta).id,
      Siembra.libreta.id,
    );
  });
}
