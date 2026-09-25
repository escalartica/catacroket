import 'package:catacroket/core/models/cata.dart';
import 'package:catacroket/core/models/corte.dart';
import 'package:catacroket/core/models/sabor.dart';
import 'package:catacroket/core/providers/catas_provider.dart';
import 'package:catacroket/features/detalle/detalle_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Quién ganó y quién perdió en una bandeja.
///
/// El modelo ya lo calculaba y no se enseñaba en ninguna pantalla. Es la
/// frase que se dice al salir del bar, y por eso vale la pena tenerla
/// protegida: es fácil que alguien la quite creyendo que sobra.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  Cata conSabores(List<Sabor> sabores) => Cata(
        id: 'bandeja',
        sitio: 'Bar Manoli',
        ciudad: 'Sevilla',
        corte: const Corte(crujiente: 7, cremosidad: 7, sabor: 7, relleno: 7),
        sabores: sabores,
        autorId: 'tu',
        mesaId: 'libreta',
        fecha: DateTime(2026, 3, 14),
      );

  Future<void> montar(WidgetTester tester, Cata cata) async {
    final ProviderContainer contenedor = ProviderContainer();
    addTearDown(contenedor.dispose);
    contenedor.read(catasProvider.notifier).state = <Cata>[cata];

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: contenedor,
        child: MaterialApp(
          home: Scaffold(body: DetallePage(cataId: cata.id)),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  testWidgets('dice cuál ganó y cuál perdió', (WidgetTester tester) async {
    await montar(
      tester,
      conSabores(const <Sabor>[
        Sabor(rellenoId: 'calamar', veredicto: Veredicto.religiosas),
        Sabor(rellenoId: 'jamon', veredicto: Veredicto.mediocres),
        Sabor(rellenoId: 'pollo', veredicto: Veredicto.buenas),
      ]),
    );

    expect(find.textContaining('Ganó la de'), findsOneWidget);
    expect(find.textContaining('La peor, la de'), findsOneWidget);
  });

  testWidgets('con empate dice el empate, no «ganó y perdió la misma»', (
    WidgetTester tester,
  ) async {
    await montar(
      tester,
      conSabores(const <Sabor>[
        Sabor(rellenoId: 'calamar', veredicto: Veredicto.buenas),
        Sabor(rellenoId: 'jamon', veredicto: Veredicto.buenas),
      ]),
    );

    expect(find.textContaining('Todas igual de'), findsOneWidget);
    expect(find.textContaining('Ganó la de'), findsNothing);
  });

  testWidgets('una croqueta sola no tiene bandeja que comparar', (
    WidgetTester tester,
  ) async {
    await montar(
      tester,
      conSabores(const <Sabor>[
        Sabor(rellenoId: 'jamon', veredicto: Veredicto.muyBuenas),
      ]),
    );

    expect(find.textContaining('Ganó la de'), findsNothing);
    expect(find.textContaining('Todas igual de'), findsNothing);
  });
}
