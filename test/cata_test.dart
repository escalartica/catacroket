import 'package:catacroket/core/models/cata.dart';
import 'package:catacroket/core/models/corte.dart';
import 'package:catacroket/core/models/persona.dart';
import 'package:catacroket/core/models/racion.dart';
import 'package:catacroket/core/models/sabor.dart';
import 'package:flutter_test/flutter_test.dart';

Cata cata({
  String id = 'x',
  String sitio = 'Bar',
  List<Sabor> sabores = const <Sabor>[Sabor(rellenoId: 'jamon')],
  Formato formato = Formato.sinDecir,
  int unidades = 0,
  double? precio,
  List<String> acompanantes = const <String>[],
}) =>
    Cata(
      id: id,
      sitio: sitio,
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
  _repetidas();

  _ciudadesInventadas();

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

/// El campo ciudad de las catas guardadas con versiones viejas.
///
/// Una versión anterior escribía el literal 'Sin ciudad' cuando el usuario no
/// decía nada. Eso hacía que la ficha pusiera "SIN CIUDAD 🇪🇸 · Bar Manoli",
/// como si existiera un pueblo así, y que esa cata contara como una ciudad
/// más en el Croquetómetro.
void _ciudadesInventadas() {
  group('ciudad inventada de versiones viejas', () {
    Cata leer(String ciudad) => Cata.fromJson(<String, dynamic>{
          'id': 'x',
          'sitio': 'Bar Manoli',
          'ciudad': ciudad,
          'pais': 'ES',
          'autorId': 'tu',
          'fecha': DateTime(2026, 1, 1).toIso8601String(),
          'sabores': <dynamic>[],
          'corte': <String, dynamic>{
            'crujiente': 5,
            'cremosidad': 5,
            'sabor': 5,
            'relleno': 5,
          },
        });

    test('«Sin ciudad» se lee como sin ciudad', () {
      expect(leer('Sin ciudad').ciudad, isEmpty);
      expect(leer('sin ciudad').ciudad, isEmpty);
      expect(leer('  SIN CIUDAD  ').ciudad, isEmpty);
    });

    test('y entonces la ficha enseña el país, no un pueblo inventado', () {
      expect(leer('Sin ciudad').lugar, isNot(contains('Sin ciudad')));
      expect(leer('Sin ciudad').lugar, 'España');
    });

    test('una ciudad de verdad no se toca', () {
      expect(leer('Sevilla').ciudad, 'Sevilla');
      expect(leer('  Sevilla  ').ciudad, 'Sevilla');
      expect(leer('Sevilla').lugar, contains('Sevilla'));
    });

    test('los guiones sueltos tampoco son una ciudad', () {
      expect(leer('—').ciudad, isEmpty);
      expect(leer('-').ciudad, isEmpty);
    });
  });
}

/// Dos catas con el mismo id.
///
/// No deberían existir, pero pueden: una copia restaurada dos veces, una
/// sincronización a medias. Y no dan un error claro, sino tres rarezas: el
/// Croquetómetro cuenta de más, una mesa enseña la croqueta dos veces y, al
/// tocar una de ellas, la app se cierra — el dibujo que vuela de la lista a
/// la ficha necesita saber cuál de las dos despega y no puede.
void _repetidas() {
  // Se apoya en el ayudante `cata()` de arriba en vez de repetir el
  // constructor: así, cuando `Cata` gane un campo obligatorio, esto no se
  // rompe. Escribir el constructor a mano aquí fue justo lo que lo rompió.
  // (No vale `copyWith`: no deja cambiar el id, y con razón — el id de una
  // cata no cambia nunca.)
  Cata conId(String id, {String sitio = 'Bar Manoli'}) =>
      cata(id: id, sitio: sitio);

  group('catas repetidas', () {
    test('una lista limpia se queda igual', () {
      final List<Cata> tres = <Cata>[conId('a'), conId('b'), conId('c')];
      expect(Cata.sinRepetidas(tres).map((Cata c) => c.id), <String>['a', 'b', 'c']);
    });

    test('las repetidas caen', () {
      final List<Cata> conDuplicado = <Cata>[conId('a'), conId('b'), conId('a')];
      expect(Cata.sinRepetidas(conDuplicado), hasLength(2));
    });

    test('se queda la primera, que es la que el usuario vio primero', () {
      final List<Cata> dos = <Cata>[
        conId('a', sitio: 'La buena'),
        conId('a', sitio: 'La repetida'),
      ];
      expect(Cata.sinRepetidas(dos).single.sitio, 'La buena');
    });

    test('con la lista vacía no se rompe', () {
      expect(Cata.sinRepetidas(const <Cata>[]), isEmpty);
    });

    test('todas iguales dejan una', () {
      final List<Cata> todas = <Cata>[for (int i = 0; i < 5; i++) conId('a')];
      expect(Cata.sinRepetidas(todas), hasLength(1));
    });
  });
}
