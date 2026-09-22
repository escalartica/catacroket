import 'package:flutter/material.dart';

/// Tiempos y curvas.
///
/// La app responde al dedo ABAJO, no al soltar: 90 ms es lo que tarda un
/// elemento en hundirse, y es deliberadamente corto. Cualquier cosa por
/// encima de 120 ms en una pulsación ya se percibe como retraso.
class AppMotion {
  const AppMotion._();

  static const Duration pulsacion = Duration(milliseconds: 90);
  static const Duration rapida = Duration(milliseconds: 180);
  static const Duration normal = Duration(milliseconds: 280);
  static const Duration lenta = Duration(milliseconds: 460);
  static const Duration celebracion = Duration(milliseconds: 900);

  static const Curve suave = Curves.easeOutCubic;
  static const Curve rebote = Curves.easeOutBack;
  static const Curve entrada = Cubic(0.2, 0.8, 0.3, 1.0);
}
