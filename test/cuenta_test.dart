import 'package:catacroket/core/services/cuenta_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lo que se le dice a alguien cuando no puede entrar.
///
/// Firebase devuelve códigos como `wrong-password` o `network-request-failed`.
/// Enseñar eso es tirarle el problema encima a quien sólo quería entrar en
/// una mesa. Estos tests protegen la traducción: es de lo primero que se
/// rompe al tocar el servicio y nadie se entera hasta que un usuario ve
/// «ERROR: auth/invalid-credential» en la pantalla.
void main() {
  FalloCuenta traducir(String codigo) =>
      FalloCuenta.de(FirebaseAuthException(code: codigo));

  test('la contraseña mal no dice cuál de los dos ha fallado', () {
    // A propósito: decir «ese correo no existe» le confirma a cualquiera qué
    // correos están registrados.
    expect(traducir('wrong-password').mensaje, contains('no cuadran'));
    expect(traducir('user-not-found').mensaje, contains('no cuadran'));
    expect(traducir('invalid-credential').mensaje, contains('no cuadran'));
  });

  test('un correo ya registrado invita a entrar, no a insistir', () {
    expect(
      traducir('email-already-in-use').mensaje,
      contains('Entra en vez de registrarte'),
    );
  });

  test('sin internet se recuerda que las catas no se han perdido', () {
    // Es el momento en que alguien piensa que la app ha perdido su trabajo.
    expect(
      traducir('network-request-failed').mensaje,
      contains('guardadas en el móvil'),
    );
  });

  test('la contraseña corta dice cuánto hace falta', () {
    expect(traducir('weak-password').mensaje, contains('Seis'));
  });

  test('un código que no conocemos no enseña el código', () {
    final String m = traducir('algo-que-no-existe-todavia').mensaje;

    expect(m, isNot(contains('algo-que-no-existe')));
    expect(m, isNot(contains('auth/')));
    expect(m, contains('Inténtalo otra vez'));
  });

  test('un error que no es de Firebase tampoco se enseña crudo', () {
    final FalloCuenta f = FalloCuenta.de(StateError('conexión rota'));

    expect(f.mensaje, isNot(contains('StateError')));
    expect(f.mensaje, contains('internet'));
  });
}
