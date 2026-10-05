import 'package:catacroket/core/models/dieta.dart';
import 'package:catacroket/core/theme/tokens/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Seis pastillas apagadas tienen que verse igual de apagadas.
void main() {
  test('todas las dietas sin marcar pesan lo mismo en pantalla', () {
    // Con una mezcla fija del 86 %, el rosa de «sin frutos secos» quedaba en
    // luminancia 0,830 y las otras cinco entre 0,877 y 0,934. En una fila
    // donde «encendida» significa «esto no lo puedo comer», que una se vea
    // más oscura que el resto no es un matiz de diseño.
    final List<double> luces = <double>[
      for (final Dieta d in Dieta.values)
        AppColors.velo(d.color).computeLuminance(),
    ];

    for (final double l in luces) {
      expect((l - 0.88).abs(), lessThan(0.01), reason: 'luces: $luces');
    }
  });

  test('un color que ya es más claro que el objetivo se deja en paz', () {
    expect(AppColors.velo(const Color(0xFFFFFFFF)), const Color(0xFFFFFFFF));
  });

  test('sigue reconociéndose de qué color era', () {
    // Lavar hasta igualar no puede acabar en seis blancos: el color es lo
    // que hace reconocible cada dieta de un vistazo.
    final Color rosa = AppColors.velo(Dieta.sinFrutosSecos.color);
    final Color azul = AppColors.velo(Dieta.sinLactosa.color);

    expect(rosa, isNot(azul));
    expect(rosa.r, greaterThan(rosa.b));
    expect(azul.b, greaterThan(azul.r));
  });
}
