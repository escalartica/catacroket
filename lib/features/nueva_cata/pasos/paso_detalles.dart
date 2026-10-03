import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/mesa.dart';
import '../../../core/providers/borrador_provider.dart';
import '../../../core/providers/mesas_provider.dart';
import '../../../core/theme/components/campo.dart';
import '../../../core/theme/components/quien_la_ve.dart';
import '../../mesas/widgets/hoja_mesa.dart';
import '../widgets/selector_gente.dart';
import '../widgets/selector_receta.dart';
import '../../../core/theme/tokens/app_spacing.dart';

/// Paso 4: quién la ve, y lo que rodea a la cata.
///
/// «Quién la ve» va DELANTE de todo lo demás. Estaba enterrado a media
/// pantalla, entre el precio y la nota, con el título «GUARDAR EN» en letra
/// pequeña: la única decisión de este paso que cambia algo para otra persona
/// parecía un campo opcional más, y la gente apuntaba su croqueta sin
/// enterarse de que su mesa no la iba a ver. El resto de este paso sí es
/// opcional de verdad.
class PasoDetalles extends ConsumerWidget {
  const PasoDetalles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Borrador borrador = ref.watch(borradorProvider);
    final BorradorNotifier notifier = ref.read(borradorProvider.notifier);
    final List<Mesa> mesas = ref.watch(mesasProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        QuienLaVe(
          mesas: mesas,
          elegidas: borrador.mesas,
          onAlternar: notifier.alternarMesa,
          onSoloYo: notifier.soloParaMi,
          // Crear la mesa desde aquí, sin abandonar la croqueta a medias:
          // en este formulario la barra de pestañas está escondida, así que
          // «créala en Mesas» mandaba a un sitio al que no se podía ir.
          onCrearMesa: () async {
            final Mesa? nueva = await hojaMesa(context);
            if (nueva != null) notifier.alternarMesa(nueva.id);
          },
        ),
        const SizedBox(height: AppSpacing.xl),

        const SelectorReceta(),
        const SizedBox(height: AppSpacing.xl),

        Campo(
          etiqueta: 'Precio por croqueta',
          valor: borrador.precio,
          pista: 'Lo que cuesta una croqueta',
          teclado: const TextInputType.numberWithOptions(decimal: true),
          onCambio: notifier.precio,
        ),
        const SizedBox(height: AppSpacing.l),

        const SelectorGente(),
        const SizedBox(height: AppSpacing.l),

        Campo(
          etiqueta: 'Tu nota',
          valor: borrador.nota,
          pista: 'Qué te ha dado, qué le falta, si volverías…',
          lineas: 4,
          onCambio: notifier.nota,
        ),
      ],
    );
  }
}
