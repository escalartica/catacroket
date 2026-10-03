import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_shape.dart';
import '../tokens/app_spacing.dart';

/// El hueco que ocupará algo que todavía se está leyendo.
///
/// Existe por un fallo concreto: La Vitrina se dibuja antes de que el disco
/// haya contestado, así que durante los primeros fotogramas la lista está
/// vacía y la pantalla decía «Aquí irán tus croquetas, apunta la primera» a
/// gente que tiene cuarenta. Y al llegar los datos, todo saltaba de sitio.
///
/// Un hueco con la forma de lo que viene no miente y no salta: dice «espera»
/// y deja el sitio hecho.
///
/// El brillo es de ida y vuelta y muy suave. Un esqueleto que destella fuerte
/// llama más la atención que el contenido que está tapando, que es justo al
/// revés de lo que tiene que hacer.
class Esqueleto extends StatefulWidget {
  const Esqueleto({
    super.key,
    this.ancho,
    required this.alto,
    this.radio = AppShape.radioM,
  });

  /// Una tarjeta de cata del tamaño de las de verdad.
  const Esqueleto.tarjeta({super.key})
      : ancho = null,
        alto = 96,
        radio = AppShape.radioL;

  final double? ancho;
  final double alto;
  final double radio;

  @override
  State<Esqueleto> createState() => _EsqueletoState();
}

class _EsqueletoState extends State<Esqueleto>
    with SingleTickerProviderStateMixin {
  late final AnimationController _latido = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _latido.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool quieto = MediaQuery.disableAnimationsOf(context);

    return AnimatedBuilder(
      animation: _latido,
      builder: (BuildContext _, Widget? _) => Container(
        width: widget.ancho,
        height: widget.alto,
        decoration: BoxDecoration(
          color: Color.lerp(
            AppColors.superficieCalida,
            AppColors.superficie,
            quieto ? 0.5 : _latido.value,
          ),
          borderRadius: BorderRadius.circular(widget.radio),
          border: Border.all(
            color: AppColors.tinta.withValues(alpha: 0.18),
            width: AppShape.bordeFino,
          ),
        ),
      ),
    );
  }
}

/// Unas cuantas tarjetas de mentira, para cubrir el hueco de una lista.
class ListaEsqueleto extends StatelessWidget {
  const ListaEsqueleto({super.key, this.cuantas = 3});

  final int cuantas;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Cargando tus catas',
      child: Column(
        children: <Widget>[
          for (int i = 0; i < cuantas; i++) ...<Widget>[
            const Esqueleto.tarjeta(),
            if (i < cuantas - 1) const SizedBox(height: AppSpacing.m),
          ],
        ],
      ),
    );
  }
}
