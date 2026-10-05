import 'package:firebase_auth/firebase_auth.dart';
import 'nube_service.dart';

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

  /// Borrar la cuenta del todo, y con ella lo que haya subido.
  ///
  /// No es un extra: la App Store lo exige desde 2022 a toda app que deje
  /// crear una cuenta, y lo que exige es que se borre la cuenta **y sus
  /// datos**, no sólo el usuario.
  ///
  /// Antes aquí sólo había `u.delete()`, que borra el usuario de Firebase y
  /// nada más. Tus catas se quedaban en las mesas compartidas —con su nota,
  /// sus fotos y las coordenadas del bar— a la vista de quien siguiera
  /// dentro. Y para siempre: borrarlas exige ser su autor, y ese autor
  /// acababa de dejar de existir. La política de privacidad prometía lo
  /// contrario.
  ///
  /// El orden importa y es el del servicio equivalente de Palito: primero lo
  /// subido, mientras la sesión sigue viva, y la cuenta al final. Si lo de
  /// arriba falla a medias, la cuenta NO se borra: más vale poder
  /// reintentarlo que quedarse sin cuenta y con los datos puestos.
  ///
  /// Las catas del móvil no se tocan. Son tuyas y están en tu móvil.
  ///
  /// Devuelve lo que no se haya podido limpiar, para poder decirlo en vez de
  /// prometer una limpieza que no fue.
  static Future<List<String>> borrarCuenta() async {
    final User? u = quien;
    if (u == null) return const <String>[];

    final List<String> fallaron = await NubeService.borrarLoMio();

    try {
      await u.delete();
    } catch (e) {
      throw FalloCuenta.de(e);
    }
    return fallaron;
  }
}
