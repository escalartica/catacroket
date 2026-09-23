import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'cata_desde_borrador.dart';
import '../../core/models/cata.dart';
import '../../core/providers/borrador_provider.dart';
import '../../core/providers/catas_provider.dart';
import '../../core/theme/components/boton.dart';
import '../../core/theme/tokens/app_colors.dart';
import '../../core/theme/tokens/app_motion.dart';
import '../../core/theme/tokens/app_shape.dart';
import '../../core/theme/tokens/app_spacing.dart';
import '../../core/theme/tokens/app_typography.dart';
import 'pasos/paso_corte.dart';
import 'pasos/paso_detalles.dart';
import 'pasos/paso_sabores.dart';
import 'pasos/paso_sitio.dart';

/// Alta —y corrección— de una cata, en cuatro pasos.
///
/// Un paso, una decisión. Es la diferencia con el formulario largo de Palito,
/// que es justo lo que la gente decía no entender: aquí nunca hay más de una
/// cosa que rellenar a la vista, y el botón de abajo sólo se enciende cuando
/// ese paso está resuelto.
///
/// Corregir una cata usa esta misma pantalla con [cataId] puesto. Es a
/// propósito: dos formularios, uno para crear y otro para editar, es la forma
/// más segura de que acaben pidiendo cosas distintas.
class NuevaCataPage extends ConsumerStatefulWidget {
  const NuevaCataPage({super.key, this.cataId});

  /// Nulo para una cata nueva; el id de la cata cuando se está corrigiendo.
  final String? cataId;

  @override
  ConsumerState<NuevaCataPage> createState() => _NuevaCataPageState();
}

class _NuevaCataPageState extends ConsumerState<NuevaCataPage> {
  static const List<String> _titulos = <String>[
    '',
    '¿Dónde estás?',
    '¿Qué has pedido?',
    'El corte',
    'Los detalles',
  ];

  @override
  void initState() {
    super.initState();
    final String? id = widget.cataId;
    if (id == null) return;

    // Después del primer frame: cargar el borrador toca providers que esta
    // misma pantalla está observando, y hacerlo durante el build es lo que
    // provoca el clásico "setState during build".
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final Cata? cata = ref.read(cataProvider(id));
      if (cata == null) return;
      ref.read(borradorProvider.notifier).desdeCata(cata);
      ref.read(pasoProvider.notifier).state = 1;
    });
  }

  void _cerrar() {
    final String? id = ref.read(borradorProvider).editando;
    ref.read(borradorProvider.notifier).limpiar();
    ref.read(pasoProvider.notifier).state = 1;
    context.go(id == null ? '/' : '/cata/$id');
  }

  /// ¿Hay algo escrito que se perdería al salir?
  ///
  /// Se mira el contenido y no el paso: alguien puede estar en el paso 3 sin
  /// haber escrito nada (todo tiene valor por defecto) y entonces preguntar
  /// sobra. Al corregir se pregunta siempre, porque ahí lo escrito es de una
  /// cata que ya existe y no hay forma barata de saber si lo has cambiado.
  bool get _hayAlgoQuePerder {
    final Borrador b = ref.read(borradorProvider);
    if (b.esEdicion) return true;
    return b.sitio.trim().isNotEmpty ||
        b.ciudad.trim().isNotEmpty ||
        b.sabores.isNotEmpty ||
        b.medios.isNotEmpty ||
        b.nota.trim().isNotEmpty ||
        b.lugar != null;
  }

  /// Salir del formulario, preguntando si hay trabajo dentro.
  ///
  /// Cuatro pasos rellenos y un toque en la equis no pueden irse en silencio:
  /// es el único sitio de la app donde se pierde algo que costó escribir.
  Future<void> _intentarSalir() async {
    if (!_hayAlgoQuePerder) {
      _cerrar();
      return;
    }

    final bool salir = await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogo) => AlertDialog(
            backgroundColor: AppColors.superficie,
            title: Text(
              ref.read(borradorProvider).esEdicion
                  ? '¿Dejar los cambios?'
                  : '¿Dejar la cata a medias?',
            ),
            content: const Text('Lo que has escrito aquí no se guarda.'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogo).pop(false),
                child: const Text('Seguir'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogo).pop(true),
                child: const Text('Salir'),
              ),
            ],
          ),
        ) ??
        false;

    if (salir && mounted) _cerrar();
  }

  Future<void> _guardar() async {
    final Borrador b = ref.read(borradorProvider);
    final Cata? original = b.editando == null
        ? null
        : ref.read(cataProvider(b.editando!));

    // Estabas corrigiendo una cata que ya no está (la borraste en otra
    // pantalla). Guardar aquí crearía un duplicado con id nuevo, que es peor
    // que no guardar: mejor decirlo y salir.
    if (b.esEdicion && original == null) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('Esa cata ya no existe.')),
        );
      ref.read(borradorProvider.notifier).limpiar();
      ref.read(pasoProvider.notifier).state = 1;
      context.go('/');
      return;
    }

    // Las reglas de cómo se convierte un borrador en cata viven en
    // cata_desde_borrador.dart, donde se pueden probar.
    final Cata cata = cataDesdeBorrador(b, original: original);

    final CatasNotifier catas = ref.read(catasProvider.notifier);
    if (original == null) {
      await catas.anadir(cata);
      await HapticFeedback.heavyImpact();
    } else {
      await catas.actualizar(cata);
      await HapticFeedback.mediumImpact();
    }

    if (!mounted) return;
    ref.read(borradorProvider.notifier).limpiar();
    ref.read(pasoProvider.notifier).state = 1;

    // Una cata nueva merece confeti. Una corrección, no: lo que quieres es
    // ver cómo ha quedado.
    context.go(original == null ? '/publicada/${cata.id}' : '/cata/${cata.id}');
  }

  @override
  Widget build(BuildContext context) {
    final int paso = ref.watch(pasoProvider);
    final Borrador borrador = ref.watch(borradorProvider);
    final bool puede = borrador.puedeAvanzarDesde(paso);
    final bool ultimo = paso == 4;
    final bool editando = borrador.esEdicion;

    // El botón físico de Android cae aquí igual que la equis: si no, el
    // formulario se cierra solo y se lleva por delante cuatro pasos.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool salido, Object? resultado) {
        if (!salido) _intentarSalir();
      },
      child: Column(
      children: <Widget>[
        // ── Cabecera ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pantalla,
            AppSpacing.s,
            AppSpacing.pantalla,
            AppSpacing.m,
          ),
          child: Row(
            children: <Widget>[
              BotonRedondo(
                icono: Icons.arrow_back_ios_new_rounded,
                etiqueta: 'Atrás',
                onTap: () {
                  if (paso > 1) {
                    ref.read(pasoProvider.notifier).state = paso - 1;
                  } else {
                    _intentarSalir();
                  }
                },
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(_titulos[paso], style: AppTypography.tituloL),
                    Text(
                      editando
                          ? 'Corrigiendo · paso $paso de 4'
                          : 'Paso $paso de 4',
                      style: AppTypography.cuerpoS.copyWith(
                        fontSize: 12.5,
                        color: AppColors.tintaSuave,
                      ),
                    ),
                  ],
                ),
              ),
              BotonRedondo(
                icono: Icons.close_rounded,
                etiqueta: 'Cerrar',
                onTap: _intentarSalir,
              ),
            ],
          ),
        ),

        // ── Progreso ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pantalla),
          child: Row(
            children: <Widget>[
              for (int i = 1; i <= 4; i++)
                Expanded(
                  child: AnimatedContainer(
                    duration: AppMotion.normal,
                    height: 10,
                    margin: EdgeInsets.only(right: i == 4 ? 0 : 6),
                    decoration: BoxDecoration(
                      color: i <= paso ? AppColors.tomate : AppColors.superficie,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: AppColors.tinta,
                        width: AppShape.bordeFino,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // ── Paso ──────────────────────────────────────────────────────────
        //
        // El contenido se desvanece contra la barra de progreso en vez de
        // cortarse a cuchillo. Sin esto, una píldora a medio salir se veía
        // pegada al indicador de pasos y parecía un elemento roto: en las
        // capturas del móvil se confundía con un fallo de pintado.
        Expanded(
          child: ShaderMask(
            shaderCallback: (Rect area) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[Colors.transparent, Colors.black],
              stops: <double>[0.0, 0.035],
            ).createShader(area),
            blendMode: BlendMode.dstIn,
            child: AnimatedSwitcher(
            duration: AppMotion.rapida,
            child: SingleChildScrollView(
              key: ValueKey<int>(paso),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pantalla,
                AppSpacing.l,
                AppSpacing.pantalla,
                AppSpacing.xl,
              ),
              child: switch (paso) {
                1 => const PasoSitio(),
                2 => const PasoSabores(),
                3 => const PasoCorte(),
                _ => const PasoDetalles(),
              },
            ),
            ),
          ),
        ),

        // ── Acción ────────────────────────────────────────────────────────
        Container(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.pantalla,
            AppSpacing.m,
            AppSpacing.pantalla,
            AppSpacing.m + MediaQuery.paddingOf(context).bottom,
          ),
          decoration: const BoxDecoration(
            color: AppColors.superficie,
            border: Border(
              top: BorderSide(color: AppColors.tinta, width: AppShape.borde),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Un botón apagado sin explicación es un botón roto: el usuario
              // lo toca, no pasa nada y se queda mirando. Decir qué falta
              // cuesta una línea.
              if (!puede) ...<Widget>[
                Text(
                  _queFalta(paso),
                  textAlign: TextAlign.center,
                  style: AppTypography.cuerpoS.copyWith(
                    fontSize: 12.5,
                    color: AppColors.tintaSuave,
                  ),
                ),
                const SizedBox(height: AppSpacing.s),
              ],
              BotonPegatina(
            texto: !ultimo
                ? 'Siguiente'
                : editando
                    ? 'Guardar cambios'
                    : 'Publicar cata',
            color: ultimo ? AppColors.tomate : AppColors.sol,
            onTap: !puede
                ? null
                : () {
                    if (ultimo) {
                      _guardar();
                    } else {
                      ref.read(pasoProvider.notifier).state = paso + 1;
                    }
                  },
              ),
            ],
          ),
        ),
      ],
      ),
    );
  }

  /// Qué falta para poder seguir. Uno por paso, en la voz de la app.
  static String _queFalta(int paso) => switch (paso) {
        1 => 'Escribe al menos el nombre del sitio',
        2 => 'Elige al menos un relleno',
        _ => '',
      };
}
