import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_motion.dart';
import '../tokens/app_shape.dart';
import '../tokens/app_typography.dart';

/// Selector de una opción entre pocas, en forma de píldora.
class Segmentado<T> extends StatelessWidget {
  const Segmentado({
    super.key,
    required this.opciones,
    required this.seleccion,
    required this.onCambio,
    this.colorActivo = AppColors.uva,
  });

  /// Valor -> etiqueta. Tres como mucho: a partir de ahí no cabe el texto.
  final Map<T, String> opciones;
  final T seleccion;
  final ValueChanged<T> onCambio;
  final Color colorActivo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(AppShape.radioPildora),
        border: Border.all(color: AppColors.tinta, width: AppShape.borde),
        boxShadow: AppShape.sombra(AppShape.sombraChica),
      ),
      child: Row(
        children: <Widget>[
          for (final MapEntry<T, String> opcion in opciones.entries)
            Expanded(
              child: Semantics(
                button: true,
                inMutuallyExclusiveGroup: true,
                selected: opcion.key == seleccion,
                label: opcion.value,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onCambio(opcion.key);
                  },
                  child: AnimatedContainer(
                    duration: AppMotion.rapida,
                    curve: AppMotion.suave,
                    // 44 y no 38: es lo mínimo que se toca sin fallar. Con el
                    // relleno del contenedor la píldora entera mide 52.
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: opcion.key == seleccion
                          ? colorActivo
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppShape.radioPildora),
                    ),
                    child: Text(
                      opcion.value,
                      style: AppTypography.etiqueta.copyWith(
                        fontSize: 13,
                        // Medido, no a ojo: el blanco sobre la uva de antes se
                        // quedaba en 4,2:1.
                        color: opcion.key == seleccion
                            ? AppColors.textoSobre(colorActivo)
                            : AppColors.tinta,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
