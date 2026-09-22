import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../tokens/app_colors.dart';
import '../tokens/app_shape.dart';
import '../tokens/app_typography.dart';

/// De dónde salen los mapas.
///
/// En un sitio y no copiado en cada pantalla, porque esto va a cambiar: las
/// teselas públicas de OpenStreetMap son para uso ligero y su política pide
/// no montar encima un producto con tráfico. Antes de publicar hay que pasar
/// a un proveedor con plan (MapTiler, Stadia, Thunderforest, Carto), y
/// entonces se toca esta constante y nada más.
class Mapas {
  const Mapas._();

  static const String teselas =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// OpenStreetMap sirve las teselas gratis y a cambio pide identificarse. A
  /// los clientes sin User-Agent propio los bloquea, y con razón.
  static const String agente = 'com.escalartica.catacroket';

  static const String atribucion = '© OpenStreetMap';
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
