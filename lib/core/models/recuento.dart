import 'cata.dart';
import 'sabor.dart';
import '../data/rellenos.dart';

/// Cuántas croquetas de cada clase lleváis.
///
/// Cuenta SABORES y no catas, y la diferencia importa: un surtido de seis es
/// una cata pero son seis croquetas, y de seis clases distintas. Contar catas
/// diría que has probado una sola croqueta esa noche.
class Recuento {
  const Recuento({required this.rellenoId, required this.cuantas});

  final String rellenoId;
  final int cuantas;

  String get nombre => Rellenos.de(rellenoId).nombre;
  String get emoji => Rellenos.de(rellenoId).emoji;

  /// De más catadas a menos. Con empate, por nombre, para que el orden no
  /// baile entre dos aperturas de la misma pantalla.
  static List<Recuento> de(Iterable<Cata> catas) {
    final Map<String, int> cuenta = <String, int>{};

    for (final Cata c in catas) {
      for (final Sabor s in c.sabores) {
        // Sólo el relleno que manda. Una croqueta de jamón y boletus es una
        // croqueta de jamón con boletus, no media de cada: sumarla a las dos
        // haría que el total no cuadrara con las croquetas que os comisteis.
        cuenta[s.rellenoId] = (cuenta[s.rellenoId] ?? 0) + 1;
      }
    }

    final List<Recuento> lista = <Recuento>[
      for (final MapEntry<String, int> e in cuenta.entries)
        Recuento(rellenoId: e.key, cuantas: e.value),
    ];

    lista.sort((Recuento a, Recuento b) {
      final int porCantidad = b.cuantas.compareTo(a.cuantas);
      return porCantidad != 0 ? porCantidad : a.nombre.compareTo(b.nombre);
    });

    return lista;
  }
}
