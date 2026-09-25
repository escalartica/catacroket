import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/cuenta_service.dart';

/// Quién hay dentro, si es que hay alguien.
///
/// Empieza en `null` y se queda en `null` mientras nadie entre, que es el
/// caso normal: la cuenta sólo hace falta para compartir mesas. Ninguna
/// pantalla debe dejar de funcionar porque esto valga `null`.
final cuentaProvider = StreamProvider<User?>((ref) {
  // Si Firebase no arrancó —sin red, configuración mal puesta— no hay
  // sesión que vigilar, pero la app sigue. Devolver un stream vacío en vez
  // de reventar es lo que mantiene la promesa de que apuntar catas no
  // depende de ningún servidor.
  try {
    return CuentaService.cambios;
  } catch (_) {
    return Stream<User?>.value(null);
  }
});

/// `true` en cuanto hay sesión. Es lo que miran las pantallas para decidir
/// si enseñan «compartir esta mesa» o «para esto hace falta una cuenta».
final haySesionProvider = Provider<bool>((ref) {
  return ref.watch(cuentaProvider).maybeWhen(
        data: (User? u) => u != null,
        orElse: () => false,
      );
});

/// El identificador de quien ha entrado, o `null`.
///
/// Es lo que se guarda en las catas compartidas para saber quién apuntó
/// cada una, y lo que comprueban las reglas de seguridad del servidor.
final miUidProvider = Provider<String?>((ref) {
  return ref.watch(cuentaProvider).maybeWhen(
        data: (User? u) => u?.uid,
        orElse: () => null,
      );
});
