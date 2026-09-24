import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_shape.dart';
import '../tokens/app_typography.dart';

/// La caja de buscar de la app.
///
/// Vive aquí y no dentro de la pantalla que la usa porque la usan dos: los
/// rellenos del formulario y las catas de La Vitrina. Estaba escrita en el
/// selector de rellenos, y la segunda habría sido una copia con las mismas
/// medidas puestas otra vez a ojo.
class Buscador extends StatelessWidget {
  const Buscador({
    super.key,
    required this.control,
    required this.onCambio,
    required this.onLimpiar,
    required this.pista,
  });

  final TextEditingController control;
  final ValueChanged<String> onCambio;

  /// Nulo cuando no hay nada que borrar: la equis no aparece hasta que hay
  /// algo escrito, para no ofrecer un botón que no haría nada.
  final VoidCallback? onLimpiar;

  /// Qué se busca aquí: «Buscar relleno», «Buscar entre tus catas».
  final String pista;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(AppShape.radioPildora),
        border: Border.all(color: AppColors.tinta, width: AppShape.borde),
      ),
      padding: const EdgeInsets.only(left: 14),
      child: Row(
        children: <Widget>[
          const Icon(Icons.search_rounded, size: 20, color: AppColors.tinta),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: control,
              onChanged: onCambio,
              textInputAction: TextInputAction.search,
              style: AppTypography.cuerpo.copyWith(fontSize: 15),
              cursorColor: AppColors.tinta,
              decoration: InputDecoration(
                hintText: pista,
                hintStyle: AppTypography.cuerpo.copyWith(
                  fontSize: 15,
                  color: AppColors.tintaSuave,
                  fontWeight: FontWeight.w600,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
          if (onLimpiar != null)
            Semantics(
              button: true,
              label: 'Borrar la búsqueda',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onLimpiar,
                // 46 de lado: por debajo de 44 el dedo no acierta, y esto se
                // toca con una mano mientras la otra sujeta una croqueta.
                child: const SizedBox(
                  width: 46,
                  height: 46,
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.tinta,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
