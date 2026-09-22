/// Los rangos del Croquetómetro. Se suben catando, no puntuando alto: la app
/// premia la constancia, no la generosidad.
class Rango {
  const Rango({required this.desde, required this.nombre});

  final int desde;
  final String nombre;
}

class Rangos {
  const Rangos._();

  static const List<Rango> todos = <Rango>[
    Rango(desde: 0, nombre: 'Aprendiz de panko'),
    Rango(desde: 5, nombre: 'Rebozador'),
    Rango(desde: 15, nombre: 'Bechamelero'),
    Rango(desde: 30, nombre: 'Maestro croquetero'),
    Rango(desde: 60, nombre: 'Leyenda dorada'),
  ];

  static Rango actual(int catas) =>
      todos.lastWhere((Rango r) => catas >= r.desde, orElse: () => todos.first);

  /// El siguiente rango, o nulo si ya está en el techo.
  static Rango? siguiente(int catas) {
    for (final Rango r in todos) {
      if (catas < r.desde) return r;
    }
    return null;
  }

  /// Progreso de 0 a 1 dentro del rango actual.
  static double progreso(int catas) {
    final Rango ahora = actual(catas);
    final Rango? proximo = siguiente(catas);
    if (proximo == null) return 1;
    final int tramo = proximo.desde - ahora.desde;
    if (tramo <= 0) return 1;
    return ((catas - ahora.desde) / tramo).clamp(0.0, 1.0);
  }
}

/// Medallas. `conseguida` se calcula en el proveedor del perfil a partir de
/// las catas reales; aquí sólo vive el catálogo.
class Medalla {
  const Medalla({
    required this.id,
    required this.emoji,
    required this.nombre,
  });

  final String id;
  final String emoji;
  final String nombre;
}

class Medallas {
  const Medallas._();

  static const List<Medalla> todas = <Medalla>[
    Medalla(id: 'primera', emoji: '🥇', nombre: 'Primera cata'),
    Medalla(id: 'ciudades', emoji: '🗺️', nombre: '10 ciudades'),
    Medalla(id: 'tinta', emoji: '🖤', nombre: 'Tinta negra'),
    Medalla(id: 'racha', emoji: '🔥', nombre: 'Racha de 4'),
    Medalla(id: 'paladar', emoji: '👅', nombre: 'Paladar fino'),
    Medalla(id: 'doble', emoji: '🍽️', nombre: 'Doble ración'),
    Medalla(id: 'pasaporte', emoji: '🛫', nombre: 'Pasaporte'),
    Medalla(id: 'mundial', emoji: '🌍', nombre: '5 países'),
    Medalla(id: 'diez', emoji: '💯', nombre: 'Un 10 redondo'),
  ];
}
