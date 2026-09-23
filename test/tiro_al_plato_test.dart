import 'package:catacroket/core/models/cata.dart';
import 'package:catacroket/core/models/corte.dart';
import 'package:catacroket/core/models/sabor.dart';
import 'package:catacroket/core/models/tiro_al_plato.dart';
import 'package:catacroket/core/providers/borrador_provider.dart';
import 'package:catacroket/features/nueva_cata/cata_desde_borrador.dart';
import 'package:catacroket/features/nueva_cata/pasos/paso_corte.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// La prueba del tiro al plato.
///
/// La regla que la define: es un apunte, no una nota. Puede convivir con el
/// deslizador de crujiente porque no lo repite —uno dice cuánto crujía y otro
/// cómo sonaba— y porque no entra en el CataScore. Si algún día alguien la
/// mete en la fórmula, estos tests tienen que fallar.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Cata desde(Borrador b) => cataDesdeBorrador(
        b,
        nuevoId: () => 'x',
        ahora: () => DateTime(2026),
      );

  const Borrador conSitio = Borrador(sitio: 'Bar Manoli');

  group('No toca la nota', () {
    test('la misma cata con y sin tiro puntúa igual', () {
      final Cata sin = desde(conSitio);
      final Cata con = desde(
        conSitio.copyWith(tiro: TiroAlPlato.hormigonArmado),
      );

      expect(con.puntuacion, sin.puntuacion);
    });

    test('ni el peor ni el mejor mueven el CataScore', () {
      final double base = desde(conSitio).puntuacion;

      for (final TiroAlPlato t in TiroAlPlato.values) {
        expect(
          desde(conSitio.copyWith(tiro: t)).puntuacion,
          base,
          reason: '${t.nombre} ha cambiado la nota, y no debería',
        );
      }
    });

    test('tampoco toca el corte, que es lo que dibuja', () {
      final Corte sin = desde(conSitio).corte;
      final Corte con =
          desde(conSitio.copyWith(tiro: TiroAlPlato.seDeshace)).corte;

      expect(con.crujiente, sin.crujiente);
      expect(con.cremosidad, sin.cremosidad);
      expect(con.sabor, sin.sabor);
      expect(con.relleno, sin.relleno);
    });
  });

  group('Marcar y desmarcar', () {
    late ProviderContainer contenedor;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      contenedor = ProviderContainer();
      contenedor.read(borradorProvider);
      await Future<void>.delayed(Duration.zero);
    });

    tearDown(() => contenedor.dispose());

    BorradorNotifier notifier() => contenedor.read(borradorProvider.notifier);
    TiroAlPlato? actual() => contenedor.read(borradorProvider).tiro;

    test('de partida no hay ninguno: es opcional', () {
      expect(actual(), isNull);
    });

    test('tocar uno lo marca', () {
      notifier().tiro(TiroAlPlato.sonidoMetalico);
      expect(actual(), TiroAlPlato.sonidoMetalico);
    });

    test('tocar otro cambia: sólo suena de una manera', () {
      notifier().tiro(TiroAlPlato.sonidoMetalico);
      notifier().tiro(TiroAlPlato.aceitoso);

      expect(actual(), TiroAlPlato.aceitoso);
    });

    test('tocar el que ya está lo quita', () {
      // Es un apunte opcional: hay que poder deshacerlo sin salir del paso.
      notifier().tiro(TiroAlPlato.muyFino);
      notifier().tiro(TiroAlPlato.muyFino);

      expect(actual(), isNull);
    });
  });

  group('Se guarda y vuelve', () {
    test('llega a la cata publicada', () {
      final Cata cata =
          desde(conSitio.copyWith(tiro: TiroAlPlato.crujientePerfecto));

      expect(cata.tiro, TiroAlPlato.crujientePerfecto);
    });

    test('sobrevive a ir al disco y volver', () {
      final Cata original =
          desde(conSitio.copyWith(tiro: TiroAlPlato.hormigonArmado));

      final Cata vuelta = Cata.fromJson(original.toJson());

      expect(vuelta.tiro, TiroAlPlato.hormigonArmado);
    });

    test('sin tiro, vuelve sin tiro y no inventa uno', () {
      final Cata vuelta = Cata.fromJson(desde(conSitio).toJson());
      expect(vuelta.tiro, isNull);
    });
  });

  group('Catas de otras versiones', () {
    /// El JSON mínimo de una cata, sin el campo del tiro.
    Map<String, dynamic> crudo({Object? tiro}) {
      final Cata base = Cata(
        id: 'x',
        sitio: 'Bar',
        ciudad: 'Sevilla',
        corte: const Corte(crujiente: 7, cremosidad: 7, sabor: 7, relleno: 7),
        sabores: const <Sabor>[Sabor(rellenoId: 'jamon')],
        autorId: 'tu',
        mesaId: 'libreta',
        fecha: DateTime(2026),
      );
      final Map<String, dynamic> json = base.toJson();
      if (tiro == null) {
        json.remove('tiro');
      } else {
        json['tiro'] = tiro;
      }
      return json;
    }

    test('una cata guardada antes de esto se abre sin problema', () {
      expect(Cata.fromJson(crudo()).tiro, isNull);
    });

    test('un valor que aquí no existe se ignora, no revienta', () {
      // Pasa al volver de una versión más nueva a una más vieja.
      expect(Cata.fromJson(crudo(tiro: 'sonidoDeCampana')).tiro, isNull);
    });

    test('un valor que no es texto tampoco revienta', () {
      expect(Cata.fromJson(crudo(tiro: 42)).tiro, isNull);
    });
  });

  group('En la pantalla del corte', () {
    Future<void> montar(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: PasoCorte()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('los seis están puestos', (WidgetTester tester) async {
      await montar(tester);

      for (final TiroAlPlato t in TiroAlPlato.values) {
        expect(find.text(t.nombre), findsOneWidget, reason: t.id);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('se presenta como opcional, porque lo es', (
      WidgetTester tester,
    ) async {
      await montar(tester);

      expect(find.text('La prueba del tiro al plato'), findsOneWidget);
      expect(find.text('opcional'), findsOneWidget);
    });

    testWidgets('sin elegir nada pregunta, no explica', (
      WidgetTester tester,
    ) async {
      await montar(tester);

      expect(find.textContaining('¿Qué se oyó?'), findsOneWidget);
    });

    testWidgets('al elegir uno, explica la coña', (
      WidgetTester tester,
    ) async {
      await montar(tester);

      await tester.tap(find.text('Hormigón armado'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Rebotó. Ahí hay obra.'), findsOneWidget);
    });

    testWidgets('no bloquea el paso: sigue sin ser obligatorio', (
      WidgetTester tester,
    ) async {
      await montar(tester);

      // La pantalla se monta y funciona sin haber tocado ningún chip. Si
      // algún día se volviera obligatorio, esto seguiría pasando pero el
      // botón de abajo dejaría de habilitarse, y eso se ve en otro test.
      expect(tester.takeException(), isNull);
    });
  });

  group('Los textos', () {
    test('todos tienen nombre, emoji y explicación', () {
      for (final TiroAlPlato t in TiroAlPlato.values) {
        expect(t.nombre, isNotEmpty, reason: t.id);
        expect(t.emoji, isNotEmpty, reason: t.id);
        expect(t.queSignifica, isNotEmpty, reason: t.id);
      }
    });

    test('los identificadores no se repiten: son lo que se guarda', () {
      final Set<String> ids =
          TiroAlPlato.values.map((TiroAlPlato t) => t.id).toSet();
      expect(ids, hasLength(TiroAlPlato.values.length));
    });
  });
}
