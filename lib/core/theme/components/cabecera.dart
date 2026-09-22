import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'boton.dart';

/// Cabecera de pantalla: título grande, subtítulo y como mucho una acción.
///
/// No es un `AppBar`: no hay barra, ni sombra, ni fondo. El título vive
/// directamente sobre el fondo de lunares y el contenido pasa por debajo al
/// hacer scroll, que es lo que mantiene la pantalla ligera.
class Cabecera extends StatelessWidget {
  const Cabecera({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.accion,
    this.volver,
  });

  final String titulo;
  final String? subtitulo;
  final Widget? accion;

  /// Si se pasa, aparece la flecha de volver a la izquierda.
  final VoidCallback? volver;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pantalla,
        AppSpacing.s,
        AppSpacing.pantalla,
        AppSpacing.m,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          if (volver != null) ...<Widget>[
            BotonRedondo(
              icono: Icons.arrow_back_ios_new_rounded,
              onTap: volver,
              etiqueta: 'Volver',
            ),
            const SizedBox(width: AppSpacing.m),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  titulo,
                  style: AppTypography.tituloXL,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitulo != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    subtitulo!,
                    style: AppTypography.cuerpoS.copyWith(
                      color: AppTypography.cuerpoS.color?.withValues(alpha: 0.65),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (accion != null) ...<Widget>[
            const SizedBox(width: AppSpacing.m),
            accion!,
          ],
        ],
      ),
    );
  }
}

/// Título de sección, con una pastilla opcional a la derecha.
class TituloSeccion extends StatelessWidget {
  const TituloSeccion({super.key, required this.texto, this.pastilla});

  final String texto;
  final Widget? pastilla;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.m),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(texto, style: AppTypography.tituloM)),
          ?pastilla,
        ],
      ),
    );
  }
}

/// Título en versales dentro de un panel (la pastilla de tinta del prototipo).
class EtiquetaPanel extends StatelessWidget {
  const EtiquetaPanel({super.key, required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTypography.antetitulo.color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        texto.toUpperCase(),
        style: AppTypography.antetitulo.copyWith(
          color: const Color(0xFFFFF7E6),
          fontSize: 11,
        ),
      ),
    );
  }
}
