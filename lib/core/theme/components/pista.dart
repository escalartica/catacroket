import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/visto_provider.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_shape.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

/// Una explicación corta la primera vez que entras a un apartado.
///
/// El problema que resuelve: un feed de tarjetas, un mapa con globos y una
/// lista de mesas no dicen para qué son. Se entienden cuando ya sabes lo que
/// haces, que es justo lo que no pasa el primer día.
///
/// Y lo que NO hace: quedarse. Un cartel explicativo permanente es una
/// disculpa por una pantalla que no se explica sola, y al décimo día es
/// estorbo. Se lee, se cierra y no vuelve. Se pueden recuperar todas desde
/// Perfil.
///
/// Tampoco grita. Iba en azul a plena saturación, igual de fuerte que el
/// contenido al que acompañaba, así que en La Vitrina competía con la
/// croqueta del día. Una explicación de paso no puede pesar lo mismo que
/// aquello que explica: va en superficie cálida y el color se lo queda el
/// emoji.
class Pista extends ConsumerStatefulWidget {
  const Pista({
    super.key,
    required this.que,
    required this.emoji,
    required this.texto,
    this.color = AppColors.superficieCalida,
  });

  /// Cuál es, para acordarse de que ya se cerró.
  final Visto que;

  final String emoji;
  final String texto;
  final Color color;

  @override
  ConsumerState<Pista> createState() => _PistaState();
}

class _PistaState extends ConsumerState<Pista> {
  /// Se ha tocado el aspa y todavía se está yendo.
  ///
  /// Sin esto, al marcar el cartel como visto desaparecía de golpe y todo lo
  /// de debajo pegaba un salto hacia arriba. El movimiento aquí no es adorno:
  /// es lo que evita que se pierda el sitio donde estabas mirando.
  bool _cerrando = false;

  static const Duration _duracion = Duration(milliseconds: 220);

  void _cerrar() {
    final bool quieto = MediaQuery.disableAnimationsOf(context);
    if (quieto) {
      ref.read(vistoProvider.notifier).marcar(widget.que);
      return;
    }

    setState(() => _cerrando = true);
    // Se marca al terminar, no al empezar: si se marcara antes, el provider
    // lo quitaría del árbol al momento y no habría nada que animar.
    Future<void>.delayed(_duracion, () {
      if (mounted) ref.read(vistoProvider.notifier).marcar(widget.que);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(tocaEnsenarProvider(widget.que))) {
      return const SizedBox.shrink();
    }

    return AnimatedSize(
      duration: _duracion,
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedOpacity(
        opacity: _cerrando ? 0 : 1,
        duration: _duracion,
        curve: Curves.easeOutCubic,
        child: _cerrando ? const SizedBox(width: double.infinity) : _cartel,
      ),
    );
  }

  Widget get _cartel => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.m),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(AppShape.radioM),
            border:
                Border.all(color: AppColors.tinta, width: AppShape.bordeFino),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(widget.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.texto,
                  style: AppTypography.cuerpoS.copyWith(
                    height: 1.35,
                    color: AppColors.tinta,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Semantics(
                button: true,
                label: 'Entendido, no volver a enseñar esto',
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _cerrar,
                  // 44x44 de zona tocable aunque el aspa se vea pequeña.
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.tinta,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
