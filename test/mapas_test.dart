import 'package:catacroket/core/theme/components/mapa_mini.dart';
import 'package:flutter_test/flutter_test.dart';

/// El proveedor de teselas.
///
/// Esto no es una preferencia técnica: la política de uso de OpenStreetMap
/// prohíbe distribuir una app que consuma sus teselas públicas. Publicar así
/// acaba con el mapa gris para todos los usuarios el día que bloqueen el
/// User-Agent.
void main() {
  // El arnés de tests (flutter_test_config.dart) ya ha cambiado el proveedor
  // antes de llegar aquí, así que se restaura lo que toque en cada caso.
  const String falsas = 'https://teselas.invalido/{z}/{x}/{y}.png';

  setUp(() => Mapas.usarOtras(falsas));

  test('en los tests no se apunta a OpenStreetMap', () {
    expect(Mapas.sonPublicas, isFalse);
    expect(Mapas.teselas, falsas);
  });

  test('cambiar de proveedor cambia lo que usa la capa', () {
    Mapas.usarOtras('https://mi.proveedor/{z}/{x}/{y}.png?key=xxx');
    expect(Mapas.teselas, contains('mi.proveedor'));
    expect(Mapas.sonPublicas, isFalse);
  });

  test('sonPublicas detecta las teselas públicas de OpenStreetMap', () {
    // La comprobación que hay que hacer antes de publicar. Si esto diera
    // false con la URL de OSM puesta, el aviso no serviría de nada.
    Mapas.usarOtras('https://tile.openstreetmap.org/{z}/{x}/{y}.png');
    expect(Mapas.sonPublicas, isTrue);
  });

  test('la plantilla lleva los tres huecos que espera el mapa', () {
    for (final String hueco in <String>['{z}', '{x}', '{y}']) {
      expect(Mapas.teselas, contains(hueco));
    }
  });

  test('se identifica con un User-Agent propio', () {
    // Sin esto OpenStreetMap bloquea, y con razón: es lo que su política pide.
    expect(Mapas.agente, isNotEmpty);
    expect(Mapas.agente, contains('.'));
  });

  test('la atribución cambia con el proveedor', () {
    // Escribir "© OpenStreetMap" debajo de un mapa que viene de otro sitio no
    // es sólo feo: los proveedores lo exigen por contrato. Sale de la misma
    // variable que la URL para que no puedan decir cosas distintas.
    Mapas.usarOtras('https://tile.openstreetmap.org/{z}/{x}/{y}.png');
    expect(Mapas.atribucion, contains('OpenStreetMap'));

    Mapas.usarOtras(falsas);
    expect(Mapas.atribucion, contains('OpenStreetMap'));
    expect(Mapas.atribucion, contains('OpenMapTiles'));
  });

  test('sin clave configurada la URL se queda tal cual', () {
    // En desarrollo no hay clave, y OpenStreetMap no la quiere.
    Mapas.usarOtras(falsas);
    expect(Mapas.teselas, falsas);
    expect(Mapas.teselas, isNot(contains('key=')));
  });

  test('una plantilla de CARTO se reconoce como no pública', () {
    // Es la comprobación que hay que hacer antes de subir a la tienda.
    Mapas.usarOtras(
      'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
    );
    expect(Mapas.sonPublicas, isFalse);
    expect(Mapas.teselas, contains('{z}'));
    expect(Mapas.teselas, contains('{r}'));
  });
}
