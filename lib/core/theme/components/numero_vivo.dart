import 'package:flutter/material.dart';

import '../tokens/app_motion.dart';

/// Un número que va de donde estaba a donde está, en vez de saltar.
///
/// Se usa en las cifras del Croquetómetro y en las de una mesa. La diferencia
/// que importa no es que quede bonito: es que avisa. Cuando llega la cata de
/// alguien de tu mesa, el contador de la pantalla sube él solo de 11 a 12, y
/// ese movimiento es lo único que te dice que ha pasado algo. Saltando de un
/// fotograma a otro no se ve: si no estabas mirando ese rincón exacto, el 12
/// parece haber estado ahí desde siempre.
///
/// Sólo anima si ya había un número antes. Al abrir la pantalla, las cifras
/// no cuentan desde cero —eso es un truco de presentación, y además cuenta
/// una mentira: que acaban de pasar de 0 a 11—.
class NumeroVivo extends StatefulWidget {
  const NumeroVivo({
    super.key,
    required this.valor,
    required this.estilo,
    this.decimales = 0,
  });

  /// El número a enseñar. Nulo se pinta como un guion.
  final double? valor;

  final TextStyle estilo;

  /// Cuántos decimales. Las notas llevan uno; los recuentos, ninguno.
  final int decimales;

  @override
  State<NumeroVivo> createState() => _NumeroVivoState();
}

class _NumeroVivoState extends State<NumeroVivo> {
  double? _desde;

  @override
  void didUpdateWidget(NumeroVivo viejo) {
    super.didUpdateWidget(viejo);
    if (viejo.valor != widget.valor) _desde = viejo.valor;
  }

  String _texto(double v) => widget.decimales == 0
      ? v.round().toString()
      : v.toStringAsFixed(widget.decimales).replaceAll('.', ',');

  @override
  Widget build(BuildContext context) {
    final double? valor = widget.valor;
    if (valor == null) return Text('—', style: widget.estilo);

    // Primera vez, o con «reducir movimiento»: el número y ya está.
    if (_desde == null || MediaQuery.disableAnimationsOf(context)) {
      return Text(_texto(valor), style: widget.estilo);
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: _desde, end: valor),
      duration: AppMotion.lenta,
      curve: AppMotion.suave,
      builder: (BuildContext _, double v, Widget? _) =>
          Text(_texto(v), style: widget.estilo),
    );
  }
}
