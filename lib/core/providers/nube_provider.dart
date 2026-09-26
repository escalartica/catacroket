import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cata.dart';
import '../models/mesa.dart';
import '../services/nube_service.dart';
import 'cuenta_provider.dart';
import 'mesas_provider.dart';

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
