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
/// Esto tardaba 1.322 ms con 2.000 catas a zoom de calle —donde cada cata es
/// su propio grupo y no hay nada que fundir—, y se recalcula en cada
/// movimiento del mapa: un mapa que se arrastra a tirones al arrastrarlo.
///
/// De dónde venía el tiempo, medido y no supuesto, porque a ojo se atribuye
/// mal (yo lo atribuí mal la primera vez):
///
/// - Volver a calcular la media de coordenadas y la proyección Mercator de
///   los dos grupos DENTRO de cada comparación: 1.322 → 65 ms. Casi todo era
///   esto. Ahora el centro se calcula una vez, al crear el grupo.
/// - Comparar sólo las casillas vecinas en vez de todas las parejas:
///   65 → 12 ms. Menos vistoso, pero es la que evita que vuelva: con el
///   barrido completo el tiempo sigue creciendo al cuadrado, así que el día
///   que alguien junte 4.000 catas estaríamos otra vez en 260 ms.
///
/// Mirar sólo las casillas de al lado no es un atajo con riesgo: dos grupos a
/// menos de [radioPx] no pueden estar a más de una casilla de distancia,
/// porque la casilla mide justo [radioPx].
///
/// Se repite hasta que no quede ninguna pareja cerca, porque fundir dos
/// mueve el centro del resultado y puede acercarlo a un tercero.
List<Grupo> _fundirCercanos(
  List<List<Cata>> grupos,
  double mundo,
  double radioPx,
) {
  // Cada grupo, con su centro ya calculado: recalcularlo en cada
  // comparación era la otra mitad del trabajo de más.
  final List<_EnObras> actuales = <_EnObras>[
    for (final List<Cata> g in grupos) _EnObras.de(g, mundo),
  ];

  bool huboCambio = true;
  while (huboCambio) {
    huboCambio = false;

    // Índice por casilla. Se rehace en cada vuelta porque al fundir, el
    // centro del grupo se mueve y puede cambiar de casilla.
    final Map<int, List<int>> porCasilla = <int, List<int>>{};
    for (int i = 0; i < actuales.length; i++) {
      porCasilla
          .putIfAbsent(_casillaDe(actuales[i], radioPx), () => <int>[])
          .add(i);
    }

    final Set<int> fundidos = <int>{};

    for (int i = 0; i < actuales.length && !huboCambio; i++) {
      if (fundidos.contains(i)) continue;

      for (final int j in _vecinos(actuales[i], radioPx, porCasilla)) {
        if (j <= i || fundidos.contains(j)) continue;
        if (_distancia(actuales[i], actuales[j]) >= radioPx) continue;

        actuales[i] = _EnObras.de(
          <Cata>[...actuales[i].catas, ...actuales[j].catas],
          mundo,
        );
        fundidos.add(j);
        huboCambio = true;
        break;
      }
    }

    if (huboCambio) {
      for (int i = actuales.length - 1; i >= 0; i--) {
        if (fundidos.contains(i)) actuales.removeAt(i);
      }
    }
  }

  return <Grupo>[
    for (final _EnObras g in actuales)
      Grupo(
        catas: g.catas,
        lat: _media(g.catas.map((Cata c) => c.lat!)),
        lon: _media(g.catas.map((Cata c) => c.lon!)),
      ),
  ];
}

/// Un grupo mientras se está fundiendo, con su centro en píxeles a mano.
class _EnObras {
  const _EnObras(this.catas, this.x, this.y);

  factory _EnObras.de(List<Cata> catas, double mundo) {
    final (double x, double y) = _aMundo(
      _media(catas.map((Cata c) => c.lat!)),
      _media(catas.map((Cata c) => c.lon!)),
      mundo,
    );
    return _EnObras(catas, x, y);
  }

  final List<Cata> catas;
  final double x;
  final double y;
}

/// La casilla de un grupo, empaquetada en un entero para usarla de clave
/// sin construir una cadena por comparación.
int _casillaDe(_EnObras g, double radioPx) =>
    _clave((g.x / radioPx).floor(), (g.y / radioPx).floor());

int _clave(int cx, int cy) => cx * 100000 + cy;

/// Los grupos que podrían estar cerca: los de su casilla y las ocho de
/// alrededor. Fuera de ahí, la distancia ya supera el radio.
Iterable<int> _vecinos(
  _EnObras g,
  double radioPx,
  Map<int, List<int>> porCasilla,
) sync* {
  final int cx = (g.x / radioPx).floor();
  final int cy = (g.y / radioPx).floor();

  for (int dx = -1; dx <= 1; dx++) {
    for (int dy = -1; dy <= 1; dy++) {
      final List<int>? dentro = porCasilla[_clave(cx + dx, cy + dy)];
      if (dentro != null) yield* dentro;
    }
  }
}

double _distancia(_EnObras a, _EnObras b) =>
    math.sqrt(math.pow(a.x - b.x, 2) + math.pow(a.y - b.y, 2));

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
