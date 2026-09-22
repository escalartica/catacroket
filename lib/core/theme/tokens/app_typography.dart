import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Tipografía de Catacroket.
///
/// Dos familias, ambas empaquetadas en `fonts/`: nada se descarga en tiempo
/// de ejecución, así que la app se ve igual con o sin cobertura.
///
/// - **Fredoka** para titulares. Es redonda y gordita; funciona en tamaños
///   grandes y pierde carácter por debajo de 16, así que ahí no se usa.
/// - **Nunito** para todo lo demás. A partir de w700, porque sobre fondos de
///   color saturado los pesos finos se disuelven.
class AppTypography {
  const AppTypography._();

  static const String display = 'Fredoka';
  static const String texto = 'Nunito';

  // ── Titulares (Fredoka) ────────────────────────────────────────────────
  static const TextStyle tituloXL = TextStyle(
    fontFamily: display,
    fontSize: 34,
    fontWeight: FontWeight.w600,
    height: 1.05,
    letterSpacing: -0.4,
    color: AppColors.tinta,
  );

  static const TextStyle tituloL = TextStyle(
    fontFamily: display,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.08,
    letterSpacing: -0.3,
    color: AppColors.tinta,
  );

  static const TextStyle tituloM = TextStyle(
    fontFamily: display,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.15,
    letterSpacing: -0.2,
    color: AppColors.tinta,
  );

  static const TextStyle tituloS = TextStyle(
    fontFamily: display,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AppColors.tinta,
  );

  /// Números grandes (la nota, las estadísticas). Tabular para que no bailen
  /// al animarse de 0,0 a 9,4.
  static const TextStyle cifra = TextStyle(
    fontFamily: display,
    fontSize: 44,
    fontWeight: FontWeight.w600,
    height: 1.0,
    letterSpacing: -1,
    color: AppColors.tinta,
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
  );

  static const TextStyle cifraM = TextStyle(
    fontFamily: display,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.0,
    color: AppColors.tinta,
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
  );

  static const TextStyle cifraS = TextStyle(
    fontFamily: display,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.0,
    color: AppColors.tinta,
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
  );

  // ── Texto (Nunito) ─────────────────────────────────────────────────────
  static const TextStyle cuerpo = TextStyle(
    fontFamily: texto,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 1.5,
    color: AppColors.tinta,
  );

  static const TextStyle cuerpoS = TextStyle(
    fontFamily: texto,
    fontSize: 13.5,
    fontWeight: FontWeight.w700,
    height: 1.45,
    color: AppColors.tinta,
  );

  static const TextStyle etiqueta = TextStyle(
    fontFamily: texto,
    fontSize: 12,
    fontWeight: FontWeight.w800,
    height: 1.2,
    color: AppColors.tinta,
  );

  /// Antetítulos en versales. El `letterSpacing` alto es obligatorio: sin él
  /// las mayúsculas de Nunito se apelmazan.
  static const TextStyle antetitulo = TextStyle(
    fontFamily: texto,
    fontSize: 11.5,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: 1.6,
    color: AppColors.tinta,
  );

  static const TextStyle boton = TextStyle(
    fontFamily: display,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.1,
    color: AppColors.tinta,
  );

  /// Escala de Material, para todo lo que pinte el framework por su cuenta
  /// (diálogos, snackbars, errores de formulario). Sin esto salen en Roboto.
  static const TextTheme textTheme = TextTheme(
    displayLarge: tituloXL,
    displayMedium: tituloL,
    headlineLarge: tituloL,
    headlineMedium: tituloM,
    headlineSmall: tituloS,
    titleLarge: tituloM,
    titleMedium: tituloS,
    titleSmall: etiqueta,
    bodyLarge: cuerpo,
    bodyMedium: cuerpo,
    bodySmall: cuerpoS,
    labelLarge: boton,
    labelMedium: etiqueta,
    labelSmall: antetitulo,
  );
}
