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
/// Los identificadores de tus mesas compartidas, como una cadena.
///
/// Esto parece una tontería y no lo es. Los tres providers de abajo abren
/// conexiones por cada mesa, y observaban `mesasProvider` entero. Pero
/// `miembrosAlDiaProvider` ESCRIBE en `mesasProvider` cada vez que entra
/// alguien: observar la lista entera montaba un bucle en el que cada
/// persona que entraba en una mesa cerraba y volvía a abrir todas las
/// conexiones de todas las mesas, y con ellas la descarga entera de todas
/// las catas y sus fotos. Renombrar una mesa hacía lo mismo.
///
/// Una cadena y no una lista porque Riverpod compara por identidad: dos
/// listas con el mismo contenido son dos objetos distintos y volvería a
/// dispararse igual. Dos cadenas iguales son iguales.
final idsCompartidosProvider = Provider<String>((ref) {
  final List<String> ids = <String>[
    for (final Mesa m in ref.watch(mesasProvider))
      if (m.enLaNube) m.id,
  ]..sort();
  return ids.join(',');
});

List<String> _trocear(String llave) =>
    llave.isEmpty ? const <String>[] : llave.split(',');

final catasDeOtrosProvider = StreamProvider<List<Cata>>((ref) {
  final String? miUid = ref.watch(miUidProvider);
  if (miUid == null) return Stream<List<Cata>>.value(const <Cata>[]);

  final List<String> compartidas = _trocear(ref.watch(idsCompartidosProvider));
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

  for (final String mesaId in compartidas) {
    escuchas.add(
      NubeService.catasDe(mesaId).listen(
        (List<Cata> catas) {
          // Fuera las mías: la copia buena está en el móvil.
          //
          // Por uid y no por autorId: autorId vale 'tu' en todos los
          // teléfonos, así que `c.autorId != miUid` era siempre cierto y
          // este filtro no filtraba absolutamente nada.
          porMesa[mesaId] =
              catas.where((Cata c) => c.autorUid != miUid).toList();
          if (!salida.isClosed) salida.add(todas());
        },
        // Que una mesa falle no puede dejar sin feed a las demás.
        onError: (Object _) {
          porMesa[mesaId] = const <Cata>[];
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

  // Y los borrados que no llegaron, por el mismo motivo: si no, la cata
  // borrada sin cobertura vuelve al feed en cuanto haya red.
  unawaited(
    ref.read(catasProvider.notifier).reintentarBorrados().catchError(
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
/// Quién hay en tus mesas compartidas, en una cadena estable.
final genteDeMisMesasProvider = Provider<String>((ref) {
  final Set<String> uids = <String>{
    for (final Mesa m in ref.watch(mesasProvider))
      if (m.enLaNube) ...m.miembros,
  };
  final List<String> lista = uids.toList()..sort();
  return lista.join(',');
});

final nombresDeLaGenteProvider =
    StreamProvider<Map<String, String>>((ref) {
  final String? miUid = ref.watch(miUidProvider);
  if (miUid == null) return Stream<Map<String, String>>.value(const <String, String>{});

  // Por la lista de gente y no por la de mesas: así renombrar una mesa o
  // cambiarle el color no corta las conexiones de los nombres.
  final List<String> uids = _trocear(ref.watch(genteDeMisMesasProvider))
    ..remove(miUid);
  if (uids.isEmpty) {
    return Stream<Map<String, String>>.value(const <String, String>{});
  }

  return NubeService.nombresVivosDe(uids);
});

/// Publica tu nombre para que tu gente lo vea, y lo vuelve a publicar si te
/// lo cambias en el perfil.
final publicarMiNombreProvider = Provider<void>((ref) {
  final String? miUid = ref.watch(miUidProvider);
  if (miUid == null) return;

  // Sólo si es un nombre de verdad. Publicar el de fábrica llenaba la mesa
  // de «Tú», que es peor que no publicar nada: al menos «Alguien» avisa de
  // que falta un nombre.
  //
  // Se LEE, no se observa. Observando `yoProvider`, cambiar la foto de
  // perfil también disparaba una escritura en el servidor con el nombre que
  // ya estaba puesto, y cambiarse el nombre escribía dos veces, porque
  // `YoNotifier.ponerNombre` ya publica por su cuenta —que es donde el dato
  // cambia de verdad—. Esto sólo cubre el caso de entrar con la cuenta.
  final Yo yo = ref.read(yoProvider);
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

  final List<String> compartidas = _trocear(ref.watch(idsCompartidosProvider));
  if (compartidas.isEmpty) return;

  final List<StreamSubscription<MesaViva?>> escuchas =
      <StreamSubscription<MesaViva?>>[];

  for (final String mesaId in compartidas) {
    escuchas.add(
      NubeService.miembrosDe(mesaId).listen(
        (MesaViva? viva) {
          if (viva == null) return;
          ref.read(mesasProvider.notifier).apuntarDeLaNube(mesaId, viva);
        },
        // Que una mesa falle no puede dejar sin escuchar a las demás.
        onError: (Object _) {},
      ),
    );
  }

  ref.onDispose(() {
    for (final StreamSubscription<MesaViva?> s in escuchas) {
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
  // Las de fuera primero, juntando las mesas de las copias repetidas.
  //
  // Una misma cata de otra persona puede llegar por dos mesas distintas si
  // estás en las dos, y cada copia dice que está sólo en la suya. Quedándose
  // con la última, la cata desaparecía de la otra mesa sin motivo aparente.
  final Map<String, Cata> porId = <String, Cata>{};
  for (final Cata c in deOtros) {
    final Cata? ya = porId[c.id];
    porId[c.id] = ya == null
        ? c
        : ya.copyWith(
            mesas: <String>{...ya.mesas, ...c.mesas}.toList(),
          );
  }

  // Y las tuyas por encima: la copia buena de una cata tuya es la del móvil,
  // con la lista completa de mesas, que el servidor no conoce entera.
  for (final Cata c in mias) {
    porId[c.id] = c;
  }

  final List<Cata> todas = porId.values.toList();
  todas.sort((Cata a, Cata b) => b.fecha.compareTo(a.fecha));
  return todas;
}
