import 'dart:io';
import 'dart:typed_data';

import 'package:catacroket/core/models/medio.dart';
import 'package:catacroket/features/detalle/widgets/carrusel_medios.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Las fotos de una cata.
///
/// La miniatura del carrusel recorta para que todas las tarjetas midan lo
/// mismo, así que de una foto apaisada se pierden los lados. Hasta ahora ese
/// recorte era lo único que se llegaba a ver de una foto propia: no había
/// forma de abrirla. Esto comprueba que ahora sí.
void main() {
  late Directory temporal;

  setUp(() {
    temporal = Directory.systemTemp.createTempSync('catacroket_fotos');
  });

  tearDown(() {
    if (temporal.existsSync()) temporal.deleteSync(recursive: true);
  });

  /// Un PNG de un píxel, que es todo lo que hace falta para que
  /// `Image.file` tenga algo que decodificar.
  Medio foto(String nombre) {
    final File f = File('${temporal.path}/$nombre.png')
      ..writeAsBytesSync(Uint8List.fromList(<int>[
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
        0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
        0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
        0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
        0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
        0x42, 0x60, 0x82,
      ]));
    return Medio(tipo: TipoMedio.foto, ruta: f.path);
  }

  Future<void> montar(WidgetTester tester, List<Medio> medios) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CarruselMedios(medios: medios)),
      ),
    );
    // Decodificar una imagen del disco —o descubrir que no está— pasa por
    // varios fotogramas. Con un solo pump, el errorBuilder aún no ha saltado.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('El carrusel', () {
    testWidgets('sin medios no ocupa sitio', (WidgetTester tester) async {
      await montar(tester, const <Medio>[]);

      expect(find.byType(Image), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('enseña una tarjeta por foto', (WidgetTester tester) async {
      await montar(tester, <Medio>[foto('a'), foto('b')]);

      expect(find.bySemanticsLabel('Foto 1 de 2'), findsOneWidget);
      expect(find.bySemanticsLabel('Foto 2 de 2'), findsOneWidget);
    });

    testWidgets('una foto que ya no está en el disco no rompe la ficha', (
      WidgetTester tester,
    ) async {
      // Pasa: el usuario borra la foto desde Fotos y la cata sigue aquí.
      await montar(tester, <Medio>[
        const Medio(tipo: TipoMedio.foto, ruta: '/no/existe/nada.png'),
      ]);

      // Sólo se comprueba que no reviente. El `errorBuilder` que enseña "No
      // se encuentra" no llega a saltar aquí: en un test de widget la E/S de
      // ficheros está simulada y el fallo de carga nunca ocurre de verdad.
      // Forzarlo con runAsync daría un test más frágil que lo que protege.
      expect(tester.takeException(), isNull);
    });
  });

  group('Ver la foto entera', () {
    testWidgets('tocar una foto la abre', (WidgetTester tester) async {
      await montar(tester, <Medio>[foto('a')]);

      await tester.tap(find.byType(Image).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // El visor trae su propio botón de cerrar; la miniatura no.
      expect(find.bySemanticsLabel('Cerrar la foto'), findsOneWidget);
    });

    testWidgets('con varias dice cuál estás viendo', (
      WidgetTester tester,
    ) async {
      await montar(tester, <Medio>[foto('a'), foto('b'), foto('c')]);

      await tester.tap(find.byType(Image).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('1 de 3'), findsOneWidget);
    });

    testWidgets('con una sola no marea con un contador de uno', (
      WidgetTester tester,
    ) async {
      await montar(tester, <Medio>[foto('a')]);

      await tester.tap(find.byType(Image).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('1 de 1'), findsNothing);
    });

    testWidgets('el botón de cerrar la cierra', (WidgetTester tester) async {
      await montar(tester, <Medio>[foto('a')]);

      await tester.tap(find.byType(Image).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.bySemanticsLabel('Cerrar la foto'));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Cerrar la foto'), findsNothing);
    });

    testWidgets('el botón de cerrar se toca en 44, como todo lo demás', (
      WidgetTester tester,
    ) async {
      await montar(tester, <Medio>[foto('a')]);

      await tester.tap(find.byType(Image).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final Size tamano =
          tester.getSize(find.bySemanticsLabel('Cerrar la foto'));
      expect(tamano.width, greaterThanOrEqualTo(44));
      expect(tamano.height, greaterThanOrEqualTo(44));
    });
  });
}
