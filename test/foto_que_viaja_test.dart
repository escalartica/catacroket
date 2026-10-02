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

    test('la miniatura sobrevive al viaje de ida y vuelta', () {
      const Medio m = Medio(
        tipo: TipoMedio.foto,
        ruta: '/tmp/croqueta.jpg',
        mini: 'eyJ1bmEiOiAiZm90byJ9',
      );
      final Medio vuelta = Medio.fromJson(m.toJson());
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
