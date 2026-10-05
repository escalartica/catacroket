import 'package:catacroket/core/models/dieta.dart';
import 'package:catacroket/core/theme/components/campo.dart';
import 'package:catacroket/core/theme/components/pildoras_dieta.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// «Como de todo» tiene que poderse decir, no sólo callarse.
void main() {
  /// La pastilla, y no el nodo que haya debajo.
  ///
  /// `getSemantics(find.text(...))` sube desde el texto hasta el primer nodo
  /// que encuentra, y ése es el del `GestureDetector`: lleva la acción de
  /// tocar y absorbe las etiquetas, pero no las marcas de «puesta» ni de
  /// «se puede tocar», que viven un nivel más arriba. Preguntarle a ése es
  /// preguntar en el sitio equivocado.
  OpcionPildora comoDeTodo(WidgetTester tester) => tester.widget<OpcionPildora>(
        find.ancestor(
          of: find.text('Como de todo'),
          matching: find.byType(OpcionPildora),
        ),
      );

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
    expect(comoDeTodo(tester).activa, isTrue);
  });

  testWidgets('al marcar una dieta se apaga solo', (
    WidgetTester tester,
  ) async {
    await montar(
      tester,
      marcadas: <Dieta>{Dieta.sinGluten},
      onComoDeTodo: () {},
    );

    expect(comoDeTodo(tester).activa, isFalse);
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

  testWidgets('ya puesto se sigue pudiendo tocar', (
    WidgetTester tester,
  ) async {
    // No por lo que hace —no hay nada que limpiar— sino por cómo se ve:
    // una pastilla sin `onTap` se pinta al 42 % de opacidad, que es la
    // manera de decir «esto no se puede tocar». La opción que describe tu
    // estado actual saliendo desvaída se lee como un fallo.
    int veces = 0;
    await montar(
      tester,
      marcadas: const <Dieta>{},
      onComoDeTodo: () => veces++,
    );

    // `onTap` nulo es lo que la pinta al 42 %: eso es lo que no puede pasar.
    expect(comoDeTodo(tester).onTap, isNotNull);

    await tester.tap(find.text('Como de todo'));
    expect(veces, 1);
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
