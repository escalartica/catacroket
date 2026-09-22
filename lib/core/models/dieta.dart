import 'package:flutter/material.dart';

import '../data/rellenos.dart';
import '../theme/tokens/app_colors.dart';
import 'alergeno.dart';
import 'receta.dart';

/// Para quién vale una croqueta.
///
/// No es una etiqueta de alérgenos con valor legal y la app no puede
/// pretender que lo sea: esto lo marca quien cata, no la cocina. Sirve para
/// que alguien que no puede comer gluten sepa a qué bares han ido ya sus
/// amigos, no para saltarse la pregunta al camarero. Ese aviso está escrito
/// en la pantalla, no sólo aquí.
///
/// El orden de la lista es el orden en el que se pintan siempre: primero lo
/// que define la croqueta entera (vegana, vegetariana) y después las
/// ausencias, de la más común a la más rara.
/// Si una croqueta te vale a ti.
///
/// Tres estados y no dos. "No lo sé" es la respuesta honesta para una cata a
/// la que nadie le preguntó la receta, y juntarla con "no te vale" escondería
/// las que sí te valdrían si alguien preguntara.
enum Encaje {
  vale('Te vale', '✅', AppColors.lima),
  ojo('Pregunta', '⚠️', AppColors.sol),
  no('No te vale', '⛔', AppColors.tomate),
  sinSaber('Sin datos', '🤷', AppColors.superficieCalida);

  const Encaje(this.nombre, this.emoji, this.color);

  final String nombre;
  final String emoji;
  final Color color;

  /// El sinSaber no se pinta: una pastilla gris en cada tarjeta diciendo "no
  /// lo sé" sería ruido en todas las pantallas.
  bool get seEnsena => this != sinSaber;
}

enum Dieta {
  vegana(
    id: 'vegana',
    nombre: 'Vegana',
    corto: 'Vegana',
    emoji: '🌱',
    color: AppColors.lima,
    explicacion: 'Nada de origen animal: ni leche, ni huevo, ni mantequilla.',
  ),
  vegetariana(
    id: 'vegetariana',
    nombre: 'Vegetariana',
    corto: 'Veggie',
    emoji: '🥬',
    color: AppColors.menta,
    explicacion: 'Sin carne ni pescado. La bechamel con leche sí entra.',
  ),
  sinGluten(
    id: 'sin_gluten',
    nombre: 'Sin gluten',
    corto: 'Sin gluten',
    emoji: '🌾',
    color: AppColors.mango,
    explicacion: 'Bechamel y rebozado sin trigo. Pregunta por la freidora: '
        'si es la misma que la del resto, hay contaminación cruzada.',
  ),
  sinLactosa(
    id: 'sin_lactosa',
    nombre: 'Sin lactosa',
    corto: 'Sin lactosa',
    emoji: '🥛',
    color: AppColors.cielo,
    explicacion: 'Bechamel con bebida vegetal o con leche sin lactosa.',
  ),
  sinHuevo(
    id: 'sin_huevo',
    nombre: 'Sin huevo',
    corto: 'Sin huevo',
    emoji: '🥚',
    color: AppColors.sol,
    explicacion: 'Rebozadas sin pasar por huevo.',
  ),
  sinFrutosSecos(
    id: 'sin_frutos_secos',
    nombre: 'Sin frutos secos',
    corto: 'Sin frutos secos',
    emoji: '🥜',
    color: AppColors.chicle,
    explicacion: 'Ni piñones dentro, ni almendra molida en el rebozado.',
  );

  const Dieta({
    required this.id,
    required this.nombre,
    required this.corto,
    required this.emoji,
    required this.color,
    required this.explicacion,
  });

  /// Se guarda el id y no el índice: añadir una dieta en medio de la lista no
  /// puede cambiar lo que significan las catas ya guardadas.
  final String id;
  final String nombre;

  /// Para las pastillas de la tarjeta, donde no cabe el nombre largo.
  final String corto;
  final String emoji;
  final Color color;
  final String explicacion;

  /// El alérgeno que esta dieta evita, si evita uno concreto.
  ///
  /// Ser vegano o vegetariano no es una alergia y no tiene alérgeno detrás:
  /// por eso es nulo en esos dos. Sirve para saber cuándo un dato sin
  /// confirmar afecta a alguien de verdad.
  Alergeno? get alergeno => switch (this) {
        Dieta.sinGluten => Alergeno.gluten,
        Dieta.sinLactosa => Alergeno.leche,
        Dieta.sinHuevo => Alergeno.huevo,
        Dieta.sinFrutosSecos => Alergeno.frutosCascara,
        Dieta.vegana || Dieta.vegetariana => null,
      };

  static Dieta? porId(String id) {
    for (final Dieta d in values) {
      if (d.id == id) return d;
    }
    return null;
  }

  /// Lee una lista guardada. Un id que ya no existe se ignora en vez de
  /// romper la cata entera.
  static Set<Dieta> desdeJson(dynamic crudo) {
    if (crudo is! List<dynamic>) return const <Dieta>{};
    return crudo
        .map((dynamic e) => porId(e.toString()))
        .whereType<Dieta>()
        .toSet();
  }

  /// Ordena como [values], que es el orden con el que se pintan en toda la
  /// app. Un `Set` no garantiza orden y las pastillas bailarían.
  static List<Dieta> ordenar(Set<Dieta> dietas) =>
      values.where(dietas.contains).toList();

  /// Deduce para quién vale una croqueta a partir de cómo está hecha.
  ///
  /// Esto sustituye a que el usuario marcase etiquetas a mano, que era el
  /// agujero de la primera versión: se podía marcar "vegana" en una croqueta
  /// de jamón y la app se lo tragaba, porque guardaba etiquetas y no hechos.
  ///
  /// Las reglas, y por qué son así:
  ///
  /// - **Vegana** necesita las tres cosas: relleno vegano, bechamel vegetal y
  ///   rebozado sin huevo. Un boletus con bechamel de leche no es vegano por
  ///   mucho que la seta lo sea, y es el caso más común de todos.
  /// - **Vegetariana** admite la bechamel de leche, pero hay que saber cuál
  ///   es: si no se preguntó, no se afirma.
  /// - **Sin lactosa** no es lo mismo que sin leche. Vale la leche sin
  ///   lactosa; no vale un relleno de queso.
  /// - **Sin gluten** mira el rebozado Y el relleno: el seitán es gluten de
  ///   trigo, así que una croqueta vegana de seitán es de las peores cosas
  ///   que le puedes poner delante a un celíaco.
  /// - Lo **dudoso no cuenta como ausente**. Si algo no se preguntó, no
  ///   aparece en la lista. Callarse es correcto; suponer, no.
  static Set<Dieta> deducir({
    required Receta receta,
    required List<Relleno> rellenos,
  }) {
    if (receta.sinRellenar || rellenos.isEmpty) return const <Dieta>{};

    final Set<Alergeno> hay = <Alergeno>{
      ...receta.alergenos,
      for (final Relleno r in rellenos) ...r.alergenos,
    };
    final Set<Alergeno> quizas = <Alergeno>{
      ...receta.dudosos,
      // Un relleno "a mi manera" es un relleno que nadie ha descrito, así que
      // puede llevar cualquier cosa: nueces, gluten, lo que sea. Bloquear
      // sólo lo vegano y lo vegetariano no bastaba —eso ya lo hacía el
      // perfil—, porque seguía diciendo "sin frutos secos" de algo cuyo
      // contenido no conoce nadie.
      if (rellenos.any((Relleno r) => r.perfil == PerfilRelleno.sinSaber))
        ...Alergeno.values,
    };

    /// Sólo se puede decir "sin X" si X no está y tampoco está en duda.
    bool libreDe(Alergeno a) => !hay.contains(a) && !quizas.contains(a);

    final bool todoVegano =
        rellenos.every((Relleno r) => r.perfil.esVegano);
    final bool todoVegetariano =
        rellenos.every((Relleno r) => r.perfil.esVegetariano);
    final bool sabemosLaBechamel = receta.bechamel != Bechamel.sinSaber;

    /// Si sabemos qué es cada relleno. Lo de "sin lactosa" también depende de
    /// esto: un relleno sin describir puede ser de queso.
    final bool todoDescrito =
        rellenos.every((Relleno r) => r.perfil != PerfilRelleno.sinSaber);
    final bool rellenoConLeche =
        rellenos.any((Relleno r) => r.alergenos.contains(Alergeno.leche));

    return <Dieta>{
      if (todoVegano &&
          receta.esVegetal &&
          !receta.rebozadoConHuevo &&
          !hay.contains(Alergeno.leche))
        vegana,
      if (todoVegetariano &&
          sabemosLaBechamel &&
          !hay.contains(Alergeno.pescado) &&
          !hay.contains(Alergeno.crustaceos) &&
          !hay.contains(Alergeno.moluscos))
        vegetariana,
      if (sabemosLaBechamel &&
          todoDescrito &&
          (receta.bechamel == Bechamel.sinLactosa || receta.esVegetal) &&
          !rellenoConLeche)
        sinLactosa,
      if (libreDe(Alergeno.gluten)) sinGluten,
      if (libreDe(Alergeno.huevo)) sinHuevo,
      if (libreDe(Alergeno.frutosCascara)) sinFrutosSecos,
    };
  }
}
