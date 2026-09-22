import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/theme/tokens/app_spacing.dart';

/// Croqui, la mascota.
///
/// Es el mismo dibujo del logo, en SVG, para que no haya dos versiones del
/// personaje que puedan acabar divergiendo. Aparece en los estados vacíos y
/// al publicar una cata; en el resto de la app manda El Corte, que sí habla
/// de una croqueta concreta.
class Croqui extends StatelessWidget {
  const Croqui({super.key, this.ancho = 160, this.conProps = true});

  final double ancho;

  /// Con tablilla y tenedor (la del logo) o sin ellos. En las dos versiones
  /// Croqui lleva su cinta, sus muñequeras y sus gotas de sudor; lo que se
  /// quita por debajo de ~140 px son sólo la tablilla y el tenedor, que a ese
  /// tamaño no se distinguen y ensucian la silueta.
  final bool conProps;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      conProps ? 'assets/brand/croqui.svg' : 'assets/brand/croqui-cuerpo.svg',
      width: ancho,
      fit: BoxFit.contain,
      semanticsLabel: 'Croqui, la mascota de Catacroket',
    );
  }
}

/// La chapa pequeña de la marca: Croqui con su cinta, sus muñequeras y sus
/// gotas de sudor, recortado en el cuadrado de la app.
class MarcaMini extends StatelessWidget {
  const MarcaMini({super.key, this.tamano = 44});

  final double tamano;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/brand/marca.svg',
      width: tamano,
      semanticsLabel: 'Catacroket',
    );
  }
}

/// El nombre, con su tipo de siempre.
///
/// Va en trazados, no en fuente: la Luckiest Guy del logo no está empaquetada
/// en la app (sería una familia entera para diez letras) y así el nombre se
/// dibuja idéntico al de la chapa, el icono y la App Store.
class NombreCatacroket extends StatelessWidget {
  const NombreCatacroket({super.key, this.alto = 22, this.sobreOscuro = false});

  final double alto;

  /// Sobre tomate, uva o cualquier fondo saturado, las letras van en crema
  /// con contorno de tinta. Sobre el fondo claro van en tinta con sombra oro.
  final bool sobreOscuro;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      sobreOscuro ? 'assets/brand/nombre-crema.svg' : 'assets/brand/nombre.svg',
      height: alto,
      semanticsLabel: 'Catacroket',
    );
  }
}

/// La marca en la cabecera: la chapa y el nombre, con una acción opcional.
///
/// La chapa respira sola —un balanceo de un par de grados que no llega a
/// distraer— y al tocarla Croqui se sacude como quien se quita el sudor.
/// El nombre no se mueve: un logotipo que baila se ve barato.
class MarcaCabecera extends StatefulWidget {
  const MarcaCabecera({
    super.key,
    this.accion,
    this.sobreOscuro = false,
    this.altoChapa = 46,
  });

  final Widget? accion;
  final bool sobreOscuro;
  final double altoChapa;

  @override
  State<MarcaCabecera> createState() => _MarcaCabeceraState();
}

class _MarcaCabeceraState extends State<MarcaCabecera>
    with TickerProviderStateMixin {
  late final AnimationController _ocioso = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat(reverse: true);

  late final AnimationController _saludo = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 820),
  );

  @override
  void dispose() {
    _ocioso.dispose();
    _saludo.dispose();
    super.dispose();
  }

  void _sacudir() {
    HapticFeedback.lightImpact();
    _saludo.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pantalla,
        AppSpacing.s,
        AppSpacing.pantalla,
        0,
      ),
      child: Row(
        children: <Widget>[
          GestureDetector(
            onTap: _sacudir,
            behavior: HitTestBehavior.opaque,
            child: AnimatedBuilder(
              animation: Listenable.merge(<Listenable>[_ocioso, _saludo]),
              builder: (BuildContext context, Widget? chapa) {
                // Balanceo de reposo: -1 → 1, suave en los extremos.
                final double vaiven =
                    Curves.easeInOut.transform(_ocioso.value) * 2 - 1;

                // Sacudida: seno amortiguado. Vale 0 en 0 y en 1, así que la
                // chapa acaba exactamente donde estaba.
                final double s = _saludo.value;
                final double meneo = _saludo.isDismissed
                    ? 0
                    : math.sin(s * math.pi * 3) * (1 - s) * 0.40;
                final double brinco = _saludo.isDismissed
                    ? 0
                    : math.sin(s * math.pi) * 0.14;

                return Transform.translate(
                  offset: Offset(0, -1.6 * vaiven),
                  child: Transform.rotate(
                    angle: 0.03 * vaiven + meneo,
                    child: Transform.scale(scale: 1 + brinco, child: chapa),
                  ),
                );
              },
              child: MarcaMini(tamano: widget.altoChapa),
            ),
          ),
          const SizedBox(width: 10),
          NombreCatacroket(
            alto: widget.altoChapa * 0.47,
            sobreOscuro: widget.sobreOscuro,
          ),
          const Spacer(),
          ?widget.accion,
        ],
      ),
    );
  }
}
