import 'package:catacroket/core/models/dieta.dart';
import 'package:catacroket/core/theme/components/pildoras_dieta.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// «Como de todo» tiene que poderse decir, no sólo callarse.
void main() {
  Future<void> montar(
    WidgetTester tester, {
    required Set<Dieta> marcadas,
    VoidCallback? onComoDeTodo,
    void Function(Dieta)? onAlternar,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PildorasDieta(
            marcadas: marcadas,
            onAlternar: onAlternar ?? (_) {},
            onComoDeTodo: onComoDeTodo,
          ),
        ),
      ),
    );
  }

  testWidgets('sin nada marcado, «Como de todo» está puesto', (
    WidgetTester tester,
  ) async {
    // Era el estado por defecto y no se veía por ninguna parte: seis
    // pastillas apetecibles sin nada que diga qué significan. Quien come de
    // todo las marcaba TODAS pensando que decía «puedo con todo esto».
    await montar(tester, marcadas: const <Dieta>{}, onComoDeTodo: () {});

    expect(find.text('Como de todo'), findsOneWidget);
    expect(
      tester.getSemantics(find.text('Como de todo')),
      isSemantics(isSelected: true),
    );
  });

  testWidgets('al marcar una dieta se apaga solo', (
    WidgetTester tester,
  ) async {
    await montar(
      tester,
      marcadas: <Dieta>{Dieta.sinGluten},
      onComoDeTodo: () {},
    );

    expect(
      tester.getSemantics(find.text('Como de todo')),
      isSemantics(isSelected: false),
    );
  });

  testWidgets('tocarlo lo desmarca todo', (WidgetTester tester) async {
    int veces = 0;
    await montar(
      tester,
      marcadas: <Dieta>{Dieta.vegana, Dieta.sinGluten},
      onComoDeTodo: () => veces++,
    );

    await tester.tap(find.text('Como de todo'));
    expect(veces, 1);
  });

  testWidgets('ya puesto no hace nada: no hay nada que limpiar', (
    WidgetTester tester,
  ) async {
    int veces = 0;
    await montar(
      tester,
      marcadas: const <Dieta>{},
      onComoDeTodo: () => veces++,
    );

    await tester.tap(find.text('Como de todo'), warnIfMissed: false);
    expect(veces, 0);
  });

  testWidgets('en el formulario de una cata no sale', (
    WidgetTester tester,
  ) async {
    // Allí se describe la croqueta, no cómo comes tú.
    await montar(tester, marcadas: const <Dieta>{});

    expect(find.text('Como de todo'), findsNothing);
    expect(find.text('Vegana'), findsOneWidget);
  });
}
