import 'package:catacroket/core/models/dieta.dart';
import 'package:catacroket/core/providers/mi_dieta_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer contenedor;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    contenedor = ProviderContainer();
    await Future<void>.delayed(Duration.zero);
  });

  tearDown(() => contenedor.dispose());

  MiDietaNotifier notifier() => contenedor.read(miDietaProvider.notifier);
  Set<Dieta> dietas() => contenedor.read(miDietaProvider);

  group('MiDietaNotifier', () {
    test('de partida no hay ninguna dieta puesta', () {
      expect(dietas(), isEmpty);
    });

    test('alternar la pone y volver a alternar la quita', () async {
      await notifier().alternar(Dieta.vegana);
      expect(dietas(), contains(Dieta.vegana));

      await notifier().alternar(Dieta.vegana);
      expect(dietas(), isNot(contains(Dieta.vegana)));
    });

    test('se pueden llevar varias a la vez', () async {
      await notifier().alternar(Dieta.vegana);
      await notifier().alternar(Dieta.sinGluten);

      expect(dietas(), hasLength(2));
    });

    test('quitar una no se lleva por delante las otras', () async {
      await notifier().alternar(Dieta.vegana);
      await notifier().alternar(Dieta.sinGluten);

      await notifier().alternar(Dieta.vegana);

      expect(dietas(), <Dieta>{Dieta.sinGluten});
    });

    test('limpiar las quita todas', () async {
      await notifier().alternar(Dieta.vegana);
      await notifier().alternar(Dieta.sinGluten);

      await notifier().limpiar();

      expect(dietas(), isEmpty);
    });

    test('limpiar con la lista ya vacía no rompe', () async {
      await notifier().limpiar();
      expect(dietas(), isEmpty);
    });

    test('el estado se reemplaza, no se muta', () async {
      final Set<Dieta> antes = dietas();

      await notifier().alternar(Dieta.vegana);

      expect(identical(antes, dietas()), isFalse);
      expect(antes, isEmpty);
    });
  });
}
