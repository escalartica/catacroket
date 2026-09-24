/// Escala de espaciado. Múltiplos de 4 para que todo caiga en la misma
/// rejilla, con [pantalla] como margen lateral único de la app.
class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Margen horizontal de todas las pantallas.
  static const double pantalla = 20;

  /// Hueco que deja la barra de pestañas al final de cada lista.
  ///
  /// La barra mide ~69 dp fijos (relleno + iconos + etiquetas) más el inset
  /// del sistema (home indicator en iPhone ≈ 34 dp; barra de 3 botones en
  /// Android ≈ 48 dp; navegación por gestos ≈ 0 dp). 120 dp cubre el peor
  /// caso conocido con un par de dp de margen.
  static const double huecoBarra = 120;
}
