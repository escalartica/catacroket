import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_shape.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'boton.dart';
import 'campo.dart';

/// Lo que no quieres que te pongan, escrito a mano.
///
/// Las seis dietas cubren lo más común, pero no cubren el marisco, el sésamo,
/// el apio ni que no te guste el boletus. Esto es la válvula de escape: una
/// lista de palabras tuyas.
///
/// Cada palabra es una pastilla con su aspa. Se quitan tocándolas, que es lo
/// que la gente intenta hacer de todas formas.
class PildorasEvitar extends StatelessWidget {
  const PildorasEvitar({
    super.key,
    required this.lista,
    required this.onAnadir,
    required this.onQuitar,
    this.maximo = 12,
  });

  final Set<String> lista;
  final void Function(String) onAnadir;
  final void Function(String) onQuitar;
  final int maximo;

  Future<void> _preguntar(BuildContext context) async {
    final String? escrito = await showDialog<String>(
      context: context,
      builder: (BuildContext _) => const _DialogoEvitar(),
    );
    if (escrito != null && escrito.trim().isNotEmpty) onAnadir(escrito);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final String palabra in lista)
          Semantics(
            button: true,
            label: 'Quitar $palabra de la lista',
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onQuitar(palabra),
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                padding: const EdgeInsets.fromLTRB(14, 11, 10, 11),
                decoration: BoxDecoration(
                  color: AppColors.superficieHonda,
                  borderRadius: BorderRadius.circular(AppShape.radioPildora),
                  border:
                      Border.all(color: AppColors.tinta, width: AppShape.borde),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(palabra, style: AppTypography.cuerpoS),
                    const SizedBox(width: 6),
                    const Icon(Icons.close_rounded,
                        size: 16, color: AppColors.tinta),
                  ],
                ),
              ),
            ),
          ),
        if (lista.length < maximo)
          Semantics(
            button: true,
            label: 'Añadir algo que no comes',
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _preguntar(context),
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: AppColors.superficie,
                  borderRadius: BorderRadius.circular(AppShape.radioPildora),
                  border: Border.all(
                    color: AppColors.tinta,
                    width: AppShape.bordeFino,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(Icons.add_rounded,
                        size: 18, color: AppColors.tinta),
                    const SizedBox(width: 6),
                    Text('Otros', style: AppTypography.cuerpoS),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// El cuadro de escribir. Sale con el teclado puesto: si has tocado "Otros"
/// es porque vas a escribir.
class _DialogoEvitar extends StatefulWidget {
  const _DialogoEvitar();

  @override
  State<_DialogoEvitar> createState() => _DialogoEvitarState();
}

class _DialogoEvitarState extends State<_DialogoEvitar> {
  String _texto = '';

  /// Atajos. Son los alérgenos obligatorios que no están entre las seis
  /// dietas, más lo que la gente pide en un bar. Un toque y dentro.
  static const List<String> _sugerencias = <String>[
    'Marisco',
    'Pescado',
    'Sésamo',
    'Apio',
    'Mostaza',
    'Soja',
    'Sulfitos',
    'Cebolla',
    'Picante',
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.pantalla),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.l),
        decoration: BoxDecoration(
          color: AppColors.crema,
          borderRadius: BorderRadius.circular(AppShape.radioL),
          border: Border.all(color: AppColors.tinta, width: AppShape.borde),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Que no te pongan', style: AppTypography.tituloM),
            const SizedBox(height: 6),
            Text(
              'Una alergia, una intolerancia o algo que no te gusta. '
              'Te avisará cuando una croqueta lo lleve apuntado.',
              style: AppTypography.cuerpoS.copyWith(height: 1.35),
            ),
            const SizedBox(height: AppSpacing.m),
            Campo(
              etiqueta: 'Ingrediente',
              valor: _texto,
              autofoco: true,
              pista: 'Marisco, sésamo, boletus…',
              onCambio: (String v) => setState(() => _texto = v),
            ),
            const SizedBox(height: AppSpacing.m),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final String s in _sugerencias)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(context).pop(s),
                    child: Container(
                      // 44 como todo lo demás en la app: era el único
                      // control que se quedaba por debajo.
                      constraints: const BoxConstraints(minHeight: 44),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: AppColors.superficie,
                        borderRadius:
                            BorderRadius.circular(AppShape.radioPildora),
                        border: Border.all(
                          color: AppColors.tinta,
                          width: AppShape.bordeFino,
                        ),
                      ),
                      child: Text(s, style: AppTypography.cuerpoS),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.l),
            Row(
              children: <Widget>[
                Expanded(
                  child: BotonPegatina.fantasma(
                    texto: 'Cancelar',
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: BotonPegatina(
                    texto: 'Añadir',
                    onTap: _texto.trim().isEmpty
                        ? null
                        : () => Navigator.of(context).pop(_texto),
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
