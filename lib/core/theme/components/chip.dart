import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_shape.dart';
import '../tokens/app_typography.dart';

/// Etiqueta pequeña con contorno. Se usa para el autor de una cata, la fecha,
/// el relleno o cualquier dato suelto.
class ChipCata extends StatelessWidget {
  const ChipCata({
    super.key,
    required this.texto,
    this.color = AppColors.superficieCalida,
    this.punto,
    this.emoji,
    this.compacto = false,
  });

  final String texto;
  final Color color;

  /// Círculo de color a la izquierda (el color del relleno, el de la mesa).
  final Color? punto;
  final String? emoji;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compacto ? 8 : 10,
        vertical: compacto ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppShape.radioPildora),
        border: Border.all(color: AppColors.tinta, width: AppShape.bordeFino),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (punto != null) ...<Widget>[
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: punto,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.tinta, width: 1.4),
              ),
            ),
            const SizedBox(width: 6),
          ],
          if (emoji != null) ...<Widget>[
            Text(emoji!, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
          ],
          Text(
            texto,
            // El color del texto lo decide el fondo: esta pastilla se pinta
            // con el color del relleno, de la dieta o de la mesa, y algunos
            // de esos colores no admiten tinta encima.
            style: AppTypography.etiqueta.copyWith(
              fontSize: compacto ? 11 : 12,
              color: AppColors.textoSobre(color),
            ),
          ),
        ],
      ),
    );
  }
}
