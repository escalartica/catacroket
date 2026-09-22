import 'dart:ui' as ui show PathMetric;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_motion.dart';
import '../tokens/app_shape.dart';
import '../tokens/app_spacing.dart';

/// La superficie base de toda la app: bloque de color con contorno de tinta y
/// sombra maciza desplazada.
///
/// Cuando es pulsable se hunde: se desplaza exactamente lo que mide su sombra
/// y la sombra desaparece, así que el bloque acaba justo donde estaba su
/// propia sombra. Es el mismo truco que usa una pegatina de verdad al
/// apretarla contra el papel, y por eso el movimiento tiene que ser EXACTO;
/// si el desplazamiento y la sombra no coinciden, el elemento parece saltar.
///
/// El hundimiento ocurre en `onTapDown`, no al soltar. Esperar al `onTap`
/// añade el tiempo de reacción del usuario a la respuesta de la interfaz y se
/// percibe como lag aunque el código sea instantáneo.
class Pegatina extends StatefulWidget {
  const Pegatina({
    super.key,
    required this.child,
    this.color = AppColors.superficie,
    this.radio = AppShape.radioL,
    this.sombra = AppShape.sombraNormal,
    this.padding = const EdgeInsets.all(AppSpacing.l),
    this.onTap,
    this.ancho,
    this.alto,
    this.discontinuo = false,
    this.lunares = false,
    this.colorLunares,
    this.alineacion,
    this.haptica = true,
  });

  final Widget child;
  final Color color;
  final double radio;
  final Offset sombra;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final double? ancho;
  final double? alto;

  /// Contorno a trazos. Se usa en las zonas que invitan a añadir algo (una
  /// mesa nueva, una foto) para distinguirlas de las que ya tienen contenido.
  final bool discontinuo;

  /// Trama de lunares blancos por encima del color. Sólo en los bloques
  /// grandes de color plano; sobre superficies claras no se ve y ensucia.
  final bool lunares;
  final Color? colorLunares;

  final AlignmentGeometry? alineacion;
  final bool haptica;

  @override
  State<Pegatina> createState() => _PegatinaState();
}

class _PegatinaState extends State<Pegatina> {
  bool _hundida = false;

  void _marcar(bool valor) {
    if (_hundida != valor) setState(() => _hundida = valor);
  }

  @override
  Widget build(BuildContext context) {
    final bool pulsable = widget.onTap != null;
    final BorderRadius radio = BorderRadius.circular(widget.radio);

    Widget contenido = ClipRRect(
      borderRadius: radio,
      child: Stack(
        // passthrough y no el `loose` por defecto: con loose, el contenido se
        // encogía a su tamaño mínimo y quedaba arriba-izquierda dentro de la
        // pegatina en vez de ocupar el ancho que le corresponde.
        fit: StackFit.passthrough,
        children: <Widget>[
          if (widget.lunares)
            Positioned.fill(
              child: CustomPaint(
                painter: _LunaresPainter(
                  widget.colorLunares ?? Colors.white.withValues(alpha: 0.28),
                ),
              ),
            ),
          Padding(padding: widget.padding, child: widget.child),
        ],
      ),
    );

    if (widget.alineacion != null) {
      contenido = Align(alignment: widget.alineacion!, child: contenido);
    }

    final Widget caja = AnimatedContainer(
      duration: AppMotion.pulsacion,
      curve: AppMotion.suave,
      width: widget.ancho,
      height: widget.alto,
      transform: Matrix4.translationValues(
        _hundida ? widget.sombra.dx : 0,
        _hundida ? widget.sombra.dy : 0,
        0,
      ),
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: radio,
        border: widget.discontinuo
            ? null
            : Border.all(color: AppColors.tinta, width: AppShape.borde),
        // Una pegatina transparente no proyecta sombra: el bloque de tinta
        // no tendría relleno que lo tapara y se vería entero.
        boxShadow: (_hundida || widget.color.a == 0)
            ? AppShape.sinSombra
            : AppShape.sombra(widget.sombra),
      ),
      child: widget.discontinuo
          ? CustomPaint(
              painter: _TrazosPainter(radio: widget.radio),
              child: contenido,
            )
          : contenido,
    );

    if (!pulsable) return caja;

    // Una pegatina pulsable es un botón, y hay que decirlo: sin esto
    // VoiceOver lee la tarjeta de una cata como un párrafo suelto y no
    // anuncia que se pueda abrir. Es la mitad de lo que se toca en esta app.
    return Semantics(
      button: true,
      container: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          _marcar(true);
          if (widget.haptica) HapticFeedback.selectionClick();
        },
        onTapUp: (_) => _marcar(false),
        onTapCancel: () => _marcar(false),
        onTap: widget.onTap,
        child: caja,
      ),
    );
  }
}

class _LunaresPainter extends CustomPainter {
  const _LunaresPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint pincel = Paint()..color = color;
    const double paso = 20;
    const double radio = 2.6;
    for (double y = paso / 2; y < size.height + paso; y += paso) {
      final double desvio = ((y / paso).round() % 2) * paso / 2;
      for (double x = desvio; x < size.width + paso; x += paso) {
        canvas.drawCircle(Offset(x, y), radio, pincel);
      }
    }
  }

  @override
  bool shouldRepaint(_LunaresPainter viejo) => viejo.color != color;
}

class _TrazosPainter extends CustomPainter {
  const _TrazosPainter({required this.radio});

  final double radio;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint pincel = Paint()
      ..color = AppColors.tinta
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppShape.borde;

    final Path contorno = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            AppShape.borde / 2,
            AppShape.borde / 2,
            size.width - AppShape.borde,
            size.height - AppShape.borde,
          ),
          Radius.circular(radio),
        ),
      );

    // Se recorre el contorno cortándolo en trazos de 9 con huecos de 7.
    for (final ui.PathMetric tramo in contorno.computeMetrics()) {
      double recorrido = 0;
      while (recorrido < tramo.length) {
        final double fin = (recorrido + 9).clamp(0, tramo.length);
        canvas.drawPath(tramo.extractPath(recorrido, fin), pincel);
        recorrido = fin + 7;
      }
    }
  }

  @override
  bool shouldRepaint(_TrazosPainter viejo) => viejo.radio != radio;
}

/// Fondo de la app: crema con lunares. Va detrás de todas las pantallas.
class FondoLunares extends StatelessWidget {
  const FondoLunares({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.fondo,
      child: CustomPaint(
        painter: const _FondoPainter(),
        child: child,
      ),
    );
  }
}

class _FondoPainter extends CustomPainter {
  const _FondoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint pincel = Paint()..color = AppColors.fondoPuntos;
    const double paso = 22;
    for (double y = 0; y < size.height + paso; y += paso) {
      for (double x = 0; x < size.width + paso; x += paso) {
        canvas.drawCircle(Offset(x, y), 2.6, pincel);
      }
    }
  }

  @override
  bool shouldRepaint(_FondoPainter viejo) => false;
}
