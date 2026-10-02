import 'dart:math';

import 'package:catacroket/core/models/mesa.dart';
import 'package:flutter_test/flutter_test.dart';

/// El código de invitación de una mesa.
///
/// Es lo único que permite a otra persona entrar en tu mesa, así que tiene
/// dos trabajos: ser dictable en voz alta en un bar con ruido, y llegar
/// hasta la pantalla de quien comparte. Lo segundo estuvo roto: `copyWith`
/// no aceptaba `codigo`, así que la mesa recién compartida se quedaba sin
/// él y la pantalla enseñaba «MESA COMPARTIDA · null».
void main() {
  const Mesa mesa = Mesa(
    id: 'm1',
    nombre: 'Los del jueves',
    descripcion: '',
    colorHex: 0xFFFFC93C,
    miembros: <String>['tu'],
  );

  group('guardar el código', () {
    test('copyWith lo guarda cuando la mesa no tenía', () {
      expect(mesa.codigo, isNull);
      expect(mesa.copyWith(codigo: 'ABC234').codigo, 'ABC234');
    });

    test('copyWith lo conserva cuando no se le pasa otro', () {
      final Mesa compartida = mesa.copyWith(codigo: 'ABC234');
      expect(compartida.copyWith(nombre: 'Otro nombre').codigo, 'ABC234');
    });

    test('marcar la mesa como subida no le borra el código', () {
      // Es la secuencia exacta que hace el provider al compartir.
      final Mesa compartida =
          mesa.copyWith(enLaNube: true, codigo: 'XK47PQ');
      expect(compartida.enLaNube, isTrue);
      expect(compartida.codigo, 'XK47PQ');
    });
  });

  group('cómo se genera', () {
    test('son seis caracteres del alfabeto permitido', () {
      for (int i = 0; i < 200; i++) {
        final String codigo = Mesa.nuevoCodigo();
        expect(codigo.length, 6);
        for (final String letra in codigo.split('')) {
          expect(Mesa.alfabetoCodigo, contains(letra));
        }
      }
    });

    test('no usa letras que se confunden al dictarlas', () {
      // Una I que alguien oye como L es una mesa a la que no entras.
      for (final String confusa in <String>['I', 'L', 'O', '0', '1']) {
        expect(Mesa.alfabetoCodigo, isNot(contains(confusa)));
      }
    });

    test('acepta un azar propio, que es lo que usan los tests', () {
      expect(Mesa.nuevoCodigo(Random(7)), Mesa.nuevoCodigo(Random(7)));
    });

    test('dos códigos seguidos no salen iguales', () {
      final Set<String> vistos = <String>{
        for (int i = 0; i < 500; i++) Mesa.nuevoCodigo(),
      };
      // Con 887 millones de combinaciones, 500 repetidos serían un generador
      // roto, no mala suerte.
      expect(vistos.length, 500);
    });
  });
}
