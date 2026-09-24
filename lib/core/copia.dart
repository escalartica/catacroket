import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Sacar tus catas de la app y volver a meterlas.
///
/// Por qué existe: hasta ahora no había ninguna forma. La app dice que las
/// catas viven en este móvil, y era literal —sin cuenta, sin nube, sin
/// exportar—, así que un móvil perdido se llevaba por delante una libreta de
/// años. Para una app cuyo argumento es "meses después ves dónde estaba
/// aquella que no se te olvida", eso era el mayor riesgo que tenía.
///
/// El formato es JSON y no un binario a propósito: se abre con cualquier
/// cosa, se lee a ojo y se puede rescatar a mano si algún día esta función
/// deja de existir. Una copia que sólo entiende la app que la hizo no es
/// una copia, es otra jaula.
///
/// Lo que NO lleva: las fotos y los vídeos, que son ficheros aparte en el
/// disco. Va dicho en la propia copia y en la pantalla, porque una copia que
/// se deja cosas sin avisar es peor que no tenerla.
class Copia {
  const Copia._();

  /// Sube cuando el formato cambie de forma que una copia vieja ya no se
  /// pueda leer tal cual. Mientras sea 1, todas son compatibles.
  static const int version = 1;

  /// Las claves que se guardan. Todo lo que el usuario ha creado o dicho.
  ///
  /// `visto` no entra: es qué carteles de ayuda ha cerrado, y en un móvil
  /// nuevo es mejor que se vuelvan a enseñar.
  static const List<String> claves = <String>[
    'catacroket.catas.v1',
    // Catas que la app no ha sabido leer y apartó sin tocarlas. Van en la
    // copia porque el fichero es JSON legible: si una actualización rompe el
    // formato, están ahí para rescatarlas a mano en vez de perdidas.
    'catacroket.catas.ilegible.v1',
    'catacroket.mesas.v1',
    'catacroket.evitar.v1',
    'catacroket.midieta.v1',
    'catacroket.yo.nombre.v1',
  ];

  /// Arma la copia con lo que haya guardado ahora mismo.
  static Future<String> hacer({DateTime Function()? ahora}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final Map<String, dynamic> datos = <String, dynamic>{};
    for (final String clave in claves) {
      final Object? valor = prefs.get(clave);
      if (valor != null) datos[clave] = valor;
    }

    return const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
      'app': 'catacroket',
      'version': version,
      'cuando': (ahora ?? DateTime.now)().toIso8601String(),
      // Se dice dentro del fichero, no sólo en la pantalla: quien lo abra
      // dentro de dos años no va a tener la pantalla delante.
      'nota': 'Las fotos y los vídeos no van aquí: son ficheros aparte en el '
          'móvil. Esta copia lleva las catas, las mesas y tus preferencias.',
      'datos': datos,
    });
  }

  /// Cuántas catas lleva una copia, para poder decirlo antes de restaurar.
  ///
  /// Devuelve nulo si el texto no es una copia de esta app: así la pantalla
  /// puede distinguir "no es una copia" de "es una copia vacía".
  static int? cuantasCatas(String texto) {
    final Map<String, dynamic>? copia = _leer(texto);
    if (copia == null) return null;

    final Object? crudo = (copia['datos'] as Map<String, dynamic>?)?[
        'catacroket.catas.v1'];
    if (crudo is! String) return 0;

    try {
      return (jsonDecode(crudo) as List<dynamic>).length;
    } catch (_) {
      return 0;
    }
  }

  /// Mete una copia en el móvil, sustituyendo lo que hubiera.
  ///
  /// Devuelve false si el texto no es una copia válida, o si el móvil no ha
  /// podido guardarla. No lanza: quien la llama está en una pantalla y
  /// necesita poder decirlo, no reventar.
  ///
  /// Lo segundo faltaba, y era lo peor que podía faltar aquí: `setString` no
  /// lanza cuando no puede escribir, devuelve false, y ese false se tiraba. La
  /// pantalla decía «restaurado» sin que se hubiera restaurado nada. Mentir
  /// está mal en cualquier sitio; en la pantalla a la que va alguien que
  /// acaba de perder el móvil, más.
  ///
  /// Sustituye en vez de mezclar. Mezclar suena mejor y es peor: sin saber
  /// cuál de dos versiones de la misma cata es la buena, acabarías con
  /// duplicados que hay que limpiar a mano. Restaurar es para un móvil
  /// nuevo, y ahí no hay nada con lo que mezclar.
  static Future<bool> restaurar(String texto) async {
    final Map<String, dynamic>? copia = _leer(texto);
    if (copia == null) return false;

    final Map<String, dynamic>? datos =
        copia['datos'] as Map<String, dynamic>?;
    if (datos == null) return false;

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // Se intentan todas aunque una falle: restaurar a medias es mejor que no
      // restaurar nada, y lo que hay que hacer con el fallo es contarlo, no
      // parar. Pero se devuelve false, para que la pantalla no cante victoria.
      bool todoEscrito = true;
      for (final String clave in claves) {
        final Object? valor = datos[clave];
        if (valor is String) {
          if (!await prefs.setString(clave, valor)) todoEscrito = false;
        } else if (valor is List<dynamic>) {
          final bool ok = await prefs.setStringList(
            clave,
            valor.map((dynamic e) => e.toString()).toList(),
          );
          if (!ok) todoEscrito = false;
        }
      }
      return todoEscrito;
    } catch (_) {
      return false;
    }
  }

  /// Comprueba que el texto es una copia de esta app y no otra cosa.
  static Map<String, dynamic>? _leer(String texto) {
    try {
      final Object? crudo = jsonDecode(texto);
      if (crudo is! Map<String, dynamic>) return null;
      if (crudo['app'] != 'catacroket') return null;

      // Una copia de una versión futura puede traer un formato que aquí no
      // se entienda. Mejor decir que no se puede que meter medio dato.
      final Object? v = crudo['version'];
      if (v is! int || v > version) return null;

      return crudo;
    } catch (_) {
      return null;
    }
  }

  /// Cómo se llama el fichero que se comparte.
  static String nombreFichero({DateTime Function()? ahora}) {
    final DateTime d = (ahora ?? DateTime.now)();
    final String dia = d.toIso8601String().substring(0, 10);
    return 'catacroket-$dia.json';
  }
}
