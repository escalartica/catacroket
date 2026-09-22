import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Geometría de la pegatina: radios, grosor del contorno y desplazamiento de
/// la sombra maciza.
///
/// La sombra NO lleva desenfoque a propósito. Es un bloque de tinta
/// desplazado, como en la serigrafía de la chapa del logo. Un `BoxShadow` con
/// `blurRadius` rompería el lenguaje.
class AppShape {
  const AppShape._();

  static const double borde = 2.5;
  static const double bordeFino = 2.0;

  static const double radioS = 10;
  static const double radioM = 16;
  static const double radioL = 22;
  static const double radioXL = 32;
  static const double radioPildora = 999;

  static const Offset sombraChica = Offset(3, 3);
  static const Offset sombraNormal = Offset(4, 4);
  static const Offset sombraGrande = Offset(6, 6);

  static BorderRadius radio(double r) => BorderRadius.circular(r);

  static Border get contorno =>
      Border.all(color: AppColors.tinta, width: borde);

  /// Sombra maciza. [desplazada] es cuánto se mueve el bloque de tinta.
  static List<BoxShadow> sombra([Offset desplazada = sombraNormal]) {
    return <BoxShadow>[
      BoxShadow(color: AppColors.tinta, offset: desplazada, blurRadius: 0),
    ];
  }

  /// Sin sombra: es lo que se aplica mientras el dedo está encima, para que
  /// el elemento parezca hundirse contra el papel.
  static const List<BoxShadow> sinSombra = <BoxShadow>[];
}
