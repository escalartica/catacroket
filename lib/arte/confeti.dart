import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/tokens/app_colors.dart';

/// Lluvia de migas al publicar una cata.
///
/// Se dispara una vez y se retira sola. No es un `Overlay` permanente: vive
/// dentro de la pantalla de "publicada" y muere con ella, así que no puede
/// quedarse animando de fondo y comiéndose la batería.
class Confeti extends StatefulWidget {
  const Confeti({super.key, this.piezas = 40});

  final int piezas;

  @override
  State<Confeti> createState() => _ConfetiState();
}

class _ConfetiState extends State<Confeti> with SingleTickerProviderStateMixin {
  late final AnimationController _control = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  late final List<_Miga> _migas;

  static const List<Color> _colores = <Color>[
    AppColors.sol,
    AppColors.tomate,
    AppColors.menta,
    AppColors.uva,
    AppColors.cielo,
    AppColors.chicle,
    AppColors.lima,
  ];

  @override
  void initState() {
    super.initState();
    final math.Random azar = math.Random();
    _migas = List<_Miga>.generate(widget.piezas, (int i) {
      return _Miga(
        origen: Offset(0.5 + azar.nextDouble() * 0.3 - 0.15, 0.34),
        destino: Offset(azar.nextDouble() * 300 - 150, azar.nextDouble() * 260 - 60),
        giro: azar.nextDouble() * 12 - 6,
        retraso: azar.nextDouble() * 0.16,
        color: _colores[azar.nextInt(_colores.length)],
      );
    });

    if (!_reducirMovimiento) _control.forward();
  }

  bool get _reducirMovimiento =>
      WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;

  @override
  void dispose() {
    _control.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_reducirMovimiento) return const SizedBox.shrink();

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _control,
        builder: (BuildContext context, Widget? _) {
          return CustomPaint(
            painter: _ConfetiPainter(migas: _migas, avance: _control.value),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _Miga {
  const _Miga({
    required this.origen,
    required this.destino,
    required this.giro,
    required this.retraso,
    required this.color,
  });

  final Offset origen;
  final Offset destino;
  final double giro;
  final double retraso;
  final Color color;
}

class _ConfetiPainter extends CustomPainter {
  const _ConfetiPainter({required this.migas, required this.avance});

  final List<_Miga> migas;
  final double avance;

  @override
  void paint(Canvas canvas, Size size) {
    for (final _Miga m in migas) {
      final double t = ((avance - m.retraso) / (1 - m.retraso)).clamp(0.0, 1.0);
      if (t <= 0) continue;

      final double suave = Curves.easeOutCubic.transform(t);
      final Offset centro = Offset(
            m.origen.dx * size.width,
            m.origen.dy * size.height,
          ) +
          m.destino * suave;

      canvas.save();
      canvas.translate(centro.dx, centro.dy);
      canvas.rotate(m.giro * suave);

      final double lado = 5 + 7 * suave;
      final RRect pieza = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: lado, height: lado),
        const Radius.circular(2),
      );
      final double opacidad = (1 - t).clamp(0.0, 1.0);

      canvas.drawRRect(pieza, Paint()..color = m.color.withValues(alpha: opacidad));
      canvas.drawRRect(
        pieza,
        Paint()
          ..color = AppColors.tinta.withValues(alpha: opacidad)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfetiPainter viejo) => viejo.avance != avance;
}
