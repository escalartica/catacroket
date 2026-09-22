import 'package:flutter/material.dart';

/// El dibujo de una croqueta, que viaja de la lista a su ficha.
///
/// Al tocar una tarjeta, su croqueta sale del plato pequeño y crece hasta el
/// tamaño grande de la ficha en vez de desaparecer aquí y aparecer allí. Es
/// la única animación de la app que cuenta algo de verdad: dice que lo que
/// estás mirando es lo mismo que acabas de tocar, y por eso vuelves con la
/// sensación de haber entrado y salido de un sitio en vez de saltar entre dos
/// pantallas sueltas.
///
/// Se hace con el mismo widget en los dos sitios y la misma etiqueta. Flutter
/// se encarga del resto.
class Vuelo extends StatelessWidget {
  const Vuelo({super.key, required this.id, required this.child});

  /// El id de la cata. Tiene que ser único EN PANTALLA: si la misma cata
  /// saliera dos veces en la misma lista, Flutter no sabría cuál de las dos
  /// despega y reventaría.
  final String id;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Con «reducir movimiento» no hay vuelo. La animación cruza media
    // pantalla creciendo, que es justo lo que marea a quien lo tiene puesto.
    if (MediaQuery.disableAnimationsOf(context)) return child;

    return Hero(
      tag: 'cata:$id',
      // Durante el vuelo se pinta con el estilo de destino, para que el
      // texto no herede el de la pantalla de la que sale.
      flightShuttleBuilder: (
        BuildContext _,
        Animation<double> animacion,
        HeroFlightDirection _,
        BuildContext desde,
        BuildContext hasta,
      ) =>
          DefaultTextStyle(
        style: DefaultTextStyle.of(hasta).style,
        child: child,
      ),
      child: child,
    );
  }
}
