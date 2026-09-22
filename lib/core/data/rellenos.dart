import 'package:flutter/material.dart';

import '../models/alergeno.dart';
import '../theme/tokens/app_colors.dart';

/// Qué come quien come este relleno.
///
/// Está en el catálogo y no en cada cata porque no depende del bar: una
/// croqueta de jamón lleva jamón en todas partes. Lo que sí depende del bar
/// es la bechamel, y eso se pregunta aparte.
enum PerfilRelleno {
  vegano('Vegano', '🌱'),
  vegetariano('Vegetariano', '🥬'),
  pescado('Pescado', '🐟'),
  marisco('Marisco', '🦐'),
  carne('Carne', '🍖'),

  /// "A mi manera" y cualquier cosa que el usuario no sepa clasificar. No es
  /// un hueco por pereza: sin saber qué lleva no se puede decir que valga
  /// para nadie, y decirlo sería peor que callarse.
  sinSaber('Sin saber', '🤷');

  const PerfilRelleno(this.nombre, this.emoji);

  final String nombre;
  final String emoji;

  bool get esVegano => this == vegano;
  bool get esVegetariano => this == vegano || this == vegetariano;
}

/// Un tipo de relleno.
///
/// El color es lo que hace que el feed se lea de un vistazo: cada relleno
/// tiñe el plato de la tarjeta y los trozos que se dibujan dentro de El
/// Corte.
class Relleno {
  const Relleno({
    required this.id,
    required this.nombre,
    required this.color,
    required this.emoji,
    this.perfil = PerfilRelleno.sinSaber,
    this.alergenos = const <Alergeno>{},
  });

  final String id;
  final String nombre;
  final Color color;
  final String emoji;
  final PerfilRelleno perfil;

  /// Los alérgenos que trae el RELLENO. Los del rebozado y la bechamel los
  /// pone la receta, porque ésos sí cambian de un bar a otro.
  final Set<Alergeno> alergenos;
}

/// Catálogo de rellenos.
///
/// Los colores se eligieron para distinguirse a 46 px, que es el tamaño del
/// plato en la tarjeta del feed. Con treinta y tantos rellenos eso ya no se
/// sostiene del todo: el color dejó de ser un identificador único y pasó a
/// ser una pista de familia —verdes lo vegetal, rojos la carne, azules el
/// mar—, que para leer un feed de un vistazo funciona igual de bien. El
/// nombre es el que manda.
///
/// La primera versión tenía once rellenos y nueve llevaban carne o pescado.
/// Para alguien vegano, abrir el formulario y no encontrar nada que pedir no
/// es un detalle: es la app diciéndole que no es para él. Los rellenos
/// vegetales de aquí son los que de verdad se ven en las cartas —boletus,
/// calabaza, puerro confitado, coliflor al curry, berenjena, boniato,
/// pimiento con hummus, seitán— y no una lista de relleno.
class Rellenos {
  const Rellenos._();

  static const List<Relleno> todos = <Relleno>[
    // ── Carne ────────────────────────────────────────────────────────────
    Relleno(
      id: 'jamon',
      nombre: 'Jamón ibérico',
      color: AppColors.tomate,
      emoji: '🍖',
      perfil: PerfilRelleno.carne,
    ),
    Relleno(
      id: 'puchero',
      nombre: 'Puchero de la abuela',
      color: AppColors.sol,
      emoji: '🍲',
      perfil: PerfilRelleno.carne,
      // El caldo de puchero lleva apio casi siempre, y casi nadie lo piensa.
      alergenos: <Alergeno>{Alergeno.apio},
    ),
    Relleno(
      id: 'rabo',
      nombre: 'Rabo de toro',
      color: Color(0xFFE0533A),
      emoji: '🐂',
      perfil: PerfilRelleno.carne,
      alergenos: <Alergeno>{Alergeno.sulfitos},
    ),
    Relleno(
      id: 'cecina',
      nombre: 'Cecina',
      color: Color(0xFFFF7847),
      emoji: '🥩',
      perfil: PerfilRelleno.carne,
    ),

    // ── Mar ──────────────────────────────────────────────────────────────
    Relleno(
      id: 'bacalao',
      nombre: 'Bacalao',
      color: Color(0xFF2ED3C6),
      emoji: '🐟',
      perfil: PerfilRelleno.pescado,
      alergenos: <Alergeno>{Alergeno.pescado},
    ),
    Relleno(
      id: 'gamba',
      nombre: 'Gamba roja',
      color: Color(0xFFFF4D8D),
      emoji: '🦐',
      perfil: PerfilRelleno.marisco,
      alergenos: <Alergeno>{Alergeno.crustaceos},
    ),
    Relleno(
      id: 'chipiron',
      nombre: 'Chipirón en su tinta',
      color: AppColors.uva,
      emoji: '🦑',
      perfil: PerfilRelleno.marisco,
      alergenos: <Alergeno>{Alergeno.moluscos},
    ),

    // ── Vegetarianas ─────────────────────────────────────────────────────
    //
    // Aquí sólo va lo que necesita lácteo o huevo en el propio relleno. Todo
    // lo vegano vale también para un vegetariano, y el selector se lo enseña
    // junto: repetir las setas en los dos grupos sería una lista más larga
    // diciendo lo mismo.
    Relleno(
      id: 'queso',
      nombre: 'Queso azul',
      color: Color(0xFF6C8CFF),
      emoji: '🧀',
      perfil: PerfilRelleno.vegetariano,
      alergenos: <Alergeno>{Alergeno.leche},
    ),
    Relleno(
      id: 'espinaca_queso',
      nombre: 'Espinacas y queso',
      color: Color(0xFF9CC6E8),
      emoji: '🧀',
      perfil: PerfilRelleno.vegetariano,
      alergenos: <Alergeno>{Alergeno.leche},
    ),
    Relleno(
      id: 'champi_queso',
      nombre: 'Champiñones al queso',
      color: Color(0xFFC8A6D6),
      emoji: '🍄',
      perfil: PerfilRelleno.vegetariano,
      alergenos: <Alergeno>{Alergeno.leche},
    ),

    // ── Veganas ──────────────────────────────────────────────────────────
    Relleno(
      id: 'boletus',
      nombre: 'Boletus',
      color: AppColors.mango,
      emoji: '🍄',
      perfil: PerfilRelleno.vegano,
    ),
    Relleno(
      id: 'setas_trufa',
      nombre: 'Setas y trufa',
      color: Color(0xFF9C7A52),
      emoji: '🍄‍🟫',
      perfil: PerfilRelleno.vegano,
    ),
    Relleno(
      id: 'espinaca',
      nombre: 'Espinacas y piñones',
      color: AppColors.lima,
      emoji: '🥬',
      perfil: PerfilRelleno.vegano,
      alergenos: <Alergeno>{Alergeno.frutosCascara},
    ),
    Relleno(
      id: 'calabaza',
      nombre: 'Calabaza asada',
      color: Color(0xFFFFA23E),
      emoji: '🎃',
      perfil: PerfilRelleno.vegano,
    ),
    Relleno(
      id: 'puerro',
      nombre: 'Puerro confitado',
      color: Color(0xFFB8DE5C),
      emoji: '🧅',
      perfil: PerfilRelleno.vegano,
    ),
    Relleno(
      id: 'coliflor_curry',
      nombre: 'Coliflor al curry',
      color: Color(0xFFF2C14E),
      emoji: '🍛',
      perfil: PerfilRelleno.vegano,
    ),
    Relleno(
      id: 'berenjena',
      nombre: 'Berenjena y ajo negro',
      color: Color(0xFF7E5BA6),
      emoji: '🍆',
      perfil: PerfilRelleno.vegano,
    ),
    Relleno(
      id: 'boniato',
      nombre: 'Boniato al curry',
      color: Color(0xFFFF8A5B),
      emoji: '🍠',
      perfil: PerfilRelleno.vegano,
    ),
    Relleno(
      id: 'pimiento_hummus',
      nombre: 'Pimiento asado y hummus',
      color: Color(0xFFE2603C),
      emoji: '🫑',
      perfil: PerfilRelleno.vegano,
      // El hummus lleva tahini, que es sésamo.
      alergenos: <Alergeno>{Alergeno.sesamo},
    ),
    Relleno(
      id: 'seitan',
      nombre: 'Seitán y cebolla',
      color: Color(0xFFA9714B),
      emoji: '🌾',
      perfil: PerfilRelleno.vegano,
      // El seitán ES gluten de trigo. Vegano y prohibidísimo para un celíaco:
      // el caso perfecto de por qué "vegano" y "sin gluten" no son lo mismo.
      alergenos: <Alergeno>{Alergeno.gluten},
    ),
    Relleno(
      id: 'tofu_shiitake',
      nombre: 'Tofu y shiitake',
      color: Color(0xFFCBB68A),
      emoji: '🍲',
      perfil: PerfilRelleno.vegano,
      alergenos: <Alergeno>{Alergeno.soja},
    ),
    Relleno(
      id: 'champinon',
      nombre: 'Champiñones',
      color: Color(0xFFB08968),
      emoji: '🍄',
      perfil: PerfilRelleno.vegano,
    ),
    Relleno(
      id: 'calabacin',
      nombre: 'Calabacín',
      color: Color(0xFF8FCB6B),
      emoji: '🥒',
      perfil: PerfilRelleno.vegano,
    ),
    Relleno(
      id: 'zanahoria_curry',
      nombre: 'Zanahoria y curry',
      color: Color(0xFFE8843A),
      emoji: '🥕',
      perfil: PerfilRelleno.vegano,
    ),
    Relleno(
      id: 'brocoli',
      nombre: 'Brócoli',
      color: Color(0xFF4FA45B),
      emoji: '🥦',
      perfil: PerfilRelleno.vegano,
    ),
    Relleno(
      id: 'maiz',
      nombre: 'Maíz',
      color: Color(0xFFFFE066),
      emoji: '🌽',
      perfil: PerfilRelleno.vegano,
    ),
    Relleno(
      id: 'guisantes',
      nombre: 'Guisantes',
      color: Color(0xFF7BC96F),
      emoji: '🫛',
      perfil: PerfilRelleno.vegano,
    ),
    Relleno(
      id: 'cebolla',
      nombre: 'Cebolla caramelizada',
      color: Color(0xFFD9A5C9),
      emoji: '🧅',
      perfil: PerfilRelleno.vegano,
    ),
    Relleno(
      id: 'patata_puerro',
      nombre: 'Patata y puerro',
      color: Color(0xFFE3CE93),
      emoji: '🥔',
      perfil: PerfilRelleno.vegano,
    ),
    Relleno(
      id: 'lentejas',
      nombre: 'Lentejas y verduras',
      color: Color(0xFFA35D3A),
      emoji: '🫘',
      perfil: PerfilRelleno.vegano,
    ),
    Relleno(
      id: 'acelgas',
      nombre: 'Acelgas y pasas',
      color: Color(0xFF3E8E5A),
      emoji: '🥬',
      perfil: PerfilRelleno.vegano,
    ),
    Relleno(
      id: 'falafel',
      nombre: 'Falafel',
      color: Color(0xFF9CAF5F),
      emoji: '🧆',
      perfil: PerfilRelleno.vegano,
    ),

    // ── Comodín ──────────────────────────────────────────────────────────
    Relleno(
      id: 'otro',
      nombre: 'A mi manera',
      color: AppColors.menta,
      emoji: '🥄',
      perfil: PerfilRelleno.sinSaber,
    ),
  ];

  static final Map<String, Relleno> _porId = <String, Relleno>{
    for (final Relleno r in todos) r.id: r,
  };

  /// Nunca devuelve nulo: un relleno desconocido (una cata vieja, un dato
  /// corrupto) cae en el genérico en vez de romper la pantalla.
  static Relleno de(String id) => _porId[id] ?? todos.last;

  /// Los rellenos que puede pedir quien come así. Lo usa el formulario para
  /// poner arriba lo que le sirve a cada uno.
  static List<Relleno> para(PerfilRelleno perfil) => switch (perfil) {
        PerfilRelleno.vegano =>
          todos.where((Relleno r) => r.perfil.esVegano).toList(),
        PerfilRelleno.vegetariano =>
          todos.where((Relleno r) => r.perfil.esVegetariano).toList(),
        _ => todos,
      };
}
