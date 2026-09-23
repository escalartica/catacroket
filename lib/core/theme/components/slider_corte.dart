import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_shape.dart';
import '../tokens/app_typography.dart';

/// El deslizador de un eje del corte, de 0 a 10.
///
/// Está hecho a mano en vez de con `Slider` por dos razones: el control de
/// Material no admite una pista con contorno y sombra maciza sin reescribir
/// sus `SliderTrackShape`, y aquí el valor es un entero de 0 a 10, no un
/// continuo. Al arrastrar se engancha a cada entero y vibra al cambiar, que
/// es lo que convierte puntuar en algo físico.
class SliderCorte extends StatelessWidget {
  const SliderCorte({
    super.key,
    required this.nombre,
    required this.pista,
    required this.valor,
    required this.color,
    required this.onCambio,
  });

  final String nombre;

  /// La coletilla que explica el eje ("la costra", "la bechamel"...).
  final String pista;

  final int valor;
  final Color color;
  final ValueChanged<int> onCambio;

  static const double _alturaPista = 16;
  static const double _radioPomo = 15;

  void _desdePosicion(double dx, double ancho) {
    final double util = ancho - _radioPomo * 2;
    if (util <= 0) return;
    final double proporcion = ((dx - _radioPomo) / util).clamp(0.0, 1.0);
    final int nuevo = (proporcion * 10).round();
    if (nuevo != valor) {
      HapticFeedback.selectionClick();
      onCambio(nuevo);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: Text(nombre, style: AppTypography.tituloS)),
            Text(
              pista,
              style: AppTypography.cuerpoS.copyWith(
                fontSize: 12.5,
                color: AppColors.tintaSuave,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 38,
              padding: const EdgeInsets.symmetric(vertical: 3),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.sol,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: AppColors.tinta, width: 2),
              ),
              // La caja mide 38 y no crece: con la letra al 1,3 un "10"
              // se salía. Encoge en vez de recortarse.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('$valor', style: AppTypography.cifraS.copyWith(fontSize: 15)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Sin esto, puntuar una croqueta es imposible con el lector de
        // pantalla encendido: el deslizador está hecho a mano con gestos, y
        // un gesto de arrastre no existe para VoiceOver. Con `slider` y los
        // dos incrementos, se recorre de 0 a 10 con deslizar arriba y abajo.
        Semantics(
          slider: true,
          label: nombre,
          value: '$valor de 10',
          increasedValue: '${(valor + 1).clamp(0, 10)} de 10',
          decreasedValue: '${(valor - 1).clamp(0, 10)} de 10',
          onIncrease: valor >= 10 ? null : () => onCambio(valor + 1),
          onDecrease: valor <= 0 ? null : () => onCambio(valor - 1),
          child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints limites) {
            final double ancho = limites.maxWidth;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (TapDownDetails d) =>
                  _desdePosicion(d.localPosition.dx, ancho),
              onHorizontalDragUpdate: (DragUpdateDetails d) =>
                  _desdePosicion(d.localPosition.dx, ancho),
              child: SizedBox(
                height: 40,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    // Pista
                    Container(
                      height: _alturaPista,
                      decoration: BoxDecoration(
                        color: AppColors.superficie,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: AppColors.tinta,
                          width: AppShape.borde,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: (valor / 10).clamp(0.0, 1.0),
                            child: Container(color: color),
                          ),
                        ),
                      ),
                    ),
                    // Pomo
                    Align(
                      alignment: Alignment(
                        (valor / 10).clamp(0.0, 1.0) * 2 - 1,
                        0,
                      ),
                      child: Container(
                        width: _radioPomo * 2,
                        height: _radioPomo * 2,
                        decoration: BoxDecoration(
                          color: AppColors.tomate,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.tinta,
                            width: AppShape.borde,
                          ),
                          boxShadow: AppShape.sombra(const Offset(2, 2)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          ),
        ),
      ],
    );
  }
}
