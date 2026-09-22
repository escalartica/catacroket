import 'package:flutter/material.dart';

import 'tokens/app_colors.dart';
import 'tokens/app_shape.dart';
import 'tokens/app_typography.dart';

/// Tema de Catacroket.
///
/// Las pantallas pintan casi todo a mano (es lo que pide el estilo pegatina),
/// pero lo que Material genera por su cuenta —diálogos, snackbars, el cursor
/// de los campos, los indicadores de carga— también tiene que estar en la
/// marca. Por eso los roles `on*` se declaran uno a uno: si se dejan a
/// Material, `onPrimary` se resuelve a blanco sobre el amarillo de marca
/// (1,5:1) y cualquier control estándar sale ilegible. Los valores de aquí
/// están medidos: ninguna pareja baja de 4,5:1.
class AppTheme {
  const AppTheme._();

  static ThemeData get tema {
    final ColorScheme esquema = ColorScheme.fromSeed(
      seedColor: AppColors.tomate,
      primary: AppColors.tomate,
      // Tinta y no blanco: el blanco sobre el tomate de marca se queda en
      // 3,05:1 y la norma pide 4,5:1 para texto. La tinta da 5,02:1.
      onPrimary: AppColors.tinta,
      secondary: AppColors.sol,
      onSecondary: AppColors.tinta,
      surface: AppColors.superficie,
      onSurface: AppColors.tinta,
      error: AppColors.tomate,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      scaffoldBackgroundColor: AppColors.fondo,
      fontFamily: AppTypography.texto,
      textTheme: AppTypography.textTheme,

      // Sin ondas de Material: en una interfaz de bloques planos con contorno,
      // el `splash` circular se ve como un error de render. El feedback de
      // pulsación lo da el hundimiento de la pegatina (ver Pegatina).
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.tinta,
      ),

      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.tinta,
        selectionColor: Color(0x55FFC93C),
        selectionHandleColor: AppColors.tinta,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.superficie,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(
            color: AppColors.tinta,
            width: AppShape.borde,
          ),
          borderRadius: BorderRadius.circular(AppShape.radioL),
        ),
        titleTextStyle: AppTypography.tituloS,
        contentTextStyle: AppTypography.cuerpo,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.tinta,
        contentTextStyle: AppTypography.cuerpoS.copyWith(
          color: AppColors.crema,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppShape.radioM),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.tinta),
      ),
    );
  }
}
