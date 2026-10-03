import 'package:catacroket/core/models/medio.dart';
import 'package:catacroket/core/theme/components/foto_medio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Las fotos que viajan entre móviles.
///
/// Una foto podía estar sólo en el móvil que la hizo, y por eso la gente de
/// una mesa compartida nunca veía las croquetas de los demás; y al reinstalar
/// la app, tampoco las suyas. Ahora viaja comprimida dentro de la cata.
void main() {
  group('el medio guarda dónde está', () {
    test('recién hecha, todavía no viaja', () {
      const Medio m = Medio(tipo: TipoMedio.foto, ruta: '/tmp/croqueta.jpg');
      expect(m.viaja, isFalse);
      expect(m.sePuedeVer, isTrue);
    });

    test('la miniatura NO se guarda en el móvil', () {
      // En este teléfono está el fichero entero, así que la copia pequeña
      // aquí sólo estorba: pesa hasta 440 KB, hay dos por cata, y el guardado
      // de TODAS las catas se reescribe entero en cada mordisco. Cuarenta
      // catas compartidas eran ~35 MB volcándose a disco por un mordisco.
      const Medio m = Medio(
        tipo: TipoMedio.foto,
        ruta: '/tmp/croqueta.jpg',
        mini: 'eyJ1bmEiOiAiZm90byJ9',
      );
      final Medio vuelta = Medio.fromJson(m.toJson());
      expect(vuelta.ruta, '/tmp/croqueta.jpg');
      expect(vuelta.mini, isNull);
    });

    test('la miniatura sí sobrevive al viaje a la nube', () {
      // Allí es justo lo único que sirve: la ruta de este móvil no abre nada
      // en el de tu gente.
      const Medio m = Medio(
        tipo: TipoMedio.foto,
        ruta: '/tmp/croqueta.jpg',
        mini: 'eyJ1bmEiOiAiZm90byJ9',
      );
      final Medio vuelta = Medio.fromJson(m.paraViajar.toJsonParaLaNube());
      expect(vuelta.mini, 'eyJ1bmEiOiAiZm90byJ9');
      expect(vuelta.viaja, isTrue);
    });

    test('al otro móvil se le manda sin la ruta de éste', () {
      const Medio m = Medio(
        tipo: TipoMedio.foto,
        ruta: '/var/mobile/mi-movil/croqueta.jpg',
        mini: 'eyJ1bmEiOiAiZm90byJ9',
      );
      expect(m.paraViajar.ruta, isEmpty);
      expect(m.paraViajar.mini, 'eyJ1bmEiOiAiZm90byJ9');
    });

    test('una foto de otro móvil, sin ruta, se puede ver igual', () {
      const Medio m = Medio(
        tipo: TipoMedio.foto,
        ruta: '',
        mini: 'eyJ1bmEiOiAiZm90byJ9',
      );
      expect(m.sePuedeVer, isTrue);
    });
  });

  group('qué se pinta', () {
    Future<void> montar(WidgetTester tester, Medio medio) => tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FotoMedio(
                medio: medio,
                siFalla: () => const Text('el dibujo'),
              ),
            ),
          ),
        );

    testWidgets('sin foto ni url, el dibujo', (WidgetTester tester) async {
      await montar(tester, const Medio(tipo: TipoMedio.foto, ruta: ''));
      expect(find.text('el dibujo'), findsOneWidget);
    });

    testWidgets('sin fichero, se pinta la miniatura que viajó', (
      WidgetTester tester,
    ) async {
      await montar(
        tester,
        const Medio(
          tipo: TipoMedio.foto,
          ruta: '',
          mini: 'eyJ1bmEiOiAiZm90byJ9',
        ),
      );
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('con fichero local manda el fichero, que es instantáneo', (
      WidgetTester tester,
    ) async {
      await montar(
        tester,
        const Medio(
          tipo: TipoMedio.foto,
          ruta: '/tmp/croqueta.jpg',
          mini: 'eyJ1bmEiOiAiZm90byJ9',
        ),
      );
      expect(find.byType(Image), findsOneWidget);
    });
  });
}
