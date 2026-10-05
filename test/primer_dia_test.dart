import 'package:catacroket/core/models/cata.dart';
import 'package:catacroket/core/models/corte.dart';
import 'package:catacroket/core/models/sabor.dart';
import 'package:catacroket/core/providers/catas_provider.dart';
import 'package:catacroket/core/providers/perfil_provider.dart';
import 'package:catacroket/core/providers/yo_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// El primer día de alguien que se baja la app de la tienda.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  Cata deOtro({List<String> acompanantes = const <String>[]}) => Cata(
        id: 'suya',
        sitio: 'Bar',
        ciudad: 'Sevilla',
        corte: const Corte(crujiente: 8, cremosidad: 7, sabor: 9, relleno: 6),
        sabores: const <Sabor>[Sabor(rellenoId: 'jamon')],
        autorId: 'eme',
        autorUid: 'uid-de-eme',
        fecha: DateTime(2026, 10, 1),
        acompanantes: acompanantes,
      );

  test('te nombran de acompañante y aún no has apuntado nada', () {
    // El camino que la app empuja a seguir el primer día: te la instalas,
    // entras con el código en la mesa de un amigo, te pide un nombre, y
    // resulta que tu amigo ya te había puesto de acompañante en sus catas.
    //
    // La guarda pedía «cero catas mías Y cero comidas». Aquí sólo se cumple
    // la primera, así que seguía adelante y hacía `mias.first` sobre una
    // lista vacía: La Vitrina y el Croquetómetro se quedaban en el
    // rectángulo gris de error hasta que apuntaras tu primera cata.
    final ProviderContainer c = ProviderContainer(
      overrides: <Override>[
        catasProvider.overrideWith(
          (Ref ref) => _Catas(ref, <Cata>[deOtro(acompanantes: <String>['Ce'])]),
        ),
        yoProvider.overrideWith((Ref ref) => _Yo('Ce')),
      ],
    );
    addTearDown(c.dispose);

    final Perfil p = c.read(perfilProvider);

    expect(p.catas, 0);
    expect(p.comidas, 1, reason: 'te la comiste, aunque no la apuntaras tú');
    expect(p.media, isNull);
    expect(p.mejor, isNull);
  });

  test('sin catas y sin que nadie te nombre, también aguanta', () {
    final ProviderContainer c = ProviderContainer(
      overrides: <Override>[
        catasProvider.overrideWith((Ref ref) => _Catas(ref, const <Cata>[])),
      ],
    );
    addTearDown(c.dispose);

    expect(c.read(perfilProvider).catas, 0);
  });

  test('con el nombre escrito de otra manera cuenta igual', () {
    // Lo escribe otra persona a mano, así que «Cehache» y «CëHachê» son la
    // misma. Esto ya funcionaba; la prueba es para que siga haciéndolo.
    final ProviderContainer c = ProviderContainer(
      overrides: <Override>[
        catasProvider.overrideWith(
          (Ref ref) => _Catas(ref, <Cata>[deOtro(acompanantes: <String>['cehache'])]),
        ),
        yoProvider.overrideWith((Ref ref) => _Yo('CëHachê')),
      ],
    );
    addTearDown(c.dispose);

    expect(c.read(perfilProvider).comidas, 1);
  });
}

class _Catas extends CatasNotifier {
  _Catas(super.ref, List<Cata> catas) {
    state = catas;
  }
}

class _Yo extends YoNotifier {
  _Yo(String nombre) {
    state = state.copiaCon(nombre: nombre);
  }
}
