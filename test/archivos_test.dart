import 'package:catacroket/core/utils/archivos.dart';
import 'package:catacroket/core/utils/texto.dart';
import 'package:flutter_test/flutter_test.dart';

/// Dos cosas que hacían «desaparecer» lo que estaba ahí.
void main() {
  group('la ruta de una foto', () {
    setUp(() => Archivos.ponerRaiz('/datos/Aplicacion/NUEVO/Documents'));

    test('se guarda sin la parte que cambia', () {
      expect(
        Archivos.guardable(
          '/datos/Aplicacion/NUEVO/Documents/medios/foto_1.jpg',
        ),
        'medios/foto_1.jpg',
      );
    });

    test('se abre colgando de la carpeta de hoy', () {
      expect(
        Archivos.enDisco('medios/foto_1.jpg'),
        '/datos/Aplicacion/NUEVO/Documents/medios/foto_1.jpg',
      );
    });

    test('una ruta vieja se recoloca sola', () {
      // Éste es el fallo entero: iOS cambia ese identificador al reinstalar
      // la app. El fichero sigue donde estaba y la ruta guardada hace un mes
      // no lleva a ningún sitio, así que la foto «desaparece».
      expect(
        Archivos.enDisco(
          '/datos/Aplicacion/VIEJO-A1B2/Documents/medios/foto_1.jpg',
        ),
        '/datos/Aplicacion/NUEVO/Documents/medios/foto_1.jpg',
      );
    });

    test('la del perfil también', () {
      expect(
        Archivos.enDisco('/otra/cosa/VIEJO/Documents/perfil/yo_9.jpg'),
        '/datos/Aplicacion/NUEVO/Documents/perfil/yo_9.jpg',
      );
    });

    test('lo que no es nuestro se deja en paz', () {
      expect(Archivos.enDisco('/tmp/suelta.jpg'), '/tmp/suelta.jpg');
      expect(Archivos.enDisco(''), '');
    });

    test('sin carpeta leída todavía no se inventa una', () {
      Archivos.ponerRaiz('');
      expect(Archivos.enDisco('medios/foto_1.jpg'), 'medios/foto_1.jpg');
    });
  });

  group('buscar en plural', () {
    test('«gambas» encuentra «Gamba roja»', () {
      // Nadie pide «una de gamba». El relleno se llama así en la lista y el
      // buscador decía que no existe, mandando a escribirlo a mano.
      expect(Texto.contiene('Gamba roja', 'gambas'), isTrue);
    });

    test('y al revés: «seta» encuentra «Setas y trufa»', () {
      expect(Texto.contiene('Setas y trufa', 'seta'), isTrue);
    });

    test('sigue valiendo lo de siempre', () {
      expect(Texto.contiene('Jamón ibérico', 'jamon'), isTrue);
      expect(Texto.contiene('Jamón ibérico', 'iberico'), isTrue);
      expect(Texto.contiene('Jamón ibérico', ''), isTrue);
    });

    test('no se vuelve loco con las palabras cortas', () {
      // Con «de» o «al» casando por el principio, media lista valdría para
      // cualquier búsqueda y el buscador dejaría de servir.
      expect(Texto.contiene('Bacalao al pil pil', 'de'), isFalse);
      expect(Texto.contiene('Setas y trufa', 'gambas'), isFalse);
      expect(Texto.contiene('Gamba roja', 'melon'), isFalse);
    });
  });
}
