import 'dart:math' as math;

import '../../core/models/cata.dart';

/// Un puñado de catas que, al zoom que toca, caerían unas encima de otras.
class Grupo {
  const Grupo({required this.catas, required this.lat, required this.lon});

  /// Las catas que van juntas. Nunca vacío.
  final List<Cata> catas;

  /// Dónde se pinta el grupo: el centro de las suyas.
  final double lat;
  final double lon;

  bool get esUna => catas.length == 1;

  /// La única cata, cuando el grupo no agrupa nada.
  Cata get unica => catas.first;

  /// La mejor nota del grupo. Es la que se enseña: de un sitio con varias
  /// catas, lo que quieres saber de un vistazo es lo bueno que llegó a estar.
  double get mejorNota => catas
      .map((Cata c) => c.puntuacion)
      .reduce((double a, double b) => a > b ? a : b);
}

/// Junta las catas que se pisarían en pantalla al zoom [zoom].
///
/// El problema que resuelve: en Sevilla hay diez bares en el mismo barrio, y
/// sus globos se solapaban hasta dejar los números en muñones ("8,", "9,",
/// "0"). La pantalla prometía por escrito "cada globo es uno, y el número es
/// la nota que le pusiste" y no lo cumplía.
///
/// El método son dos pasadas sobre coordenadas de mundo Mercator:
///
/// 1. Una rejilla: dos catas van juntas si caen en la misma casilla de
///    [radioPx] píxeles. Rápido, estable y sin dependencias.
/// 2. Una fusión: la rejilla sola deja pasar dos grupos a ambos lados de una
///    linde, que en pantalla se pisan igual. Así que después se funden los
///    grupos cuyos centros queden a menos de [radioPx].
///
/// La segunda pasada no es un adorno: sin ella seguían solapándose racimos
/// contiguos, que es exactamente el problema que esto venía a resolver.
///
/// [radioPx] es el ancho del marcador más ancho. Por debajo de eso, se tocan.
List<Grupo> agruparCatas(
  List<Cata> catas,
  double zoom, {
  double radioPx = 78,
}) {
  final List<Cata> conSitio =
      catas.where((Cata c) => c.tieneUbicacion).toList();
  if (conSitio.length < 2) {
    return <Grupo>[
      for (final Cata c in conSitio) Grupo(catas: <Cata>[c], lat: c.lat!, lon: c.lon!),
    ];
  }

  final double mundo = 256 * math.pow(2, zoom).toDouble();

  // Las casillas se guardan en orden de aparición para que el resultado no
  // dependa de cómo itere el mapa.
  final Map<String, List<Cata>> casillas = <String, List<Cata>>{};
  for (final Cata c in conSitio) {
    final (double x, double y) = _aMundo(c.lat!, c.lon!, mundo);
    final String celda = '${(x / radioPx).floor()}:${(y / radioPx).floor()}';
    casillas.putIfAbsent(celda, () => <Cata>[]).add(c);
  }

  return _fundirCercanos(casillas.values.toList(), mundo, radioPx);
}

/// Segunda pasada: junta los grupos que en pantalla seguirían pisándose.
///
/// Se repite hasta que no quede ninguna pareja demasiado cerca, porque fundir
/// dos puede acercar el resultado a un tercero.
List<Grupo> _fundirCercanos(
  List<List<Cata>> grupos,
  double mundo,
  double radioPx,
) {
  final List<List<Cata>> actuales = <List<Cata>>[...grupos];

  bool huboCambio = true;
  while (huboCambio) {
    huboCambio = false;

    for (int i = 0; i < actuales.length && !huboCambio; i++) {
      for (int j = i + 1; j < actuales.length && !huboCambio; j++) {
        if (_separacion(actuales[i], actuales[j], mundo) >= radioPx) continue;
        actuales[i] = <Cata>[...actuales[i], ...actuales[j]];
        actuales.removeAt(j);
        huboCambio = true;
      }
    }
  }

  return <Grupo>[
    for (final List<Cata> juntas in actuales)
      Grupo(
        catas: juntas,
        lat: _media(juntas.map((Cata c) => c.lat!)),
        lon: _media(juntas.map((Cata c) => c.lon!)),
      ),
  ];
}

/// Cuántos píxeles separan los centros de dos grupos.
double _separacion(List<Cata> a, List<Cata> b, double mundo) {
  final (double ax, double ay) = _aMundo(
    _media(a.map((Cata c) => c.lat!)),
    _media(a.map((Cata c) => c.lon!)),
    mundo,
  );
  final (double bx, double by) = _aMundo(
    _media(b.map((Cata c) => c.lat!)),
    _media(b.map((Cata c) => c.lon!)),
    mundo,
  );
  return math.sqrt(math.pow(ax - bx, 2) + math.pow(ay - by, 2));
}

/// Latitud y longitud a píxeles de mundo, Web Mercator.
(double, double) _aMundo(double lat, double lon, double mundo) {
  final double x = (lon + 180) / 360 * mundo;
  final double senoLat = math.sin(lat * math.pi / 180).clamp(-0.9999, 0.9999);
  final double y =
      (0.5 - math.log((1 + senoLat) / (1 - senoLat)) / (4 * math.pi)) * mundo;
  return (x, y);
}

double _media(Iterable<double> valores) =>
    valores.reduce((double a, double b) => a + b) / valores.length;
