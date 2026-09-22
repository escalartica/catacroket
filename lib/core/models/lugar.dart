import '../data/paises.dart';

/// Un punto concreto del mundo con un nombre.
///
/// Lo devuelve tanto el GPS como el buscador, y es lo único que el formulario
/// necesita saber de una ubicación. La cata guarda al final lat y lon
/// sueltos: el nombre del lugar no se persiste porque el nombre bueno es el
/// que escribió el usuario en «Sitio», no el que traiga OpenStreetMap.
class Lugar {
  const Lugar({
    required this.nombre,
    required this.lat,
    required this.lon,
    this.ciudad = '',
    this.pais = '',
  });

  final String nombre;
  final double lat;
  final double lon;

  /// Ciudad y código ISO deducidos, cuando se han podido deducir. Sirven para
  /// rellenar el formulario, nunca para pisar lo que el usuario ya escribió.
  final String ciudad;
  final String pais;

  bool get tienePais => pais.isNotEmpty && Paises.existe(pais);

  /// "37,3886 · -5,9885" — lo que se enseña cuando no hay nombre que dar.
  String get coordenadas =>
      '${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}'
          .replaceAll('.', ',');
}
