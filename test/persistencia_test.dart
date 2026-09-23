import 'dart:convert';

import 'package:catacroket/core/data/siembra.dart';
import 'package:catacroket/core/models/cata.dart';
import 'package:catacroket/core/models/corte.dart';
import 'package:catacroket/core/models/dieta.dart';
import 'package:catacroket/core/models/sabor.dart';
import 'package:catacroket/core/providers/catas_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Que lo guardado vuelva, y que lo roto no se lleve por delante la app.
///
/// En la v1 todo vive en el móvil. Si el disco devuelve basura —una
/// actualización a medias, un fichero truncado— lo peor que puede pasar es
/// que el usuario abra la app y no estén sus catas. El notifier ya lo tiene
/// previsto en un `catch`, pero nada lo comprobaba.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const String clave = 'catacroket.catas.v1';

  Cata cata({
    String id = 'guardada',
    String sitio = 'Bar Manoli',
    double? precio,
    double? lat,
    double? lon,
    Set<Dieta> aptas = const <Dieta>{},
  }) =>
      Cata(
        id: id,
        sitio: sitio,
        ciudad: 'Sevilla',
        corte: const Corte(crujiente: 8, cremosidad: 7, sabor: 9, relleno: 6),
        sabores: const <Sabor>[Sabor(rellenoId: 'jamon')],
        autorId: 'tu',
        mesaId: 'libreta',
        fecha: DateTime(2026, 3, 14),
        precio: precio,
        lat: lat,
        lon: lon,
        aptas: aptas,
        nota: 'Estaba muy buena',
      );

  /// Arranca un contenedor y le deja terminar de leer el disco.
  ///
  /// El `read` de la primera línea no sobra: los providers de Riverpod son
  /// perezosos, así que sin él el notifier no existe todavía, la lectura del
  /// disco ni siquiera ha empezado, y esperar no sirve de nada.
  Future<ProviderContainer> arrancar() async {
    final ProviderContainer c = ProviderContainer();
    c.read(catasProvider);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return c;
  }

  group('Ida y vuelta al disco', () {
    test('lo que guardas está al volver a abrir', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final ProviderContainer primera = await arrancar();
      await primera.read(catasProvider.notifier).anadir(cata(id: 'la-mia'));
      primera.dispose();

      // Segunda sesión: mismo disco, contenedor nuevo.
      final ProviderContainer segunda = await arrancar();
      final List<Cata> catas = segunda.read(catasProvider);
      segunda.dispose();

      expect(catas.where((Cata c) => c.id == 'la-mia'), hasLength(1));
    });

    test('vuelve entera, no sólo el nombre', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final ProviderContainer primera = await arrancar();
      await primera.read(catasProvider.notifier).anadir(
            cata(
              id: 'completa',
              precio: 2.20,
              lat: 37.38,
              lon: -6.0,
              aptas: <Dieta>{Dieta.vegana},
            ),
          );
      primera.dispose();

      final ProviderContainer segunda = await arrancar();
      final Cata vuelta =
          segunda.read(catasProvider).firstWhere((Cata c) => c.id == 'completa');
      segunda.dispose();

      expect(vuelta.sitio, 'Bar Manoli');
      expect(vuelta.precio, 2.20);
      expect(vuelta.lat, 37.38);
      expect(vuelta.lon, -6.0);
      expect(vuelta.aptas, contains(Dieta.vegana));
      expect(vuelta.nota, 'Estaba muy buena');
      expect(vuelta.corte.crujiente, 8);
      expect(vuelta.fecha, DateTime(2026, 3, 14));
    });

    test('borrar también se guarda', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final ProviderContainer primera = await arrancar();
      final CatasNotifier n = primera.read(catasProvider.notifier);
      await n.anadir(cata(id: 'efimera'));
      await n.borrar('efimera');
      primera.dispose();

      final ProviderContainer segunda = await arrancar();
      final List<Cata> catas = segunda.read(catasProvider);
      segunda.dispose();

      expect(catas.where((Cata c) => c.id == 'efimera'), isEmpty);
    });
  });

  /// Lo que da sentido a este grupo es el de arriba: allí se comprueba que un
  /// guardado bueno SÍ vuelve. Sin ese contraste, "vuelve la siembra" se
  /// cumpliría también si la carga del disco no se ejecutara jamás.
  group('Un disco roto no deja la app en blanco', () {
    Future<List<Cata>> conGuardado(Object guardado) async {
      SharedPreferences.setMockInitialValues(<String, Object>{clave: guardado});
      final ProviderContainer c = await arrancar();
      final List<Cata> catas = c.read(catasProvider);
      c.dispose();
      return catas;
    }

    /// Comprueba que se ha vuelto a la siembra, no que "haya algo".
    ///
    /// `isNotEmpty` a secas no valdría: la siembra nunca está vacía, así que
    /// el test pasaría aunque la carga del disco no se ejecutara nunca.
    void esLaSiembra(List<Cata> catas) {
      expect(catas.map((Cata c) => c.id), containsAll(_idsDeSiembra()));
    }

    test('un JSON que no es JSON', () async {
      esLaSiembra(await conGuardado('esto no es json {{{'));
    });

    test('un JSON válido que no es una lista de catas', () async {
      esLaSiembra(await conGuardado('{"algo":"otra cosa"}'));
    });

    test('una lista con basura dentro', () async {
      esLaSiembra(await conGuardado('[1, 2, 3]'));
    });

    test('una cata a la que le faltan campos', () async {
      esLaSiembra(
        await conGuardado(jsonEncode(<Map<String, Object>>[
          <String, Object>{'id': 'coja'},
        ])),
      );
    });

    test('una cadena vacía', () async {
      esLaSiembra(await conGuardado(''));
    });

    test('sin nada guardado arranca con la siembra', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final ProviderContainer c = await arrancar();
      final List<Cata> catas = c.read(catasProvider);
      c.dispose();

      esLaSiembra(catas);
    });
  });
}

/// Los identificadores con los que arranca la app cuando no hay nada guardado.
List<String> _idsDeSiembra() =>
    Siembra.catas().map((Cata c) => c.id).toList();
