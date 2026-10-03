import 'package:catacroket/core/models/mesa.dart';
import 'package:catacroket/core/providers/mesas_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// El nombre de una mesa compartida lo manda el servidor.
///
/// Cambiarle el nombre a una mesa sólo lo cambiaba en TU móvil: el servidor
/// no se enteraba y tu gente seguía viendo el nombre viejo para siempre, sin
/// manera de arreglarlo. Y aunque llegara, nadie lo escuchaba: del documento
/// de la mesa sólo se leían los miembros.
void main() {
  late ProviderContainer contenedor;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    contenedor = ProviderContainer();
    // Que termine de leer el disco antes de tocar nada.
    await Future<void>.delayed(Duration.zero);
  });
  tearDown(() => contenedor.dispose());

  MesasNotifier mesas() => contenedor.read(mesasProvider.notifier);
  Mesa? buscar(String id) =>
      contenedor.read(mesasProvider).where((Mesa m) => m.id == id).firstOrNull;

  test('lo que dice el servidor se aplica al nombre, color y gente', () async {
    final String id = (await mesas().crear(
      nombre: 'Prueba',
      descripcion: 'La de siempre',
      colorHex: 0xFFFFC93C,
    ))
        .id;

    await mesas().apuntarDeLaNube(id, (
      nombre: 'Croquetólogos',
      descripcion: 'Los jueves',
      colorHex: 0xFF4EC9B0,
      miembros: <String>['uno', 'dos'],
    ));

    final Mesa? m = buscar(id);
    expect(m?.nombre, 'Croquetólogos');
    expect(m?.descripcion, 'Los jueves');
    expect(m?.colorHex, 0xFF4EC9B0);
    expect(m?.miembros, <String>['uno', 'dos']);
  });

  test('una lista de gente vacía no vacía la mesa', () async {
    // Un documento a medio llegar no puede dejarte una mesa sin nadie: quien
    // la está leyendo es miembro por definición.
    final String id = (await mesas().crear(
      nombre: 'Prueba',
      descripcion: '',
      colorHex: 0xFFFFC93C,
    ))
        .id;
    final List<String> antes = buscar(id)!.miembros;

    await mesas().apuntarDeLaNube(id, (
      nombre: 'Prueba',
      descripcion: '',
      colorHex: 0xFFFFC93C,
      miembros: const <String>[],
    ));

    expect(buscar(id)!.miembros, antes);
  });

  test('de una mesa que no existe no se hace nada', () async {
    await mesas().apuntarDeLaNube('no-existe', (
      nombre: 'X',
      descripcion: '',
      colorHex: 0,
      miembros: const <String>['a'],
    ));
    expect(buscar('no-existe'), isNull);
  });
}
