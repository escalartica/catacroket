import 'dart:io';

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../models/medio.dart';

/// La foto de una cata, venga de donde venga.
///
/// Una misma foto puede estar en tres estados y cada pantalla resolvía los
/// tres a mano, con el resultado de que unas se acordaban de la nube y otras
/// no. Aquí se decide una vez:
///
/// 1. Hay fichero en este móvil: se pinta, que es instantáneo y no gasta
///    datos. Es el caso de quien hizo la foto.
/// 2. No hay fichero pero sí miniatura: se pinta ésa. Es el caso de tu
///    gente, y el tuyo después de reinstalar la app.
/// 3. No hay ninguna de las dos: [siFalla], que suele ser el dibujo.
///
/// El orden importa. El fichero local va primero aunque también haya
/// miniatura, porque es la foto entera y no una reducción.
class FotoMedio extends StatelessWidget {
  const FotoMedio({
    super.key,
    required this.medio,
    required this.siFalla,
    this.fit = BoxFit.cover,
    this.ancho,
    this.alto,
  });

  final Medio medio;

  /// Qué pintar cuando no hay foto que valga. Se construye a demanda: no
  /// tiene sentido montar el dibujo si al final va a ganar la foto.
  final Widget Function() siFalla;

  final BoxFit fit;
  final double? ancho;
  final double? alto;

  @override
  Widget build(BuildContext context) {
    // Se intenta el fichero y se deja que falle si no está, en vez de
    // preguntar antes con existsSync: eso es una lectura de disco en cada
    // fotograma, y estas tarjetas van en listas que se desplazan. Cuando el
    // fichero no está —al reinstalar, las rutas siguen guardadas pero los
    // ficheros ya no— el error cae en la miniatura, que es la que queda.
    if (medio.ruta.isNotEmpty) {
      return Image.file(
        File(medio.ruta),
        width: ancho,
        height: alto,
        fit: fit,
        errorBuilder: (_, _, _) => _laQueViajo(),
      );
    }
    return _laQueViajo();
  }

  /// La miniatura que viajó con la cata.
  ///
  /// Se decodifica cada vez que se pinta, que suena a caro y no lo es: son
  /// 800 píxeles y Flutter guarda el resultado en su caché de imágenes, así
  /// que el trabajo se hace una vez por foto y no una vez por fotograma.
  Widget _laQueViajo() {
    if (!medio.viaja) return siFalla();

    try {
      final Uint8List datos = base64Decode(medio.mini!);
      return Image.memory(
        datos,
        width: ancho,
        height: alto,
        fit: fit,
        errorBuilder: (_, _, _) => siFalla(),
      );
    } catch (_) {
      // Una miniatura corrupta no puede tumbar la pantalla: el dibujo, y a
      // seguir.
      return siFalla();
    }
  }
}
