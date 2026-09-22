import 'dart:math' as math;

/// Generador determinista a partir de un texto.
///
/// Se usa para dibujar El Corte: las migas de panko y los trozos de relleno
/// tienen que caer SIEMPRE en el mismo sitio para una misma cata. Si se usara
/// `Random()` sin semilla, la misma croqueta se redibujaría distinta en cada
/// `build` y la ilustración dejaría de ser el retrato de esa cata.
math.Random semillaDe(String texto) {
  int valor = 2166136261;
  for (final int unidad in texto.codeUnits) {
    valor = (valor ^ unidad) * 16777619;
    valor &= 0x7FFFFFFF;
  }
  return math.Random(valor);
}
