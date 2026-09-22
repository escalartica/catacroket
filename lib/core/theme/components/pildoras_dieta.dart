import 'package:flutter/material.dart';

import '../../models/dieta.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_shape.dart';
import '../tokens/app_typography.dart';
import 'campo.dart';

/// Las seis dietas, en pastillas. Es el mismo control en el formulario y en
/// el filtro de la Barra Libre: si en un sitio se marca "sin gluten" y en el
/// otro se pide, tienen que ser exactamente el mismo botón y el mismo color.
class PildorasDieta extends StatelessWidget {
  const PildorasDieta({
    super.key,
    required this.marcadas,
    required this.onAlternar,
    this.recuento,
  });

  final Set<Dieta> marcadas;
  final void Function(Dieta) onAlternar;

  /// Cuántas catas hay de cada una. Sólo lo pasa el filtro; en el formulario
  /// el número no significa nada y sobra.
  final Map<Dieta, int>? recuento;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final Dieta d in Dieta.values)
          OpcionPildora(
            texto: recuento == null
                ? d.nombre
                : '${d.nombre}  ${recuento![d] ?? 0}',
            emoji: d.emoji,
            activa: marcadas.contains(d),
            colorActiva: d.color,
            // Un velo del color de la dieta, no el color entero: se reconoce
            // cada una de un vistazo y la marcada sigue destacando, porque
            // va a saturación completa y con más sombra.
            colorInactiva: Color.lerp(d.color, AppColors.superficie, 0.86)!,
            // Se marcan varias: alguien puede ser vegano Y celíaco.
            enGrupoUnico: false,
            onTap: () => onAlternar(d),
          ),
      ],
    );
  }
}

/// El aviso. Va donde se marcan las dietas y donde se leen.
///
/// No es letra pequeña por cubrirse: una app que le dice a un celíaco "esta
/// vale" y se equivoca le hace daño de verdad. La app guarda lo que apuntó
/// quien comió, y eso es lo que tiene que decir, con todas las letras.
class AvisoAlergias extends StatelessWidget {
  const AvisoAlergias({super.key, this.texto});

  final String? texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.agua,
        borderRadius: BorderRadius.circular(AppShape.radioM),
        border: Border.all(color: AppColors.tinta, width: AppShape.bordeFino),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('⚠️', style: TextStyle(fontSize: 15)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto ??
                  'Esto lo marca quien cata, no la cocina. Si hay alergia de '
                      'por medio, pregunta siempre en el bar.',
              style: AppTypography.cuerpoS.copyWith(
                fontSize: 12.5,
                height: 1.3,
                color: AppColors.tinta,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
