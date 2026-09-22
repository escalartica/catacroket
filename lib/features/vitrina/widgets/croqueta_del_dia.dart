import 'package:flutter/material.dart';

import '../../../arte/corte_painter.dart';
import '../../../core/data/rellenos.dart';
import '../../../core/models/cata.dart';
import '../../../core/theme/components/chip.dart';
import '../../../core/theme/components/nota.dart';
import '../../../core/theme/components/pegatina.dart';
import '../../../core/theme/tokens/app_colors.dart';
import '../../../core/theme/tokens/app_shape.dart';
import '../../../core/theme/tokens/app_typography.dart';

/// El bloque grande de La Vitrina: la mejor croqueta registrada.
///
/// Es el único elemento de la pantalla con fondo de color saturado. Si
/// hubiera dos, ninguno sería el importante.
class CroquetaDelDia extends StatelessWidget {
  const CroquetaDelDia({super.key, required this.cata, this.onTap});

  final Cata cata;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Relleno relleno = Rellenos.de(cata.rellenoId);

    return Pegatina(
      onTap: onTap,
      color: AppColors.tomate,
      radio: AppShape.radioXL,
      sombra: AppShape.sombraGrande,
      lunares: true,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Transform.rotate(
                  angle: -0.05,
                  child: const ChipCata(
                    texto: 'CROQUETA DEL DÍA',
                    color: AppColors.sol,
                    compacto: true,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  relleno.nombre,
                  style: AppTypography.tituloM,
                ),
                const SizedBox(height: 3),
                Text(
                  cata.sitioYLugar,
                  style: AppTypography.cuerpoS.copyWith(
                    color: AppColors.tinta,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Nota(valor: cata.puntuacion),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: ChipCata(
                        texto: 'Récord de tu mesa',
                        color: AppColors.chicle,
                        compacto: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 104,
            child: ElCorte(
              corte: cata.corte,
              rellenoId: cata.rellenoId,
              semilla: cata.id,
            ),
          ),
        ],
      ),
    );
  }
}

/// La racha semanal.
///
/// Dos datos distintos en un bloque: el número son las semanas seguidas
/// catando, y las siete pastillas son las siete últimas semanas tal cual,
/// con sus huecos. Antes las pastillas pintaban la racha recortada a siete,
/// así que a partir de la octava semana el número subía y el dibujo no.
class Racha extends StatelessWidget {
  const Racha({
    super.key,
    required this.semanas,
    required this.historial,
    required this.catadaEstaSemana,
  });

  /// Semanas seguidas catando.
  final int semanas;

  /// Las siete últimas semanas, de la más antigua a la de hoy.
  final List<bool> historial;

  /// Si la de esta semana ya está hecha.
  final bool catadaEstaSemana;

  String get _titulo => semanas == 0
      ? 'Sin racha todavía'
      : 'Racha de $semanas ${semanas == 1 ? 'semana' : 'semanas'}';

  /// El subtítulo explica qué se está contando y en qué estado estás. Antes
  /// decía siempre "una cata más y sigue viva", incluso cuando ya habías
  /// catado: pedía algo que ya estaba hecho.
  String get _pie {
    if (semanas == 0) return 'Cata una croqueta y arranca la cuenta';
    if (catadaEstaSemana) return 'Semanas seguidas catando. Esta ya está.';
    return 'Semanas seguidas catando. Cata esta semana o se apaga.';
  }

  @override
  Widget build(BuildContext context) {
    return Pegatina(
      color: AppColors.lima,
      sombra: AppShape.sombraChica,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Semantics(
        label: semanas == 0
            ? 'Sin racha todavía. $_pie'
            : 'Racha de $semanas semanas. $_pie',
        excludeSemantics: true,
        child: Row(
          children: <Widget>[
            Text(
              catadaEstaSemana || semanas == 0 ? '\u{1F525}' : '\u{23F3}',
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(_titulo, style: AppTypography.tituloS.copyWith(fontSize: 16)),
                  Text(
                    _pie,
                    style: AppTypography.cuerpoS.copyWith(
                      fontSize: 12.5,
                      color: AppColors.tinta,
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (final bool hubo in historial)
                  Container(
                    width: 9,
                    height: 20,
                    margin: const EdgeInsets.only(left: 4),
                    decoration: BoxDecoration(
                      color: hubo
                          ? AppColors.sol
                          : Colors.white.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: AppColors.tinta, width: 1.4),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
