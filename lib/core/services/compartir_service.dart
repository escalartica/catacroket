import 'package:url_launcher/url_launcher.dart';

import '../data/enlaces.dart';
import '../models/cata.dart';
import '../models/mesa.dart';
import '../utils/formato.dart';

/// Mandar cosas fuera de la app.
///
/// WhatsApp se abre por `wa.me`, que es un enlace normal y corriente: si
/// WhatsApp está instalado lo coge él, y si no, se abre la web. Se podría
/// usar el esquema `whatsapp://`, pero entonces habría que declararlo en el
/// Info.plist, preguntar si está instalado y tener un plan para cuando no lo
/// esté. Un enlace https no necesita nada de eso y no falla nunca.
///
/// Esto es para el texto. Para mandar la estampa —una imagen— sigue siendo la
/// hoja del sistema, porque ninguna app se puede saltar eso, y en esa hoja
/// WhatsApp suele salir el primero.
class CompartirService {
  const CompartirService._();

  /// Abre WhatsApp con el texto ya escrito. Devuelve false si no se pudo
  /// abrir nada, para que la pantalla lo diga en vez de quedarse muda.
  static Future<bool> porWhatsApp(String texto) async {
    try {
      return await launchUrl(
        Uri.https('wa.me', '/', <String, String>{'text': texto}),
        mode: LaunchMode.externalApplication,
      );
    } on Object catch (_) {
      return false;
    }
  }

  /// "Esto es lo que me estoy comiendo ahora mismo."
  ///
  /// Es el mensaje del momento: se manda con la croqueta todavía en el plato,
  /// así que va al grano y cabe en la vista previa de una notificación.
  static String cata(Cata c) {
    final String plato = c.esSurtido
        ? 'Surtido de ${c.sabores.length}'
        : c.saborPrincipal.nombre;
    final String nota = '${Formato.nota(c.puntuacion)}/10';
    final String apunte = c.nota.trim().isEmpty ? '' : ' «${c.nota.trim()}»';
    return '$plato en ${c.sitio} (${c.lugar}): $nota.$apunte';
  }

  /// "Vente a la app."
  static String invitacionApp() =>
      'Me he hecho una libreta de croquetas en Catacroket: apuntas dónde te '
      'la comiste, le pones nota y te dibuja el corte. Vente y comparamos. 🥔\n'
      '${Enlaces.dondeEsta}';

  /// "Vente a mi mesa."
  static String invitacionMesa(Mesa mesa) =>
      'Te abro sitio en «${mesa.nombre}», mi mesa de Catacroket. '
      'El código es ${mesa.codigo}. 🥔\n${Enlaces.dondeEsta}';
}
