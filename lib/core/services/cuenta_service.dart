import 'package:firebase_auth/firebase_auth.dart';

/// Lo que puede salir mal al entrar o registrarse, ya traducido.
///
/// Firebase devuelve códigos como `wrong-password` o `email-already-in-use`.
/// Enseñar eso es tirarle el problema encima a quien sólo quería entrar en
/// una mesa, así que se traducen aquí y no en cada pantalla.
class FalloCuenta implements Exception {
  const FalloCuenta(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;

  factory FalloCuenta.de(Object error) {
    if (error is! FirebaseAuthException) {
      return const FalloCuenta(
        'No se ha podido conectar. Comprueba que tienes internet.',
      );
    }

    return FalloCuenta(switch (error.code) {
      'invalid-email' => 'Ese correo no tiene buena pinta. Revísalo.',
      'user-disabled' => 'Esta cuenta está desactivada.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' =>
        'El correo o la contraseña no cuadran.',
      'email-already-in-use' =>
        'Ya hay una cuenta con ese correo. Entra en vez de registrarte.',
      'weak-password' =>
        'La contraseña es demasiado corta. Seis caracteres como mínimo.',
      'network-request-failed' =>
        'Sin internet. Tus catas siguen guardadas en el móvil.',
      'too-many-requests' =>
        'Demasiados intentos seguidos. Espera un momento.',
      'requires-recent-login' =>
        'Por seguridad, vuelve a entrar antes de hacer esto.',
      _ => 'No se ha podido completar. Inténtalo otra vez.',
    });
  }
}

/// La cuenta: entrar, registrarse, salir y borrarla.
///
/// Todo esto es OPCIONAL. La app funciona entera sin cuenta: apuntar catas,
/// el mapa, las mesas propias. La cuenta sólo hace falta para compartir una
/// mesa con otras personas, porque para eso sus móviles tienen que saber
/// quién eres.
class CuentaService {
  const CuentaService._();

  static FirebaseAuth get _auth => FirebaseAuth.instance;

  /// Quién hay dentro ahora mismo, o `null` si nadie.
  static User? get quien => _auth.currentUser;

  /// Avisa cada vez que se entra o se sale.
  static Stream<User?> get cambios => _auth.authStateChanges();

  static Future<User> registrarse({
    required String correo,
    required String clave,
  }) async {
    try {
      final UserCredential c = await _auth.createUserWithEmailAndPassword(
        email: correo.trim(),
        password: clave,
      );
      return c.user!;
    } catch (e) {
      throw FalloCuenta.de(e);
    }
  }

  static Future<User> entrar({
    required String correo,
    required String clave,
  }) async {
    try {
      final UserCredential c = await _auth.signInWithEmailAndPassword(
        email: correo.trim(),
        password: clave,
      );
      return c.user!;
    } catch (e) {
      throw FalloCuenta.de(e);
    }
  }

  static Future<void> salir() => _auth.signOut();

  /// Para quien no se acuerda de la contraseña.
  static Future<void> recordarClave(String correo) async {
    try {
      await _auth.sendPasswordResetEmail(email: correo.trim());
    } catch (e) {
      throw FalloCuenta.de(e);
    }
  }

  /// Borrar la cuenta del todo.
  ///
  /// No es un extra: la App Store lo exige desde 2022 a toda app que deje
  /// crear una cuenta, y tiene que poder hacerse desde dentro de la app, sin
  /// escribir a nadie.
  ///
  /// Las catas del móvil NO se tocan. Son tuyas y están en tu móvil; lo que
  /// desaparece es la cuenta y con ella el acceso a las mesas compartidas.
  static Future<void> borrarCuenta() async {
    final User? u = quien;
    if (u == null) return;
    try {
      await u.delete();
    } catch (e) {
      throw FalloCuenta.de(e);
    }
  }
}
