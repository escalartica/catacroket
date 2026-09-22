/// Los catorce alérgenos de declaración obligatoria.
///
/// Son los del Anexo II del Reglamento (UE) 1169/2011, el mismo que obliga a
/// cualquier bar de España a poder decirte qué lleva un plato. Se usa la
/// lista oficial entera y no una versión recortada "de croquetas" por dos
/// razones: es la que el camarero tiene detrás de la barra, así que preguntar
/// y apuntar hablan el mismo idioma; y una lista inventada siempre se deja
/// fuera el alérgeno de alguien.
///
/// [enCroquetas] dice por dónde se cuela cada uno en una croqueta. No es
/// adorno: la mitad de los sustos vienen de no saber que la bechamel lleva
/// harina o que el rebozado pasa por huevo.
enum Alergeno {
  gluten(
    id: 'gluten',
    nombre: 'Gluten',
    emoji: '🌾',
    detalle: 'Trigo, centeno, cebada, avena, espelta y kamut',
    enCroquetas: 'En la harina de la bechamel y en el pan rallado. También en '
        'el seitán, que es gluten puro.',
  ),
  crustaceos(
    id: 'crustaceos',
    nombre: 'Crustáceos',
    emoji: '🦐',
    detalle: 'Gambas, langostinos, cigalas, cangrejo…',
    enCroquetas: 'Las de gamba y las de marisco.',
  ),
  huevo(
    id: 'huevo',
    nombre: 'Huevo',
    emoji: '🥚',
    detalle: 'Huevo y derivados',
    enCroquetas: 'Casi siempre en el rebozado, aunque el relleno no lleve.',
  ),
  pescado(
    id: 'pescado',
    nombre: 'Pescado',
    emoji: '🐟',
    detalle: 'Pescado y derivados',
    enCroquetas: 'Bacalao, atún, merluza. Ojo también con el caldo.',
  ),
  cacahuetes(
    id: 'cacahuetes',
    nombre: 'Cacahuetes',
    emoji: '🥜',
    detalle: 'Cacahuetes y productos a base de cacahuetes',
    enCroquetas: 'Raro en la receta, habitual en el aceite de fritura de '
        'algunas cocinas.',
  ),
  soja(
    id: 'soja',
    nombre: 'Soja',
    emoji: '🫘',
    detalle: 'Soja y productos a base de soja',
    enCroquetas: 'En la bebida de soja de una bechamel vegetal, y en el tofu.',
  ),
  leche(
    id: 'leche',
    nombre: 'Leche',
    emoji: '🥛',
    detalle: 'Leche y derivados, incluida la lactosa',
    enCroquetas: 'La bechamel clásica y la mantequilla. Es el alérgeno más '
        'difícil de esquivar en una croqueta.',
  ),
  frutosCascara(
    id: 'frutos_cascara',
    nombre: 'Frutos de cáscara',
    emoji: '🌰',
    detalle: 'Almendras, avellanas, nueces, anacardos, pistachos, pacanas…',
    enCroquetas: 'Piñones en las de espinacas, y la bebida de almendra en una '
        'bechamel vegetal.',
  ),
  apio(
    id: 'apio',
    nombre: 'Apio',
    emoji: '🥬',
    detalle: 'Apio y productos derivados',
    enCroquetas: 'En el sofrito y en casi cualquier caldo de puchero.',
  ),
  mostaza(
    id: 'mostaza',
    nombre: 'Mostaza',
    emoji: '🌭',
    detalle: 'Mostaza y productos derivados',
    enCroquetas: 'Más en la salsa que las acompaña que dentro.',
  ),
  sesamo(
    id: 'sesamo',
    nombre: 'Sésamo',
    emoji: '🫓',
    detalle: 'Granos de sésamo y productos a base de sésamo',
    enCroquetas: 'En el pan rallado de algunos rebozados y en el tahini.',
  ),
  sulfitos(
    id: 'sulfitos',
    nombre: 'Sulfitos',
    emoji: '🍷',
    detalle: 'Dióxido de azufre y sulfitos por encima de 10 mg/kg',
    enCroquetas: 'En el vino del sofrito y en algunas patatas prefritas.',
  ),
  altramuces(
    id: 'altramuces',
    nombre: 'Altramuces',
    emoji: '🫛',
    detalle: 'Altramuces y productos a base de altramuces',
    enCroquetas: 'En harinas sin gluten y en algunos preparados veganos.',
  ),
  moluscos(
    id: 'moluscos',
    nombre: 'Moluscos',
    emoji: '🦑',
    detalle: 'Almejas, mejillones, calamares, chipirones, pulpo…',
    enCroquetas: 'Chipirón en su tinta, pulpo, sepia.',
  );

  const Alergeno({
    required this.id,
    required this.nombre,
    required this.emoji,
    required this.detalle,
    required this.enCroquetas,
  });

  final String id;
  final String nombre;
  final String emoji;
  final String detalle;
  final String enCroquetas;

  static Alergeno? porId(String id) {
    for (final Alergeno a in values) {
      if (a.id == id) return a;
    }
    return null;
  }

  static Set<Alergeno> desdeJson(dynamic crudo) {
    if (crudo is! List<dynamic>) return const <Alergeno>{};
    return crudo
        .map((dynamic e) => porId(e.toString()))
        .whereType<Alergeno>()
        .toSet();
  }

  /// En el orden de [values], que es el de la lista oficial.
  static List<Alergeno> ordenar(Set<Alergeno> alergenos) =>
      values.where(alergenos.contains).toList();
}
