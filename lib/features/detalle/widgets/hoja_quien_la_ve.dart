import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/cata.dart';
import '../../../core/models/mesa.dart';
import '../../../core/providers/catas_provider.dart';
import '../../../core/providers/mesas_provider.dart';
import '../../../core/theme/components/boton.dart';
import '../../../core/theme/components/quien_la_ve.dart';
import '../../mesas/widgets/hoja_mesa.dart';
import '../../../core/theme/tokens/app_colors.dart';
import '../../../core/theme/tokens/app_shape.dart';
import '../../../core/theme/tokens/app_spacing.dart';
import '../../../core/theme/tokens/app_typography.dart';

/// Cambiar a quién le enseñas una cata que ya tienes apuntada.
///
/// Antes esto no existía: la cata nacía en un sitio y ahí se quedaba, y la
/// única forma de moverla era abrir la corrección entera y pasar por los
/// cuatro pasos. Lo normal, en cambio, es apuntar la croqueta en el bar para
/// ti y decidir después si la enseñas; esa es justo la decisión que no se
/// podía cambiar.
Future<void> hojaQuienLaVe(
  BuildContext context,
  WidgetRef ref,
  Cata cata,
) async {
  await showModalBottomSheet<void>(
    context: context,
    // Por el Navigator raíz: la ficha de una cata vive dentro de la concha, y
    // sin esto la barra de pestañas se dibuja encima de la hoja y le tapa el
    // botón de «Listo». Se abría, se tocaban las mesas y no había forma de
    // guardar.
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext _) => _Hoja(cataId: cata.id),
  );
}

class _Hoja extends ConsumerStatefulWidget {
  const _Hoja({required this.cataId});

  final String cataId;

  @override
  ConsumerState<_Hoja> createState() => _HojaState();
}

class _HojaState extends ConsumerState<_Hoja> {
  late List<String> _elegidas =
      <String>[...?ref.read(cataProvider(widget.cataId))?.mesas];
  bool _guardando = false;
  String? _fallo;

  Future<void> _guardar() async {
    if (_guardando) return;
    final Cata? cata = ref.read(cataProvider(widget.cataId));
    if (cata == null) return;

    setState(() => _guardando = true);
    try {
      // `actualizar` ya se encarga de subirla a las mesas nuevas y de
      // borrarla de las que se han quitado.
      final bool guardado = await ref
          .read(catasProvider.notifier)
          .actualizar(cata.copyWith(mesas: _elegidas));

      if (!mounted) return;

      // Si no ha llegado al disco, la hoja NO se cierra. Antes se cerraba
      // igual, vibraba confirmando y el panel de detrás se ponía en verde
      // diciendo «la ve tu gente»: el usuario se quedaba convencido de algo
      // que no había pasado y que al reiniciar no estaba.
      if (!guardado) {
        setState(() => _fallo =
            'No se ha podido guardar. Mira si al móvil le queda sitio y '
            'vuelve a intentarlo.');
        return;
      }

      await HapticFeedback.mediumImpact();
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Mesa> mesas = ref.watch(mesasProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.8,
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.pantalla,
        AppSpacing.l,
        AppSpacing.pantalla,
        AppSpacing.l + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppShape.radioXL),
        ),
        border: Border(
          top: BorderSide(color: AppColors.tinta, width: AppShape.borde),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  QuienLaVe(
                    titulo: '¿Quién ve esta cata?',
                    mesas: mesas,
                    elegidas: _elegidas,
                    onAlternar: (String id) => setState(() {
                      if (!_elegidas.remove(id)) _elegidas.add(id);
                    }),
                    onSoloYo: () => setState(() => _elegidas = <String>[]),
                    onCrearMesa: () async {
                      final Mesa? nueva = await hojaMesa(context);
                      if (nueva != null && mounted) {
                        setState(() => _elegidas.add(nueva.id));
                      }
                    },
                  ),
                  if (_fallo != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.m),
                    Semantics(
                      liveRegion: true,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.tomate,
                          borderRadius: BorderRadius.circular(AppShape.radioM),
                          border: Border.all(
                            color: AppColors.tinta,
                            width: AppShape.bordeFino,
                          ),
                        ),
                        child: Text(
                          _fallo!,
                          style: AppTypography.cuerpoS.copyWith(
                            color: AppColors.textoSobre(AppColors.tomate),
                            height: 1.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.m),
                  Text(
                    'Quitarla de una mesa no la borra: sigue siendo tuya y '
                    'sigue en tu diario. Lo que deja de pasar es que la vea '
                    'esa gente.',
                    style: AppTypography.cuerpoS.copyWith(
                      fontSize: 12.5,
                      color: AppColors.tintaSuave,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          BotonPegatina(
            texto: _guardando ? 'Guardando…' : 'Listo',
            onTap: _guardando ? null : _guardar,
          ),
        ],
      ),
    );
  }
}
