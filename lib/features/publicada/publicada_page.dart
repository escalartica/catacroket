import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../arte/confeti.dart';
import '../../arte/corte_painter.dart';
import '../../arte/croqui.dart';
import '../../core/data/rellenos.dart';
import '../../core/models/cata.dart';
import '../../core/models/persona.dart';
import '../../core/providers/catas_provider.dart';
import '../../core/providers/perfil_provider.dart';
import '../../core/theme/components/boton.dart';
import '../../core/theme/components/chip.dart';
import '../../core/theme/components/nota.dart';
import '../../core/theme/tokens/app_colors.dart';
import '../../core/theme/tokens/app_motion.dart';
import '../../core/theme/tokens/app_spacing.dart';
import '../../core/theme/tokens/app_typography.dart';
import '../compartir/compartir_cata.dart';

/// La celebración. Dura lo que el usuario quiera: no se cierra sola.
class PublicadaPage extends ConsumerStatefulWidget {
  const PublicadaPage({super.key, required this.cataId});

  final String cataId;

  @override
  ConsumerState<PublicadaPage> createState() => _PublicadaPageState();
}

class _PublicadaPageState extends ConsumerState<PublicadaPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _control = AnimationController(
    vsync: this,
    duration: AppMotion.celebracion,
  )..forward();

  @override
  void dispose() {
    _control.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Cata? cata = ref.watch(cataProvider(widget.cataId));

    if (cata == null) {
      return Center(
        child: BotonPegatina(
          texto: 'Volver a La Vitrina',
          onTap: () => context.go('/'),
        ),
      );
    }

    final Relleno relleno = Rellenos.de(cata.rellenoId);
    final int numero = ref.watch(perfilProvider).catas;
    final String rango = ref.watch(perfilProvider).rango;
    final double nota = cata.puntuacion;

    return Stack(
      children: <Widget>[
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.xxl,
          ),
          child: Column(
            children: <Widget>[
              // El corte de tu croqueta, con Croqui asomando al lado.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  ScaleTransition(
                    scale: CurvedAnimation(
                      parent: _control,
                      curve: Curves.elasticOut,
                    ),
                    child: ElCorte(
                      corte: cata.corte,
                      rellenoId: cata.rellenoId,
                      semilla: cata.id,
                      ancho: 190,
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(-22, 14),
                    child: FadeTransition(
                      opacity: _control,
                      child: const Croqui(ancho: 96, conProps: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.l),
              Text(
                'CATA Nº $numero',
                style: AppTypography.antetitulo.copyWith(
                  color: AppColors.tintaSuave,
                ),
              ),
              const SizedBox(height: AppSpacing.m),

              // La nota sube de 0,0 hasta la real.
              AnimatedBuilder(
                animation: _control,
                builder: (BuildContext context, Widget? _) {
                  final double t = Curves.easeOutCubic.transform(_control.value);
                  return Nota(valor: nota * t, grande: true);
                },
              ),
              const SizedBox(height: AppSpacing.m),
              ChipCata(
                texto: '${relleno.nombre} · ${cata.sitio}',
                color: AppColors.chicle,
                emoji: relleno.emoji,
              ),
              const SizedBox(height: AppSpacing.m),
              Text(
                // La primera cata no se juzga por la nota. Es el momento en
                // que alguien empieza a usar la app, y contestarle "no todas
                // pueden ser leyenda" porque le salió un 6 es recibirle con
                // una palmadita en la espalda. A partir de la segunda, el
                // chiste ya tiene gracia.
                numero == 1
                    ? 'Tu primera cata. Ya tienes libreta.'
                    : nota >= 8.5
                        ? 'Menuda joya. Ya está en lo más alto de tu libreta.'
                        : nota >= 7
                            ? 'Buena cata. Tu media sube un poquito.'
                            : 'Anotada. No todas pueden ser leyenda.',
                textAlign: TextAlign.center,
                style: AppTypography.cuerpo,
              ),
              const SizedBox(height: AppSpacing.m),
              ChipCata(texto: rango, color: AppColors.sol, emoji: '🏅'),
              const SizedBox(height: AppSpacing.xxl),
              BotonPegatina(
                texto: 'Compartir la estampa',
                color: AppColors.chicle,
                icono: Icons.ios_share_rounded,
                onTap: () => compartirCata(
                  context,
                  cata: cata,
                  autor: ref.read(personasProvider)[cata.autorId] ??
                      Persona.desconocida,
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              BotonPegatina.fantasma(
                texto: 'Ver la cata',
                onTap: () => context.go('/cata/${cata.id}'),
              ),
              const SizedBox(height: AppSpacing.s),
              BotonPegatina.fantasma(
                texto: 'Volver a La Vitrina',
                pequeno: true,
                onTap: () => context.go('/'),
              ),
            ],
          ),
        ),
        const Positioned.fill(child: Confeti()),
      ],
    );
  }
}
