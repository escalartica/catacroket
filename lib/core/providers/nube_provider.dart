import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cata.dart';
import '../models/mesa.dart';
import '../services/nube_service.dart';
import 'catas_provider.dart';
import 'cuenta_provider.dart';
import 'mesas_provider.dart';
import 'yo_provider.dart';

/// Las catas que han apuntado los demás en tus mesas compartidas.
///
/// Sólo las de OTROS. Las tuyas ya están en el móvil y son la copia buena:
/// mezclar la versión del servidor con la local haría que una corrección
/// hecha sin cobertura se pisara sola al volver la conexión.
///
/// Sin sesión o sin mesas compartidas esto es una lista vacía, y el feed
/// funciona exactamente igual que antes de que existiera la nube.
final catasDeOtrosProvider = StreamProvider<List<Cata>>((ref) {
  final String? miUid = ref.watch(miUidProvider);
  if (miUid == null) return Stream<List<Cata>>.value(const <Cata>[]);

  final List<Mesa> compartidas =
      ref.watch(mesasProvider).where((Mesa m) => m.enLaNube).toList();
  if (compartidas.isEmpty) return Stream<List<Cata>>.value(const <Cata>[]);

  // Un mapa por mesa y no una lista suelta: cada mesa llega por su cuenta y
  // hay que poder sustituir lo de una sin borrar lo de las demás.
  final Map<String, List<Cata>> porMesa = <String, List<Cata>>{};
  final StreamController<List<Cata>> salida =
      StreamController<List<Cata>>.broadcast();

  List<Cata> todas() => <Cata>[
        for (final List<Cata> c in porMesa.values) ...c,
      ];

  final List<StreamSubscription<List<Cata>>> escuchas =
      <StreamSubscription<List<Cata>>>[];

  for (final Mesa mesa in compartidas) {
    escuchas.add(
      NubeService.catasDe(mesa.id).listen(
        (List<Cata> catas) {
          // Fuera las mías: la copia buena está en el móvil.
          porMesa[mesa.id] =
              catas.where((Cata c) => c.autorId != miUid).toList();
          if (!salida.isClosed) salida.add(todas());
        },
        // Que una mesa falle no puede dejar sin feed a las demás.
        onError: (Object _) {
          porMesa[mesa.id] = const <Cata>[];
          if (!salida.isClosed) salida.add(todas());
        },
      ),
    );
  }

  ref.onDispose(() {
    for (final StreamSubscription<List<Cata>> s in escuchas) {
      s.cancel();
    }
    salida.close();
  });

  return salida.stream;
});

/// Recupera tus mesas compartidas en cuanto entras con tu cuenta.
///
/// Las mesas vivían sólo en el móvil: al reinstalar la app o estrenar
/// teléfono desaparecían aunque el servidor supiera que seguías dentro, y
/// había que pedir el código otra vez. Ahora vuelven solas.
///
/// Se dispara con cada cuenta distinta, no en cada reconstrucción: la marca
/// es el uid, y mientras no cambie esto no vuelve a llamar al servidor.
final recuperarMesasProvider = Provider<void>((ref) {
  final String? miUid = ref.watch(miUidProvider);
  if (miUid == null) return;

  // Sin await ni bloqueo: la app arranca con lo que hay en el móvil y las
  // mesas que falten aparecen cuando el servidor conteste.
  unawaited(
    ref.read(mesasProvider.notifier).recuperarDeLaNube().catchError(
          (Object _) => 0,
        ),
  );

  // Y las catas que se quedaron sin subir —sin cobertura, casi siempre—
  // vuelven a intentarlo. Antes se quedaban en el móvil para siempre.
  unawaited(
    ref.read(catasProvider.notifier).reintentarPendientes().catchError(
          (Object _) => 0,
        ),
  );
});

/// Los nombres de tu gente, por identificador de cuenta.
///
/// Los miembros de una mesa se guardan por su identificador de cuenta, que no
/// dice nada: sin esto salían todos como «Alguien» y con cero catas. Se piden
/// una vez por tanda de miembros y se quedan cacheados mientras no cambie la
/// lista.
final nombresDeLaGenteProvider = FutureProvider<Map<String, String>>((ref) async {
  final String? miUid = ref.watch(miUidProvider);
  if (miUid == null) return const <String, String>{};

  final Set<String> uids = <String>{
    for (final Mesa m in ref.watch(mesasProvider))
      if (m.enLaNube) ...m.miembros,
  }..remove(miUid);

  if (uids.isEmpty) return const <String, String>{};
  return NubeService.nombresDe(uids.toList());
});

/// Publica tu nombre para que tu gente lo vea, y lo vuelve a publicar si te
/// lo cambias en el perfil.
final publicarMiNombreProvider = Provider<void>((ref) {
  final String? miUid = ref.watch(miUidProvider);
  if (miUid == null) return;

  // Sólo si es un nombre de verdad. Publicar el de fábrica llenaba la mesa
  // de «Tú», que es peor que no publicar nada: al menos «Alguien» avisa de
  // que falta un nombre.
  final Yo yo = ref.watch(yoProvider);
  if (!yo.tieneNombrePropio) return;

  unawaited(NubeService.publicarNombre(yo.nombre.trim()));
});

/// Mantiene al día quién hay en cada mesa compartida.
///
/// No devuelve nada: su trabajo es escuchar el servidor y apuntar en el
/// móvil quién ha entrado. Sin esto, la ficha de una mesa decía «tú sola»
/// aunque tu gente ya estuviera dentro, porque la mesa se leía una vez y
/// nunca más.
///
/// Hay que mirarlo desde alguna pantalla para que se encienda; lo hace la
/// lista de mesas, que es por donde se pasa siempre.
final miembrosAlDiaProvider = Provider<void>((ref) {
  final String? miUid = ref.watch(miUidProvider);
  if (miUid == null) return;

  final List<Mesa> compartidas =
      ref.watch(mesasProvider).where((Mesa m) => m.enLaNube).toList();
  if (compartidas.isEmpty) return;

  final List<StreamSubscription<List<String>>> escuchas =
      <StreamSubscription<List<String>>>[];

  for (final Mesa mesa in compartidas) {
    escuchas.add(
      NubeService.miembrosDe(mesa.id).listen(
        (List<String> miembros) {
          if (miembros.isEmpty) return;
          ref.read(mesasProvider.notifier).apuntarMiembros(mesa.id, miembros);
        },
        // Que una mesa falle no puede dejar sin escuchar a las demás.
        onError: (Object _) {},
      ),
    );
  }

  ref.onDispose(() {
    for (final StreamSubscription<List<String>> s in escuchas) {
      s.cancel();
    }
  });
});

/// Lo tuyo y lo de tu gente, junto y sin repetidos.
///
/// Si una cata aparece en los dos sitios manda la del móvil. Eso pasa en
/// cuanto corriges una tuya sin cobertura: la del servidor está vieja y
/// dejarla ganar borraría la corrección delante de tus ojos.
List<Cata> juntarCatas(List<Cata> mias, List<Cata> deOtros) {
  final Map<String, Cata> porId = <String, Cata>{
    for (final Cata c in deOtros) c.id: c,
    for (final Cata c in mias) c.id: c,
  };

  final List<Cata> todas = porId.values.toList();
  todas.sort((Cata a, Cata b) => b.fecha.compareTo(a.fecha));
  return todas;
}
