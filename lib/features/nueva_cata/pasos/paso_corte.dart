import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../arte/corte_painter.dart';
import '../../../core/data/rellenos.dart';
import '../../../core/models/corte.dart';
import '../../../core/models/tiro_al_plato.dart';
import '../../../core/providers/borrador_provider.dart';
import '../../../core/theme/components/barra_eje.dart';
import '../../../core/theme/components/campo.dart';
import '../../../core/theme/components/nota.dart';
import '../../../core/theme/components/pegatina.dart';
import '../../../core/theme/components/slider_corte.dart';
import '../../../core/theme/tokens/app_colors.dart';
import '../../../core/theme/tokens/app_spacing.dart';
import '../../../core/theme/tokens/app_typography.dart';

/// Paso 3: EL CORTE.
///
/// Es el momento que vende la app: el dibujo se rehace mientras arrastras.
/// Por eso el orden en pantalla es dibujo primero, nota después y mandos al
/// final — si los mandos estuvieran arriba, el pulgar taparía justo lo que
/// hay que mirar.
class PasoCorte extends ConsumerWidget {
  const PasoCorte({super.key});

  /// Qué le dice la app al usuario según la nota que lleva puesta.
  static const List<(double, String)> _frases = <(double, String)>[
    (0, 'Para olvidar'),
    (4, 'Correcta'),
    (6, 'Buena'),
    (7.5, 'Muy buena'),
    (8.5, 'De las que se recuerdan'),
    (9.3, 'Obra maestra'),
  ];

  static String _frase(double nota) {
    String elegida = _frases.first.$2;
    for (final (double, String) f in _frases) {
      if (nota >= f.$1) elegida = f.$2;
    }
    return elegida;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Borrador borrador = ref.watch(borradorProvider);
    final BorradorNotifier notifier = ref.read(borradorProvider.notifier);
    final Relleno relleno = Rellenos.de(borrador.rellenoVisible);
    final Corte corte = borrador.corteFinal;
    final double nota = corte.nota;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Pegatina(
          color: Color.lerp(relleno.color, Colors.white, 0.78)!,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
          child: Center(
            child: ElCorte(
              corte: corte,
              rellenoId: relleno.id,
              semilla: 'en-vivo',
              animado: true,
              ancho: 200,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.l),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Nota(valor: nota, grande: true),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text('La nota', style: AppTypography.tituloS.copyWith(fontSize: 16)),
                Text(_frase(nota), style: AppTypography.cuerpoS.copyWith(fontSize: 13)),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        SliderCorte(
          nombre: 'Crujiente',
          pista: 'la costra',
          valor: borrador.corte.crujiente,
          color: BarraEje.colores['crujiente']!,
          onCambio: (int v) => notifier.eje('crujiente', v),
        ),
        const SizedBox(height: AppSpacing.m),
        _TiroAlPlato(
          elegido: borrador.tiro,
          onElegir: notifier.tiro,
        ),
        const SizedBox(height: AppSpacing.l),
        SliderCorte(
          nombre: 'Cremosidad',
          pista: 'la bechamel',
          valor: borrador.corte.cremosidad,
          color: BarraEje.colores['cremosidad']!,
          onCambio: (int v) => notifier.eje('cremosidad', v),
        ),
        const SizedBox(height: AppSpacing.l),
        if (!borrador.surtido) ...<Widget>[
          SliderCorte(
            nombre: 'Sabor',
            pista: 'lo que se recuerda',
            valor: borrador.corte.sabor,
            color: BarraEje.colores['sabor']!,
            onCambio: (int v) => notifier.eje('sabor', v),
          ),
          const SizedBox(height: AppSpacing.l),
          SliderCorte(
            nombre: 'Relleno',
            pista: 'cantidad y calidad',
            valor: borrador.corte.relleno,
            color: BarraEje.colores['relleno']!,
            onCambio: (int v) => notifier.eje('relleno', v),
          ),
        ] else
          // En un surtido, sabor y relleno no los pone un slider: los pone la
          // media de lo que has dicho de cada croqueta. Se enseña para que se
          // entienda de dónde sale la nota.
          Pegatina(
            color: AppColors.superficieCalida,
            sombra: const Offset(2, 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'SABOR Y RELLENO LOS PONE EL SURTIDO',
                  style: AppTypography.antetitulo.copyWith(fontSize: 10.5),
                ),
                const SizedBox(height: AppSpacing.s),
                Text(
                  'Media de tus ${borrador.sabores.length} sabores: '
                  '${corte.sabor}/10. El crujiente y la bechamel son del '
                  'cocinero, así que esos sí los pones tú.',
                  style: AppTypography.cuerpoS.copyWith(
                    color: AppColors.tinta,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.l),
        Text(
          'Cada eje cambia el dibujo: el crujiente engorda la costra, la '
          'cremosidad aclara la bechamel, el relleno añade trozos y el sabor '
          'levanta el vapor.',
          style: AppTypography.cuerpoS.copyWith(
            fontSize: 12.5,
            color: AppColors.tintaSuave,
          ),
        ),
      ],
    );
  }
}

/// La prueba del tiro al plato.
///
/// Va justo debajo del deslizador de crujiente porque habla de lo mismo: el
/// rebozado. Pero no lo repite. El deslizador dice cuánto crujía y esto dice
/// cómo sonaba, y a veces no coinciden, que es lo que tiene gracia.
///
/// Es opcional del todo: no bloquea el paso, no entra en la nota y no cambia
/// el dibujo. Quien no quiera jugar, pasa de largo y no se entera.
class _TiroAlPlato extends StatelessWidget {
  const _TiroAlPlato({required this.elegido, required this.onElegir});

  final TiroAlPlato? elegido;
  final ValueChanged<TiroAlPlato> onElegir;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              'La prueba del tiro al plato',
              style: AppTypography.tituloS.copyWith(fontSize: 15),
            ),
            const SizedBox(width: 6),
            Text(
              'opcional',
              style: AppTypography.etiqueta.copyWith(
                fontSize: 10.5,
                color: AppColors.tintaSuave,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          elegido?.queSignifica ?? 'Déjala caer en el plato. ¿Qué se oyó?',
          style: AppTypography.cuerpoS.copyWith(
            fontSize: 12.5,
            height: 1.3,
            color: AppColors.tintaSuave,
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        Wrap(
          spacing: AppSpacing.s,
          runSpacing: AppSpacing.s,
          children: <Widget>[
            for (final TiroAlPlato t in TiroAlPlato.values)
              OpcionPildora(
                texto: t.nombre,
                emoji: t.emoji,
                activa: elegido == t,
                colorActiva: t.color,
                // De marcar varias no: sólo suena de una manera. Pero se
                // puede desmarcar tocando la que ya está, y por eso no se
                // anuncia como grupo de una sola.
                enGrupoUnico: false,
                onTap: () => onElegir(t),
              ),
          ],
        ),
      ],
    );
  }
}
