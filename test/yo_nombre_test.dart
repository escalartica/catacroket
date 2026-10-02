import 'package:catacroket/core/providers/yo_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// Cuándo hay un nombre de verdad que enseñar a los demás.
///
/// El de fábrica es «Tú»: se lee bien en tu propio móvil y es absurdo en el
/// de otro. Publicarlo llenaba la mesa de «Tú»; no publicar nada la llenaba
/// de «Alguien». Por eso se pregunta al entrar en una mesa.
void main() {
  test('el nombre de fábrica no cuenta como nombre propio', () {
    expect(const Yo().tieneNombrePropio, isFalse);
    expect(const Yo(nombre: 'Tú').tieneNombrePropio, isFalse);
  });

  test('un nombre vacío o de espacios tampoco', () {
    expect(const Yo(nombre: '').tieneNombrePropio, isFalse);
    expect(const Yo(nombre: '   ').tieneNombrePropio, isFalse);
  });

  test('un nombre elegido sí', () {
    expect(const Yo(nombre: 'Eme').tieneNombrePropio, isTrue);
    expect(const Yo(nombre: 'Cehache').tieneNombrePropio, isTrue);
  });

  test('«Tú» con espacios alrededor sigue siendo el de fábrica', () {
    expect(const Yo(nombre: '  Tú  ').tieneNombrePropio, isFalse);
  });
}
