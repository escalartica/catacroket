import 'package:catacroket/core/models/dieta.dart';
import 'package:catacroket/core/providers/bloqueados_provider.dart';
import 'package:catacroket/core/providers/mi_dieta_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lo que toca el usuario no lo deshace la lectura del disco.
///
/// Estos providers arrancan con un valor de partida y leen
/// `SharedPreferences` en segundo plano. Entre las dos cosas hay una ventana
/// en la que ya se puede tocar la pantalla, y la lectura llegaba después y
/// pisaba el toque sin decir nada: el usuario desmarcaba una dieta, la veía
/// desmarcarse y volvía a marcarse sola.
///
/// Es la explicación de dos cosas que se reportaron: «aparece la opción
/// vegana si yo no le di» y «no sé por qué frutos secos está marcado».
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('una dieta que quitas no vuelve sola', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'catacroket.midieta.v1': <String>['vegana', 'sin_frutos_secos'],
    });
    final ProviderContainer c = ProviderContainer();
    addTearDown(c.dispose);

    // Se crea el notifier —con la carga ya en marcha— y se toca enseguida,
    // que es lo que hace quien abre la app y va directo a «cómo comes».
    await c.read(miDietaProvider.notifier).poner(const <Dieta>{});

    // Tiempo de sobra para que la carga aterrice.
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(c.read(miDietaProvider), isEmpty);
  });

  test('marcar una dieta gana a lo que hubiera guardado', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'catacroket.midieta.v1': <String>['vegana'],
    });
    final ProviderContainer c = ProviderContainer();
    addTearDown(c.dispose);

    await c.read(miDietaProvider.notifier).poner(<Dieta>{Dieta.sinGluten});
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(c.read(miDietaProvider), <Dieta>{Dieta.sinGluten});
  });

  test('un bloqueo recién hecho no lo borra la carga', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final ProviderContainer c = ProviderContainer();
    addTearDown(c.dispose);

    await c.read(bloqueadosProvider.notifier).bloquear('pesado');
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(c.read(bloqueadosProvider), contains('pesado'));
  });

  test('sin tocar nada, lo guardado sí se aplica', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'catacroket.midieta.v1': <String>['vegana'],
    });
    final ProviderContainer c = ProviderContainer();
    addTearDown(c.dispose);

    c.read(miDietaProvider);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(c.read(miDietaProvider), <Dieta>{Dieta.vegana});
  });
}
