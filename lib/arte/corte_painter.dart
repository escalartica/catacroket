import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/data/rellenos.dart';
import '../core/models/corte.dart';
import '../core/theme/tokens/app_colors.dart';
import '../core/utils/semilla.dart';

/// EL CORTE — el retrato de cada croqueta.
///
/// Esto es la idea de producto, no un adorno. Las cuatro notas de una cata se
/// convierten en un dibujo distinto para cada croqueta:
///
///   crujiente  -> grosor de la costra y cantidad de migas de panko
///   cremosidad -> claridad y saturación de la bechamel
///   sabor      -> cuánto vapor sube
///   relleno    -> cuántos trozos hay dentro, del color de su relleno
///
/// Resuelve además un problema real: las fotos de croquetas hechas en la
/// barra de un bar con mala luz son feas, y un feed de fotos feas no invita a
/// volver. Aquí el feed lo dibuja la app.
///
/// La posición de cada miga y cada trozo sale de [semillaDe] con el id de la
/// cata, así que el dibujo de una croqueta es SIEMPRE el mismo. Esa
/// estabilidad es lo que lo convierte en un retrato y no en ruido.
class ElCorte extends StatefulWidget {
  const ElCorte({
    super.key,
    required this.corte,
    required this.rellenoId,
    required this.semilla,
    this.vapor = true,
    this.animado = false,
    this.ancho,
  });

  final Corte corte;
  final String rellenoId;

  /// Normalmente el id de la cata.
  final String semilla;

  /// El vapor se apaga en los tamaños pequeños: a 46 px son tres rayas que
  /// sólo ensucian.
  final bool vapor;

  /// El vapor sube de verdad, en bucle. Sólo en los tamaños grandes: en una
  /// lista, veinte croquetas humeando a la vez marean y gastan batería.
  final bool animado;

  final double? ancho;

  static const double proporcion = 140 / 116;

  @override
  State<ElCorte> createState() => _ElCorteState();
}

class _ElCorteState extends State<ElCorte> with SingleTickerProviderStateMixin {
  AnimationController? _humo;

  @override
  void initState() {
    super.initState();
    _prepararHumo();
  }

  @override
  void didUpdateWidget(ElCorte anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.animado != widget.animado) _prepararHumo();
  }

  void _prepararHumo() {
    _humo?.dispose();
    _humo = null;
    if (widget.animado && widget.vapor) {
      _humo = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 3400),
      )..repeat();
    }
  }

  @override
  void dispose() {
    _humo?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool quieto = MediaQuery.disableAnimationsOf(context);
    final AnimationController? humo = quieto ? null : _humo;

    Widget pintar(double fase) => AspectRatio(
          aspectRatio: ElCorte.proporcion,
          child: CustomPaint(
            painter: _CortePainter(
              corte: widget.corte,
              relleno: Rellenos.de(widget.rellenoId).color,
              semilla: widget.semilla + widget.rellenoId,
              vapor: widget.vapor,
              fase: fase,
            ),
            isComplex: true,
          ),
        );

    final Widget dibujo = humo == null
        ? pintar(0)
        : AnimatedBuilder(
            animation: humo,
            builder: (BuildContext context, Widget? _) => pintar(humo.value),
          );

    if (widget.ancho == null) return dibujo;
    return SizedBox(width: widget.ancho, child: dibujo);
  }
}

class _CortePainter extends CustomPainter {
  _CortePainter({
    required this.corte,
    required this.relleno,
    required this.semilla,
    required this.vapor,
    this.fase = 0,
  });

  final Corte corte;
  final Color relleno;
  final String semilla;
  final bool vapor;

  /// 0 a 1, en bucle. Desplaza el vapor hacia arriba y lo desvanece.
  final double fase;

  // Lienzo lógico. Todo se dibuja en estas unidades y luego se escala, así
  // que los grosores de línea se mantienen proporcionales a cualquier tamaño.
  static const double _ancho = 140;
  static const double _cx = 70;
  static const double _cy = 66;
  static const double _rx = 50;
  static const double _ry = 38;

  @override
  void paint(Canvas canvas, Size size) {
    final double escala = size.width / _ancho;
    canvas.save();
    canvas.scale(escala);

    final math.Random azar = semillaDe(semilla);

    final double grosorCostra = 5 + corte.crujiente * 0.85;
    final double irx = _rx - grosorCostra;
    final double iry = _ry - grosorCostra;
    final double intensidadVapor = corte.sabor / 10;

    final Paint tinta = Paint()
      ..color = AppColors.tinta
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    // ── Vapor ──────────────────────────────────────────────────────────────
    if (vapor && intensidadVapor > 0.05) {
      for (int i = 0; i < 3; i++) {
        final double ox = _cx - 21 + i * 21;
        final double h = (8 + intensidadVapor * 4.5) * (1 - i * 0.1);
        final double w = 5.5 + intensidadVapor * 2;

        // Cada hilo de humo va desfasado un tercio de ciclo: así no suben
        // los tres a la vez como un semáforo.
        final double ciclo = (fase + i / 3) % 1.0;
        final double subida = ciclo * 16;
        // Nace tenue, se ve en medio y se disuelve arriba.
        final double desvanecido = math.sin(ciclo * math.pi);

        final Path onda = Path()..moveTo(ox, 26 - subida);
        onda.relativeCubicTo(w, -h, -w, -h, 0, -h * 2);
        onda.relativeCubicTo(w, -h, -w, -h, 0, -h * 2);

        final double opacidad = fase == 0
            ? 0.25 + intensidadVapor * 0.6
            : (0.15 + intensidadVapor * 0.7) * desvanecido;

        canvas.drawPath(
          onda,
          Paint()
            ..color = AppColors.tinta.withValues(alpha: opacidad.clamp(0.0, 1.0))
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.4
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    // ── Sombra maciza ──────────────────────────────────────────────────────
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(_cx + 3, _cy + 6),
        width: _rx * 2,
        height: _ry * 2,
      ),
      Paint()..color = AppColors.tinta,
    );

    // ── Costra ─────────────────────────────────────────────────────────────
    final Rect cuerpo = Rect.fromCenter(
      center: const Offset(_cx, _cy),
      width: _rx * 2,
      height: _ry * 2,
    );
    canvas.drawOval(
      cuerpo,
      Paint()..shader = AppColors.rebozado.createShader(cuerpo),
    );
    canvas.drawOval(cuerpo, tinta..strokeWidth = 3.4);

    // ── Bechamel ───────────────────────────────────────────────────────────
    // La cremosidad se traduce a luz y saturación, no a tamaño: una bechamel
    // de 10 se ve más blanca y más viva, no más grande.
    final Color bechamel = HSLColor.fromAHSL(
      1,
      38,
      (0.40 + corte.cremosidad * 0.032).clamp(0.0, 0.96),
      (0.74 + corte.cremosidad * 0.018).clamp(0.0, 0.97),
    ).toColor();

    final Rect dentro = Rect.fromCenter(
      center: const Offset(_cx, _cy),
      width: irx * 2,
      height: iry * 2,
    );
    canvas.drawOval(dentro, Paint()..color = bechamel);
    canvas.drawOval(dentro, tinta..strokeWidth = 2.6);

    // ── Trozos de relleno ──────────────────────────────────────────────────
    final int trozos = (1 + corte.relleno * 1.0).round();
    for (int i = 0; i < trozos; i++) {
      final double angulo = azar.nextDouble() * math.pi * 2;
      final double k = math.sqrt(azar.nextDouble()) * 0.7;
      final double px = _cx + math.cos(angulo) * irx * k;
      final double py = _cy + math.sin(angulo) * iry * k;
      final double tam = 3 + azar.nextDouble() * 3.4;
      final double giro = (azar.nextDouble() * 120 - 60) * math.pi / 180;

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(giro);
      final Rect trozo = Rect.fromCenter(
        center: Offset.zero,
        width: tam * 2,
        height: tam * 1.52,
      );
      canvas.drawOval(trozo, Paint()..color = relleno);
      canvas.drawOval(trozo, tinta..strokeWidth = 1.6);
      canvas.restore();
    }

    // ── Migas de panko ─────────────────────────────────────────────────────
    final int migas = (5 + corte.crujiente * 1.8).round();
    for (int i = 0; i < migas; i++) {
      final double angulo = azar.nextDouble() * math.pi * 2;
      final double k = 1 -
          (grosorCostra / 2 / _rx) -
          azar.nextDouble() * (grosorCostra / _rx) * 0.7;
      final double px = _cx + math.cos(angulo) * _rx * (k + 0.02);
      final double py = _cy + math.sin(angulo) * _ry * (k + 0.02);
      final double w = 3 + azar.nextDouble() * 2.4;
      final double giro = (azar.nextDouble() * 90 - 45) * math.pi / 180;

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(giro);
      final RRect miga = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: w, height: w * 0.66),
        Radius.circular(w * 0.3),
      );
      canvas.drawRRect(miga, Paint()..color = AppColors.miga);
      canvas.drawRRect(miga, tinta..strokeWidth = 1.4);
      canvas.restore();
    }

    // ── Brillo ─────────────────────────────────────────────────────────────
    final Path brillo = Path()
      ..moveTo(_cx - _rx * 0.58, _cy - _ry * 0.62)
      ..arcToPoint(
        Offset(_cx - _rx * 0.12, _cy - _ry * 0.78),
        radius: Radius.elliptical(_rx * 0.58, _ry * 0.58),
        clockwise: true,
      );
    canvas.drawPath(
      brillo,
      Paint()
        ..color = const Color(0xFFFFF6DC).withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(_CortePainter viejo) {
    return viejo.corte.crujiente != corte.crujiente ||
        viejo.corte.cremosidad != corte.cremosidad ||
        viejo.corte.sabor != corte.sabor ||
        viejo.corte.relleno != corte.relleno ||
        viejo.relleno != relleno ||
        viejo.semilla != semilla ||
        viejo.vapor != vapor ||
        viejo.fase != fase;
  }
}
