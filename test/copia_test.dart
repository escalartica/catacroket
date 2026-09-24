import 'dart:convert';

import 'package:catacroket/core/copia.dart';
import 'package:catacroket/core/models/cata.dart';
import 'package:catacroket/core/models/corte.dart';
import 'package:catacroket/core/models/sabor.dart';
import 'package:catacroket/core/providers/catas_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// La copia de seguridad.
///
/// Lo que se prueba no es que el fichero se cree: es que sirva para
/// recuperar. Una copia que se genera bonita y no restaura nada es peor que
/// no tenerla, porque además te da confianza.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Cata cata({required String id, String sitio = 'Bar Manoli'}) => Cata(
        id: id,
        sitio: sitio,
        ciudad: 'Sevilla',
        corte: const Corte(crujiente: 9, cremosidad: 7, sabor: 8, relleno: 6),
        sabores: const <Sabor>[Sabor(rellenoId: 'jamon')],
        autorId: 'tu',
        mesaId: 'libreta',
        fecha: DateTime(2026, 3, 14),
        nota: 'Para recordarla',
      );

  /// Un contenedor con la lectura de disco ya hecha.
  Future<ProviderContainer> arrancar() async {
    final ProviderContainer c = ProviderContainer();
    c.read(catasProvider);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return c;
  }

  group('Ida y vuelta de verdad', () {
    test('lo que catas hoy se recupera en un móvil vacío', () async {
      // El caso que justifica que esto exista: pierdes el móvil.
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final ProviderContainer viejo = await arrancar();
      await viejo.read(catasProvider.notifier).anadir(cata(id: 'la-buena'));
      final String copia = await Copia.hacer();
      viejo.dispose();

      // Móvil nuevo: no hay nada.
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await Copia.restaurar(copia);

      final ProviderContainer nuevo = await arrancar();
      final List<Cata> catas = nuevo.read(catasProvider);
      nuevo.dispose();

      expect(catas.where((Cata c) => c.id == 'la-buena'), hasLength(1));
    });

    test('la cata vuelve entera, no sólo el nombre', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final ProviderContainer viejo = await arrancar();
      await viejo.read(catasProvider.notifier).anadir(cata(id: 'completa'));
      final String copia = await Copia.hacer();
      viejo.dispose();

      SharedPreferences.setMockInitialValues(<String, Object>{});
      await Copia.restaurar(copia);
      final ProviderContainer nuevo = await arrancar();
      final Cata vuelta =
          nuevo.read(catasProvider).firstWhere((Cata c) => c.id == 'completa');
      nuevo.dispose();

      expect(vuelta.sitio, 'Bar Manoli');
      expect(vuelta.nota, 'Para recordarla');
      expect(vuelta.corte.crujiente, 9);
      expect(vuelta.fecha, DateTime(2026, 3, 14));
    });
  });

  group('El fichero se puede leer sin la app', () {
    test('es JSON de verdad, no un binario', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final String copia = await Copia.hacer();

      expect(() => jsonDecode(copia), returnsNormally);
    });

    test('dice de qué app es y de cuándo', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final Map<String, dynamic> copia =
          jsonDecode(await Copia.hacer(ahora: () => DateTime(2026, 3, 14)))
              as Map<String, dynamic>;

      expect(copia['app'], 'catacroket');
      expect(copia['version'], Copia.version);
      expect(copia['cuando'], startsWith('2026-03-14'));
    });

    test('avisa dentro del fichero de que no lleva las fotos', () async {
      // Quien lo abra dentro de dos años no va a tener la pantalla delante.
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final Map<String, dynamic> copia =
          jsonDecode(await Copia.hacer()) as Map<String, dynamic>;

      expect(copia['nota'], contains('fotos'));
    });

    test('el nombre del fichero lleva la fecha, para no pisarse', () {
      expect(
        Copia.nombreFichero(ahora: () => DateTime(2026, 3, 14)),
        'catacroket-2026-03-14.json',
      );
    });
  });

  group('Lo que no se restaura', () {
    test('un fichero que no es una copia de esta app', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      expect(await Copia.restaurar('{"app":"otra","datos":{}}'), isFalse);
    });

    test('algo que ni siquiera es JSON', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      expect(await Copia.restaurar('esto no es json {{{'), isFalse);
    });

    test('una copia de una versión futura', () async {
      // Puede traer un formato que aquí no se entienda: mejor decir que no
      // se puede que meter medio dato y dejar la libreta a medias.
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final String futura = jsonEncode(<String, dynamic>{
        'app': 'catacroket',
        'version': Copia.version + 1,
        'datos': <String, dynamic>{},
      });

      expect(await Copia.restaurar(futura), isFalse);
    });

    test('un fichero corrupto no borra lo que ya tenías', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final ProviderContainer antes = await arrancar();
      await antes.read(catasProvider.notifier).anadir(cata(id: 'la-mia'));
      antes.dispose();

      await Copia.restaurar('basura');

      final ProviderContainer despues = await arrancar();
      final List<Cata> catas = despues.read(catasProvider);
      despues.dispose();

      expect(catas.where((Cata c) => c.id == 'la-mia'), hasLength(1));
    });
  });

  group('Antes de restaurar se puede decir qué hay dentro', () {
    test('cuántas catas lleva', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final ProviderContainer c = await arrancar();
      final int cuantasHabia = c.read(catasProvider).length;
      await c.read(catasProvider.notifier).anadir(cata(id: 'a'));
      await c.read(catasProvider.notifier).anadir(cata(id: 'b'));
      final String copia = await Copia.hacer();
      c.dispose();

      expect(Copia.cuantasCatas(copia), cuantasHabia + 2);
    });

    test('un fichero que no es una copia se distingue de una vacía', () {
      // Nulo es "esto no es una copia"; cero es "es una copia sin catas".
      // Confundirlos haría que la pantalla dijera "0 catas" ante un PDF.
      expect(Copia.cuantasCatas('no soy una copia'), isNull);
      expect(
        Copia.cuantasCatas('{"app":"catacroket","version":1,"datos":{}}'),
        0,
      );
    });
  });

  group('Qué entra en la copia', () {
    test('las catas, las mesas y lo que has dicho sobre ti', () {
      expect(Copia.claves, contains('catacroket.catas.v1'));
      expect(Copia.claves, contains('catacroket.mesas.v1'));
      expect(Copia.claves, contains('catacroket.evitar.v1'));
      expect(Copia.claves, contains('catacroket.midieta.v1'));
    });

    test('los carteles de ayuda cerrados NO entran', () {
      // En un móvil nuevo es mejor que se vuelvan a enseñar: estás
      // empezando otra vez, aunque tus catas sean las de siempre.
      expect(Copia.claves, isNot(contains('catacroket.visto.v1')));
    });
  });
}
