import 'alergeno.dart';

/// De qué está hecha la bechamel.
enum Bechamel {
  leche('De leche', '🥛', 'La clásica: leche de vaca y mantequilla.'),
  sinLactosa('Sin lactosa', '🥛', 'Leche sin lactosa o mantequilla sin lactosa.'),
  vegetal('Vegetal', '🌱', 'Bebida de avena, soja, almendra o arroz, y aceite.'),
  sinSaber('No lo sé', '🤷', 'No lo preguntaste, y no pasa nada.');

  const Bechamel(this.nombre, this.emoji, this.detalle);

  final String nombre;
  final String emoji;
  final String detalle;
}

/// Con qué se hace una bechamel vegetal.
///
/// No es un capricho de gourmet: la de avena es la más cremosa, pero la de
/// soja y la de almendra son dos alérgenos de la lista oficial. Sin esta
/// pregunta, "bechamel vegetal" deja en el aire si esa croqueta lleva frutos
/// de cáscara, y ahí es donde la app tendría que callarse en vez de decir
/// "sin frutos secos".
enum BebidaVegetal {
  avena('Avena', '🌾'),
  soja('Soja', '🫘'),
  almendra('Almendra', '🌰'),
  arroz('Arroz', '🍚'),
  coco('Coco', '🥥'),
  sinSaber('No lo sé', '🤷');

  const BebidaVegetal(this.nombre, this.emoji);

  final String nombre;
  final String emoji;
}

/// Si el bar fríe las croquetas en el mismo aceite que todo lo demás.
///
/// Tiene pregunta propia y no va metido dentro de "sin gluten" porque son dos
/// cosas distintas y sólo una la decide la receta. Una croqueta puede estar
/// hecha con harina de arroz y seguir siendo peligrosa para un celíaco si
/// comparte aceite con las croquetas de trigo del resto de la carta.
enum Freidora {
  aparte('Freidora aparte', '✅'),
  compartida('Freidora compartida', '⚠️'),
  sinSaber('No lo sé', '🤷');

  const Freidora(this.nombre, this.emoji);

  final String nombre;
  final String emoji;
}

/// Cómo estaba hecha esta croqueta.
///
/// Es la pieza que faltaba, y es la importante: lo que hace apta a una
/// croqueta no es el relleno, es la base. Una croqueta de boletus es vegana
/// hasta que le echan leche de vaca y la rebozan pasándola por huevo, que es
/// lo que pasa en el 95 % de los bares.
///
/// Antes la app dejaba marcar "vegana" en una de jamón y se quedaba tan
/// ancha: guardaba etiquetas, no hechos. Ahora se preguntan tres cosas
/// concretas —de qué es la bechamel, cómo es el rebozado y si la freidora es
/// aparte— y las dietas salen solas. Preguntar por lo concreto tiene dos
/// ventajas: son cosas que el camarero sabe responder, y no obliga a nadie a
/// saberse de memoria qué implica cada etiqueta.
class Receta {
  const Receta({
    this.bechamel = Bechamel.sinSaber,
    this.bebida = BebidaVegetal.sinSaber,
    this.rebozadoConGluten = true,
    this.rebozadoConHuevo = true,
    this.freidora = Freidora.sinSaber,
    this.extra = const <Alergeno>{},
  });

  final Bechamel bechamel;

  /// Sólo tiene sentido con [Bechamel.vegetal].
  final BebidaVegetal bebida;

  /// Pan rallado de trigo (lo normal) o rebozado sin gluten.
  final bool rebozadoConGluten;

  /// Pasada por huevo antes del pan rallado (lo normal) o no.
  final bool rebozadoConHuevo;

  final Freidora freidora;

  /// Alérgenos que el usuario añade a mano porque los sabe y la receta no los
  /// puede deducir: el vino del sofrito, la mostaza de la salsa, el sésamo
  /// del pan rallado.
  final Set<Alergeno> extra;

  bool get esVegetal => bechamel == Bechamel.vegetal;

  /// Los alérgenos que aporta la base, sin contar el relleno.
  Set<Alergeno> get alergenos => <Alergeno>{
        // "Sin lactosa" sigue siendo leche: el alérgeno es la proteína, no el
        // azúcar. Un alérgico a la proteína de la leche no puede comerla; un
        // intolerante a la lactosa, sí. Confundirlo es el error clásico.
        if (bechamel == Bechamel.leche || bechamel == Bechamel.sinLactosa)
          Alergeno.leche,
        if (esVegetal && bebida == BebidaVegetal.soja) Alergeno.soja,
        if (esVegetal && bebida == BebidaVegetal.almendra) Alergeno.frutosCascara,
        if (rebozadoConGluten) Alergeno.gluten,
        if (rebozadoConHuevo) Alergeno.huevo,
        ...extra,
      };

  /// Alérgenos que no se pueden descartar.
  ///
  /// No es lo mismo "no lo lleva" que "no lo sé", y meter los dos en el mismo
  /// saco es exactamente el error que manda a alguien al hospital. Una
  /// bechamel vegetal de bebida sin identificar puede ser de almendra o de
  /// soja, y mientras no se sepa, la app no dice ni que sí ni que no.
  Set<Alergeno> get dudosos => <Alergeno>{
        // Una bechamel sin identificar puede esconder los cuatro: la leche,
        // el gluten de su harina —que la bechamel también lleva harina, no
        // sólo el rebozado— y la soja o la almendra si resulta que era
        // vegetal. Antes sólo dudaba de la leche y del gluten, y entonces una
        // cata en la que sólo se había contestado "freidora compartida"
        // acababa presumiendo de "sin frutos secos" sin que nadie hubiera
        // preguntado nada. Justo lo que este cambio venía a quitar.
        if (bechamel == Bechamel.sinSaber) ...<Alergeno>{
          Alergeno.leche,
          Alergeno.gluten,
          Alergeno.frutosCascara,
          Alergeno.soja,
        },
        if (esVegetal && bebida == BebidaVegetal.sinSaber) ...<Alergeno>{
          Alergeno.soja,
          Alergeno.frutosCascara,
        },
      };

  /// ¿Se apuntó algo, o está todo por defecto?
  bool get sinRellenar =>
      bechamel == Bechamel.sinSaber &&
      freidora == Freidora.sinSaber &&
      rebozadoConGluten &&
      rebozadoConHuevo &&
      extra.isEmpty;

  Receta copyWith({
    Bechamel? bechamel,
    BebidaVegetal? bebida,
    bool? rebozadoConGluten,
    bool? rebozadoConHuevo,
    Freidora? freidora,
    Set<Alergeno>? extra,
  }) {
    return Receta(
      bechamel: bechamel ?? this.bechamel,
      bebida: bebida ?? this.bebida,
      rebozadoConGluten: rebozadoConGluten ?? this.rebozadoConGluten,
      rebozadoConHuevo: rebozadoConHuevo ?? this.rebozadoConHuevo,
      freidora: freidora ?? this.freidora,
      extra: extra ?? this.extra,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'bechamel': bechamel.name,
        'bebida': bebida.name,
        'rebozadoConGluten': rebozadoConGluten,
        'rebozadoConHuevo': rebozadoConHuevo,
        'freidora': freidora.name,
        'extra': extra.map((Alergeno a) => a.id).toList(),
      };

  factory Receta.fromJson(Map<String, dynamic> json) => Receta(
        bechamel: Bechamel.values.firstWhere(
          (Bechamel b) => b.name == json['bechamel'],
          orElse: () => Bechamel.sinSaber,
        ),
        bebida: BebidaVegetal.values.firstWhere(
          (BebidaVegetal b) => b.name == json['bebida'],
          orElse: () => BebidaVegetal.sinSaber,
        ),
        rebozadoConGluten: json['rebozadoConGluten'] as bool? ?? true,
        rebozadoConHuevo: json['rebozadoConHuevo'] as bool? ?? true,
        freidora: Freidora.values.firstWhere(
          (Freidora f) => f.name == json['freidora'],
          orElse: () => Freidora.sinSaber,
        ),
        extra: Alergeno.desdeJson(json['extra']),
      );
}
