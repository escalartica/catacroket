import 'package:catacroket/core/models/cata.dart';
import 'package:catacroket/core/models/corte.dart';
import 'package:catacroket/core/models/mesa.dart';
import 'package:catacroket/core/models/sabor.dart';
import 'package:catacroket/core/providers/catas_provider.dart';
import 'package:catacroket/core/providers/mesas_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Cata cata({required String id, required String mesaId}) => Cata(
      id: id,
      sitio: 'Bar de prueba',
      ciudad: 'Sevilla',
      corte: const Corte(crujiente: 7, cremosidad: 7, sabor: 7, relleno: 7),
      sabores: const <Sabor>[Sabor(rellenoId: 'jamon')],
      autorId: 'tu',
      mesas: <String>[mesaId],
      fecha: DateTime(2026),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer contenedor;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    contenedor = ProviderContainer();
    await Future<void>.delayed(Duration.zero);
  });

  tearDown(() => contenedor.dispose());

  MesasNotifier mesas() => contenedor.read(mesasProvider.notifier);
  CatasNotifier catas() => contenedor.read(catasProvider.notifier);
  List<Cata> lasCatas() => contenedor.read(catasProvider);

  /// Una mesa del sembrado que no sea la libreta.
  String unaMesa() => contenedor
      .read(mesasProvider)
      .firstWhere((Mesa m) => m.id != Mesa.libretaId)
      .id;

  group('MesasNotifier.borrar', () {
    test('borrar una mesa NO borra sus catas: las manda a la libreta',
        () async {
      final String mesaId = unaMesa();
      await catas().anadir(cata(id: 'la-de-la-mesa', mesaId: mesaId));
      final int catasAntes = lasCatas().length;

      await mesas().borrar(mesaId);

      // La cata sigue existiendo...
      expect(lasCatas().length, catasAntes);
      final Cata superviviente =
          lasCatas().firstWhere((Cata c) => c.id == 'la-de-la-mesa');
      // ...y ahora vive en la libreta.
      // La cata se queda en tu diario y sin ninguna mesa: borrar una mesa
      // quita quién la ve, no la cata.
      expect(superviviente.mesas, isEmpty);
    });

    test('devuelve cuántas catas ha reasignado', () async {
      final String mesaId = unaMesa();
      final int suyasAntes =
          lasCatas().where((Cata c) => c.estaEn(mesaId)).length;
      await catas().anadir(cata(id: 'una', mesaId: mesaId));
      await catas().anadir(cata(id: 'otra', mesaId: mesaId));

      final int movidas = await mesas().borrar(mesaId);

      expect(movidas, suyasAntes + 2);
    });

    test('la mesa desaparece de la lista', () async {
      final String mesaId = unaMesa();

      await mesas().borrar(mesaId);

      expect(
        contenedor.read(mesasProvider).where((Mesa m) => m.id == mesaId),
        isEmpty,
      );
    });

    test('la libreta no se puede borrar', () async {
      final int antes = contenedor.read(mesasProvider).length;

      final int movidas = await mesas().borrar(Mesa.libretaId);

      expect(movidas, 0);
      expect(contenedor.read(mesasProvider).length, antes);
      expect(
        contenedor
            .read(mesasProvider)
            .where((Mesa m) => m.id == Mesa.libretaId),
        hasLength(1),
      );
    });

    test('las catas de otras mesas no se tocan', () async {
      final List<Mesa> todas = contenedor
          .read(mesasProvider)
          .where((Mesa m) => m.id != Mesa.libretaId)
          .toList();
      if (todas.length < 2) return; // Sin dos mesas no hay nada que separar.

      await catas().anadir(cata(id: 'de-la-que-se-borra', mesaId: todas[0].id));
      await catas().anadir(cata(id: 'de-la-que-se-queda', mesaId: todas[1].id));

      await mesas().borrar(todas[0].id);

      expect(
        lasCatas().firstWhere((Cata c) => c.id == 'de-la-que-se-queda').mesas,
        <String>[todas[1].id],
      );
    });
  });

  group('quién hay en la mesa', () {
    test('apunta a quien entra, que antes no se enteraba nunca', () async {
      final String id = unaMesa();
      await mesas().apuntarMiembros(id, <String>['tu', 'eme']);

      final Mesa m = contenedor
          .read(mesasProvider)
          .firstWhere((Mesa m) => m.id == id);
      expect(m.miembros, containsAll(<String>['tu', 'eme']));
    });

    test('no toca el nombre ni el color de la mesa', () async {
      final String id = unaMesa();
      final Mesa antes = contenedor
          .read(mesasProvider)
          .firstWhere((Mesa m) => m.id == id);

      await mesas().apuntarMiembros(id, <String>['tu', 'eme']);

      final Mesa ahora = contenedor
          .read(mesasProvider)
          .firstWhere((Mesa m) => m.id == id);
      expect(ahora.nombre, antes.nombre);
      expect(ahora.colorHex, antes.colorHex);
    });

    test('una mesa que no existe no revienta', () async {
      await mesas().apuntarMiembros('no-existe', <String>['eme']);
    });
  });

  group('recuperar mesas del servidor', () {
    // Sin Firebase levantado, el servidor no contesta y devuelve cero. Lo que
    // se comprueba aquí es lo peligroso: que un servidor que no contesta no
    // te deje sin las mesas que ya tienes en el móvil.
    test('un servidor mudo no borra tus mesas', () async {
      final List<Mesa> antes = contenedor.read(mesasProvider);
      expect(antes, isNotEmpty);

      final int nuevas = await mesas().recuperarDeLaNube();

      expect(nuevas, 0);
      expect(contenedor.read(mesasProvider).length, antes.length);
      expect(
        contenedor.read(mesasProvider).map((Mesa m) => m.id),
        containsAll(antes.map((Mesa m) => m.id)),
      );
    });

    test('la libreta sigue estando después de recuperar', () async {
      await mesas().recuperarDeLaNube();
      expect(
        contenedor.read(mesasProvider).any((Mesa m) => m.esLibreta),
        isTrue,
      );
    });
  });
}
