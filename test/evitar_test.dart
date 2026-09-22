import 'package:catacroket/core/providers/evitar_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Evitar.normalizar', () {
    test('quita tildes y baja a minúsculas', () {
      expect(Evitar.normalizar('Jamón'), 'jamon');
      expect(Evitar.normalizar('  SÉSAMO  '), 'sesamo');
      expect(Evitar.normalizar('Champiñón'), 'champinon');
    });
  });

  group('Evitar.coincidencias', () {
    test('sin lista no avisa de nada', () {
      expect(Evitar.coincidencias(const <String>{}, <String>['Jamón']), isEmpty);
    });

    test('encuentra aunque cambien tildes y mayúsculas', () {
      expect(
        Evitar.coincidencias(const <String>{'jamon'}, <String>['Jamón ibérico']),
        <String>['jamon'],
      );
    });

    test('devuelve la palabra tal y como la escribió el usuario', () {
      expect(
        Evitar.coincidencias(const <String>{'Boletus'}, <String>['boletus edulis']),
        <String>['Boletus'],
      );
    });

    test('no confunde un relleno con otro', () {
      expect(
        Evitar.coincidencias(const <String>{'marisco'}, <String>['Espinacas', 'Queso']),
        isEmpty,
      );
    });

    test('con varios rellenos avisa de todos los que salen', () {
      expect(
        Evitar.coincidencias(
          const <String>{'gamba', 'cebolla'},
          <String>['Gambas al ajillo', 'Cebolla caramelizada'],
        ),
        <String>['gamba', 'cebolla'],
      );
    });

    test('una cata sin rellenos apuntados no dispara avisos', () {
      expect(Evitar.coincidencias(const <String>{'marisco'}, <String>[]), isEmpty);
      expect(Evitar.coincidencias(const <String>{'marisco'}, <String>['', '  ']), isEmpty);
    });
  });
}
