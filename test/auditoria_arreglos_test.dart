import 'package:catacroket/core/models/cata.dart';
import 'package:catacroket/core/models/corte.dart';
import 'package:catacroket/core/models/dieta.dart';
import 'package:catacroket/core/models/medio.dart';
import 'package:catacroket/core/models/receta.dart';
import 'package:catacroket/core/models/sabor.dart';
import 'package:catacroket/core/utils/texto.dart';
import 'package:flutter_test/flutter_test.dart';

/// Los arreglos de la auditoría, cada uno con su prueba.
void main() {
  group('Texto.enumerar', () {
    test('uno solo', () => expect(Texto.enumerar(<String>['A']), '«A»'));

    test('dos, con «y» y sin coma', () {
      expect(Texto.enumerar(<String>['A', 'B']), '«A» y «B»');
    });

    test('tres, con coma y «y» al final', () {
      // Lo que había decía «A y B y C» justo encima del botón de publicar.
      expect(Texto.enumerar(<String>['A', 'B', 'C']), '«A», «B» y «C»');
    });

    test('sin comillas cuando se pide', () {
      expect(
        Texto.enumerar(<String>['A', 'B'], comillas: false),
        'A y B',
      );
    });
  });

  group('de quién es una cata', () {
    Cata cata({String autorId = 'tu', String? autorUid}) => Cata(
          id: 'c1',
          sitio: 'Bar',
          ciudad: 'Sevilla',
          corte: const Corte.media(),
          sabores: const <Sabor>[Sabor(rellenoId: 'jamon')],
          autorId: autorId,
          autorUid: autorUid,
          fecha: DateTime(2026),
        );

    test('sin sesión manda el identificador local', () {
      // Entrar con otra cuenta en el mismo móvil no puede esconderte tus
      // propias catas: siguen en este disco y siguen siendo tuyas.
      expect(cata(autorUid: 'vieja').esMia(null), isTrue);
    });

    test('la de otra persona no es tuya aunque traiga autorId «tu»', () {
      expect(cata(autorUid: 'de-otra').esMia('mia'), isFalse);
    });

    test('la tuya lo es', () {
      expect(cata(autorUid: 'mia').esMia('mia'), isTrue);
    });
  });

  group('las dietas de una cata', () {
    Cata conReceta(Receta r) => Cata(
          id: 'c1',
          sitio: 'Bar',
          ciudad: 'Sevilla',
          corte: const Corte.media(),
          sabores: const <Sabor>[Sabor(rellenoId: 'jamon')],
          autorId: 'tu',
          fecha: DateTime(2026),
          receta: r,
        );

    test('vale para las dietas que se deducen de su receta', () {
      // `valePara` comparaba contra las dietas marcadas A MANO, que están
      // vacías en todo lo que se apunta hoy: la Barra Libre enseñaba cero en
      // cuanto marcabas una dieta, aunque hubiera diez que sí valían.
      // Con la bechamel «no lo sé» no se puede deducir NADA, y es correcto:
      // una bechamel sin identificar puede esconder leche, gluten, soja o
      // almendra. Para esta prueba hace falta una receta contestada.
      final Cata c = conReceta(const Receta(
        bechamel: Bechamel.leche,
        rebozadoConGluten: false,
        rebozadoConHuevo: false,
      ));
      expect(
        c.aptasCalculadas,
        isNotEmpty,
        reason: 'si esto falla, la receta de la prueba no deduce nada',
      );
      expect(c.valePara(c.aptasCalculadas), isTrue);
      expect(c.aptas, isEmpty, reason: 'nadie las marcó a mano');
    });

    test('sin pedir nada, vale cualquiera', () {
      expect(conReceta(const Receta()).valePara(const <Dieta>{}), isTrue);
    });
  });

  group('lo que se guarda de una foto', () {
    const Medio foto = Medio(tipo: TipoMedio.foto, ruta: '/a/b.jpg', mini: 'XXXX');

    test('en el móvil NO va la miniatura', () {
      // Pesa hasta 440 KB, hay dos por cata, y el guardado entero se
      // reescribe en cada mordisco. El fichero ya está en este teléfono.
      expect(foto.toJson().containsKey('mini'), isFalse);
      expect(foto.toJson()['ruta'], '/a/b.jpg');
    });

    test('a la nube sí va, que es lo único que allí sirve', () {
      expect(foto.paraViajar.toJsonParaLaNube()['mini'], 'XXXX');
    });
  });
}
