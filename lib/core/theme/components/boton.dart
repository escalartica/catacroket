import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_shape.dart';
import '../tokens/app_typography.dart';
import 'pegatina.dart';

/// Botón de la app. Es una [Pegatina] con forma de píldora.
///
/// Deshabilitado no se pinta gris: se desatura y se le baja la opacidad, pero
/// conserva el contorno. Un botón gris en esta paleta parecería una superficie
/// más, no un botón apagado.
class BotonPegatina extends StatelessWidget {
  const BotonPegatina({
    super.key,
    required this.texto,
    this.onTap,
    this.color = AppColors.sol,
    this.icono,
    this.pequeno = false,
    this.ancho,
  });

  /// Variante clara, para acciones secundarias.
  const BotonPegatina.fantasma({
    super.key,
    required this.texto,
    this.onTap,
    this.icono,
    this.pequeno = false,
    this.ancho,
  }) : color = AppColors.superficie;

  final String texto;
  final VoidCallback? onTap;
  final Color color;
  final IconData? icono;
  final bool pequeno;
  final double? ancho;

  @override
  Widget build(BuildContext context) {
    final bool activo = onTap != null;

    final Color fondo = activo ? color : AppColors.superficieCalida;
    final Color tono =
        activo ? AppColors.tinta : AppColors.tintaApagada;

    final Widget contenido = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (icono != null) ...<Widget>[
          Icon(icono, size: pequeno ? 18 : 21, color: tono),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            texto,
            textAlign: TextAlign.center,
            style: (pequeno
                    ? AppTypography.boton.copyWith(fontSize: 15.5)
                    : AppTypography.boton)
                .copyWith(color: tono),
          ),
        ),
      ],
    );

    return Pegatina(
      onTap: onTap,
      color: fondo,
      radio: AppShape.radioPildora,
      sombra: activo ? AppShape.sombraNormal : AppShape.sombraChica,
      ancho: ancho ?? double.infinity,
      alto: pequeno ? 46 : 54,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alineacion: Alignment.center,
      child: contenido,
    );
  }
}

/// Botón redondo de la cabecera (volver, cerrar, ajustes).
class BotonRedondo extends StatelessWidget {
  const BotonRedondo({
    super.key,
    required this.icono,
    this.onTap,
    this.color = AppColors.superficie,
    this.tamano = 44,
    this.etiqueta,
  });

  final IconData icono;
  final VoidCallback? onTap;
  final Color color;
  final double tamano;
  final String? etiqueta;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: etiqueta,
      child: Pegatina(
        onTap: onTap,
        color: color,
        radio: tamano,
        sombra: AppShape.sombraChica,
        ancho: tamano,
        alto: tamano,
        padding: EdgeInsets.zero,
        alineacion: Alignment.center,
        child: Icon(icono, size: tamano * 0.46, color: AppColors.tinta),
      ),
    );
  }
}
