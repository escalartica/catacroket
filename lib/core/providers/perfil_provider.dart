import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/datos_demo.dart';
import '../data/rangos.dart';
import '../models/cata.dart';
import '../models/corte.dart';
import '../models/semanas.dart';
import 'catas_provider.dart';

/// Resumen del Croquetómetro. Todo se calcula a partir de las catas: no hay
/// contadores guardados que puedan desincronizarse de la realidad.
class Perfil {
  const Perfil({
    required this.catas,
    required this.media,
    required this.ciudades,
    required this.paises,
    required this.racha,
    required this.semanas,
    required this.paladar,
    required this.mejor,
    required this.medallas,
  });

  final int catas;

  /// Nulo mientras no haya ninguna cata: así la pantalla pinta un guion en
  /// vez de un 0,0 que parecería una nota malísima.
  final double? media;

  final int ciudades;

  /// Países distintos. Es el dato que convierte la app en un pasaporte.
  final int paises;

  /// Semanas seguidas catando, contando hacia atrás desde esta.
  final int racha;

  /// Las últimas siete semanas, de la más antigua a la de hoy: `true` si esa
  /// semana tuvo al menos una cata. Es el dato que pintan las pastillas.
  ///
  /// Va aparte de [racha] porque dicen cosas distintas. La racha se corta en
  /// el primer hueco; esto es el historial tal cual, huecos incluidos. Pintar
  /// la racha en siete casillas mentía en cuanto pasabas de siete semanas:
  /// el número subía y el dibujo se quedaba clavado.
  final List<bool> semanas;

  /// Si la semana en curso ya tiene cata. Decide entre "a salvo" y "se
  /// apaga", que es la diferencia entre avisar y dar la lata.
  bool get catadaEstaSemana => semanas.isNotEmpty && semanas.last;

  /// Media de cada eje. Es lo que permite decirle al usuario en qué es duro.
  final Corte paladar;

  final Cata? mejor;
  final Set<String> medallas;

  String get rango => Rangos.actual(catas).nombre;
  Rango? get siguienteRango => Rangos.siguiente(catas);
  double get progreso => Rangos.progreso(catas);

  /// El eje que más puntúa. Lo usa la frase de "Tu paladar".
  String get ejeFuerte => paladar.ejeFuerte;

  /// Y el que menos. Con los dos, la frase del paladar dice algo cierto en
  /// vez de repetir siempre el mismo reproche.
  String get ejeDebil {
    final Map<String, int> ejes = <String, int>{
      'crujiente': paladar.crujiente,
      'cremosidad': paladar.cremosidad,
      'sabor': paladar.sabor,
      'relleno': paladar.relleno,
    };
    return ejes.entries
        .reduce((MapEntry<String, int> a, MapEntry<String, int> b) =>
            b.value < a.value ? b : a)
        .key;
  }
}

final perfilProvider = Provider<Perfil>((ref) {
  final List<Cata> mias = ref
      .watch(catasRecientesProvider)
      .where((Cata c) => c.autorId == DatosDemo.yo)
      .toList();

  if (mias.isEmpty) {
    return const Perfil(
      catas: 0,
      media: null,
      ciudades: 0,
      paises: 0,
      racha: 0,
      semanas: <bool>[false, false, false, false, false, false, false],
      paladar: Corte(crujiente: 0, cremosidad: 0, sabor: 0, relleno: 0),
      mejor: null,
      medallas: <String>{},
    );
  }

  int cr = 0, be = 0, sa = 0, re = 0;
  final Set<String> ciudades = <String>{};
  final Set<String> paises = <String>{};
  Cata mejor = mias.first;

  for (final Cata c in mias) {
    cr += c.corte.crujiente;
    be += c.corte.cremosidad;
    sa += c.corte.sabor;
    re += c.corte.relleno;
    if (c.ciudad.isNotEmpty) ciudades.add(c.ciudad);
    paises.add(c.pais);
    if (c.puntuacion > mejor.puntuacion) mejor = c;
  }

  final int n = mias.length;
  final Corte paladar = Corte(
    crujiente: (cr / n).round(),
    cremosidad: (be / n).round(),
    sabor: (sa / n).round(),
    relleno: (re / n).round(),
  );

  final List<DateTime> fechas = <DateTime>[for (final Cata c in mias) c.fecha];
  final int racha = Semanas.racha(fechas);
  final List<bool> semanas = Semanas.ultimas(fechas);

  return Perfil(
    catas: n,
    media: mediaDe(mias),
    ciudades: ciudades.length,
    paises: paises.length,
    racha: racha,
    semanas: semanas,
    paladar: paladar,
    mejor: mejor,
    medallas: _calcularMedallas(mias, ciudades, paises, racha),
  );
});

Set<String> _calcularMedallas(
  List<Cata> mias,
  Set<String> ciudades,
  Set<String> paises,
  int racha,
) {
  final Set<String> ganadas = <String>{};

  if (mias.isNotEmpty) ganadas.add('primera');
  if (ciudades.length >= 10) ganadas.add('ciudades');
  if (mias.any((Cata c) => c.rellenoId == 'chipiron')) ganadas.add('tinta');
  if (racha >= 4) ganadas.add('racha');
  if (mias.where((Cata c) => c.puntuacion >= 9).length >= 3) {
    ganadas.add('paladar');
  }
  if (paises.length >= 2) ganadas.add('pasaporte');
  if (paises.length >= 5) ganadas.add('mundial');
  if (mias.any((Cata c) =>
      c.corte.crujiente == 10 &&
      c.corte.cremosidad == 10 &&
      c.corte.sabor == 10 &&
      c.corte.relleno == 10)) {
    ganadas.add('diez');
  }

  // Doble ración: dos catas el mismo día.
  final Map<String, int> porDia = <String, int>{};
  for (final Cata c in mias) {
    final String dia = '${c.fecha.year}-${c.fecha.month}-${c.fecha.day}';
    porDia[dia] = (porDia[dia] ?? 0) + 1;
  }
  if (porDia.values.any((int v) => v >= 2)) ganadas.add('doble');

  return ganadas;
}
