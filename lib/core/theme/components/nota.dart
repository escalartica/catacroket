import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../utils/formato.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_shape.dart';
import '../tokens/app_typography.dart';

/// El CataScore: la nota de 0 a 10 dentro de una pegatina amarilla girada.
///
/// El giro es lo que la convierte en pegatina y no en etiqueta. Es constante
/// (-3°) y NO aleatorio: un giro distinto en cada tarjeta parecería un fallo
/// de maquetación, no una decisión.
class Nota extends StatelessWidget {
  const Nota({
    super.key,
    required this.valor,
    this.grande = false,
    this.conSufijo = false,
  });

  final double valor;
  final bool grande;
  final bool conSufijo;

  @override
  Widget build(BuildContext context) {
    // "8,5 sobre 10" y no "ocho coma cinco, barra, diez": los dos trozos de
    // texto son uno solo y así se dicen.
    return Semantics(
      label: 'Nota ${Formato.nota(valor)} sobre 10',
      excludeSemantics: true,
      child: Transform.rotate(
      angle: (grande ? -4 : -3) * math.pi / 180,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: grande ? 16 : 9,
          vertical: grande ? 6 : 5,
        ),
        decoration: BoxDecoration(
          color: AppColors.sol,
          borderRadius: BorderRadius.circular(grande ? 18 : 11),
          border: Border.all(color: AppColors.tinta, width: AppShape.borde),
          boxShadow: AppShape.sombra(
            grande ? AppShape.sombraNormal : const Offset(2, 2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: <Widget>[
            Text(
              Formato.nota(valor),
              style: grande
                  ? AppTypography.cifra
                  : AppTypography.cifraS.copyWith(fontSize: 16),
            ),
            if (conSufijo)
              Text(
                '/10',
                style: AppTypography.etiqueta.copyWith(
                  fontSize: grande ? 17 : 11,
                  color: AppColors.tintaSuave,
                ),
              ),
          ],
        ),
      ),
      ),
    );
  }
}
