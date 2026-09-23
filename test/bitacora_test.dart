import 'package:catacroket/core/bitacora.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// La bitácora de fallos.
///
/// Existe porque la app no manda nada a ningún servidor, así que sin esto un
/// fallo en release desaparecía y el usuario sólo podía decir "no me
/// funciona". Lo que se prueba aquí es que no se pierda, que no crezca sin
/// límite, y que el informe se lea.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer contenedor;

  Future<void> arrancar([Map<String, Object> guardado = const {}]) async {
    SharedPreferences.setMockInitialValues(guardado);
    contenedor = ProviderContainer();
    // El read despierta al notifier: sin él es perezoso y no lee el disco.
    contenedor.read(bitacoraProvider);
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }

  tearDown(() => contenedor.dispose());

  BitacoraNotifier notifier() => contenedor.read(bitacoraProvider.notifier);
  List<Fallo> fallos() => contenedor.read(bitacoraProvider);

  group('Apuntar', () {
    test('de partida no hay nada', () async {
      await arrancar();
      expect(fallos(), isEmpty);
    });

    test('un fallo queda apuntado con su origen', () async {
      await arrancar();

      await notifier().apuntar(
        Exception('se rompió algo'),
        StackTrace.current,
        'flutter',
      );

      expect(fallos(), hasLength(1));
      expect(fallos().first.origen, 'flutter');
      expect(fallos().first.que, contains('se rompió algo'));
    });

    test('el más nuevo va primero', () async {
      await arrancar();

      await notifier().apuntar(Exception('el viejo'), null, 'app');
      await notifier().apuntar(Exception('el nuevo'), null, 'app');

      expect(fallos().first.que, contains('el nuevo'));
    });

    test('un fallo en bucle no llena el móvil', () async {
      // Los hay: un error en un build se repite en cada frame. Sin tope, en
      // un minuto habría decenas de miles de líneas guardadas.
      await arrancar();

      for (int i = 0; i < 50; i++) {
        await notifier().apuntar(Exception('el mismo de siempre'), null, 'app');
      }

      expect(fallos().length, lessThanOrEqualTo(20));
    });

    test('al pasarse del tope se tiran los viejos, no los nuevos', () async {
      await arrancar();

      for (int i = 0; i < 25; i++) {
        await notifier().apuntar(Exception('fallo $i'), null, 'app');
      }

      expect(fallos().first.que, contains('fallo 24'));
      expect(
        fallos().where((Fallo f) => f.que.contains('fallo 0')),
        isEmpty,
      );
    });

    test('la pila se recorta: entera no cabe y no hace falta', () async {
      await arrancar();

      await notifier().apuntar(Exception('x'), StackTrace.current, 'app');

      final int lineas = fallos().first.pila.split('\n').length;
      expect(lineas, lessThanOrEqualTo(5));
      expect(fallos().first.pila, isNotEmpty);
    });

    test('sin pila tampoco revienta', () async {
      await arrancar();

      await notifier().apuntar(Exception('sin pila'), null, 'app');

      expect(fallos().first.pila, isEmpty);
    });

    test('limpiar los borra', () async {
      await arrancar();
      await notifier().apuntar(Exception('x'), null, 'app');

      await notifier().limpiar();

      expect(fallos(), isEmpty);
    });
  });

  group('Sobrevive a cerrar la app', () {
    test('lo apuntado sigue ahí al volver', () async {
      await arrancar();
      await notifier().apuntar(Exception('de la sesión anterior'), null, 'app');
      contenedor.dispose();

      contenedor = ProviderContainer();
      contenedor.read(bitacoraProvider);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(
        contenedor.read(bitacoraProvider).first.que,
        contains('de la sesión anterior'),
      );
    });

    test('una bitácora corrupta no impide arrancar', () async {
      // Es lo menos importante que hay guardado: si está rota, se ignora.
      await arrancar(<String, Object>{
        'catacroket.bitacora.v1': 'esto no es json {{{',
      });

      expect(fallos(), isEmpty);
    });
  });

  group('El informe', () {
    test('sin fallos lo dice y no se queda en blanco', () {
      expect(
        informeDe(const <Fallo>[], version: 'v1'),
        contains('sin fallos'),
      );
    });

    test('lleva la versión, la cuenta y cada fallo', () {
      final List<Fallo> lista = <Fallo>[
        Fallo(
          cuando: DateTime(2026, 3, 14, 20, 30),
          origen: 'flutter',
          que: 'RangeError',
          pila: 'linea uno',
        ),
      ];

      final String informe = informeDe(lista, version: 'v1.2');

      expect(informe, contains('v1.2'));
      expect(informe, contains('1 fallo'));
      expect(informe, contains('RangeError'));
      expect(informe, contains('flutter'));
      expect(informe, contains('2026-03-14'));
    });

    test('con varios dice "fallos", no "fallo"', () {
      final List<Fallo> dos = <Fallo>[
        Fallo(cuando: DateTime(2026), origen: 'app', que: 'a', pila: ''),
        Fallo(cuando: DateTime(2026), origen: 'app', que: 'b', pila: ''),
      ];

      expect(informeDe(dos, version: 'v1'), contains('2 fallos'));
    });
  });
}
