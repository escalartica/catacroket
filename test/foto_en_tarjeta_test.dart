import 'package:catacroket/core/models/cata.dart';
import 'package:catacroket/core/models/corte.dart';
import 'package:catacroket/core/models/medio.dart';
import 'package:catacroket/core/models/persona.dart';
import 'package:catacroket/core/models/sabor.dart';
import 'package:catacroket/features/vitrina/widgets/tarjeta_cata.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// La foto del usuario, en el feed.
///
/// Antes una foto propia se reducía a una pastillita que ponía «📷 Foto» y el
/// plato enseñaba el dibujo igualmente: quien se molestaba en fotografiar su
/// croqueta no volvía a verla.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  Cata cata({List<Medio> medios = const <Medio>[]}) => Cata(
        id: 'una',
        sitio: 'Bar Manoli',
        ciudad: 'Sevilla',
        corte: const Corte(crujiente: 8, cremosidad: 8, sabor: 8, relleno: 8),
        sabores: const <Sabor>[Sabor(rellenoId: 'jamon')],
        autorId: 'tu',
        mesas: const <String>[],
        fecha: DateTime(2026, 3, 14),
        medios: medios,
      );

  Future<void> montar(WidgetTester tester, Cata c) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: TarjetaCata(
              cata: c,
              autor: Persona.desconocida,
              onTap: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  testWidgets('sin foto, el plato es el dibujo', (WidgetTester tester) async {
    await montar(tester, cata());

    expect(find.byType(Image), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('con foto, la foto manda', (WidgetTester tester) async {
    await montar(
      tester,
      cata(medios: const <Medio>[
        Medio(tipo: TipoMedio.foto, ruta: '/tmp/croqueta.jpg'),
      ]),
    );

    expect(find.byType(Image), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('con vídeo pero sin foto se queda el dibujo', (
    WidgetTester tester,
  ) async {
    // Un fotograma de vídeo no se saca sin descodificarlo, y hacerlo para
    // cada tarjeta de una lista es caro. El dibujo nunca falla.
    await montar(
      tester,
      cata(medios: const <Medio>[
        Medio(tipo: TipoMedio.video, ruta: '/tmp/croqueta.mp4'),
      ]),
    );

    expect(find.byType(Image), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
