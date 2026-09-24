import 'dart:convert';

import 'package:catacroket/core/data/siembra.dart';
import 'package:catacroket/core/errores.dart';
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

  group('Lo que no se ha podido leer no se pierde', () {
    const String ilegible = 'catacroket.catas.ilegible.v1';

    /// Un guardado de verdad que esta versión no sabe interpretar.
    ///
    /// No es un caso de laboratorio: basta con que una actualización cambie
    /// el tipo de un campo y `fromJson` reviente, y entonces le pasa a todos
    /// los usuarios a la vez, el mismo día.
    const String loQueHabia = '[{"id":"la-de-mi-boda",'
        '"sitio":"Casa Ricardo","corte":"esto ya no cuela"}]';

    test('el primer cambio del usuario no lo pisa', () async {
      // Éste era el fallo. Al no poder leer, el estado se quedaba con los
      // datos de demostración; en cuanto el usuario tocaba algo se llamaba a
      // guardar, y guardar escribía la demostración encima de la única copia
      // que existía de sus catas. Sin aviso y sin vuelta atrás.
      SharedPreferences.setMockInitialValues(
        <String, Object>{clave: loQueHabia},
      );
      final ProviderContainer c = await arrancar();

      await c.read(catasProvider.notifier).anadir(cata(id: 'la-de-hoy'));
      c.dispose();

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(ilegible),
        loQueHabia,
        reason: 'lo que no se pudo leer tiene que quedar apartado antes de '
            'que el siguiente guardado lo pise',
      );
    });

    test('lo apartado la primera vez no lo pisa lo de después', () async {
      // Al segundo arranque lo guardado ya es la siembra, que se lee bien. La
      // guarda está por si acaso: el primer apartado es el del usuario, y
      // cualquier otro sería de la app funcionando con la demostración.
      SharedPreferences.setMockInitialValues(<String, Object>{
        clave: 'basura nueva',
        ilegible: loQueHabia,
      });
      final ProviderContainer c = await arrancar();
      c.dispose();

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(ilegible), loQueHabia);
    });

    test('un guardado que se lee bien no aparta nada', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        clave: jsonEncode(<Map<String, dynamic>>[cata().toJson()]),
      });
      final ProviderContainer c = await arrancar();
      c.dispose();

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(ilegible), isNull);
    });

    test('sin nada guardado tampoco', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final ProviderContainer c = await arrancar();
      c.dispose();

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(ilegible), isNull);
    });
  });


  group('Un fallo al leer deja rastro', () {
    // El embudo de errores existía y no lo usaba nadie salvo los fallos no
    // capturados de Flutter. O sea: si alguien decía «he perdido mis catas»,
    // la bitácora que puede mandar desde Ajustes venía vacía. Esto comprueba
    // que los providers están enchufados de verdad, no sólo que el embudo
    // está escrito.
    late List<String> apuntados;

    setUp(() {
      apuntados = <String>[];
      Errores.apuntarEn(
        (Object error, StackTrace? pila, String origen) =>
            apuntados.add(origen),
      );
    });

    tearDown(() => Errores.apuntarEn((_, _, _) {}));

    test('un guardado ilegible se apunta y dice de dónde viene', () async {
      SharedPreferences.setMockInitialValues(
        <String, Object>{clave: 'esto no es json {{{'},
      );
      final ProviderContainer c = await arrancar();
      c.dispose();

      expect(apuntados, contains('catas.cargar'));
    });

    test('un arranque normal no apunta nada', () async {
      // Un embudo que se queja cuando todo va bien es un embudo que se acaba
      // ignorando.
      SharedPreferences.setMockInitialValues(<String, Object>{
        clave: jsonEncode(<Map<String, dynamic>>[cata().toJson()]),
      });
      final ProviderContainer c = await arrancar();
      c.dispose();

      expect(apuntados, isEmpty);
    });
  });

}

/// Los identificadores con los que arranca la app cuando no hay nada guardado.
List<String> _idsDeSiembra() =>
    Siembra.catas().map((Cata c) => c.id).toList();
