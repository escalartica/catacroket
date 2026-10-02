import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../tokens/app_colors.dart';
import '../tokens/app_shape.dart';
import '../tokens/app_typography.dart';

/// De dónde salen los mapas.
///
/// Las teselas públicas de OpenStreetMap son para uso ligero. Su política de
/// uso prohíbe expresamente distribuir una aplicación que tire de ellas, y la
/// propia librería del mapa lo avisa por consola cada vez que se monta una
/// capa. Funciona mientras seas tú probando; con usuarios de verdad te
/// bloquean por User-Agent y el mapa se queda gris para todos a la vez.
///
/// Por eso el proveedor **no** es una constante que haya que acordarse de
/// cambiar antes de publicar, sino algo que se pasa al compilar:
///
///     flutter build ipa --dart-define=CATACROKET_TESELAS=https://...
///
/// Sin pasar nada se usa OpenStreetMap, que es lo correcto en desarrollo.
/// [sonPublicas] dice cuál de las dos está puesta, para que un test o una
/// comprobación previa a publicar pueda mirarlo en vez de fiarse.
abstract final class Mapas {
  // ── OpenStreetMap: sólo para desarrollo ────────────────────────────────
  //
  // Su política de uso PROHÍBE distribuir una app que consuma estas teselas.
  // Funciona mientras seas tú probando; con usuarios de verdad bloquean por
  // User-Agent y el mapa se queda gris para todos a la vez.
  static const String _osm = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  // ── Lo que va a la tienda ──────────────────────────────────────────────
  //
  // Ni la plantilla ni la clave se escriben aquí: se pasan al compilar. Así
  // la clave no acaba en el repositorio y cambiar de proveedor no toca el
  // código.
  //
  // Lo más cómodo es no escribirlo a mano: `herramientas/empaquetar.sh`
  // lee `mapa.env` y pasa los tres defines por ti.
  //
  //     flutter build appbundle \
  //       --dart-define=CATACROKET_TESELAS='https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png' \
  //       --dart-define=CATACROKET_MAPA_CLAVE=la-clave-de-carto \
  //       --dart-define=CATACROKET_MAPA_CREDITO='© OpenStreetMap · © CARTO'
  static const String _configurado = String.fromEnvironment(
    'CATACROKET_TESELAS',
    defaultValue: _osm,
  );

  static const String _clave = String.fromEnvironment('CATACROKET_MAPA_CLAVE');

  /// Cómo se llama el parámetro de la clave en la URL.
  ///
  /// CARTO la pide como `key`; Stadia, MapTiler y Thunderforest como
  /// `api_key`. Se deja configurable porque equivocarse aquí no rompe la
  /// compilación: el mapa sale, pero con la marca de agua «API KEY REQUIRED»
  /// encima, y eso sólo se ve mirando.
  static const String _parametroClave = String.fromEnvironment(
    'CATACROKET_MAPA_PARAM',
    defaultValue: 'key',
  );

  static String _actual = _configurado;

  /// La plantilla de URL de las teselas, con la clave puesta si la hay.
  ///
  /// Si la plantilla ya trae el parámetro escrito, no se toca: así se puede
  /// pasar la URL entera en CATACROKET_TESELAS cuando un proveedor quiera
  /// algo que no encaje aquí.
  static String get teselas {
    if (_clave.isEmpty || _actual.contains('$_parametroClave=')) return _actual;
    final String union = _actual.contains('?') ? '&' : '?';
    return '$_actual$union$_parametroClave=$_clave';
  }

  /// Si se están usando las teselas públicas de OpenStreetMap.
  ///
  /// En una compilación para la tienda esto tiene que ser `false`.
  static bool get sonPublicas => _actual == _osm;

  /// Otro proveedor, sólo para los tests.
  ///
  /// El arnés de tests apunta a un servidor que no existe: así la suite no
  /// llama a nadie ni por error, y sobre todo deja de imprimir el aviso de
  /// la política de OSM quince veces, que enterraba los fallos de verdad.
  @visibleForTesting
  static void usarOtras(String plantilla) => _actual = plantilla;

  /// OpenStreetMap sirve las teselas gratis y a cambio pide identificarse. A
  /// los clientes sin User-Agent propio los bloquea, y con razón.
  static const String agente = 'com.escalartica.catacroket';

  /// Lo que hay que escribir debajo del mapa.
  ///
  /// No es cortesía: los tres proveedores lo exigen por contrato, y el de
  /// las teselas cambia según cuál esté puesto. Sale de la misma variable
  /// que la URL para que nunca se quede diciendo una cosa mientras el mapa
  /// viene de otra.
  static const String _atribucionConfigurada = String.fromEnvironment(
    'CATACROKET_MAPA_CREDITO',
    defaultValue: '',
  );

  static String get atribucion => _atribucionConfigurada.isNotEmpty
      ? _atribucionConfigurada
      : (sonPublicas ? '© OpenStreetMap' : '© OpenStreetMap · © OpenMapTiles');
}


/// La capa de teselas.
///
/// Es una función y no un widget a propósito. Envuelta en un `StatelessWidget`
/// funcionaba —flutter_map reparte la cámara por `InheritedModel` y llega a
/// cualquier profundidad—, pero metía un elemento de más entre `FlutterMap` y
/// su capa, y cuando el mapa salía en blanco esa capa era una variable que
/// había que descartar a mano. Así lo que va en `children` es un `TileLayer`
/// de verdad y la configuración sigue estando en un solo sitio.
TileLayer teselasOsm({
  void Function(Object error)? onFallo,
  void Function()? onPedida,
}) {
  return TileLayer(
    urlTemplate: Mapas.teselas,
    userAgentPackageName: Mapas.agente,
    // Teselas del doble de resolución (`{r}` -> `@2x`).
    //
    // Va fijo a `true` y no a `RetinaMode.isHighDensity(context)`, que es lo
    // que recomienda la documentación, por dos razones. Una: todos los
    // móviles a los que va esta app son de densidad alta, así que la
    // comprobación daría `true` siempre. Y dos, la importante: con retina
    // apagado no está claro en qué se convierte el `{r}` de la plantilla, y
    // si se quedara literal el mapa pediría `.../797{r}.png` y no cargaría
    // NADA. Dejándolo fijo, el hueco siempre se rellena con `@2x`, que es una
    // URL comprobada a mano contra CARTO.
    retinaMode: true,
    // Un mapa en blanco no se distingue de un mapa sobre el mar: sin esto, el
    // usuario no sabe si es la app, su cobertura o que ahí no hay nada.
    errorTileCallback: onFallo == null
        ? null
        : (TileImage tile, Object error, StackTrace? _) => onFallo(error),
    // Cuenta las teselas que la capa llega a pedir. Distingue los dos fallos
    // que se ven igual de grises: "se pidieron y no llegaron" (red, servidor,
    // User-Agent) y "no se pidió ninguna" (la capa no está, o la cámara está
    // en un sitio imposible).
    tileBuilder: onPedida == null
        ? null
        : (BuildContext context, Widget tile, TileImage _) {
            onPedida();
            return tile;
          },
  );
}

/// La línea de atribución, abajo a la derecha del mapa.
class AtribucionOsm extends StatelessWidget {
  const AtribucionOsm({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.crema.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          Mapas.atribucion,
          style: AppTypography.etiqueta.copyWith(
            fontSize: 9,
            color: AppColors.tintaSuave,
          ),
        ),
      ),
    );
  }
}

/// La chincheta de Catacroket: una croqueta clavada en el mapa.
class Chincheta extends StatelessWidget {
  const Chincheta({super.key, this.color = AppColors.tomate, this.tamano = 30});

  final Color color;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: tamano,
          height: tamano,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.tinta, width: AppShape.borde),
            boxShadow: AppShape.sombra(const Offset(2, 2)),
          ),
          child: Text(
            '🥔',
            style: TextStyle(fontSize: tamano * 0.5),
          ),
        ),
        CustomPaint(size: const Size(12, 8), painter: const _Punta()),
      ],
    );
  }
}

class _Punta extends CustomPainter {
  const _Punta();

  @override
  void paint(Canvas canvas, Size size) {
    final Path punta = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(punta, Paint()..color = AppColors.tinta);
  }

  @override
  bool shouldRepaint(_Punta viejo) => false;
}

/// Un mapa pequeño, quieto, con un punto marcado. Es la confirmación visual
/// de "sí, es ahí": una latitud y una longitud escritas no las comprueba
/// nadie, un mapa sí.
class MapaMini extends StatelessWidget {
  const MapaMini({
    super.key,
    required this.lat,
    required this.lon,
    this.alto = 118,
    this.zoom = 16,
  });

  final double lat;
  final double lon;
  final double alto;
  final double zoom;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppShape.radioM),
      child: SizedBox(
        height: alto,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: FlutterMap(
                // Sin la llave, mover el punto no recentra el mapa: flutter_map
                // sólo mira `initialCenter` al construirse.
                key: ValueKey<String>('$lat,$lon,$zoom'),
                options: MapOptions(
                  initialCenter: LatLng(lat, lon),
                  initialZoom: zoom,
                  backgroundColor: AppColors.superficieCalida,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: <Widget>[
                  teselasOsm(),
                  MarkerLayer(
                    markers: <Marker>[
                      Marker(
                        point: LatLng(lat, lon),
                        width: 40,
                        height: 42,
                        alignment: Alignment.topCenter,
                        child: const Chincheta(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const AtribucionOsm(),
          ],
        ),
      ),
    );
  }
}
