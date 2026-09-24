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

  /// Se serializa sólo para el borrador a medias, no para la cata.
  ///
  /// La cata guarda lat y lon sueltos y se olvida del nombre a propósito. Pero
  /// un formulario a medio escribir sí tiene que volver tal cual estaba,
  /// incluido el nombre que se eligió en el buscador.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'nombre': nombre,
        'lat': lat,
        'lon': lon,
        'ciudad': ciudad,
        'pais': pais,
      };

  /// Nulo si el guardado no tiene forma de lugar: un borrador a medias es lo
  /// menos importante que hay guardado, así que ante la duda se deja sin sitio
  /// en vez de reventar el arranque.
  static Lugar? desdeJson(Object? json) {
    if (json is! Map<dynamic, dynamic>) return null;
    final Object? lat = json['lat'];
    final Object? lon = json['lon'];
    if (lat is! num || lon is! num) return null;

    return Lugar(
      nombre: json['nombre'] as String? ?? '',
      lat: lat.toDouble(),
      lon: lon.toDouble(),
      ciudad: json['ciudad'] as String? ?? '',
      pais: json['pais'] as String? ?? '',
    );
  }

  /// "37,3886 · -5,9885" — lo que se enseña cuando no hay nombre que dar.
  String get coordenadas =>
      '${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}'
          .replaceAll('.', ',');
}
