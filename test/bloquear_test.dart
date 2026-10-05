import 'package:catacroket/core/models/cata.dart';
import 'package:catacroket/core/models/corte.dart';
import 'package:catacroket/core/models/sabor.dart';
import 'package:catacroket/core/providers/bloqueados_provider.dart';
import 'package:catacroket/core/providers/catas_provider.dart';
import 'package:catacroket/core/providers/nube_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bloquear a alguien de tu mesa.
///
/// Apple lo exige a toda app que enseñe cosas escritas por otras personas, y
/// lo que de verdad importa es que funcione en TODAS las pantallas: un
/// bloqueo que funciona en cuatro y en la quinta no, no es un bloqueo.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  Cata de(String uid, String id) => Cata(
        id: id,
        sitio: 'Bar',
        ciudad: 'Sevilla',
        corte: const Corte(crujiente: 7, cremosidad: 7, sabor: 7, relleno: 7),
        sabores: const <Sabor>[Sabor(rellenoId: 'jamon')],
        autorId: uid,
        autorUid: uid,
        fecha: DateTime(2026, 10, 1),
        mesas: const <String>['mesa-1'],
      );

  ProviderContainer conGenteDeFuera(List<Cata> deOtros) {
    final ProviderContainer c = ProviderContainer(
      overrides: <Override>[
        catasProvider.overrideWith((Ref ref) => _Catas(ref, const <Cata>[])),
        catasDeOtrosProvider.overrideWith(
          (Ref ref) => Stream<List<Cata>>.value(deOtros),
        ),
      ],
    );
    addTearDown(c.dispose);
    // El stream tiene que haber emitido antes de leer.
    c.listen(catasDeOtrosProvider, (_, _) {});
    return c;
  }

  test('sus catas desaparecen de la lista por la que pasan todas las pantallas',
      () async {
    final ProviderContainer c = conGenteDeFuera(<Cata>[
      de('pesado', 'c1'),
      de('eme', 'c2'),
    ]);
    await Future<void>.delayed(Duration.zero);

    expect(c.read(catasRecientesProvider), hasLength(2));

    await c.read(bloqueadosProvider.notifier).bloquear('pesado');

    final List<Cata> quedan = c.read(catasRecientesProvider);
    expect(quedan, hasLength(1));
    expect(quedan.single.autorUid, 'eme');
  });

  test('se puede deshacer', () async {
    final ProviderContainer c = conGenteDeFuera(<Cata>[de('pesado', 'c1')]);
    await Future<void>.delayed(Duration.zero);

    await c.read(bloqueadosProvider.notifier).bloquear('pesado');
    expect(c.read(catasRecientesProvider), isEmpty);

    // Sin esto, bloquear no es una herramienta: es una trampa.
    await c.read(bloqueadosProvider.notifier).desbloquear('pesado');
    expect(c.read(catasRecientesProvider), hasLength(1));
  });

  test('bloquear dos veces no duplica', () async {
    final ProviderContainer c = conGenteDeFuera(const <Cata>[]);
    await c.read(bloqueadosProvider.notifier).bloquear('pesado');
    await c.read(bloqueadosProvider.notifier).bloquear('pesado');

    expect(c.read(bloqueadosProvider), hasLength(1));
  });

  test('aguanta al reabrir la app', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'catacroket.bloqueados.v1': <String>['pesado'],
    });
    final ProviderContainer c = ProviderContainer();
    addTearDown(c.dispose);

    c.read(bloqueadosProvider);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(c.read(bloqueadosProvider), contains('pesado'));
  });

  test('no se puede bloquear a nadie sin identificador', () async {
    final ProviderContainer c = ProviderContainer();
    addTearDown(c.dispose);

    await c.read(bloqueadosProvider.notifier).bloquear('');
    await c.read(bloqueadosProvider.notifier).bloquear('   ');

    expect(c.read(bloqueadosProvider), isEmpty);
  });
}

class _Catas extends CatasNotifier {
  _Catas(super.ref, List<Cata> catas) {
    state = catas;
  }
}
