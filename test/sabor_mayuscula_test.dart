import 'package:catacroket/core/models/sabor.dart';
import 'package:flutter_test/flutter_test.dart';

/// Cómo se escribe el nombre de lo que lleva una croqueta.
///
/// Los rellenos de la lista vienen ya capitalizados; los que escribe la gente
/// a mano, no. Sin esto, en la misma pantalla convivían «Jamón ibérico» y
/// «cecina», y parecía un fallo.
void main() {
  test('un relleno escrito a mano empieza en mayúscula', () {
    const Sabor s = Sabor(rellenoId: 'otro', propio: 'cecina');
    expect(s.nombre, 'Cecina');
  });

  test('ya en mayúscula se queda como está', () {
    const Sabor s = Sabor(rellenoId: 'otro', propio: 'Cecina');
    expect(s.nombre, 'Cecina');
  });

  test('dentro de la frase los demás siguen en minúscula', () {
    // «Jamón ibérico y Cecina» estaría mal escrito en castellano.
    const Sabor s = Sabor(
      rellenoId: 'jamon',
      otros: <String>['otro'],
      propio: 'cecina',
    );
    expect(s.nombre, contains(' y cecina'));
    expect(s.nombre.substring(0, 1), s.nombre.substring(0, 1).toUpperCase());
  });

  test('un nombre vacío no revienta', () {
    const Sabor s = Sabor(rellenoId: 'otro', propio: '');
    expect(() => s.nombre, returnsNormally);
  });
}
