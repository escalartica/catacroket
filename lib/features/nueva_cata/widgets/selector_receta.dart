import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/alergeno.dart';
import '../../../core/models/dieta.dart';
import '../../../core/models/receta.dart';
import '../../../core/providers/borrador_provider.dart';
import '../../../core/theme/components/boton.dart';
import '../../../core/theme/components/campo.dart';
import '../../../core/theme/components/chip.dart';
import '../../../core/theme/components/pegatina.dart';
import '../../../core/theme/components/pildoras_dieta.dart';
import '../../../core/theme/tokens/app_colors.dart';
import '../../../core/theme/tokens/app_shape.dart';
import '../../../core/theme/tokens/app_spacing.dart';
import '../../../core/theme/tokens/app_typography.dart';

/// Cómo está hecha la croqueta.
///
/// Aquí no se marcan etiquetas ("vegana", "sin gluten"), se contestan tres
/// preguntas concretas y las etiquetas salen solas. El cambio no es de forma:
/// antes se podía marcar "vegana" en una de jamón y la app se lo creía.
///
/// Además son preguntas que el camarero sabe responder. "¿Esto es vegano?"
/// se contesta mal muchas veces; "¿la bechamel es de leche?" no.
class SelectorReceta extends ConsumerWidget {
  const SelectorReceta({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Borrador b = ref.watch(borradorProvider);
    final BorradorNotifier n = ref.read(borradorProvider.notifier);
    final Receta r = b.receta;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text('CÓMO ESTABA HECHA', style: AppTypography.antetitulo),
        const SizedBox(height: 4),
        Text(
          'Opcional, pero es lo que decide si alguien de tu mesa puede '
          'comérsela. Pregunta en la barra: son tres cosas que saben.',
          style: AppTypography.cuerpoS.copyWith(
            fontSize: 12.5,
            height: 1.3,
            color: AppColors.tintaSuave,
          ),
        ),
        const SizedBox(height: AppSpacing.m),

        _Pregunta(
          texto: 'La bechamel',
          hijos: <Widget>[
            for (final Bechamel v in Bechamel.values)
              OpcionPildora(
                texto: v.nombre,
                emoji: v.emoji,
                activa: r.bechamel == v,
                colorActiva: AppColors.cielo,
                onTap: () => n.bechamel(v),
              ),
          ],
        ),

        // La bebida sólo aparece si hace falta: preguntar de qué es la bebida
        // vegetal de una bechamel de leche sería ruido.
        if (r.esVegetal)
          _Pregunta(
            texto: '¿De qué bebida?',
            ayuda: 'La de soja y la de almendra son alérgenos. Si no se sabe, '
                'la app no dirá que está libre de ellos.',
            hijos: <Widget>[
              for (final BebidaVegetal v in BebidaVegetal.values)
                OpcionPildora(
                  texto: v.nombre,
                  emoji: v.emoji,
                  activa: r.bebida == v,
                  colorActiva: AppColors.lima,
                  onTap: () => n.bebida(v),
                ),
            ],
          ),

        _Pregunta(
          texto: 'El rebozado',
          hijos: <Widget>[
            OpcionPildora(
              texto: 'Pan rallado normal',
              emoji: '🌾',
              activa: r.rebozadoConGluten,
              colorActiva: AppColors.mango,
              onTap: () => n.rebozadoConGluten(true),
            ),
            OpcionPildora(
              texto: 'Sin gluten',
              emoji: '✅',
              activa: !r.rebozadoConGluten,
              colorActiva: AppColors.mango,
              onTap: () => n.rebozadoConGluten(false),
            ),
            OpcionPildora(
              texto: 'Pasada por huevo',
              emoji: '🥚',
              activa: r.rebozadoConHuevo,
              colorActiva: AppColors.sol,
              onTap: () => n.rebozadoConHuevo(true),
            ),
            OpcionPildora(
              texto: 'Sin huevo',
              emoji: '✅',
              activa: !r.rebozadoConHuevo,
              colorActiva: AppColors.sol,
              onTap: () => n.rebozadoConHuevo(false),
            ),
          ],
        ),

        _Pregunta(
          texto: 'La freidora',
          ayuda: 'Si se fríe en el mismo aceite que el resto de la carta, una '
              'croqueta sin gluten deja de ser segura para un celíaco.',
          hijos: <Widget>[
            for (final Freidora v in Freidora.values)
              OpcionPildora(
                texto: v.nombre,
                emoji: v.emoji,
                activa: r.freidora == v,
                colorActiva: AppColors.menta,
                onTap: () => n.freidora(v),
              ),
          ],
        ),

        const SizedBox(height: AppSpacing.m),
        BotonPegatina.fantasma(
          texto: r.extra.isEmpty
              ? 'Añadir otro alérgeno'
              : 'Alérgenos añadidos: ${r.extra.length}',
          icono: Icons.add_rounded,
          pequeno: true,
          onTap: () => _hojaAlergenos(context, ref),
        ),

        const SizedBox(height: AppSpacing.l),
        _Resultado(borrador: b),
      ],
    );
  }

  Future<void> _hojaAlergenos(BuildContext context, WidgetRef ref) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext hoja) => const _HojaAlergenos(),
    );
  }
}

class _Pregunta extends StatelessWidget {
  const _Pregunta({required this.texto, required this.hijos, this.ayuda});

  final String texto;
  final String? ayuda;
  final List<Widget> hijos;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(texto, style: AppTypography.tituloS.copyWith(fontSize: 16)),
          if (ayuda != null) ...<Widget>[
            const SizedBox(height: 2),
            Text(
              ayuda!,
              style: AppTypography.cuerpoS.copyWith(
                fontSize: 12,
                height: 1.25,
                color: AppColors.tintaSuave,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: hijos),
        ],
      ),
    );
  }
}

/// Lo que sale de las respuestas.
///
/// Se enseña en vivo porque es donde se entiende la regla: contestas
/// "bechamel vegetal" y ves aparecer la pastilla de vegana; vuelves a "de
/// leche" y desaparece. Eso enseña más que un párrafo de ayuda.
class _Resultado extends StatelessWidget {
  const _Resultado({required this.borrador});

  final Borrador borrador;

  @override
  Widget build(BuildContext context) {
    final List<Dieta> dietas = Dieta.ordenar(borrador.dietasDeducidas);
    final List<Alergeno> alergenos =
        Alergeno.ordenar(borrador.alergenosDeducidos);
    final bool sinRellenar = borrador.receta.sinRellenar;
    final bool avisoFreidora = dietas.contains(Dieta.sinGluten) &&
        borrador.receta.freidora != Freidora.aparte;

    return Pegatina(
      color: AppColors.superficieCalida,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('CON ESTO SALE', style: AppTypography.antetitulo),
          const SizedBox(height: AppSpacing.m),
          if (sinRellenar)
            Text(
              'Nada todavía. Sin contestar nada, la cata se publica igual: '
              'simplemente no dirá para quién vale.',
              style: AppTypography.cuerpoS,
            )
          else if (dietas.isEmpty)
            Text(
              'Para ninguna dieta de la lista. Es lo normal en una croqueta '
              'de bar: bechamel de leche y rebozado de trigo y huevo.',
              style: AppTypography.cuerpoS,
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: <Widget>[
                for (final Dieta d in dietas)
                  ChipCata(texto: d.corto, emoji: d.emoji, color: d.color),
              ],
            ),
          if (alergenos.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.m),
            Text('LLEVA', style: AppTypography.antetitulo),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: <Widget>[
                for (final Alergeno a in alergenos)
                  ChipCata(
                    texto: a.nombre,
                    emoji: a.emoji,
                    color: AppColors.superficie,
                    compacto: true,
                  ),
              ],
            ),
          ],
          if (avisoFreidora) ...<Widget>[
            const SizedBox(height: AppSpacing.m),
            const AvisoAlergias(
              texto: 'Sin gluten en la receta, pero la freidora no es aparte. '
                  'Para un celíaco eso no es seguro, y la ficha lo dirá.',
            ),
          ],
        ],
      ),
    );
  }
}

/// Los catorce de la lista oficial, para añadir lo que la receta no deduce.
class _HojaAlergenos extends ConsumerWidget {
  const _HojaAlergenos();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Borrador b = ref.watch(borradorProvider);
    final BorradorNotifier n = ref.read(borradorProvider.notifier);
    final Set<Alergeno> deducidos = b.alergenosDeducidos;

    return Container(
      margin: const EdgeInsets.all(AppSpacing.s),
      padding: const EdgeInsets.all(AppSpacing.l),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      decoration: BoxDecoration(
        color: AppColors.fondo,
        borderRadius: BorderRadius.circular(AppShape.radioXL),
        border: Border.all(color: AppColors.tinta, width: AppShape.borde),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('Qué lleva', style: AppTypography.tituloM),
          const SizedBox(height: 4),
          Text(
            'Los catorce de declaración obligatoria, los mismos que el bar '
            'tiene que poder decirte. Los que ya salen del relleno y de la '
            'receta vienen marcados.',
            style: AppTypography.cuerpoS.copyWith(
              fontSize: 12.5,
              height: 1.3,
              color: AppColors.tintaSuave,
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: Alergeno.values.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (BuildContext context, int i) {
                final Alergeno a = Alergeno.values[i];
                final bool automatico = deducidos.contains(a) &&
                    !b.receta.extra.contains(a);
                return _FilaAlergeno(
                  alergeno: a,
                  marcado: deducidos.contains(a),
                  automatico: automatico,
                  onTap: automatico ? null : () => n.alternarAlergeno(a),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          BotonPegatina(
            texto: 'Listo',
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _FilaAlergeno extends StatelessWidget {
  const _FilaAlergeno({
    required this.alergeno,
    required this.marcado,
    required this.automatico,
    required this.onTap,
  });

  final Alergeno alergeno;
  final bool marcado;

  /// Viene del relleno o de la receta: se enseña marcado y no se puede
  /// desmarcar. Dejar quitar a mano un alérgeno que la app sabe que está
  /// sería dejar mentir sobre lo único que no admite mentiras.
  final bool automatico;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      selected: marcado,
      child: ExcludeSemantics(
        child: Pegatina(
          color: marcado ? AppColors.superficieHonda : AppColors.superficie,
          sombra: AppShape.sombraChica,
          padding: const EdgeInsets.all(AppSpacing.m),
          onTap: onTap,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(alergeno.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      alergeno.nombre,
                      style: AppTypography.tituloS.copyWith(fontSize: 15.5),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      alergeno.enCroquetas,
                      style: AppTypography.cuerpoS.copyWith(
                        fontSize: 12,
                        height: 1.25,
                        color: AppColors.tintaSuave,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                marcado
                    ? (automatico ? Icons.lock_rounded : Icons.check_circle_rounded)
                    : Icons.circle_outlined,
                size: 22,
                color: marcado ? AppColors.tinta : AppColors.tintaApagada,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
