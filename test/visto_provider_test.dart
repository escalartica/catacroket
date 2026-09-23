import 'package:catacroket/core/providers/visto_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer contenedor;

  /// Arranca y espera a que el notifier haya leido el disco de verdad.
  ///
  /// Un solo tick de microtask no basta: SharedPreferences.getInstance()
  /// encadena varios saltos antes de contestar.
  Future<void> arrancar([Map<String, Object> guardado = const {}]) async {
    SharedPreferences.setMockInitialValues(guardado);
    contenedor = ProviderContainer();
    await _esperarCarga(contenedor);
  }

  tearDown(() => contenedor.dispose());

  group('VistoNotifier', () {
    test('de partida no se ha visto nada', () async {
      await arrancar();
      expect(contenedor.read(vistoProvider), isEmpty);
    });

    test('marcar deja constancia', () async {
      await arrancar();

      await contenedor.read(vistoProvider.notifier).marcar(Visto.pistaRuta);

      expect(contenedor.read(vistoProvider), contains(Visto.pistaRuta.id));
    });

    test('marcar dos veces no duplica ni rompe', () async {
      await arrancar();
      final VistoNotifier notifier = contenedor.read(vistoProvider.notifier);

      await notifier.marcar(Visto.pistaVitrina);
      await notifier.marcar(Visto.pistaVitrina);

      expect(contenedor.read(vistoProvider), hasLength(1));
    });

    test('marcar una cosa no marca las demás', () async {
      await arrancar();

      await contenedor.read(vistoProvider.notifier).marcar(Visto.pistaMesas);

      expect(
        contenedor.read(vistoProvider),
        isNot(contains(Visto.pistaPerfil.id)),
      );
    });

    test('olvidar devuelve todas las explicaciones', () async {
      await arrancar();
      final VistoNotifier notifier = contenedor.read(vistoProvider.notifier);
      await notifier.marcar(Visto.pistaRuta);
      await notifier.marcar(Visto.comoComes);

      await notifier.olvidar();

      expect(contenedor.read(vistoProvider), isEmpty);
    });

    test('el estado se reemplaza, no se muta', () async {
      await arrancar();
      final Set<String> antes = contenedor.read(vistoProvider);

      await contenedor.read(vistoProvider.notifier).marcar(Visto.pistaRuta);

      expect(identical(antes, contenedor.read(vistoProvider)), isFalse);
      expect(antes, isEmpty);
    });
  });

  group('tocaEnsenarProvider', () {
    test('calla hasta haber leído el disco', () async {
      // La regla que evita el parpadeo al arrancar: si se contestara "sí"
      // antes de saber qué hay guardado, la pantalla de "cómo comes" saldría
      // un instante a quien ya la contestó hace meses.
      SharedPreferences.setMockInitialValues(<String, Object>{});
      contenedor = ProviderContainer();

      // Se mira ANTES de que termine la lectura, que es justo el instante
      // que la regla protege.
      expect(contenedor.read(vistoProvider.notifier).cargado, isFalse);
      expect(contenedor.read(tocaEnsenarProvider(Visto.comoComes)), isFalse);

      // Y se le deja terminar, para no dejar un future colgando sobre un
      // contenedor que tearDown va a destruir.
      await _esperarCarga(contenedor);
    });

    test('una vez leído, lo no visto sí toca enseñarlo', () async {
      await arrancar();
      expect(contenedor.read(tocaEnsenarProvider(Visto.comoComes)), isTrue);
    });

    test('lo ya visto no se repite', () async {
      await arrancar();

      await contenedor.read(vistoProvider.notifier).marcar(Visto.pistaRuta);

      expect(contenedor.read(tocaEnsenarProvider(Visto.pistaRuta)), isFalse);
    });

    test('lo guardado de una sesión anterior se respeta', () async {
      await arrancar(<String, Object>{
        'catacroket.visto.v1': <String>[Visto.comoComes.id],
      });

      expect(contenedor.read(tocaEnsenarProvider(Visto.comoComes)), isFalse);
      expect(contenedor.read(tocaEnsenarProvider(Visto.pistaRuta)), isTrue);
    });
  });
}

/// Espera a que VistoNotifier confirme que ya ha leído el disco.
Future<void> _esperarCarga(ProviderContainer contenedor) async {
  for (int i = 0; i < 100; i++) {
    if (contenedor.read(vistoProvider.notifier).cargado) return;
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  fail('VistoNotifier no terminó de cargar');
}
