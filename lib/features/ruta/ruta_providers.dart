import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/datos_demo.dart';
import '../../core/models/cata.dart';
import '../../core/providers/catas_provider.dart';

/// Qué se enseña en el mapa.
enum FiltroRuta { todas, mias, libres }

final filtroRutaProvider = StateProvider<FiltroRuta>((ref) => FiltroRuta.todas);

/// Aplica un filtro a una lista de catas.
///
/// Suelta y no dentro de un provider porque la pantalla también la necesita
/// con una lista concreta en la mano —al cambiar de filtro, para reencuadrar
/// el mapa antes de que el provider se haya propagado.
List<Cata> filtrarRuta(List<Cata> catas, FiltroRuta filtro) {
  return switch (filtro) {
    FiltroRuta.todas => catas,
    FiltroRuta.mias =>
      catas.where((Cata c) => c.autorId == DatosDemo.yo).toList(),
    FiltroRuta.libres => catas.where((Cata c) => c.tieneDietas).toList(),
  };
}

/// Las catas que tienen punto en el mapa. El resto no se pueden pintar.
final catasConSitioProvider = Provider<List<Cata>>((ref) {
  return ref
      .watch(catasProvider)
      .where((Cata c) => c.tieneUbicacion)
      .toList();
});

/// Cuántas catas se quedan fuera del mapa por no tener sitio apuntado.
///
/// Se enseña en vez de esconderse: si tienes tres catas sin sitio, lo mejor
/// que puede hacer esta pantalla es decírtelo.
final catasSinSitioProvider = Provider<int>((ref) {
  return ref.watch(catasProvider).length - ref.watch(catasConSitioProvider).length;
});

/// Las catas que el filtro deja ver.
final catasVisiblesProvider = Provider<List<Cata>>((ref) {
  return filtrarRuta(
    ref.watch(catasConSitioProvider),
    ref.watch(filtroRutaProvider),
  );
});

/// Las visibles, de mejor a peor nota. Es el orden de la hoja de resultados.
final catasRutaOrdenadasProvider = Provider<List<Cata>>((ref) {
  final List<Cata> catas = <Cata>[...ref.watch(catasVisiblesProvider)];
  catas.sort((Cata a, Cata b) => b.puntuacion.compareTo(a.puntuacion));
  return catas;
});

/// Las catas del sitio donde más has catado.
///
/// Encuadrar *todas* las catas es mala idea en cuanto una está lejos: con
/// diecisiete en Sevilla y una en Buenos Aires, el mapa tiene que abarcar el
/// Atlántico y lo que se ve al abrir es océano. Quien entra aquí quiere ver
/// sus bares, no un planisferio; la cata de Buenos Aires sigue estando, y se
/// llega a ella alejándose.
///
/// Se agrupa por ciudad porque es el dato que ya tiene la cata y es el que
/// usa el usuario para pensar dónde cata.
List<Cata> grupoMayoritario(List<Cata> conSitio) {
  if (conSitio.length < 2) return conSitio;

  final Map<String, List<Cata>> porCiudad = <String, List<Cata>>{};
  for (final Cata c in conSitio) {
    porCiudad.putIfAbsent(c.ciudad, () => <Cata>[]).add(c);
  }

  List<Cata>? mejor;
  for (final List<Cata> grupo in porCiudad.values) {
    if (mejor == null || grupo.length > mejor.length) {
      mejor = grupo;
      continue;
    }
    // Empate: manda donde hayas catado más recientemente. Si tienes tres en
    // Sevilla y tres en Lisboa, abrir donde estuviste ayer acierta más.
    if (grupo.length == mejor.length &&
        _masReciente(grupo).isAfter(_masReciente(mejor))) {
      mejor = grupo;
    }
  }
  return mejor ?? conSitio;
}

DateTime _masReciente(List<Cata> catas) => catas
    .map((Cata c) => c.fecha)
    .reduce((DateTime a, DateTime b) => a.isAfter(b) ? a : b);

/// El grupo con el que abre el mapa, ya filtrado.
final grupoInicialRutaProvider = Provider<List<Cata>>((ref) {
  return grupoMayoritario(ref.watch(catasVisiblesProvider));
});

/// Cuántas ciudades y cuántos países llevas. Va en el subtítulo.
typedef ResumenRuta = ({int ciudades, int paises});

final resumenRutaProvider = Provider<ResumenRuta>((ref) {
  final List<Cata> conSitio = ref.watch(catasConSitioProvider);
  return (
    ciudades: conSitio
        .map((Cata c) => c.ciudad)
        .where((String c) => c.isNotEmpty)
        .toSet()
        .length,
    paises: conSitio.map((Cata c) => c.pais).toSet().length,
  );
});
