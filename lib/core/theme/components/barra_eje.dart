import 'package:flutter/material.dart';

import '../../models/corte.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_motion.dart';
import '../tokens/app_shape.dart';
import '../tokens/app_typography.dart';

/// Un eje del corte: nombre, barra de color y número.
///
/// Cada eje tiene su color fijo en toda la app. Eso permite leer una ficha de
/// un vistazo sin volver a mirar las etiquetas, y es lo que hace que la misma
/// información funcione en la ficha, en el perfil y en el formulario.
class BarraEje extends StatelessWidget {
  const BarraEje({
    super.key,
    required this.nombre,
    required this.valor,
    required this.color,
  });

  final String nombre;
  final int valor;
  final Color color;

  static const Map<String, Color> colores = <String, Color>{
    'crujiente': AppColors.menta,
    'cremosidad': AppColors.sol,
    'sabor': AppColors.chicle,
    'relleno': AppColors.cielo,
  };

  /// Los cuatro ejes de un corte, en el orden canónico.
  static List<BarraEje> deCorte(Corte corte) => <BarraEje>[
        BarraEje(nombre: 'Crujiente', valor: corte.crujiente, color: colores['crujiente']!),
        BarraEje(nombre: 'Cremosidad', valor: corte.cremosidad, color: colores['cremosidad']!),
        BarraEje(nombre: 'Sabor', valor: corte.sabor, color: colores['sabor']!),
        BarraEje(nombre: 'Relleno', valor: corte.relleno, color: colores['relleno']!),
      ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 92,
            child: Text(nombre, style: AppTypography.etiqueta),
          ),
          Expanded(
            child: Container(
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.superficieCalida,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: AppColors.tinta, width: AppShape.bordeFino),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: (valor / 10).clamp(0.0, 1.0),
                  child: AnimatedContainer(
                    duration: AppMotion.rapida,
                    curve: AppMotion.suave,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(99),
                      border: Border(
                        right: BorderSide(
                          color: valor >= 10 ? Colors.transparent : AppColors.tinta,
                          width: AppShape.bordeFino,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 30,
            child: Text(
              '$valor',
              textAlign: TextAlign.end,
              style: AppTypography.cifraS,
            ),
          ),
        ],
      ),
    );
  }
}
