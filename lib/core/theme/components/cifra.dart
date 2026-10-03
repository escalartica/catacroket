import 'package:flutter/material.dart';

import '../tokens/app_shape.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'numero_vivo.dart';
import 'pegatina.dart';

/// Un número grande con su etiqueta debajo, en un bloque de color.
///
/// Es la pieza del Croquetómetro del perfil y de la cabecera de una mesa.
/// Vivía copiada letra por letra en las dos pantallas, y las dos copias se
/// rompían igual: sin `FittedBox`, «ciudades» a 11,5 px no cabe en los ~40
/// puntos útiles que quedan cuando la fila tiene cinco celdas, y Flutter no
/// parte una palabra sin espacios: la corta. Se leía «ciudade». Con el texto
/// grande de los ajustes de accesibilidad pasaba también con cuatro celdas, y
/// con cualquier número de tres cifras.
///
/// `scaleDown` y no `contain`: a tamaño normal no se toca nada, y sólo encoge
/// cuando de verdad no cabe. Encoger es peor que no encoger, y muchísimo
/// mejor que cortar.
class Cifra extends StatelessWidget {
  const Cifra({
    super.key,
    required this.valor,
    required this.etiqueta,
    required this.color,
    this.numero,
    this.decimales = 0,
  });

  /// Lo que se pinta cuando no hay [numero]: un guion, un texto cualquiera.
  final String valor;

  /// El número, si lo hay, para que vaya de donde estaba a donde está.
  ///
  /// Se pasa aparte del texto porque lo que hay que interpolar es la
  /// cantidad, no las letras. Cuando llega la cata de alguien de tu mesa,
  /// esta cifra sube sola y ese movimiento es lo único que te avisa.
  final double? numero;

  final int decimales;

  final String etiqueta;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Pegatina(
      color: color,
      radio: AppShape.radioM,
      sombra: AppShape.sombraChica,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          FittedBox(
            fit: BoxFit.scaleDown,
            child: numero == null
                ? Text(
                    valor,
                    maxLines: 1,
                    style: AppTypography.cifraM.copyWith(fontSize: 28),
                  )
                : NumeroVivo(
                    valor: numero,
                    decimales: decimales,
                    estilo: AppTypography.cifraM.copyWith(fontSize: 28),
                  ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              etiqueta,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: AppTypography.etiqueta.copyWith(fontSize: 11.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// Una fila de [Cifra] que se parte en dos cuando la letra crece.
///
/// Cinco celdas en una pantalla de 375 puntos dejan ~45 útiles cada una. A
/// tamaño normal entran justas; con la letra del sistema al doble, «nota
/// media» pide el triple y el `FittedBox` de [Cifra] la encoge hasta ~8
/// puntos: más pequeña que al 100%. O sea que quien amplía la letra porque la
/// necesita recibía letra todavía menor, que es exactamente lo contrario de
/// lo que pide la norma.
///
/// Partiéndolas, cada celda tiene el doble de ancho y la letra crece de
/// verdad. La lista de mesas ya resolvía esto mismo con un `Wrap`; esto es lo
/// mismo para bloques de ancho fijo.
class FilaDeCifras extends StatelessWidget {
  const FilaDeCifras({super.key, required this.cifras});

  final List<Cifra> cifras;

  @override
  Widget build(BuildContext context) {
    if (cifras.isEmpty) return const SizedBox.shrink();

    // La escala real del sistema, medida sobre el tamaño de la etiqueta.
    final double escala = MediaQuery.textScalerOf(context).scale(11.5) / 11.5;
    final int porFila = escala > 1.25
        ? (cifras.length > 2 ? 2 : cifras.length)
        : cifras.length;

    final List<List<Cifra>> filas = <List<Cifra>>[];
    for (int i = 0; i < cifras.length; i += porFila) {
      filas.add(cifras.sublist(
        i,
        i + porFila > cifras.length ? cifras.length : i + porFila,
      ));
    }

    return Column(
      children: <Widget>[
        for (int f = 0; f < filas.length; f++) ...<Widget>[
          if (f > 0) const SizedBox(height: AppSpacing.s),
          // Sin `CrossAxisAlignment.stretch`: estas filas viven dentro de
          // una lista, donde el alto que llega es infinito, y «estirar» pide
          // a los hijos que ocupen ese infinito. El layout reventaba y detrás
          // caían dieciocho excepciones de semántica que no decían de dónde
          // venían. Cada celda mide lo que mide su contenido, como antes.
          Row(
            children: <Widget>[
              for (int i = 0; i < filas[f].length; i++) ...<Widget>[
                if (i > 0) const SizedBox(width: AppSpacing.s),
                Expanded(child: filas[f][i]),
              ],
              // Rellena el hueco de la última fila incompleta para que una
              // celda suelta no se estire a lo ancho de toda la fila.
              for (int i = filas[f].length; i < porFila; i++) ...<Widget>[
                const SizedBox(width: AppSpacing.s),
                const Expanded(child: SizedBox.shrink()),
              ],
            ],
          ),
        ],
      ],
    );
  }
}
