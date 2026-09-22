/// Las cuentas de la racha, aparte y sin depender del reloj.
///
/// Viven aqui y no dentro del provider por una razon practica: "que dia es
/// hoy" cambia el resultado, asi que un test que usara la hora del sistema
/// pasaria o fallaria segun el dia de la semana en que se ejecutara. Pasando
/// [hoy] se puede comprobar de verdad que un lunes por la manana la racha
/// sigue en pie.
abstract final class Semanas {
  /// El lunes de la semana en la que cae [dia], a las cero horas.
  static DateTime lunesDe(DateTime dia) =>
      DateTime(dia.year, dia.month, dia.day)
          .subtract(Duration(days: dia.weekday - 1));

  /// Si alguna de [fechas] cae en la semana que empieza en [inicio].
  static bool hayEn(Iterable<DateTime> fechas, DateTime inicio) {
    final DateTime fin = inicio.add(const Duration(days: 7));
    return fechas.any((DateTime f) => !f.isBefore(inicio) && f.isBefore(fin));
  }

  /// Semanas seguidas con al menos una cata.
  ///
  /// Si la semana en curso todavia no tiene ninguna, se cuenta desde la
  /// anterior: una racha no se pierde el lunes por la manana, se pierde
  /// cuando acaba una semana entera sin catar. Contandola desde esta, un
  /// lunes cualquiera borraba seis semanas de golpe y el fuego aparecia
  /// apagado sin que nadie hubiera hecho nada mal.
  static int racha(Iterable<DateTime> fechas, {DateTime? hoy}) {
    final DateTime lunes = lunesDe(hoy ?? DateTime.now());
    final int desde = hayEn(fechas, lunes) ? 0 : 1;

    int cuenta = 0;
    for (int semana = desde; semana < 104 + desde; semana++) {
      if (!hayEn(fechas, lunes.subtract(Duration(days: 7 * semana)))) break;
      cuenta++;
    }
    return cuenta;
  }

  /// Las ultimas [cuantas] semanas, de la mas antigua a la de hoy.
  ///
  /// Esto no es la racha recortada: es el historial con sus huecos. Pintar la
  /// racha en siete casillas mentia en cuanto pasabas de siete semanas, que
  /// es justo cuando la racha empieza a importarte.
  static List<bool> ultimas(
    Iterable<DateTime> fechas, {
    DateTime? hoy,
    int cuantas = 7,
  }) {
    final DateTime lunes = lunesDe(hoy ?? DateTime.now());
    return <bool>[
      for (int atras = cuantas - 1; atras >= 0; atras--)
        hayEn(fechas, lunes.subtract(Duration(days: 7 * atras))),
    ];
  }
}
