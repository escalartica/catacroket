/// Formateo de textos. Todo en español: coma decimal y "hace N días".
class Formato {
  const Formato._();

  /// Nota con un decimal y coma: 9,4.
  static String nota(double valor) => valor.toStringAsFixed(1).replaceAll('.', ',');

  /// Precio en euros con dos decimales: 2,20 €.
  static String precio(double valor) =>
      '${valor.toStringAsFixed(2).replaceAll('.', ',')} €';

  /// Fecha en lenguaje natural. Se corta en meses a propósito: una cata de
  /// hace más de un año no necesita precisión, necesita ser vieja.
  static String relativo(DateTime fecha) {
    final Duration diferencia = DateTime.now().difference(fecha);

    if (diferencia.inMinutes < 2) return 'ahora mismo';
    if (diferencia.inMinutes < 60) return 'hace ${diferencia.inMinutes} min';
    if (diferencia.inHours < 24) {
      final int h = diferencia.inHours;
      return h == 1 ? 'hace 1 hora' : 'hace $h horas';
    }

    final int dias = diferencia.inDays;
    if (dias == 1) return 'ayer';
    if (dias < 7) return 'hace $dias días';
    if (dias < 14) return 'hace 1 semana';
    if (dias < 30) return 'hace ${dias ~/ 7} semanas';
    if (dias < 60) return 'hace 1 mes';
    if (dias < 365) return 'hace ${dias ~/ 30} meses';
    return 'hace más de un año';
  }

  /// Plural sencillo: 1 cata / 3 catas.
  static String plural(int cantidad, String singular, String plural) =>
      cantidad == 1 ? '$cantidad $singular' : '$cantidad $plural';
}
