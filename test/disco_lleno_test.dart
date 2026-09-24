import 'dart:io';

import 'package:catacroket/core/copia.dart';
import 'package:catacroket/core/models/cata.dart';
import 'package:catacroket/core/models/corte.dart';
import 'package:catacroket/core/models/medio.dart';
import 'package:catacroket/core/models/sabor.dart';
import 'package:catacroket/core/providers/catas_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

/// Cuando el móvil no tiene sitio.
///
/// Éste es el fallo que nadie prueba y que le pasa a todo el mundo: el móvil
/// lleno de fotos. Y no se parece a un disco roto, porque no lanza ninguna
/// excepción: `setString` simplemente devuelve false. Ese false se ignoraba en
/// todas partes, así que la app decía «guardada», lanzaba confeti y limpiaba el
/// formulario mientras la cata se quedaba sólo en memoria.
///
/// Se prueba con un almacenamiento falso que acepta leer y rechaza escribir,
/// que es exactamente lo que hace un móvil sin espacio.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Cata cata({String id = 'la-de-hoy', List<Medio> medios = const <Medio>[]}) =>
      Cata(
        id: id,
        sitio: 'Bar Manoli',
        ciudad: 'Sevilla',
        corte: const Corte(crujiente: 8, cremosidad: 7, sabor: 9, relleno: 6),
        sabores: const <Sabor>[Sabor(rellenoId: 'jamon')],
        autorId: 'tu',
        mesaId: 'libreta',
        fecha: DateTime(2026, 3, 14),
        medios: medios,
      );

  /// Deja puesto un almacenamiento que no puede escribir.
  void sinSitio() {
    SharedPreferencesStorePlatform.instance = _TiendaLlena();
    // La instancia que ya hubiera cacheado se tira: si no, sigue hablando con
    // la anterior y el test mide otra cosa.
    SharedPreferences.resetStatic();
  }

  void conSitio() {
    SharedPreferencesStorePlatform.instance = InMemorySharedPreferencesStore
        .withData(<String, Object>{});
    SharedPreferences.resetStatic();
  }

  tearDown(conSitio);

  Future<ProviderContainer> arrancar() async {
    final ProviderContainer c = ProviderContainer();
    c.read(catasProvider);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return c;
  }

  group('Guardar una cata', () {
    test('dice que no se ha guardado, en vez de dar por hecho que sí', () async {
      conSitio();
      final ProviderContainer c = await arrancar();
      sinSitio();

      final bool guardada = await c.read(catasProvider.notifier).anadir(cata());
      c.dispose();

      expect(
        guardada,
        isFalse,
        reason: 'la pantalla necesita esto para no lanzar el confeti y no '
            'limpiar el formulario que el usuario tendrá que volver a escribir',
      );
    });

    test('con sitio, dice que sí', () async {
      // Un aviso que salta siempre es un aviso que se ignora.
      conSitio();
      final ProviderContainer c = await arrancar();

      final bool guardada = await c.read(catasProvider.notifier).anadir(cata());
      c.dispose();

      expect(guardada, isTrue);
    });

    test('la cata sigue en pantalla aunque no se haya guardado', () async {
      // Quitarla de la lista al fallar sería peor: el usuario la ve
      // desaparecer sin entender nada. Se queda, y el aviso explica qué pasa.
      conSitio();
      final ProviderContainer c = await arrancar();
      sinSitio();

      await c.read(catasProvider.notifier).anadir(cata(id: 'en-el-aire'));
      final List<Cata> catas = c.read(catasProvider);
      c.dispose();

      expect(catas.where((Cata x) => x.id == 'en-el-aire'), hasLength(1));
    });
  });

  group('Borrar sin poder guardar', () {
    late Directory carpeta;

    setUp(() => carpeta = Directory.systemTemp.createTempSync('disco_lleno'));
    tearDown(() {
      if (carpeta.existsSync()) carpeta.deleteSync(recursive: true);
    });

    test('no se lleva las fotos por delante', () async {
      // Lo importante de este test. Si el borrado no llega al disco, la cata
      // reaparece al reiniciar; si además le hubiéramos borrado las fotos,
      // volvería con huecos. Un fichero de más se arregla; una ficha rota, no.
      conSitio();
      final ProviderContainer c = await arrancar();

      final File f = File('${carpeta.path}/suya.jpg')
        ..writeAsBytesSync(<int>[0, 1, 2]);
      final Medio foto = Medio(tipo: TipoMedio.foto, ruta: f.path);
      await c.read(catasProvider.notifier).anadir(
            cata(id: 'con-foto', medios: <Medio>[foto]),
          );

      sinSitio();
      final bool borrada = await c.read(catasProvider.notifier).borrar(
            'con-foto',
          );
      c.dispose();

      expect(borrada, isFalse);
      expect(
        File(foto.ruta).existsSync(),
        isTrue,
        reason: 'la cata va a volver al reiniciar y su foto tiene que estar',
      );
    });
  });

  group('Restaurar una copia', () {
    test('no dice «restaurado» si no ha podido escribir nada', () async {
      // La pantalla a la que llega alguien que acaba de perder el móvil. Es el
      // peor sitio de la app para dar una buena noticia que no es verdad.
      //
      // La copia tiene que llevar algo dentro: una vacía no escribe nada, así
      // que nada falla y devolver true es correcto. La primera versión de este
      // test no metía ninguna cata y por eso «fallaba» sin que hubiera
      // ningún fallo.
      conSitio();
      final ProviderContainer c = await arrancar();
      await c.read(catasProvider.notifier).anadir(cata(id: 'la-de-mi-boda'));
      final String copia = await Copia.hacer();
      c.dispose();
      expect(Copia.cuantasCatas(copia), greaterThan(0));

      sinSitio();
      expect(await Copia.restaurar(copia), isFalse);
    });

    test('con sitio, restaura y lo dice', () async {
      conSitio();
      final ProviderContainer c = await arrancar();
      await c.read(catasProvider.notifier).anadir(cata(id: 'la-buena'));
      final String copia = await Copia.hacer();
      c.dispose();

      expect(await Copia.restaurar(copia), isTrue);
    });
  });
}

/// Un almacenamiento que deja leer y no deja escribir.
///
/// Es lo que hace un móvil sin espacio: las escrituras devuelven false sin
/// lanzar nada. Hereda del de memoria para no tener que reimplementar la
/// lectura, y sólo cambia la respuesta a escribir.
class _TiendaLlena extends InMemorySharedPreferencesStore {
  _TiendaLlena() : super.empty();

  @override
  Future<bool> setValue(String valueType, String key, Object value) async =>
      false;

  @override
  Future<bool> clear() async => false;

  @override
  Future<bool> remove(String key) async => false;
}
