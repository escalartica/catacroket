import 'package:catacroket/core/data/datos_demo.dart';
import 'package:catacroket/core/models/cata.dart';
import 'package:catacroket/core/models/corte.dart';
import 'package:catacroket/core/models/sabor.dart';
import 'package:catacroket/core/providers/borrador_provider.dart';
import 'package:catacroket/features/nueva_cata/cata_desde_borrador.dart';
import 'package:flutter_test/flutter_test.dart';

/// El camino más importante de la app: lo que escribes en el formulario
/// acaba siendo una cata.
///
/// Estas reglas vivían dentro de un método privado de la pantalla, así que
/// nadie las podía probar: qué pasa si dejas el formulario a medias, cómo se
/// lee un precio escrito en español, y qué se conserva cuando corriges una
/// cata en vez de crearla.
void main() {
  String idFijo() => 'id-de-prueba';
  DateTime fechaFija() => DateTime(2026, 3, 14);

  Cata desde(Borrador b, {Cata? original}) => cataDesdeBorrador(
        b,
        original: original,
        nuevoId: idFijo,
        ahora: fechaFija,
      );

  /// Una cata ya publicada, para los casos de corregir.
  Cata publicada({
    String id = 'la-vieja',
    String autorId = 'marta',
    int mordiscos = 7,
    double? lat,
    double? lon,
  }) =>
      Cata(
        id: id,
        sitio: 'Bar de antes',
        ciudad: 'Sevilla',
        corte: const Corte(crujiente: 5, cremosidad: 5, sabor: 5, relleno: 5),
        sabores: const <Sabor>[Sabor(rellenoId: 'jamon')],
        autorId: autorId,
        mesaId: 'libreta',
        fecha: DateTime(2024, 1, 1),
        mordiscos: mordiscos,
        lat: lat,
        lon: lon,
      );

  group('Un formulario a medias sigue dando una cata usable', () {
    test('sin nombre de sitio no se queda en blanco', () {
      final Cata cata = desde(const Borrador());
      expect(cata.sitio, 'Sitio sin nombre');
    });

    test('sin ciudad tampoco', () {
      expect(desde(const Borrador()).ciudad, 'Sin ciudad');
    });

    test('los espacios no cuentan como nombre', () {
      final Cata cata = desde(const Borrador(sitio: '   ', ciudad: '  '));
      expect(cata.sitio, 'Sitio sin nombre');
      expect(cata.ciudad, 'Sin ciudad');
    });

    test('al sitio y la ciudad se les quitan los espacios de los lados', () {
      final Cata cata =
          desde(const Borrador(sitio: '  Bar Manoli  ', ciudad: ' Sevilla '));
      expect(cata.sitio, 'Bar Manoli');
      expect(cata.ciudad, 'Sevilla');
    });

    test('sin sabor se guarda uno genérico, nunca la lista vacía', () {
      // Una cata sin sabores rompería saborPrincipal, que asume que hay uno.
      final Cata cata = desde(const Borrador());
      expect(cata.sabores, hasLength(1));
      expect(cata.sabores.first.rellenoId, 'otro');
    });
  });

  group('El precio se escribe como se escribe en español', () {
    test('con coma decimal', () {
      expect(desde(const Borrador(precio: '2,20')).precio, 2.20);
    });

    test('con punto también, por si acaso', () {
      expect(desde(const Borrador(precio: '2.20')).precio, 2.20);
    });

    test('sin precio queda nulo, no cero', () {
      // Cero significaría "gratis", que es un dato distinto de "no lo apunté".
      expect(desde(const Borrador()).precio, isNull);
    });

    test('un precio ilegible no revienta ni inventa un número', () {
      expect(desde(const Borrador(precio: 'dos euros')).precio, isNull);
    });
  });

  group('Una cata nueva', () {
    test('la firmas tú', () {
      expect(desde(const Borrador()).autorId, DatosDemo.yo);
    });

    test('lleva la fecha de ahora y cero mordiscos', () {
      final Cata cata = desde(const Borrador());
      expect(cata.fecha, fechaFija());
      expect(cata.mordiscos, 0);
    });

    test('estrena identificador', () {
      expect(desde(const Borrador()).id, 'id-de-prueba');
    });
  });

  group('Corregir una cata no es crear otra', () {
    test('conserva el identificador: no se duplica', () {
      final Cata cata = desde(const Borrador(), original: publicada());
      expect(cata.id, 'la-vieja');
    });

    test('conserva a quien la cató', () {
      // Corregir una falta de ortografía no te hace autor de la cata ajena.
      final Cata cata = desde(const Borrador(), original: publicada());
      expect(cata.autorId, 'marta');
    });

    test('conserva la fecha: es la de cuando te la comiste', () {
      final Cata cata = desde(const Borrador(), original: publicada());
      expect(cata.fecha, DateTime(2024, 1, 1));
    });

    test('conserva los mordiscos que le dieron', () {
      final Cata cata =
          desde(const Borrador(), original: publicada(mordiscos: 7));
      expect(cata.mordiscos, 7);
    });

    test('lo que sí has cambiado, cambia', () {
      final Cata cata = desde(
        const Borrador(sitio: 'Bar corregido'),
        original: publicada(),
      );
      expect(cata.sitio, 'Bar corregido');
    });
  });

  group('El punto en el mapa', () {
    test('sin tocarlo al corregir, se queda el que tenía', () {
      final Cata cata = desde(
        const Borrador(),
        original: publicada(lat: 37.38, lon: -6.0),
      );
      expect(cata.lat, 37.38);
      expect(cata.lon, -6.0);
    });

    test('una cata nueva sin punto no sale en el mapa, y está bien', () {
      final Cata cata = desde(const Borrador());
      expect(cata.tieneUbicacion, isFalse);
    });
  });

  group('La receta', () {
    test('sin contestar nada no se guarda', () {
      // Una receta vacía diría "bechamel desconocida, rebozado con gluten"
      // como si fuera un dato, y no lo es.
      expect(desde(const Borrador()).receta, isNull);
    });
  });
}
