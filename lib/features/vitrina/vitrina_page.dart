import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../arte/croqui.dart';
import '../../core/models/cata.dart';
import '../../core/models/persona.dart';
import '../../core/providers/catas_provider.dart';
import '../../core/providers/perfil_provider.dart';
import '../../core/theme/components/boton.dart';
import '../../core/theme/components/cabecera.dart';
import '../../core/theme/components/chip.dart';
import '../../core/providers/visto_provider.dart';
import '../../core/theme/components/entrada.dart';
import '../../core/theme/components/pista.dart';
import '../../core/theme/components/segmentado.dart';
import '../../core/theme/tokens/app_colors.dart';
import '../../core/theme/tokens/app_spacing.dart';
import '../../core/theme/tokens/app_typography.dart';
import '../libre/barra_libre_page.dart';
import 'widgets/croqueta_del_dia.dart';
import 'widgets/tarjeta_cata.dart';

/// LA VITRINA — donde se guarda lo que ha catado tu gente.
class VitrinaPage extends ConsumerWidget {
  const VitrinaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Cata> feed = ref.watch(feedProvider);

    // Dos vacíos que no son el mismo:
    //
    // - Sin una sola cata: es el primer día. Sobra todo lo que sirve para
    //   manejar una lista —el filtro de tres opciones, el título de sección,
    //   la cuenta— porque no hay lista. Y sobre todo: con todo eso puesto, la
    //   única frase que dice qué hacer se iba por debajo del pliegue.
    // - Con catas pero ninguna en este filtro: ahí el filtro es justo lo que
    //   hay que dejar a mano, porque cambiarlo es la salida.
    final bool primerDia = ref.watch(catasProvider).isEmpty;
    final Cata? mejor = ref.watch(croquetaDelDiaProvider);
    final Map<String, Persona> personas = ref.watch(personasProvider);
    final FiltroVitrina filtro = ref.watch(filtroVitrinaProvider);
    final Perfil perfil = ref.watch(perfilProvider);

    return CustomScrollView(
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: MarcaCabecera(
            accion: BotonRedondo(
              icono: Icons.person_rounded,
              etiqueta: 'Tu perfil',
              onTap: () => context.go('/perfil'),
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: Cabecera(
            titulo: 'La Vitrina',
            subtitulo: 'Lo último que habéis catado',
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pantalla),
          sliver: SliverList(
            delegate: SliverChildListDelegate(<Widget>[
              const Pista(
                que: Visto.pistaVitrina,
                emoji: '🛎️',
                texto: 'Aquí aparece cada croqueta que catáis tú y tu gente, '
                    'de la más reciente a la más vieja. Toca una para ver la '
                    'ficha entera, o dale al botón rojo para apuntar la tuya.',
              ),
              Racha(
                semanas: perfil.racha,
                historial: perfil.semanas,
                catadaEstaSemana: perfil.catadaEstaSemana,
              ),
              const SizedBox(height: AppSpacing.m),
              if (mejor != null)
                CroquetaDelDia(
                  cata: mejor,
                  onTap: () => context.push('/cata/${mejor.id}'),
                ),
              const SizedBox(height: AppSpacing.l),
              const EntradaBarraLibre(),
              if (!primerDia) ...<Widget>[
                const SizedBox(height: AppSpacing.l),
                Segmentado<FiltroVitrina>(
                  seleccion: filtro,
                  onCambio: (FiltroVitrina f) =>
                      ref.read(filtroVitrinaProvider.notifier).state = f,
                  opciones: const <FiltroVitrina, String>{
                    FiltroVitrina.todo: 'Todo',
                    FiltroVitrina.misMesas: 'Mis mesas',
                    FiltroVitrina.mias: 'Mías',
                  },
                ),
                TituloSeccion(
                  texto: 'Últimas catas',
                  pastilla: ChipCata(
                    texto: '${feed.length} catas',
                    color: AppColors.menta,
                  ),
                ),
              ],
            ]),
          ),
        ),
        if (feed.isEmpty)
          SliverToBoxAdapter(child: _VitrinaVacia(primerDia: primerDia))
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pantalla),
            sliver: SliverList.separated(
              itemCount: feed.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.m),
              itemBuilder: (BuildContext context, int i) {
                final Cata cata = feed[i];
                return Entrada(
                  key: ValueKey<String>(cata.id),
                  indice: i,
                  child: TarjetaCata(
                    cata: cata,
                    autor: personas[cata.autorId] ?? Persona.desconocida,
                    onTap: () => context.push('/cata/${cata.id}'),
                  ),
                );
              },
            ),
          ),
        const SliverToBoxAdapter(
          child: SizedBox(height: AppSpacing.huecoBarra),
        ),
      ],
    );
  }
}

class _VitrinaVacia extends StatelessWidget {
  const _VitrinaVacia({required this.primerDia});

  /// Si no hay ni una cata en toda la app, o sólo ninguna en este filtro.
  final bool primerDia;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pantalla,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        children: <Widget>[
          // El primer día el dibujo va más pequeño: con 150 empujaba la única
          // frase que dice qué hacer por debajo del pliegue, y había que
          // hacer scroll para enterarse de cómo se empieza.
          Croqui(ancho: primerDia ? 110 : 150),
          const SizedBox(height: AppSpacing.l),
          Text(
            primerDia
                ? 'Aquí irán tus croquetas.\nDale al botón rojo y apunta la '
                    'primera.'
                : 'Ninguna cata con este filtro.\nPrueba con «Todo».',
            textAlign: TextAlign.center,
            style: AppTypography.cuerpo,
          ),
        ],
      ),
    );
  }
}
