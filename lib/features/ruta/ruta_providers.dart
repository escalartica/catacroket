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
