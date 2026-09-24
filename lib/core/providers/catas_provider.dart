import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/datos_demo.dart';
import '../data/siembra.dart';
import '../models/cata.dart';
import '../models/dieta.dart';
import '../models/medio.dart';
import '../models/mesa.dart';
import '../models/persona.dart';
import '../services/medios_service.dart';
import 'evitar_provider.dart';
import 'mi_dieta_provider.dart';
import 'yo_provider.dart';

/// Almacén de catas.
///
/// En la v1 vive en el móvil: arranca con los datos de demostración y guarda
/// en `SharedPreferences` cada cambio. El contrato de este notifier (añadir,
/// mordisco, borrar) es el mismo que tendrá cuando detrás haya Firestore, así
/// que las pantallas no se tocarán al migrar.
class CatasNotifier extends StateNotifier<List<Cata>> {
  CatasNotifier() : super(Siembra.catas()) {
    _cargar();
  }

  static const String _clave = 'catacroket.catas.v1';

  Future<void> _cargar() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? crudo = prefs.getString(_clave);
      if (crudo == null || crudo.isEmpty) return;

      final List<dynamic> lista = jsonDecode(crudo) as List<dynamic>;
      final List<Cata> leidas = lista
          .map((dynamic e) => Cata.fromJson(Map<String, dynamic>.from(e as Map<dynamic, dynamic>)))
          .toList();

      if (leidas.isNotEmpty) state = leidas;
    } catch (_) {
      // Un guardado corrupto no puede dejar la app en blanco: se ignora y se
      // sigue con lo que haya en memoria.
    }
  }

  Future<void> _guardar() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _clave,
        jsonEncode(state.map((Cata c) => c.toJson()).toList()),
      );
    } catch (_) {
      // Guardar es best-effort. Si falla, la sesión sigue funcionando.
    }
  }

  Future<void> anadir(Cata cata) async {
    state = <Cata>[cata, ...state];
    await _guardar();
  }

  /// Guarda una cata corregida en el sitio que ya ocupaba.
  ///
  /// No la mueve al principio del feed: corregir una falta de ortografía de
  /// hace un mes no es una cata nueva y no debería reordenarle el feed a
  /// nadie. La fecha tampoco se toca; es la de cuando te la comiste.
  Future<void> actualizar(Cata cata) async {
    final Cata? antes = _buscar(cata.id);
    state = <Cata>[
      for (final Cata c in state)
        if (c.id == cata.id) cata else c,
    ];
    await _guardar();

    // Las fotos que se quitaron al editar ya no las referencia nadie.
    if (antes != null) await _limpiarMedios(antes, cata.medios);
  }

  Cata? _buscar(String id) {
    for (final Cata c in state) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Borra del disco los ficheros de [antes] que no estén en [siguen].
  Future<void> _limpiarMedios(Cata antes, List<Medio> siguen) async {
    final Set<String> vivas = siguen.map((Medio m) => m.ruta).toSet();
    for (final Medio m in antes.medios) {
      if (!vivas.contains(m.ruta)) await MediosService.borrar(m);
    }
  }

  Future<void> darMordisco(String id) async {
    state = <Cata>[
      for (final Cata c in state)
        if (c.id == id) c.copyWith(mordiscos: c.mordiscos + 1) else c,
    ];
    await _guardar();
  }

  /// Borra una cata y, con ella, sus fotos y su vídeo.
  ///
  /// Dejar los ficheros en disco llenaría el móvil de medios de catas que ya
  /// no existen y que el usuario no puede ver ni borrar desde ninguna parte.
  Future<void> borrar(String id) async {
    final Cata? fuera = _buscar(id);
    state = state.where((Cata c) => c.id != id).toList();
    await _guardar();
    if (fuera != null) await _limpiarMedios(fuera, const <Medio>[]);
  }

  /// Vuelve a los datos de demostración. Está en el perfil, en ajustes.
  /// Deja la app como recién instalada.
  ///
  /// En desarrollo vuelven los datos de ejemplo; en la app publicada la deja
  /// vacía, que es lo que significa "restablecer" para quien la usa. Devolver
  /// dieciocho croquetas ajenas a alguien que acaba de pedir borrar las suyas
  /// sería lo contrario de lo que pidió.
  ///
  /// Se lleva también las fotos y los vídeos. Durante un tiempo no lo hacía, y
  /// era el peor sitio donde faltaba: esto lo pulsa precisamente quien quiere
  /// recuperar espacio, así que la app se quedaba con cientos de megas de
  /// vídeos de catas que ya no existen y que no hay forma de borrar desde
  /// ninguna pantalla.
  Future<void> restablecer() async {
    final List<Cata> habia = state;
    state = Siembra.catas();
    await _guardar();

    // Se compara con lo que queda, no se borra a ciegas: los datos de
    // demostración podrían apuntar a alguna de las mismas rutas, y borrar un
    // fichero que sigue en uso dejaría una ficha con un hueco.
    final List<Medio> siguen = <Medio>[
      for (final Cata c in state) ...c.medios,
    ];
    for (final Cata c in habia) {
      await _limpiarMedios(c, siguen);
    }
  }
}

final catasProvider = StateNotifierProvider<CatasNotifier, List<Cata>>(
  (ref) => CatasNotifier(),
);

/// Catas de la más reciente a la más antigua. Es el orden del feed y el de
/// todas las listas de la app; nunca se ordena a mano en una pantalla.
final catasRecientesProvider = Provider<List<Cata>>((ref) {
  final List<Cata> catas = <Cata>[...ref.watch(catasProvider)];
  catas.sort((Cata a, Cata b) => b.fecha.compareTo(a.fecha));
  return catas;
});

final cataProvider = Provider.family<Cata?, String>((ref, String id) {
  for (final Cata c in ref.watch(catasProvider)) {
    if (c.id == id) return c;
  }
  return null;
});

final catasDeMesaProvider = Provider.family<List<Cata>, String>((ref, String mesaId) {
  return ref
      .watch(catasRecientesProvider)
      .where((Cata c) => c.mesaId == mesaId)
      .toList();
});

/// La mejor cata registrada. Es la "croqueta del día" de La Vitrina.
final croquetaDelDiaProvider = Provider<Cata?>((ref) {
  final List<Cata> catas = ref.watch(catasProvider);
  if (catas.isEmpty) return null;
  return catas.reduce(
    (Cata a, Cata b) => b.puntuacion > a.puntuacion ? b : a,
  );
});

/// Gente. Cuando entre Firebase esto lo servirá el perfil de cada usuario.
final personasProvider = Provider<Map<String, Persona>>((ref) {
  final Map<String, Persona> todas = <String, Persona>{
    for (final Persona p in Siembra.personas) p.id: p,
  };

  // Tu nombre y tu foto pisan los de la demo. Así, cambiarlos en el perfil
  // se nota al momento en el feed, en las mesas y en la estampa que se
  // comparte, sin que ninguna de esas pantallas sepa que existe un ajuste.
  final Yo yo = ref.watch(yoProvider);
  final Persona? mia = todas[DatosDemo.yo];
  if (mia != null) {
    todas[DatosDemo.yo] = mia.copiaCon(nombre: yo.nombre, foto: yo.foto);
  }
  return todas;
});

/// Resuelve una persona sin poder fallar. Una cata de alguien que ya no está
/// en la mesa sigue teniendo que pintarse.
Persona personaDe(WidgetRef ref, String id) =>
    ref.read(personasProvider)[id] ?? Persona.desconocida;

/// Media de una lista de catas. Nulo si no hay ninguna, para que la pantalla
/// pueda decidir si pinta un guion o un número.
double? mediaDe(List<Cata> catas) {
  if (catas.isEmpty) return null;
  double suma = 0;
  for (final Cata c in catas) {
    suma += c.puntuacion;
  }
  return suma / catas.length;
}

/// Filtros del feed de La Vitrina.
enum FiltroVitrina { todo, misMesas, mias }

final filtroVitrinaProvider = StateProvider<FiltroVitrina>((ref) => FiltroVitrina.todo);

final feedProvider = Provider<List<Cata>>((ref) {
  final List<Cata> catas = ref.watch(catasRecientesProvider);
  switch (ref.watch(filtroVitrinaProvider)) {
    case FiltroVitrina.todo:
      return catas;
    case FiltroVitrina.misMesas:
      return catas.where((Cata c) => c.mesaId != Mesa.libretaId).toList();
    case FiltroVitrina.mias:
      return catas.where((Cata c) => c.autorId == DatosDemo.yo).toList();
  }
});

// ── Barra Libre ─────────────────────────────────────────────────────────────

/// Dietas marcadas en el filtro. Vacío quiere decir "enséñamelo todo".
final filtroDietaProvider = StateProvider<Set<Dieta>>((ref) => const <Dieta>{});

/// Las catas de la Barra Libre.
///
/// Sólo entran las que alguien marcó. Una cata sin dietas apuntadas no es
/// "no apta": es que nadie lo miró, y colarla aquí sería decirle a un celíaco
/// algo que no sabemos.
final catasLibresProvider = Provider<List<Cata>>((ref) {
  final Set<Dieta> filtro = ref.watch(filtroDietaProvider);
  final Set<String> fuera = ref.watch(evitarProvider);

  return ref
      .watch(catasRecientesProvider)
      .where((Cata c) =>
          c.tieneDietas &&
          c.valePara(filtro) &&
          Evitar.coincidencias(fuera, c.loQueLleva).isEmpty)
      .toList();
});

/// Cuántas catas hay de cada dieta, para los contadores del filtro.
final recuentoDietasProvider = Provider<Map<Dieta, int>>((ref) {
  final Map<Dieta, int> cuenta = <Dieta, int>{
    for (final Dieta d in Dieta.values) d: 0,
  };
  for (final Cata c in ref.watch(catasProvider)) {
    for (final Dieta d in c.aptas) {
      cuenta[d] = (cuenta[d] ?? 0) + 1;
    }
  }
  return cuenta;
});

/// Cuántas catas llevan al menos una dieta marcada.
///
/// Ojo con lo que significa: son las catas a las que alguien apuntó la
/// receta, no las que le valen a nadie en concreto. Una puede ser sin gluten
/// y llevar jamón.
final totalLibresProvider = Provider<int>((ref) =>
    ref.watch(catasProvider).where((Cata c) => c.tieneDietas).length);

/// Cuántas catas le valen a quien usa la app, según la dieta de su perfil.
///
/// Sin dieta marcada devuelve nulo, no cero: "no lo he mirado" y "ninguna te
/// vale" son respuestas distintas y la de arriba no se puede dar sin saber
/// para quién. La pantalla decide qué frase enseña con eso.
final totalParaMiProvider = Provider<int?>((ref) {
  final Set<Dieta> mia = ref.watch(miDietaProvider);
  if (mia.isEmpty) return null;
  return ref
      .watch(catasProvider)
      .where((Cata c) => c.tieneDietas && c.valePara(mia))
      .length;
});
