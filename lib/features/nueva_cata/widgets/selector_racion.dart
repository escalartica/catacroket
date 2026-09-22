import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/racion.dart';
import '../../../core/providers/borrador_provider.dart';
import '../../../core/theme/components/campo.dart';
import '../../../core/theme/tokens/app_colors.dart';
import '../../../core/theme/tokens/app_shape.dart';
import '../../../core/theme/tokens/app_spacing.dart';
import '../../../core/theme/tokens/app_typography.dart';

/// Cómo te la sirvieron: tapa, media ración o ración, y cuántas traía.
///
/// Va lo primero del paso porque es lo primero que sabes: lo dices al pedir,
/// antes incluso de probarla. Elegir formato propone sus unidades habituales
/// —una tapa suelen ser dos, una ración seis— para que en el caso normal no
/// haya que tocar el contador, pero el número que manda es el tuyo.
class SelectorRacion extends ConsumerWidget {
  const SelectorRacion({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Borrador b = ref.watch(borradorProvider);
    final BorradorNotifier n = ref.read(borradorProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('¿CÓMO TE LA HAN PUESTO?', style: AppTypography.antetitulo),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final Formato f in Formato.values)
              OpcionPildora(
                texto: f.nombre,
                emoji: f.emoji,
                activa: b.formato == f,
                colorActiva: AppColors.mango,
                onTap: () => n.formato(f),
              ),
          ],
        ),
        if (b.formato.seDijo) ...<Widget>[
          const SizedBox(height: AppSpacing.m),
          _Contador(
            valor: b.unidades,
            onCambio: n.unidades,
          ),
        ],
      ],
    );
  }
}

/// Cuántas croquetas. Menos y más, sin teclado.
///
/// Un campo de texto para un número entre uno y diez obliga a sacar el
/// teclado, tapar media pantalla y volver a cerrarlo. Dos botones no.
class _Contador extends StatelessWidget {
  const _Contador({required this.valor, required this.onCambio});

  final int valor;
  final ValueChanged<int> onCambio;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        // La etiqueta no repite el número: ya está dos centímetros a la
        // derecha, dentro del contador. Decirlo dos veces es ruido.
        Expanded(
          child: Text(
            '¿Cuántas traía?',
            style: AppTypography.tituloS.copyWith(fontSize: 16),
          ),
        ),
        Semantics(
          button: true,
          label: 'Una menos',
          child: _Tecla(
            icono: Icons.remove_rounded,
            activa: valor > 0,
            onTap: () => onCambio(valor - 1),
          ),
        ),
        Container(
          width: 52,
          alignment: Alignment.center,
          child: Text(
            '$valor',
            style: AppTypography.cifraM,
          ),
        ),
        Semantics(
          button: true,
          label: 'Una más',
          child: _Tecla(
            icono: Icons.add_rounded,
            activa: valor < 99,
            onTap: () => onCambio(valor + 1),
          ),
        ),
      ],
    );
  }
}

class _Tecla extends StatelessWidget {
  const _Tecla({
    required this.icono,
    required this.activa,
    required this.onTap,
  });

  final IconData icono;
  final bool activa;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: activa
          ? () {
              HapticFeedback.selectionClick();
              onTap();
            }
          : null,
      child: Container(
        width: 46,
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: activa ? AppColors.sol : AppColors.superficieCalida,
          borderRadius: BorderRadius.circular(AppShape.radioM),
          border: Border.all(color: AppColors.tinta, width: AppShape.borde),
          boxShadow: activa ? AppShape.sombra(const Offset(2, 2)) : null,
        ),
        child: Icon(
          icono,
          size: 22,
          color: activa ? AppColors.tinta : AppColors.tintaApagada,
        ),
      ),
    );
  }
}
