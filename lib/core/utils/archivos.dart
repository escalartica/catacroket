import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Dónde está de verdad un fichero nuestro.
///
/// La app copia a su propia carpeta cada foto que eliges, y hasta ahora
/// guardaba la ruta entera: algo como
/// `/var/mobile/Containers/Data/Application/A1B2-…/Documents/medios/foto.jpg`.
///
/// Ese trozo del medio es un identificador que **iOS cambia** cada vez que se
/// reinstala la app, y en algunas actualizaciones también. El fichero sigue
/// donde estaba, pero la ruta apuntada hace un mes ya no lleva a ningún
/// sitio: la foto «desaparece» sin que nadie la haya borrado. En Android pasa
/// lo mismo al restaurar una copia de seguridad en otro teléfono.
///
/// Así que se guarda sólo la parte estable —`medios/foto.jpg`— y la carpeta
/// de la app se pone delante al abrirla, con lo que valga hoy.
///
/// [enDisco] también arregla las rutas antiguas que ya están guardadas: si le
/// llega una absoluta, busca nuestra carpeta dentro y la vuelve a colgar de
/// la de ahora. Por eso las fotos de antes vuelven solas sin migrar nada.
abstract final class Archivos {
  /// La carpeta de la app, tal y como se llama en esta ejecución.
  ///
  /// Se lee una vez al arrancar porque `path_provider` es asíncrono y esto se
  /// necesita dentro de un `build`, que no puede esperar a nada.
  static String _raiz = '';

  static String get raiz => _raiz;

  static Future<void> preparar() async {
    try {
      final Directory carpeta = await getApplicationDocumentsDirectory();
      _raiz = carpeta.path;
    } catch (_) {
      // Sin carpeta se sigue trabajando con lo que haya guardado. Las fotos
      // no se verán, pero nada más se rompe.
    }
  }

  /// Sólo para los tests, que no tienen carpeta de aplicación.
  static void ponerRaiz(String ruta) => _raiz = ruta;

  /// Las carpetas que crea la app. Sirven de ancla para rescatar una ruta
  /// vieja: lo que vaya de ahí en adelante es lo que hay que conservar.
  static const List<String> _nuestras = <String>['/medios/', '/perfil/'];

  /// Lo que se guarda: la parte que no cambia.
  static String guardable(String absoluta) {
    if (absoluta.isEmpty) return absoluta;
    if (_raiz.isNotEmpty && absoluta.startsWith('$_raiz/')) {
      return absoluta.substring(_raiz.length + 1);
    }
    return _soloLoNuestro(absoluta) ?? absoluta;
  }

  /// Dónde abrirlo hoy.
  static String enDisco(String guardada) {
    if (guardada.isEmpty) return guardada;

    // Relativa: lo normal desde que esto existe.
    if (!guardada.startsWith('/')) {
      return _raiz.isEmpty ? guardada : '$_raiz/$guardada';
    }

    // Absoluta y guardada antes de esto. Si lleva una carpeta nuestra
    // dentro, se recoloca; si no, se devuelve tal cual y que lo intente.
    final String? trozo = _soloLoNuestro(guardada);
    if (trozo == null || _raiz.isEmpty) return guardada;
    return '$_raiz/$trozo';
  }

  static File fichero(String guardada) => File(enDisco(guardada));

  static String? _soloLoNuestro(String ruta) {
    for (final String carpeta in _nuestras) {
      final int donde = ruta.lastIndexOf(carpeta);
      if (donde >= 0) return ruta.substring(donde + 1);
    }
    return null;
  }
}
