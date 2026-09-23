import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../arte/croqui.dart';
import '../../core/models/cata.dart';
import '../../core/models/dieta.dart';
import '../../core/models/persona.dart';
import '../../core/providers/catas_provider.dart';
import '../../core/providers/mi_dieta_provider.dart';
import '../../core/theme/components/cabecera.dart';
import '../../core/theme/components/campo.dart';
import '../../core/theme/components/chip.dart';
import '../../core/theme/components/entrada.dart';
import '../../core/theme/components/pegatina.dart';
import '../../core/theme/components/pildoras_dieta.dart';
import '../../core/theme/tokens/app_colors.dart';
import '../../core/theme/tokens/app_shape.dart';
import '../../core/theme/tokens/app_spacing.dart';
import '../../core/theme/tokens/app_typography.dart';
import '../vitrina/widgets/tarjeta_cata.dart';

/// BARRA LIBRE — las croquetas que valen para quien no puede con todo.
///
/// Es una pantalla aparte y no un filtro más del feed a propósito. Quien no
/// come gluten no quiere ver veinte croquetas que no puede probar y buscar la
/// suya entre ellas: quiere entrar en un sitio donde todo lo que hay le vale.
///
/// Aquí sólo entran las catas que alguien marcó. Una cata sin dietas
/// apuntadas no aparece: que nadie lo mirara no es lo mismo que que valga.
class BarraLibrePage extends ConsumerStatefulWidget {
  const BarraLibrePage({super.key});

  @override
  ConsumerState<BarraLibrePage> createState() => _BarraLibrePageState();
}

class _BarraLibrePageState extends ConsumerState<BarraLibrePage> {
  @override
  void initState() {
    super.initState();
    // Abrir esta pantalla filtrada por lo tuyo es todo el sentido de haber
    // dicho cómo comes. Sólo la primera vez y sólo si no hay filtro puesto:
    // si vuelves después de tocar las pastillas, manda lo que tocaste.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final Set<Dieta> mias = ref.read(miDietaProvider);
      if (mias.isEmpty) return;
      if (ref.read(filtroDietaProvider).isNotEmpty) return;
      ref.read(filtroDietaProvider.notifier).state = mias;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Set<Dieta> filtro = ref.watch(filtroDietaProvider);
    final List<Cata> catas = ref.watch(catasLibresProvider);
    final Map<Dieta, int> recuento = ref.watch(recuentoDietasProvider);
    final Map<String, Persona> personas = ref.watch(personasProvider);

    void alternar(Dieta d) {
      final Set<Dieta> nuevo = <Dieta>{...filtro};
      nuevo.contains(d) ? nuevo.remove(d) : nuevo.add(d);
      ref.read(filtroDietaProvider.notifier).state = nuevo;
    }

    return CustomScrollView(
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Cabecera(
            titulo: 'Barra Libre',
            subtitulo: 'Sin gluten, sin lactosa, sin drama',
            // `pop` y no `go('/')`: a esta pantalla se llega empujándola
            // desde La Vitrina, así que volver es deshacer ese paso.
            volver: () => context.pop(),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pantalla),
          sliver: SliverList(
            delegate: SliverChildListDelegate(<Widget>[
              Pegatina(
                color: AppColors.menta,
                lunares: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const EtiquetaPanel(texto: 'Qué es esto'),
                    const SizedBox(height: AppSpacing.m),
                    Text(
                      'Croquetas de las que alguien de tus mesas preguntó de '
                      'qué estaban hechas. Filtra por lo tuyo y vete sobre '
                      'seguro… hasta la puerta del bar.',
                      style: AppTypography.cuerpo.copyWith(
                        color: AppColors.tinta,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    const AvisoAlergias(),
                  ],
                ),
              ),

              TituloSeccion(
                texto: 'Filtra por lo tuyo',
                // Una `OpcionPildora` y no un chip: el chip medía 27 px de
                // alto y esto es un botón, no una etiqueta.
                pastilla: filtro.isEmpty
                    ? null
                    : OpcionPildora(
                        texto: 'Quitar filtros',
                        emoji: '✕',
                        activa: false,
                        onTap: () => ref
                            .read(filtroDietaProvider.notifier)
                            .state = const <Dieta>{},
                      ),
              ),
              PildorasDieta(
                marcadas: filtro,
                onAlternar: alternar,
                recuento: recuento,
              ),

              TituloSeccion(
                texto: filtro.isEmpty ? 'Todas las aptas' : 'Te valen',
                pastilla: ChipCata(
                  texto: catas.length == 1 ? '1 cata' : '${catas.length} catas',
                  color: AppColors.lima,
                ),
              ),
            ]),
          ),
        ),
        if (catas.isEmpty)
          SliverToBoxAdapter(child: _Vacia(filtro: filtro))
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pantalla),
            sliver: SliverList.separated(
              itemCount: catas.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.m),
              itemBuilder: (BuildContext context, int i) {
                final Cata cata = catas[i];
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

class _Vacia extends StatelessWidget {
  const _Vacia({required this.filtro});

  final Set<Dieta> filtro;

  @override
  Widget build(BuildContext context) {
    final bool porFiltro = filtro.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pantalla,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        children: <Widget>[
          const Croqui(ancho: 150, conProps: false),
          const SizedBox(height: AppSpacing.l),
          Text(
            porFiltro
                ? 'Nadie ha catado todavía una croqueta que cumpla eso.\n'
                    'Si la encuentras, apúntala y la estrenas tú.'
                : 'Aquí no hay nada todavía.\nContestad en el formulario '
                    'cómo está hecha una croqueta y aparece sola.',
            textAlign: TextAlign.center,
            style: AppTypography.cuerpo,
          ),
        ],
      ),
    );
  }
}

/// La entrada a la Barra Libre desde el feed.
///
/// Va en La Vitrina y no en una quinta pestaña: la barra de abajo tiene cuatro
/// destinos y el botón de añadir, y meter un quinto icono para una sección
/// que no todo el mundo usa a diario empeoraría los cuatro que sí.
class EntradaBarraLibre extends ConsumerWidget {
  const EntradaBarraLibre({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int total = ref.watch(totalLibresProvider);
    final int? paraMi = ref.watch(totalParaMiProvider);

    // Tres frases para tres situaciones distintas. La de antes ("N croquetas
    // aptas") decía "aptas" sin decir para quién, que en esta sección es
    // justo lo que no se puede hacer: quien la usa se fía para decidir qué
    // se come.
    final String pie;
    if (total == 0) {
      pie = 'Veganas, sin gluten, sin lactosa';
    } else if (paraMi == null) {
      pie = '$total con la receta apuntada';
    } else if (paraMi == 0) {
      pie = 'Ninguna de las $total te vale aún';
    } else {
      pie = '$paraMi te valen de $total apuntadas';
    }

    // El menta pasa del bloque entero a la pastilla del icono: como
    // rectángulo verde a ancho completo era el cuarto de la misma pantalla y
    // le quitaba protagonismo a la croqueta del día.
    return Pegatina(
      color: AppColors.superficie,
      lunares: true,
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      onTap: () => context.push('/libre'),
      child: Row(
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              // Antes era crema sobre el menta del bloque. Ahora que el
              // bloque es blanco, la crema desaparecería: el verde se muda
              // aquí, que es donde queda como acento y no como grito.
              color: AppColors.menta,
              borderRadius: BorderRadius.circular(AppShape.radioM),
              border: Border.all(
                color: AppColors.tinta,
                width: AppShape.bordeFino,
              ),
            ),
            child: const Text('🌱', style: TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Barra Libre',
                  style: AppTypography.tituloS.copyWith(
                    color: AppColors.tinta,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  pie,
                  style: AppTypography.cuerpoS.copyWith(
                    fontSize: 12.5,
                    color: AppColors.tinta,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: AppColors.tinta,
          ),
        ],
      ),
    );
  }
}
