import 'package:catacroket/core/models/cata.dart';
import 'package:catacroket/core/models/corte.dart';
import 'package:catacroket/core/models/persona.dart';
import 'package:catacroket/core/models/sabor.dart';
import 'package:catacroket/core/providers/catas_provider.dart';
import 'package:catacroket/core/data/siembra.dart';
import 'package:catacroket/features/detalle/detalle_page.dart';
import 'package:catacroket/features/libre/barra_libre_page.dart';
import 'package:catacroket/features/mesas/mesas_page.dart';
import 'package:catacroket/features/perfil/perfil_page.dart';
import 'package:catacroket/features/vitrina/vitrina_page.dart';
import 'package:catacroket/features/vitrina/widgets/tarjeta_cata.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Con el texto grande de los ajustes de accesibilidad.
///
/// En iOS se sube desde Ajustes > Pantalla > Tamaño del texto, y en las
/// opciones de accesibilidad llega bastante más lejos. Quien lo lleva puesto
/// no lo lleva por capricho, y es exactamente quien no puede permitirse una
/// pantalla rota.
///
/// Lo que se comprueba es que nada se desborde: un `RenderFlex` que se sale no
/// lo ve el analizador y en el móvil son rayas amarillas y negras encima del
/// contenido.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  /// Monta [pantalla] en un móvil con el texto a [escala] veces su tamaño.
  Future<void> montar(
    WidgetTester tester,
    Widget pantalla, {
    required double escala,
    List<Cata>? catas,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(440, 956);
    addTearDown(tester.view.reset);

    final ProviderContainer contenedor = ProviderContainer();
    addTearDown(contenedor.dispose);
    if (catas != null) {
      contenedor.read(catasProvider.notifier).state = catas;
    }

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: contenedor,
        child: MaterialApp(
          builder: (BuildContext context, Widget? hijo) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(escala),
            ),
            child: hijo!,
          ),
          home: Scaffold(body: pantalla),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
  }

  Cata cata() => Cata(
        id: 'la-de-hoy',
        sitio: 'Bar Manoli',
        ciudad: 'Sevilla',
        corte: const Corte(crujiente: 9, cremosidad: 8, sabor: 9, relleno: 7),
        sabores: const <Sabor>[Sabor(rellenoId: 'jamon')],
        autorId: 'tu',
        mesaId: 'libreta',
        fecha: DateTime(2026, 3, 14),
        nota: 'Estaba muy buena',
      );

  /// Las escalas que de verdad se usan. 1,3 es subir un par de pasos el
  /// tamaño normal; 2,0 es ya accesibilidad de la de verdad.
  const List<double> escalas = <double>[1.3, 2.0];

  for (final double escala in escalas) {
    group('Con el texto a ${escala}x', () {
      testWidgets('la tarjeta de una cata no se desborda', (
        WidgetTester tester,
      ) async {
        await montar(
          tester,
          Padding(
            padding: const EdgeInsets.all(16),
            child: TarjetaCata(
              cata: cata(),
              autor: Persona.desconocida,
              onTap: () {},
            ),
          ),
          escala: escala,
          catas: <Cata>[cata()],
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('La Vitrina se monta entera', (WidgetTester tester) async {
        await montar(tester, const VitrinaPage(), escala: escala);

        expect(tester.takeException(), isNull);
      });

      testWidgets('la ficha de una cata también', (WidgetTester tester) async {
        final Cata alguna = Siembra.catas().first;

        await montar(
          tester,
          DetallePage(cataId: alguna.id),
          escala: escala,
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('las mesas también', (WidgetTester tester) async {
        await montar(tester, const MesasPage(), escala: escala);

        expect(tester.takeException(), isNull);
      });

      testWidgets('el perfil también', (WidgetTester tester) async {
        await montar(tester, const PerfilPage(), escala: escala);

        expect(tester.takeException(), isNull);
      });

      testWidgets('la Barra Libre también', (WidgetTester tester) async {
        await montar(tester, const BarraLibrePage(), escala: escala);

        expect(tester.takeException(), isNull);
      });
    });
  }
}
