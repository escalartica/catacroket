import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/mesa.dart';
import '../../../core/providers/borrador_provider.dart';
import '../../../core/providers/mesas_provider.dart';
import '../../../core/theme/components/campo.dart';
import '../widgets/selector_gente.dart';
import '../widgets/selector_receta.dart';
import '../../../core/theme/tokens/app_spacing.dart';
import '../../../core/theme/tokens/app_typography.dart';

/// Paso 4: lo que rodea a la cata. Todo es opcional a propósito; lo
/// imprescindible ya se pidió en los tres pasos anteriores.
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
        const SelectorReceta(),
        const SizedBox(height: AppSpacing.xl),

        Campo(
          etiqueta: 'Precio por croqueta',
          valor: borrador.precio,
          pista: '2,20',
          teclado: const TextInputType.numberWithOptions(decimal: true),
          onCambio: notifier.precio,
        ),
        const SizedBox(height: AppSpacing.l),

        Text('GUARDAR EN', style: AppTypography.antetitulo),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final Mesa m in mesas)
              OpcionPildora(
                texto: m.nombre,
                color: Color(m.colorHex),
                activa: borrador.mesaId == m.id,
                onTap: () => notifier.mesa(m.id),
              ),
          ],
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
