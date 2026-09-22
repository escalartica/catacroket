import 'package:flutter/material.dart';

import '../tokens/app_motion.dart';

/// Entrada escalonada: el elemento sube y aparece, con un retraso propio.
///
/// Se usa en las listas para que el contenido "caiga" en cascada en vez de
/// aparecer de golpe. El retraso se corta a los ocho primeros elementos: a
/// partir de ahí el usuario ya está haciendo scroll y esperar por una
/// animación sería una tontería.
class Entrada extends StatefulWidget {
  const Entrada({
    super.key,
    required this.child,
    this.indice = 0,
    this.desde = 16,
  });

  final Widget child;

  /// Posición en la lista. Marca el retraso.
  final int indice;

  /// Cuántos píxeles sube al entrar.
  final double desde;

  static const Duration _paso = Duration(milliseconds: 55);

  @override
  State<Entrada> createState() => _EntradaState();
}

class _EntradaState extends State<Entrada> {
  bool _dentro = false;

  @override
  void initState() {
    super.initState();
    final int pasos = widget.indice.clamp(0, 8);
    Future<void>.delayed(Entrada._paso * pasos, () {
      if (mounted) setState(() => _dentro = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Con movimiento reducido no hay cascada: el contenido está y ya está.
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;

    return AnimatedSlide(
      offset: _dentro ? Offset.zero : Offset(0, widget.desde / 100),
      duration: AppMotion.normal,
      curve: AppMotion.entrada,
      child: AnimatedOpacity(
        opacity: _dentro ? 1 : 0,
        duration: AppMotion.normal,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
