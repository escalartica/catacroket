import 'dart:convert';

import 'package:catacroket/core/models/cata.dart';
import 'package:catacroket/core/models/corte.dart';
import 'package:catacroket/core/models/lugar.dart';
import 'package:catacroket/core/models/sabor.dart';
import 'package:catacroket/core/models/tiro_al_plato.dart';
import 'package:catacroket/core/providers/borrador_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// La cata a medio escribir.
///
/// Es lo único de la app que cuesta trabajo hacer y no estaba guardado en
/// ninguna parte: vivía en memoria y se iba con la app. Y el escenario no es
/// raro, es el normal. Estás en el bar, abres la cámara para fotografiar la
/// croqueta y iOS mata la app por memoria. Entra una llamada. Te vas a
/// contestar un mensaje. Vuelves y el formulario está en blanco.
///
/// La app ya preguntaba «¿dejar la cata a medias?» al salir, o sea que sabía
/// que eso se perdía. Lo que no cubría era lo que el usuario no decide.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const String clave = 'catacroket.borrador.v1';

  /// Un contenedor con la lectura del disco ya hecha.
  ///
  /// El `read` no sobra: los providers de Riverpod son perezosos y sin él el
  /// notifier no existe todavía, así que esperar no serviría de nada.
  Future<ProviderContainer> arrancar() async {
    final ProviderContainer c = ProviderContainer();
    c.read(borradorProvider);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return c;
  }

  /// Da tiempo a que el guardado, que espera medio segundo, llegue al disco.
  Future<void> dejarGuardar() =>
      Future<void>.delayed(const Duration(milliseconds: 700));

  Future<String?> loGuardado() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(clave);
  }

  /// Envuelve un borrador con la fecha que tendría al guardarse.
  String comoGuardado(Map<String, dynamic> borrador, DateTime cuando) =>
      jsonEncode(<String, dynamic>{
        'cuando': cuando.toIso8601String(),
        'borrador': borrador,
      });

  group('Lo escrito sobrevive a que se cierre la app', () {
    test('el sitio vuelve al abrirla otra vez', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final ProviderContainer antes = await arrancar();
      antes.read(borradorProvider.notifier).sitio('Casa Ricardo');
      await dejarGuardar();
      antes.dispose();

      // La app se cierra y se vuelve a abrir: contenedor nuevo, mismo disco.
      final ProviderContainer despues = await arrancar();
      final Borrador b = despues.read(borradorProvider);
      despues.dispose();

      expect(b.sitio, 'Casa Ricardo');
    });

    test('vuelve entero, no sólo el nombre del bar', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final ProviderContainer antes = await arrancar();
      final BorradorNotifier n = antes.read(borradorProvider.notifier);
      n.sitio('Casa Ricardo');
      n.ciudad('Sevilla');
      n.nota('Estaba muy buena');
      n.tiro(TiroAlPlato.crujientePerfecto);
      await dejarGuardar();
      antes.dispose();

      final ProviderContainer despues = await arrancar();
      final Borrador b = despues.read(borradorProvider);
      despues.dispose();

      expect(b.ciudad, 'Sevilla');
      expect(b.nota, 'Estaba muy buena');
      expect(b.tiro, TiroAlPlato.crujientePerfecto);
    });

    test('sin nada escrito no deja basura guardada', () async {
      // Un guardado vacío haría que al arrancar hubiera siempre algo que
      // recuperar, y no hay nada que recuperar.
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final ProviderContainer c = await arrancar();
      c.read(borradorProvider.notifier).eje('crujiente', 9);
      await dejarGuardar();
      c.dispose();

      expect(await loGuardado(), isNull);
    });

    test('al limpiarlo se borra del disco', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final ProviderContainer c = await arrancar();
      c.read(borradorProvider.notifier).sitio('Casa Ricardo');
      await dejarGuardar();
      expect(await loGuardado(), isNotNull);

      c.read(borradorProvider.notifier).limpiar();
      await dejarGuardar();
      c.dispose();

      expect(await loGuardado(), isNull);
    });
  });

  group('Corregir una cata NO se guarda', () {
    /// Esto no es una funcionalidad que falte: es lo que evita un desastre.
    ///
    /// Un borrador de corrección lleva el id de la cata que se está
    /// corrigiendo. Si volviera al abrir el formulario y el usuario no se
    /// diera cuenta de en qué está, darle a publicar pisaría una cata que ya
    /// existía, con lo que hubiera escrito otro día.
    Cata cata() => Cata(
          id: 'la-de-mi-boda',
          sitio: 'Casa Ricardo',
          ciudad: 'Sevilla',
          corte: const Corte(crujiente: 8, cremosidad: 7, sabor: 9, relleno: 6),
          sabores: const <Sabor>[Sabor(rellenoId: 'jamon')],
          autorId: 'tu',
          mesaId: 'libreta',
          fecha: DateTime(2026, 3, 14),
        );

    test('una corrección a medias no llega al disco', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final ProviderContainer c = await arrancar();
      c.read(borradorProvider.notifier).desdeCata(cata());
      c.read(borradorProvider.notifier).nota('cambiando la nota');
      await dejarGuardar();
      c.dispose();

      expect(await loGuardado(), isNull);
    });

    test('y si alguien mete uno a mano, vuelve como cata nueva', () async {
      // Defensa en profundidad: aunque el guardado se saltara la regla, lo
      // que se recupera nunca puede traer a qué cata pisar.
      SharedPreferences.setMockInitialValues(<String, Object>{
        clave: comoGuardado(
          <String, dynamic>{'sitio': 'Casa Ricardo', 'editando': 'la-de-mi-boda'},
          DateTime.now(),
        ),
      });

      final ProviderContainer c = await arrancar();
      final Borrador b = c.read(borradorProvider);
      c.dispose();

      expect(b.sitio, 'Casa Ricardo');
      expect(b.editando, isNull, reason: 'un borrador recuperado es una cata '
          'nueva, nunca una corrección de otra');
      expect(b.esEdicion, isFalse);
    });
  });

  group('Lo viejo no vuelve', () {
    test('un borrador de hace una semana se tira', () async {
      // Volver a «apuntar una cata» y encontrarte media cata de un bar que no
      // recuerdas confunde más de lo que ayuda.
      SharedPreferences.setMockInitialValues(<String, Object>{
        clave: comoGuardado(
          <String, dynamic>{'sitio': 'De hace mucho'},
          DateTime.now().subtract(const Duration(days: 7)),
        ),
      });

      final ProviderContainer c = await arrancar();
      final Borrador b = c.read(borradorProvider);
      c.dispose();

      expect(b.sitio, isEmpty);
      expect(await loGuardado(), isNull, reason: 'y se limpia al pasar');
    });

    test('el del viernes por la noche vuelve el sábado', () async {
      // Se queda el móvil sin batería y lo cargas al día siguiente. Eso tiene
      // que volver: es exactamente para lo que existe esto.
      SharedPreferences.setMockInitialValues(<String, Object>{
        clave: comoGuardado(
          <String, dynamic>{'sitio': 'Casa Ricardo'},
          DateTime.now().subtract(const Duration(hours: 14)),
        ),
      });

      final ProviderContainer c = await arrancar();
      final Borrador b = c.read(borradorProvider);
      c.dispose();

      expect(b.sitio, 'Casa Ricardo');
    });

    test('un guardado sin fecha no se recupera', () async {
      // No se puede saber si es de hace una hora o de hace un año.
      SharedPreferences.setMockInitialValues(<String, Object>{
        clave: jsonEncode(<String, dynamic>{
          'borrador': <String, dynamic>{'sitio': 'Sin fecha'},
        }),
      });

      final ProviderContainer c = await arrancar();
      final Borrador b = c.read(borradorProvider);
      c.dispose();

      expect(b.sitio, isEmpty);
    });

    test('un guardado corrupto no impide abrir el formulario', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        clave: 'esto no es json {{{',
      });

      final ProviderContainer c = await arrancar();
      final Borrador b = c.read(borradorProvider);
      c.dispose();

      expect(b.sitio, isEmpty);
      expect(await loGuardado(), isNull, reason: 'y se tira, no se reintenta');
    });
  });

  group('Ida y vuelta de cada campo', () {
    test('el lugar del mapa vuelve con su nombre y sus coordenadas', () {
      const Borrador b = Borrador(
        sitio: 'Casa Ricardo',
        lugar: Lugar(
          nombre: 'Casa Ricardo',
          lat: 37.3886,
          lon: -5.9885,
          ciudad: 'Sevilla',
          pais: 'ES',
        ),
      );

      final Borrador vuelta = Borrador.fromJson(b.toJson());

      expect(vuelta.lugar?.nombre, 'Casa Ricardo');
      expect(vuelta.lugar?.lat, closeTo(37.3886, 0.0001));
      expect(vuelta.lugar?.lon, closeTo(-5.9885, 0.0001));
      expect(vuelta.lugar?.ciudad, 'Sevilla');
    });

    test('un surtido vuelve siendo un surtido, con sus sabores', () {
      const Borrador b = Borrador(
        sitio: 'Casa Ricardo',
        surtido: true,
        sabores: <Sabor>[
          Sabor(rellenoId: 'jamon'),
          Sabor(rellenoId: 'boletus'),
        ],
      );

      final Borrador vuelta = Borrador.fromJson(b.toJson());

      expect(vuelta.surtido, isTrue);
      expect(vuelta.sabores, hasLength(2));
      expect(vuelta.sabores.last.rellenoId, 'boletus');
    });

    test('un borrador vacío va y vuelve sin inventarse nada', () {
      final Borrador vuelta = Borrador.fromJson(const Borrador().toJson());

      expect(vuelta.tieneAlgoEscrito, isFalse);
      expect(vuelta.sabores, isEmpty);
      expect(vuelta.tiro, isNull);
      expect(vuelta.lugar, isNull);
    });
  });

  group('Qué cuenta como «algo escrito»', () {
    test('las notas de los deslizadores, no', () {
      // Todas tienen valor de partida: estar en el paso 3 sin haber tocado
      // nada no es tener trabajo que perder.
      const Borrador b = Borrador(
        corte: Corte(crujiente: 9, cremosidad: 9, sabor: 9, relleno: 9),
      );

      expect(b.tieneAlgoEscrito, isFalse);
    });

    test('el nombre del bar, sí', () {
      expect(const Borrador(sitio: 'Casa Ricardo').tieneAlgoEscrito, isTrue);
    });

    test('un espacio en blanco, no', () {
      expect(const Borrador(sitio: '   ').tieneAlgoEscrito, isFalse);
    });

    test('una foto, sí: es lo que más cuesta volver a hacer', () {
      const Borrador b = Borrador(sitio: '', nota: '');
      expect(b.tieneAlgoEscrito, isFalse);
      expect(
        const Borrador(sabores: <Sabor>[Sabor(rellenoId: 'jamon')])
            .tieneAlgoEscrito,
        isTrue,
      );
    });
  });
}
