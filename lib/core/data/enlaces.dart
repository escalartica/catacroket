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

  // ── Lo público ──────────────────────────────────────────────────────────

  /// Dónde escribe quien tiene un problema, quiere denunciar algo o pide que
  /// le borren los datos. Es un buzón que lee una persona.
  static const String correoSoporte = 'escalartica@gmail.com';

  /// La política de privacidad, colgada en el hosting del propio proyecto de
  /// Firebase. App Store Connect no deja enviar la ficha sin una dirección
  /// que conteste, y la revisión la abre.
  static const String privacidad =
      'https://catacroket-2b047.web.app/privacidad.html';

  /// La página de soporte, que Apple pide como campo aparte.
  static const String soporte =
      'https://catacroket-2b047.web.app/soporte.html';

  // ── La otra app ─────────────────────────────────────────────────────────

  /// Palito de Sabores, de los mismos, en la App Store.
  ///
  /// Catacroket es sólo de croquetas a propósito: es lo que la hace
  /// reconocible. Quien además quiera llevar la cuenta de ensaladillas,
  /// tortillas y postres tiene la otra, y es mejor decírselo que ensanchar
  /// ésta hasta que no sea de nada.
  static const String palito =
      'https://apps.apple.com/es/app/palito-de-sabores/id6806819468';

  static bool get hayPalito => palito.isNotEmpty;

  /// El logo de la otra app. Va en assets/palito/, no en assets/brand/,
  /// porque no es nuestra marca.
  static const String logoPalito = 'assets/palito/palito-de-sabores.webp';
}
