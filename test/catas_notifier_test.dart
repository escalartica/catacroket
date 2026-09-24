import 'dart:io';

import 'package:catacroket/core/models/cata.dart';
import 'package:catacroket/core/models/corte.dart';
import 'package:catacroket/core/models/medio.dart';
import 'package:catacroket/core/models/sabor.dart';
import 'package:catacroket/core/providers/catas_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Una cata cualquiera. Lo que no se pasa no importa para estas pruebas.
Cata cata({
  String id = 'nueva',
  String sitio = 'Bar de prueba',
  String mesaId = 'libreta',
  int crujiente = 7,
  int mordiscos = 0,
  List<Medio> medios = const <Medio>[],
}) =>
    Cata(
      id: id,
      sitio: sitio,
      ciudad: 'Sevilla',
      corte: Corte(
        crujiente: crujiente,
        cremosidad: 7,
        sabor: 7,
        relleno: 7,
      ),
      sabores: const <Sabor>[Sabor(rellenoId: 'jamon')],
      autorId: 'tu',
      mesaId: mesaId,
      fecha: DateTime(2026),
      mordiscos: mordiscos,
      medios: medios,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer contenedor;

  setUp(() async {
    // Sin esto, SharedPreferences no existe en un test y el notifier se queda
    // con lo que trae de fábrica. Vacío: aquí no se prueba la carga.
    SharedPreferences.setMockInitialValues(<String, Object>{});
    contenedor = ProviderContainer();
    // El constructor lanza _cargar(); se le deja terminar antes de tocar nada.
    await Future<void>.delayed(Duration.zero);
  });

  tearDown(() => contenedor.dispose());

  CatasNotifier notifier() => contenedor.read(catasProvider.notifier);
  List<Cata> catas() => contenedor.read(catasProvider);

  group('CatasNotifier', () {
    test('añadir pone la cata la primera, que es el orden del feed', () async {
      final int antes = catas().length;

      await notifier().anadir(cata(id: 'recien-hecha'));

      expect(catas().length, antes + 1);
      expect(catas().first.id, 'recien-hecha');
    });

    test('actualizar no mueve la cata de sitio', () async {
      await notifier().anadir(cata(id: 'primera'));
      await notifier().anadir(cata(id: 'segunda'));
      // 'primera' quedó en el índice 1 al entrar 'segunda' por delante.
      final int posicion = catas().indexWhere((Cata c) => c.id == 'primera');

      await notifier().actualizar(cata(id: 'primera', sitio: 'Bar corregido'));

      expect(catas().indexWhere((Cata c) => c.id == 'primera'), posicion);
      expect(catas()[posicion].sitio, 'Bar corregido');
    });

    test('actualizar no toca el número de catas', () async {
      await notifier().anadir(cata(id: 'unica'));
      final int antes = catas().length;

      await notifier().actualizar(cata(id: 'unica', sitio: 'Otro nombre'));

      expect(catas().length, antes);
    });

    test('actualizar una cata que no existe no inventa ninguna', () async {
      final int antes = catas().length;

      await notifier().actualizar(cata(id: 'no-existe'));

      expect(catas().length, antes);
      expect(catas().where((Cata c) => c.id == 'no-existe'), isEmpty);
    });

    test('borrar quita esa y sólo esa', () async {
      await notifier().anadir(cata(id: 'sobra'));
      await notifier().anadir(cata(id: 'se-queda'));
      final int antes = catas().length;

      await notifier().borrar('sobra');

      expect(catas().length, antes - 1);
      expect(catas().where((Cata c) => c.id == 'sobra'), isEmpty);
      expect(catas().where((Cata c) => c.id == 'se-queda'), hasLength(1));
    });

    test('borrar algo que no está deja la lista igual', () async {
      final int antes = catas().length;

      await notifier().borrar('fantasma');

      expect(catas().length, antes);
    });

    test('un mordisco suma uno, y sólo a esa cata', () async {
      await notifier().anadir(cata(id: 'mordida', mordiscos: 3));
      await notifier().anadir(cata(id: 'intacta', mordiscos: 0));

      await notifier().darMordisco('mordida');

      expect(catas().firstWhere((Cata c) => c.id == 'mordida').mordiscos, 4);
      expect(catas().firstWhere((Cata c) => c.id == 'intacta').mordiscos, 0);
    });

    test('restablecer se lleva por delante lo añadido', () async {
      await notifier().anadir(cata(id: 'temporal'));
      expect(catas().where((Cata c) => c.id == 'temporal'), hasLength(1));

      await notifier().restablecer();

      expect(catas().where((Cata c) => c.id == 'temporal'), isEmpty);
    });

    test('el estado se reemplaza, nunca se muta en el sitio', () async {
      final List<Cata> referenciaVieja = catas();

      await notifier().anadir(cata(id: 'nueva-de-verdad'));

      // Si el notifier mutara la lista, las dos referencias serían la misma
      // y Riverpod no se enteraría del cambio.
      expect(identical(referenciaVieja, catas()), isFalse);
      expect(
        referenciaVieja.where((Cata c) => c.id == 'nueva-de-verdad'),
        isEmpty,
      );
    });
  });

  group('Las fotos y los vídeos no se quedan ocupando sitio', () {
    // Aquí se usan ficheros de verdad porque lo que hay que comprobar es que
    // desaparezcan del disco. Un doble de MediosService probaría que se le
    // llama, que no es lo mismo: lo que llena el móvil es el fichero.
    late Directory carpeta;

    setUp(() => carpeta = Directory.systemTemp.createTempSync('catas_medios'));
    tearDown(() {
      if (carpeta.existsSync()) carpeta.deleteSync(recursive: true);
    });

    Medio foto(String nombre) {
      final File f = File('${carpeta.path}/$nombre')
        ..writeAsBytesSync(<int>[0, 1, 2]);
      return Medio(tipo: TipoMedio.foto, ruta: f.path);
    }

    test('al borrar una cata se van sus ficheros', () async {
      final Medio suya = foto('suya.jpg');
      await notifier().anadir(cata(id: 'con-foto', medios: <Medio>[suya]));

      await notifier().borrar('con-foto');

      expect(File(suya.ruta).existsSync(), isFalse);
    });

    test('al quitar una foto editando, se va del disco', () async {
      final Medio quitada = foto('quitada.jpg');
      final Medio sigue = foto('sigue.jpg');
      await notifier().anadir(
        cata(id: 'editable', medios: <Medio>[quitada, sigue]),
      );

      await notifier().actualizar(
        cata(id: 'editable', medios: <Medio>[sigue]),
      );

      expect(File(quitada.ruta).existsSync(), isFalse);
      expect(File(sigue.ruta).existsSync(), isTrue,
          reason: 'la que se queda no se puede borrar');
    });

    test('restablecer también se los lleva', () async {
      // El caso que se colaba. «Restablecer» dice «deja la app como recién
      // instalada», y lo pulsa justo quien quiere recuperar espacio: si las
      // catas desaparecen pero sus vídeos siguen ahí, la app se queda
      // ocupando cientos de megas que ya no le sirven a nadie y que no hay
      // forma de borrar desde ninguna pantalla.
      final Medio una = foto('una.jpg');
      final Medio otra = foto('otra.jpg');
      await notifier().anadir(cata(id: 'primera', medios: <Medio>[una]));
      await notifier().anadir(cata(id: 'segunda', medios: <Medio>[otra]));

      await notifier().restablecer();

      expect(File(una.ruta).existsSync(), isFalse);
      expect(File(otra.ruta).existsSync(), isFalse);
    });

    test('un fichero que ya no está no hace fallar el borrado', () async {
      // Pasa: el usuario restaura una copia en un móvil nuevo, donde las
      // rutas apuntan a ficheros que nunca se copiaron.
      final Medio fantasma = foto('fantasma.jpg');
      await notifier().anadir(cata(id: 'sin-fichero', medios: <Medio>[fantasma]));
      File(fantasma.ruta).deleteSync();

      await expectLater(notifier().borrar('sin-fichero'), completes);
      expect(catas().where((Cata c) => c.id == 'sin-fichero'), isEmpty);
    });
  });
}
