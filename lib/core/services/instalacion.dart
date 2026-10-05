import 'package:shared_preferences/shared_preferences.dart';

import '../errores.dart';

/// Borrar la app tiene que cerrar la sesión.
///
/// Firebase Auth guarda la sesión en el llavero de iOS, y el llavero
/// SOBREVIVE a desinstalar la app. Sin esto, quien borra Catacroket y la
/// vuelve a instalar sigue dentro de su cuenta sin haber tecleado nada: se
/// le bajan sus mesas y sus catas como si no hubiera pasado nada. Y quien
/// presta o vende el móvil después de «borrar la app» deja su cuenta dentro.
///
/// `SharedPreferences` sí se borra con la app, así que sirve de marca: si no
/// está, esta instalación es nueva y lo que quede en el llavero viene de una
/// anterior.
abstract final class Instalacion {
  static const String _clave = 'catacroket.instalacion.v1';

  /// Cierra la sesión heredada si la hay. Dice si ha cerrado alguna.
  ///
  /// `haySesion` y `salir` se pasan de fuera para poder probar esto sin
  /// levantar Firebase: aquí lo que importa es CUÁNDO se cierra la sesión,
  /// no quién la cierra.
  ///
  /// No lanza nunca. Esto corre en el arranque, y no poder leer una marca no
  /// puede dejar la app sin abrir.
  static Future<bool> cerrarSesionHeredada({
    required Future<bool> Function() haySesion,
    required Future<void> Function() salir,
  }) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_clave) ?? false) return false;

      // La marca se pone ANTES de cerrar, no después, y es a propósito.
      //
      // Si se pusiera después y la escritura fallara, el siguiente arranque
      // volvería a creerse una instalación nueva y echaría al usuario de la
      // sesión que acaba de abrir. Eso es un bucle: entras, reinicias, fuera.
      // Al revés lo peor que pasa es que una sesión heredada sobreviva, que
      // es exactamente lo de antes de este arreglo.
      await prefs.setBool(_clave, true);

      if (!await haySesion()) return false;
      await salir();
      return true;
    } catch (error, pila) {
      Errores.registrar(error, pila, origen: 'instalacion.sesionHeredada');
      return false;
    }
  }
}
