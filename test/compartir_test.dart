import 'dart:io';

import 'package:catacroket/core/data/enlaces.dart';
import 'package:catacroket/core/models/cata.dart';
import 'package:catacroket/core/models/corte.dart';
import 'package:catacroket/core/models/mesa.dart';
import 'package:catacroket/core/models/sabor.dart';
import 'package:catacroket/core/services/compartir_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lo que sale de la app hacia el grupo de WhatsApp.
///
/// Es el motor de crecimiento: cada estampa que alguien manda enseña la app a
/// gente que no la tiene. Lo que se prueba aquí es que el mensaje diga qué
/// es, de dónde sale y —cuando haya enlace— dónde conseguirla.
void main() {
  Cata cata({
    String sitio = 'Bar Manoli',
    int crujiente = 8,
    String nota = '',
  }) =>
      Cata(
        id: 'x',
        sitio: sitio,
        ciudad: 'Sevilla',
        corte: Corte(crujiente: crujiente, cremosidad: 8, sabor: 8, relleno: 8),
        sabores: const <Sabor>[Sabor(rellenoId: 'jamon')],
        autorId: 'tu',
        mesaId: 'libreta',
        fecha: DateTime(2026),
        nota: nota,
      );

  group('El mensaje de una cata', () {
    test('dice qué era, dónde y cuánto', () {
      final String texto = CompartirService.cata(cata());

      expect(texto, contains('Bar Manoli'));
      expect(texto, contains('Sevilla'));
      expect(texto, contains('/10'));
    });

    test('lleva tu apunte si lo escribiste', () {
      final String texto =
          CompartirService.cata(cata(nota: 'La mejor del barrio'));

      expect(texto, contains('La mejor del barrio'));
    });

    test('sin apunte no deja unas comillas vacías colgando', () {
      expect(CompartirService.cata(cata()), isNot(contains('«»')));
    });
  });

  group('Las invitaciones', () {
    test('la de la app dice cómo se llama', () {
      expect(CompartirService.invitacionApp(), contains('Catacroket'));
    });

    test('la de una mesa lleva su código, que es lo que hace falta', () {
      final Mesa mesa = const Mesa(
        id: 'm',
        nombre: 'Los Croquetólogos',
        descripcion: '',
        colorHex: 0xFFFFC93C,
        miembros: <String>[],
        codigo: 'KRQ482',
      );

      final String texto = CompartirService.invitacionMesa(mesa);

      expect(texto, contains('KRQ482'));
      expect(texto, contains('Los Croquetólogos'));
    });

    test('las dos dicen dónde conseguir la app', () {
      // Sin esto, a quien recibe el mensaje le llega una app que suena bien y
      // ningún sitio al que ir.
      expect(CompartirService.invitacionApp(), contains(Enlaces.dondeEsta));
      expect(
        CompartirService.invitacionMesa(
          const Mesa(
            id: 'm',
            nombre: 'X',
            descripcion: '',
            colorHex: 0xFFFFC93C,
            miembros: <String>[],
            codigo: 'ABC123',
          ),
        ),
        contains(Enlaces.dondeEsta),
      );
    });
  });

  group('La otra app', () {
    test('el enlace apunta a la App Store, no a cualquier sitio', () {
      expect(Enlaces.palito, startsWith('https://apps.apple.com/'));
      expect(Enlaces.hayPalito, isTrue);
    });

    test('hayPalito y palito no pueden contradecirse', () {
      expect(Enlaces.hayPalito, Enlaces.palito.isNotEmpty);
    });

    test('el logo está donde dice y no en assets/brand', () {
      // assets/brand es la marca de Catacroket. Meter ahí el logo de otra
      // app confundiría a quien abra la carpeta dentro de seis meses.
      expect(Enlaces.logoPalito, startsWith('assets/palito/'));
    });

    test('el fichero del logo existe de verdad', () {
      // Un asset que falta no lo detecta el analizador: sale como un hueco
      // en el móvil y ya está.
      expect(File(Enlaces.logoPalito).existsSync(), isTrue);
    });

    test('la carpeta del logo está declarada en pubspec', () {
      // Se puede copiar el fichero y olvidarse de declararlo. Entonces
      // existe en disco, el test de arriba pasa, y en la app no se ve.
      final String pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('assets/palito/'));
    });
  });

  group('Enlaces', () {
    test('sin tienda publicada se dice el nombre, no un enlace roto', () {
      // Hoy `tienda` está vacío a propósito: mandar a alguien un enlace que
      // no lleva a ninguna parte es peor que no mandarlo.
      if (Enlaces.hayTienda) {
        expect(Enlaces.dondeEsta, Enlaces.tienda);
      } else {
        expect(Enlaces.dondeEsta, contains('Catacroket'));
        expect(Enlaces.dondeEsta, isNot(startsWith('http')));
      }
    });

    test('hayTienda y tienda no pueden contradecirse', () {
      // El test que de verdad protege esto: el día que se pegue el enlace,
      // `hayTienda` tiene que pasar a true solo. Si alguien cambia uno sin
      // el otro, los textos de invitación se quedan a medias.
      expect(Enlaces.hayTienda, Enlaces.tienda.isNotEmpty);
    });
  });
}
