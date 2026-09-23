import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/cata.dart';
import '../../core/models/mesa.dart';
import '../../core/models/persona.dart';
import '../../core/providers/catas_provider.dart';
import '../../core/providers/mesas_provider.dart';

/// Un sitio en el ranking de una mesa.
class Puesto {
  const Puesto({
    required this.persona,
    required this.catas,
    required this.media,
  });

  final Persona persona;

  /// Cuántas ha catado en esta mesa.
  final int catas;

  /// Su nota media en esta mesa. Nula si no ha catado nada.
  final double? media;
}

/// Ordena a la gente de una mesa: primero quien más cata, y a igualdad,
/// quien mejor puntúa.
///
/// Catar más manda sobre puntuar mejor a propósito. Esto es una mesa de
/// amigos, no un jurado: quien se ha comido veinte croquetas ha aportado más
/// que quien se comió una y le puso un diez.
List<Puesto> rankingDe(
  Mesa mesa,
  List<Cata> catas,
  Map<String, Persona> personas,
) {
  final List<Puesto> ranking = mesa.miembros.map((String id) {
    final List<Cata> suyas =
        catas.where((Cata c) => c.autorId == id).toList();
    return Puesto(
      persona: personas[id] ?? Persona.desconocida,
      catas: suyas.length,
      media: mediaDe(suyas),
    );
  }).toList();

  ranking.sort((Puesto a, Puesto b) {
    final int porCatas = b.catas.compareTo(a.catas);
    if (porCatas != 0) return porCatas;
    return (b.media ?? 0).compareTo(a.media ?? 0);
  });

  return ranking;
}

/// El ranking de una mesa, ya montado.
///
/// Vive en un provider y no en el `build()` de la pantalla porque es trabajo
/// de verdad —recorre todas las catas una vez por miembro y luego ordena— y
/// porque así se puede probar sin montar la pantalla entera.
final rankingMesaProvider = Provider.family<List<Puesto>, String>((
  ref,
  String mesaId,
) {
  final Mesa? mesa = ref.watch(mesaProvider(mesaId));
  if (mesa == null) return const <Puesto>[];

  return rankingDe(
    mesa,
    ref.watch(catasDeMesaProvider(mesaId)),
    ref.watch(personasProvider),
  );
});
