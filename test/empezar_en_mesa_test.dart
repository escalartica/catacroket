import 'package:catacroket/core/models/cata.dart';
import 'package:catacroket/core/models/corte.dart';
import 'package:catacroket/core/models/sabor.dart';
import 'package:catacroket/core/providers/borrador_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// «Apuntar aquí» tiene que empezar una cata nueva, no continuar la que
/// estuvieras corrigiendo.
///
/// El borrador recuerda qué cata estás corrigiendo. Si te metiste a corregir
/// una y te saliste sin guardar, ese identificador sigue dentro; entrando
/// desde una mesa sin comprobarlo, lo que parecía una cata nueva era aquella
/// misma cata, y al guardar se escribía encima de ella y de sus fotos.
void main() {
  late ProviderContainer contenedor;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    contenedor = ProviderContainer();
  });
  tearDown(() => contenedor.dispose());

  BorradorNotifier notas() => contenedor.read(borradorProvider.notifier);
  Borrador ahora() => contenedor.read(borradorProvider);

  final Cata cata = Cata(
    id: 'la-de-antes',
    sitio: 'Bar',
    ciudad: 'Sevilla',
    corte: const Corte.media(),
    sabores: const <Sabor>[Sabor(rellenoId: 'jamon')],
    autorId: 'tu',
    mesas: const <String>[],
    fecha: DateTime(2026),
  );

  test('estando a medias de una corrección, empieza de cero', () {
    notas().desdeCata(cata);
    expect(ahora().esEdicion, isTrue);

    notas().empezarEnMesa('m1');

    expect(ahora().esEdicion, isFalse, reason: 'ya no corrige nada');
    expect(ahora().sitio, isEmpty, reason: 'el formulario está en blanco');
    expect(ahora().mesas, <String>['m1']);
  });

  test('con un borrador nuevo a medias, lo respeta y añade la mesa', () {
    notas().sitio('Casa Paca');
    notas().empezarEnMesa('m1');

    expect(ahora().sitio, 'Casa Paca', reason: 'no se le borra lo escrito');
    expect(ahora().mesas, <String>['m1']);
  });

  test('dos veces la misma mesa no la repite', () {
    notas().empezarEnMesa('m1');
    notas().empezarEnMesa('m1');
    expect(ahora().mesas, <String>['m1']);
  });
}
