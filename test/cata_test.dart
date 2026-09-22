import 'package:catacroket/core/models/cata.dart';
import 'package:catacroket/core/models/corte.dart';
import 'package:catacroket/core/models/persona.dart';
import 'package:catacroket/core/models/racion.dart';
import 'package:catacroket/core/models/sabor.dart';
import 'package:flutter_test/flutter_test.dart';

Cata cata({
  List<Sabor> sabores = const <Sabor>[Sabor(rellenoId: 'jamon')],
  Formato formato = Formato.sinDecir,
  int unidades = 0,
  double? precio,
  List<String> acompanantes = const <String>[],
}) =>
    Cata(
      id: 'x',
      sitio: 'Bar',
      ciudad: 'Sevilla',
      corte: const Corte(crujiente: 7, cremosidad: 7, sabor: 7, relleno: 7),
      sabores: sabores,
      autorId: 'tu',
      mesaId: 'libreta',
      fecha: DateTime(2026),
      formato: formato,
      unidades: unidades,
      precio: precio,
      acompanantes: acompanantes,
    );

void main() {
  group('Cómo se llama un sabor', () {
    test('uno solo, su nombre', () {
      expect(const Sabor(rellenoId: 'jamon').nombre, 'Jamón ibérico');
    });

    test('dos, con "y"', () {
      expect(
        const Sabor(rellenoId: 'jamon', otros: <String>['boletus']).nombre,
        'Jamón ibérico y Boletus',
      );
    });

    test('tres, con comas y una "y" al final', () {
      expect(
        const Sabor(
          rellenoId: 'calabaza',
          otros: <String>['puerro', 'boletus'],
        ).nombre,
        'Calabaza asada, Puerro confitado y Boletus',
      );
    });

    test('lo escrito a mano se lee, y "A mi manera" desaparece', () {
      // "A mi manera y carrillada" no lo diría nadie.
      expect(
        const Sabor(rellenoId: 'otro', propio: 'Carrillada').nombre,
        'Carrillada',
      );
      expect(
        const Sabor(rellenoId: 'jamon', propio: 'Carrillada').nombre,
        'Jamón ibérico y Carrillada',
      );
    });
  });

  group('Lo que pediste', () {
    test('formato y unidades juntos', () {
      expect(cata(formato: Formato.racion, unidades: 6).racion, 'Ración de 6');
      expect(cata(formato: Formato.tapa, unidades: 2).racion, 'Tapa de 2');
    });

    test('sin unidades, sólo el formato', () {
      expect(cata(formato: Formato.mediaRacion).racion, 'Media ración');
    });

    test('sin nada, nada: no se inventa un "ración de 6"', () {
      // Es lo que hacía la ficha antes, dijeras lo que dijeras.
      expect(cata().racion, isEmpty);
      expect(cata().sabemosLaRacion, isFalse);
    });

    test('el precio del plato sale de las unidades, no de una suposición', () {
      expect(cata(precio: 2.2, unidades: 6).precioTotal, closeTo(13.2, 0.001));
      expect(cata(precio: 2.2).precioTotal, isNull);
      expect(cata(unidades: 6).precioTotal, isNull);
    });
  });

  group('Con quién', () {
    test('los acompañantes son nombres y salen como personas', () {
      final Cata c = cata(acompanantes: <String>['Marta', 'Jose']);
      expect(c.gente.map((Persona p) => p.nombre), <String>['Marta', 'Jose']);
    });

    test('el color de alguien no cambia entre pantallas', () {
      expect(
        Persona.deNombre('Marta').color,
        Persona.deNombre('Marta').color,
      );
    });

    test('los identificadores viejos se traducen al cargar', () {
      expect(Persona.nombreGuardado('rocio'), 'Rocío');
      expect(Persona.nombreGuardado('Ana'), 'Ana');
    });
  });
}
