import 'package:flutter/material.dart';

/// Paleta de Catacroket.
///
/// La marca es una pegatina: colores planos y saturados, contorno de tinta y
/// sombra dura. Por eso aquí no hay grises intermedios ni elevaciones de
/// Material: todo lo que separa una superficie de otra es el borde y la
/// sombra, nunca un degradado.
///
/// Regla de oro: los contornos SIEMPRE son [tinta]. Para el texto hay dos
/// reglas y sólo dos:
///
/// 1. Sobre un fondo de color, el texto lo decide [textoSobre]. A ojo se
///    falla: [uva] parece clara y no lo es.
/// 2. Sobre crema o blanco, el texto principal es [tinta] y el secundario
///    [tintaSuave]. Nunca `tinta.withValues(alpha: …)`: una tinta al 55 %
///    sobre el fondo crema se queda en 3,6:1 y la norma pide 4,5:1.
///
/// Las alfas siguen valiendo para lo que NO es texto (sombras, tramas,
/// tiradores), donde el mínimo es 3:1 o ninguno.
class AppColors {
  const AppColors._();

  // ── Colores de la fiesta ────────────────────────────────────────────────
  static const Color sol = Color(0xFFFFC93C);
  static const Color mango = Color(0xFFFF9E1B);
  static const Color tomate = Color(0xFFFF5A5F);
  static const Color chicle = Color(0xFFFF3D8B);
  // Una uva más oscura que la de la primera paleta (era #8B5CF6). Aquella
  // se quedaba en tierra de nadie: 4,2:1 con texto blanco y 3,6:1 con tinta,
  // o sea que ningún texto llegaba a 4,5:1 encima. Ésta da 5,7:1 en crema.
  static const Color uva = Color(0xFF7C3AED);
  static const Color menta = Color(0xFF12C2A0);
  static const Color cielo = Color(0xFF3AA8FF);
  static const Color lima = Color(0xFF7DD640);
  static const Color agua = Color(0xFF7FD4FF);

  // ── Estructura ──────────────────────────────────────────────────────────
  /// Contornos, sombras y texto. Morado muy oscuro en vez de negro puro:
  /// el negro absoluto sobre estos amarillos resulta duro en pantalla.
  static const Color tinta = Color(0xFF2C1B4D);

  static const Color fondo = Color(0xFFFFF3DC);
  static const Color fondoPuntos = Color(0xFFF3DFB6);
  static const Color superficie = Color(0xFFFFFFFF);
  static const Color superficieCalida = Color(0xFFFFF0CF);
  static const Color superficieHonda = Color(0xFFFFE1A3);
  static const Color crema = Color(0xFFFFF7E6);

  // ── Rebozado ────────────────────────────────────────────────────────────
  static const Color rebozadoClaro = Color(0xFFFFE9A6);
  static const Color rebozadoMedio = Color(0xFFFFB02E);
  static const Color rebozadoOscuro = Color(0xFFE8760D);
  static const Color miga = Color(0xFFFFF0C4);

  /// Degradado del rebozado, tal cual aparece en el logo.
  static const LinearGradient rebozado = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[rebozadoClaro, rebozadoMedio, rebozadoOscuro],
    stops: <double>[0.0, 0.48, 1.0],
  );

  // ── Mapa ────────────────────────────────────────────────────────────────
  static const Color mapaVelo = Color(0x33FFC93C);

  // ── Texto ───────────────────────────────────────────────────────────────

  /// Texto secundario sobre crema o blanco.
  ///
  /// Es [tinta] al 68 % ya mezclada con el fondo, en color fijo y no en alfa:
  /// una alfa cambia de contraste según lo que tenga debajo, y este mismo
  /// texto aparece sobre crema, sobre blanco y sobre la superficie cálida.
  /// Así mide 5,2:1 en el peor de los tres.
  static const Color tintaSuave = Color(0xFF70607B);

  /// Texto de un control apagado.
  ///
  /// La norma exime a los controles deshabilitados del contraste, pero
  /// "exento" no es lo mismo que "ilegible": al 38 % se quedaba en 2,2:1 y no
  /// se leía. Esto da 3,5:1, que se lee y sigue pareciendo apagado.
  static const Color tintaApagada = Color(0xFF8B7B88);

  /// El color de texto que se lee sobre [fondo]: [tinta] si el fondo es
  /// claro, [crema] si es oscuro.
  ///
  /// Se decide por contraste medido y no por intuición, que es justo donde se
  /// falla: sobre [chicle] gana la tinta y sobre [uva] gana la crema, y las
  /// dos parecen igual de "de color".
  static Color textoSobre(Color fondo) =>
      _contraste(tinta, fondo) >= _contraste(crema, fondo) ? tinta : crema;

  static double _contraste(Color a, Color b) {
    final double la = a.computeLuminance();
    final double lb = b.computeLuminance();
    final double alto = la > lb ? la : lb;
    final double bajo = la > lb ? lb : la;
    return (alto + 0.05) / (bajo + 0.05);
  }
}
