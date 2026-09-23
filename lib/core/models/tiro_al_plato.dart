import 'package:flutter/material.dart';

import '../theme/tokens/app_colors.dart';

/// La prueba del tiro al plato: qué se oye al dejar caer la croqueta.
///
/// Es un apunte con gracia, no una nota. No entra en el CataScore ni cambia
/// el dibujo del corte, y por eso puede convivir con el deslizador de
/// crujiente sin contradecirlo: el deslizador dice cuánto crujía y esto dice
/// cómo sonaba, que no es lo mismo y a veces no coincide. Una croqueta puede
/// crujir un ocho y sonar a hormigón armado; de hecho es lo más divertido
/// que puede pasar.
///
/// Se guarda con la cata porque es de las cosas que se recuerdan, y el
/// nombre que le pongas hoy es el que leerás dentro de un año.
enum TiroAlPlato {
  muyFino(
    id: 'muyFino',
    nombre: 'Muy fino',
    emoji: '🪶',
    color: AppColors.agua,
    queSignifica: 'Apenas se oyó. Rebozado de seda.',
  ),
  crujientePerfecto(
    id: 'crujientePerfecto',
    nombre: 'Crujiente perfecto',
    emoji: '✨',
    color: AppColors.lima,
    queSignifica: 'El sonido que buscas. Ni más ni menos.',
  ),
  sonidoMetalico(
    id: 'sonidoMetalico',
    nombre: 'Sonido metálico',
    emoji: '🔔',
    color: AppColors.sol,
    queSignifica: 'Sonó a llave contra el plato. Demasiado tostada.',
  ),
  seDeshace(
    id: 'seDeshace',
    nombre: 'Se deshace',
    emoji: '💨',
    color: AppColors.menta,
    queSignifica: 'No llegó entera al plato.',
  ),
  aceitoso(
    id: 'aceitoso',
    nombre: 'Aceitoso',
    emoji: '🫗',
    color: AppColors.mango,
    queSignifica: 'Dejó marca en el plato antes de tocarlo.',
  ),
  hormigonArmado(
    id: 'hormigonArmado',
    nombre: 'Hormigón armado',
    emoji: '🧱',
    color: AppColors.tomate,
    queSignifica: 'Rebotó. Ahí hay obra.',
  );

  const TiroAlPlato({
    required this.id,
    required this.nombre,
    required this.emoji,
    required this.color,
    required this.queSignifica,
  });

  /// Lo que se guarda. No se traduce nunca: el nombre puede cambiar, esto no.
  final String id;

  final String nombre;
  final String emoji;
  final Color color;

  /// La coña explicada, para quien no haya visto el programa.
  final String queSignifica;

  /// Recupera uno de lo guardado. Nulo si no está o no se reconoce, que es
  /// lo que pasa al abrir una cata guardada por una versión más nueva.
  static TiroAlPlato? desdeId(Object? id) {
    if (id is! String) return null;
    for (final TiroAlPlato t in TiroAlPlato.values) {
      if (t.id == id) return t;
    }
    return null;
  }
}
