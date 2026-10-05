import 'package:catacroket/core/services/instalacion.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Borrar la app cierra la sesión.
///
/// El llavero de iOS sobrevive a desinstalar la app, así que la sesión de
/// Firebase también. Quien reinstalaba seguía dentro de su cuenta sin
/// teclear nada, y quien prestaba el móvil «con la app borrada» dejaba su
/// cuenta dentro.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Lo que haría la app, con la sesión de mentira.
  Future<bool> arrancar({required bool conSesion, List<String>? apuntes}) {
    bool dentro = conSesion;
    return Instalacion.cerrarSesionHeredada(
      haySesion: () async => dentro,
      salir: () async {
        dentro = false;
        apuntes?.add('salir');
      },
    );
  }

  test('instalación nueva: la sesión del llavero se cierra', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final List<String> apuntes = <String>[];

    expect(await arrancar(conSesion: true, apuntes: apuntes), isTrue);
    expect(apuntes, <String>['salir']);
  });

  test('el segundo arranque ya no echa a nadie', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await arrancar(conSesion: true);

    // Aquí el usuario ya ha vuelto a entrar. Si esto lo volviera a echar,
    // la app sería un bucle: entras, reinicias, fuera.
    final List<String> apuntes = <String>[];
    expect(await arrancar(conSesion: true, apuntes: apuntes), isFalse);
    expect(apuntes, isEmpty);
  });

  test('instalación nueva sin sesión: no pasa nada', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final List<String> apuntes = <String>[];

    expect(await arrancar(conSesion: false, apuntes: apuntes), isFalse);
    expect(apuntes, isEmpty);
  });

  test('una instalación ya marcada no toca la sesión', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'catacroket.instalacion.v1': true,
    });
    final List<String> apuntes = <String>[];

    expect(await arrancar(conSesion: true, apuntes: apuntes), isFalse);
    expect(apuntes, isEmpty);
  });
}
