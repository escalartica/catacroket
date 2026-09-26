import 'package:catacroket/core/models/cata.dart';
import 'package:catacroket/core/models/corte.dart';
import 'package:catacroket/core/models/sabor.dart';
import 'package:catacroket/core/providers/nube_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// Juntar lo tuyo con lo de tu gente.
///
/// Es la parte donde se pierden datos si se hace mal, así que va probada
/// aparte de cualquier pantalla.
void main() {
  Cata cata(String id, {String sitio = 'Bar', DateTime? cuando}) => Cata(
        id: id,
        sitio: sitio,
        ciudad: 'Sevilla',
        corte: const Corte(crujiente: 7, cremosidad: 7, sabor: 7, relleno: 7),
        sabores: const <Sabor>[Sabor(rellenoId: 'jamon')],
        autorId: 'quien-sea',
        mesaId: 'mesa',
        fecha: cuando ?? DateTime(2026, 3, 14),
      );

  test('sin nada de otros, el feed es el tuyo tal cual', () {
    final List<Cata> mias = <Cata>[cata('a'), cata('b')];

    expect(juntarCatas(mias, const <Cata>[]).length, 2);
  });

  test('las de tu gente se suman a las tuyas', () {
    final List<Cata> juntas = juntarCatas(
      <Cata>[cata('mia')],
      <Cata>[cata('suya')],
    );

    expect(juntas.length, 2);
    expect(juntas.map((Cata c) => c.id), containsAll(<String>['mia', 'suya']));
  });

  test('una cata que está en los dos sitios no sale dos veces', () {
    final List<Cata> juntas = juntarCatas(
      <Cata>[cata('misma')],
      <Cata>[cata('misma')],
    );

    expect(juntas.length, 1);
  });

  test('si está en los dos sitios manda la del móvil', () {
    // Esto es lo que protege una corrección hecha sin cobertura: la copia
    // del servidor está vieja, y dejarla ganar borraría el cambio delante de
    // los ojos de quien acaba de hacerlo.
    final List<Cata> juntas = juntarCatas(
      <Cata>[cata('x', sitio: 'Bar Manoli corregido')],
      <Cata>[cata('x', sitio: 'Bar Manoli')],
    );

    expect(juntas.single.sitio, 'Bar Manoli corregido');
  });

  test('el feed sale de la más reciente a la más vieja', () {
    final List<Cata> juntas = juntarCatas(
      <Cata>[cata('vieja', cuando: DateTime(2026, 1, 1))],
      <Cata>[cata('nueva', cuando: DateTime(2026, 6, 1))],
    );

    expect(juntas.first.id, 'nueva');
    expect(juntas.last.id, 'vieja');
  });

  test('sin nada por ningún lado, lista vacía y no un fallo', () {
    expect(juntarCatas(const <Cata>[], const <Cata>[]), isEmpty);
  });
}
