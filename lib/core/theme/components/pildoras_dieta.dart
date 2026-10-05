import 'package:flutter/material.dart';

import '../../models/dieta.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_shape.dart';
import '../tokens/app_typography.dart';
import 'campo.dart';

/// Las seis dietas, en pastillas. Es el mismo control en el formulario y en
/// el filtro de la Barra Libre: si en un sitio se marca "sin gluten" y en el
/// otro se pide, tienen que ser exactamente el mismo botón y el mismo color.
class PildorasDieta extends StatelessWidget {
  const PildorasDieta({
    super.key,
    required this.marcadas,
    required this.onAlternar,
    this.recuento,
    this.onComoDeTodo,
  });

  final Set<Dieta> marcadas;
  final void Function(Dieta) onAlternar;

  /// Pone delante un «Como de todo» que lo desmarca todo.
  ///
  /// Hace falta donde se dice CÓMO COMES, y no donde se describe una
  /// croqueta ni donde se filtra. «No tengo ninguna restricción» era el
  /// estado por defecto y no se veía por ninguna parte: seis pastillas
  /// apetecibles y nada que diga qué significan, así que quien come de todo
  /// las marca TODAS pensando que dice «puedo con todo esto», cuando lo que
  /// la app entiende es que eres vegano, celíaco y alérgico al huevo a la
  /// vez. Pasó de verdad, y deja la app escondiéndote media lista de
  /// rellenos en cada cata que apuntas.
  final VoidCallback? onComoDeTodo;

  /// Cuántas catas quedarían al marcar cada una, contando lo que ya haya
  /// marcado. Sólo lo pasa el filtro; en el formulario el número no significa
  /// nada y sobra.
  final Map<Dieta, int>? recuento;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        if (onComoDeTodo != null)
          OpcionPildora(
            texto: 'Como de todo',
            emoji: '🍽️',
            activa: marcadas.isEmpty,
            colorActiva: AppColors.lima,
            colorInactiva: AppColors.superficie,
            enGrupoUnico: false,
            // Siempre pulsable, aunque ya esté puesta. Apagarla con `onTap:
            // null` la dejaba al 42 % de opacidad, que es como se pinta lo
            // que no se puede tocar: la opción que describe tu estado actual
            // se veía desvaída y con el borde gris, o sea rota. Volver a
            // tocarla no hace daño.
            onTap: onComoDeTodo,
          ),
        for (final Dieta d in Dieta.values) _unaPildora(d),
      ],
    );
  }

  Widget _unaPildora(Dieta d) {
    final bool marcada = marcadas.contains(d);
    // Marcar una dieta es decir que NO puedes con ella, así que al tocarla
    // «Como de todo» se apaga solo. Lo hace el propio estado: está activa
    // mientras no haya ninguna marcada.

    final int? cuantas = recuento?[d];

    // Sin ninguna detrás, la pastilla se apaga.
    //
    // El contador dice lo que saldría al pulsarla, así que un cero es la
    // promesa de una lista vacía. La marcada nunca se apaga: si se apagara no
    // habría forma de desmarcarla y te quedarías encerrado en un filtro que
    // no da nada.
    final bool apagada = cuantas == 0 && !marcada;

    final Color sobre =
        marcada ? AppColors.textoSobre(d.color) : AppColors.tinta;

    return OpcionPildora(
      texto: d.nombre,
      emoji: d.emoji,
      activa: marcada,
      colorActiva: d.color,
      // Un velo del color de la dieta, no el color entero: se reconoce
      // cada una de un vistazo y la marcada sigue destacando, porque
      // va a saturación completa y con más sombra.
      //
      // Por [AppColors.velo] y no por una mezcla fija: con el 86 % de antes,
      // el rosa de «sin frutos secos» quedaba bastante más oscuro que los
      // otros cinco y parecía marcado sin estarlo.
      colorInactiva: AppColors.velo(d.color),
      // Se marcan varias: alguien puede ser vegano Y celíaco.
      enGrupoUnico: false,
      // El número, en su propia insignia y no pegado al nombre.
      //
      // «Vegana  0» se leía como una sola frase y el cero parecía parte del
      // nombre. Separado se ve lo que es: cuántas croquetas hay detrás.
      //
      // En la marcada no se pone. El número contesta «cuántas saldrían si la
      // pulso», y en una que ya está puesta eso es el total de la lista, que
      // está dicho ahí mismo en el título. Con varias marcadas y la lista
      // vacía se veían cinco pastillas encendidas poniendo «0»: parecía la
      // app rota, cuando lo que pasaba era que pedías cinco cosas a la vez.
      cola: cuantas == null || marcada
          ? null
          : Container(
              constraints: const BoxConstraints(minWidth: 21),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: sobre.withValues(alpha: marcada ? 0.22 : 0.10),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$cuantas',
                style: AppTypography.etiqueta.copyWith(
                  fontSize: 12,
                  color: sobre,
                ),
                maxLines: 1,
              ),
            ),
      enVoz: cuantas == null
          ? null
          : <String>[
              d.nombre,
              if (marcada)
                'marcado'
              else
                switch (cuantas) {
                  0 => 'ninguna croqueta',
                  1 => '1 croqueta',
                  _ => '$cuantas croquetas',
                },
            ].join(', '),
      onTap: apagada ? null : () => onAlternar(d),
    );
  }
}

/// El aviso. Va donde se marcan las dietas y donde se leen.
///
/// No es letra pequeña por cubrirse: una app que le dice a un celíaco "esta
/// vale" y se equivoca le hace daño de verdad. La app guarda lo que apuntó
/// quien comió, y eso es lo que tiene que decir, con todas las letras.
class AvisoAlergias extends StatelessWidget {
  const AvisoAlergias({super.key, this.texto});

  final String? texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.agua,
        borderRadius: BorderRadius.circular(AppShape.radioM),
        border: Border.all(color: AppColors.tinta, width: AppShape.bordeFino),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('⚠️', style: TextStyle(fontSize: 15)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto ??
                  'Esto lo marca quien cata, no la cocina. Si hay alergia de '
                      'por medio, pregunta siempre en el bar.',
              style: AppTypography.cuerpoS.copyWith(
                fontSize: 12.5,
                height: 1.3,
                color: AppColors.tinta,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
