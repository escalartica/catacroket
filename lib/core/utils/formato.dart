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
  ///
  /// [ahora] se puede pasar para poder probarlo: si no, cada test daría un
  /// resultado distinto según el día en que se ejecute.
  static String relativo(DateTime fecha, {DateTime? ahora}) {
    final DateTime hoy = ahora ?? DateTime.now();
    final Duration diferencia = hoy.difference(fecha);

    if (diferencia.inMinutes < 2) return 'ahora mismo';
    if (diferencia.inMinutes < 60) return 'hace ${diferencia.inMinutes} min';
    if (diferencia.inHours < 24) {
      final int h = diferencia.inHours;
      return h == 1 ? 'hace 1 hora' : 'hace $h horas';
    }

    // Por debajo de un día se cuentan horas transcurridas, que es lo que
    // significa «hace tres horas». De un día en adelante se cuentan días de
    // CALENDARIO, que es lo que significa «ayer».
    //
    // No es lo mismo y antes se usaba lo primero para las dos cosas: una cata
    // del lunes a las once de la noche, vista el miércoles a las doce y media,
    // son veinticinco horas, o sea «ayer» — y fue anteayer.
    final int dias = _diasDeCalendario(fecha, hoy);
    if (dias == 1) return 'ayer';
    if (dias < 7) return 'hace $dias días';
    if (dias < 14) return 'hace 1 semana';
    if (dias < 30) return 'hace ${dias ~/ 7} semanas';
    if (dias < 60) return 'hace 1 mes';
    if (dias < 365) return 'hace ${dias ~/ 30} meses';
    return 'hace más de un año';
  }

  /// Días de calendario entre dos fechas, sin que los cambios de hora cuenten.
  ///
  /// Se pasa por UTC a propósito. Restar dos medianoches locales que tengan un
  /// cambio de hora en medio da 6 días y 23 horas, y `inDays` lo trunca a 6:
  /// una cata de hace justo una semana diría «hace 6 días». En UTC no hay
  /// cambios de hora y la cuenta es exacta.
  ///
  /// Nunca devuelve menos de 1, porque aquí sólo se llega con más de
  /// veinticuatro horas encima: al volver atrás la hora, veinticuatro horas
  /// pueden caer dentro del mismo día de calendario, y «hace 0 días» no lo
  /// dice nadie.
  static int _diasDeCalendario(DateTime desde, DateTime hasta) {
    final int dias = DateTime.utc(hasta.year, hasta.month, hasta.day)
        .difference(DateTime.utc(desde.year, desde.month, desde.day))
        .inDays;
    return dias < 1 ? 1 : dias;
  }

  /// Plural sencillo: 1 cata / 3 catas.
  static String plural(int cantidad, String singular, String plural) =>
      cantidad == 1 ? '$cantidad $singular' : '$cantidad $plural';
}
