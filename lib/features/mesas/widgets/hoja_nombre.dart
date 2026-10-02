import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/yo_provider.dart';
import '../../../core/services/nube_service.dart';
import '../../../core/theme/components/boton.dart';
import '../../../core/theme/components/campo.dart';
import '../../../core/theme/tokens/app_colors.dart';
import '../../../core/theme/tokens/app_shape.dart';
import '../../../core/theme/tokens/app_spacing.dart';
import '../../../core/theme/tokens/app_typography.dart';

/// Pregunta con qué nombre quieres que te vea tu gente.
///
/// Sale al entrar en una mesa compartida y al activar el código de una mesa
/// propia, que son los dos únicos momentos en que tu nombre deja de ser cosa
/// tuya y pasa a leerlo alguien más.
///
/// Antes de esto, el nombre por defecto era «Tú»: perfecto en tu propio móvil
/// y absurdo en el de los demás, donde la mitad de la mesa salía como
/// «Alguien» y la otra mitad habría salido como «Tú». Una mesa en la que no
/// sabes quién es quién no es una mesa.
///
/// Sólo se pregunta una vez. Quien ya se haya puesto nombre en el perfil no
/// vuelve a ver esta hoja.
Future<void> hojaNombre(
  BuildContext context,
  WidgetRef ref, {
  required String motivo,
}) async {
  if (ref.read(yoProvider).tieneNombrePropio) return;

  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    // Sin nombre, en la mesa sales como «Alguien». Se puede saltar, pero no
    // con un gesto distraído.
    isDismissible: false,
    enableDrag: false,
    builder: (BuildContext _) => _HojaNombre(motivo: motivo),
  );
}

class _HojaNombre extends ConsumerStatefulWidget {
  const _HojaNombre({required this.motivo});

  /// Por qué se está preguntando, en una línea.
  final String motivo;

  @override
  ConsumerState<_HojaNombre> createState() => _HojaNombreState();
}

class _HojaNombreState extends ConsumerState<_HojaNombre> {
  String _nombre = '';
  bool _guardando = false;

  Future<void> _guardar() async {
    final String limpio = _nombre.trim();
    if (limpio.isEmpty || _guardando) return;

    setState(() => _guardando = true);
    await ref.read(yoProvider.notifier).ponerNombre(limpio);

    // Al servidor, para que a tu gente le salga ya. Si falla no se avisa: el
    // nombre está guardado en el móvil y se vuelve a publicar solo.
    await NubeService.publicarNombre(limpio);

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom +
            MediaQuery.paddingOf(context).bottom,
      ),
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.s),
        padding: const EdgeInsets.all(AppSpacing.l),
        decoration: BoxDecoration(
          color: AppColors.fondo,
          borderRadius: BorderRadius.circular(AppShape.radioXL),
          border: Border.all(color: AppColors.tinta, width: AppShape.borde),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('¿Cómo te llamamos?', style: AppTypography.tituloM),
            const SizedBox(height: 6),
            Text(
              widget.motivo,
              style: AppTypography.cuerpoS.copyWith(
                color: AppColors.tintaSuave,
                height: 1.35,
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            Campo(
              etiqueta: 'Tu nombre',
              valor: _nombre,
              pista: 'Eme',
              autofoco: true,
              onCambio: (String v) => setState(() => _nombre = v),
            ),
            const SizedBox(height: AppSpacing.m),
            Text(
              'Es el nombre con el que aparecerás en todas tus mesas. '
              'Puedes cambiarlo cuando quieras en tu perfil.',
              style: AppTypography.cuerpoS.copyWith(
                fontSize: 12.5,
                height: 1.3,
                color: AppColors.tintaSuave,
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            BotonPegatina(
              texto: _guardando ? 'Guardando…' : 'Listo',
              color: AppColors.menta,
              onTap: _nombre.trim().isEmpty || _guardando ? null : _guardar,
            ),
            const SizedBox(height: AppSpacing.s),
            BotonPegatina.fantasma(
              texto: 'Ahora no',
              pequeno: true,
              onTap: _guardando ? null : () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
