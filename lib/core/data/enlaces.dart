/// Enlaces de la app hacia fuera.
///
/// Viven aquí y no repartidos por las pantallas para que el día que
/// Catacroket esté publicada haya que tocar un sitio y no seis.
class Enlaces {
  const Enlaces._();

  /// La ficha de la App Store. Vacío mientras la app no esté publicada.
  ///
  /// En cuanto esté, se pega aquí y todos los textos de invitación lo llevan
  /// solos. Mientras tanto, las invitaciones dicen el nombre y ya: mandar a
  /// alguien un enlace que no lleva a ninguna parte es peor que no mandarlo.
  static const String tienda = '';

  static bool get hayTienda => tienda.isNotEmpty;

  /// La coletilla de "dónde se consigue esto", según haya enlace o no.
  static String get dondeEsta =>
      hayTienda ? tienda : 'Se llama Catacroket, búscala en la App Store.';
}
