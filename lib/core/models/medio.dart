/// Una foto o un vídeo de una cata.
enum TipoMedio { foto, video }

/// La ruta es local al dispositivo: el fichero se copia a la carpeta de la
/// app al elegirlo, así que no depende de que la foto siga en la galería ni
/// de permisos posteriores. Cuando entre Firebase Storage, aquí convivirán
/// la ruta local (caché) y la URL remota.
class Medio {
  const Medio({required this.tipo, required this.ruta});

  final TipoMedio tipo;
  final String ruta;

  bool get esVideo => tipo == TipoMedio.video;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'tipo': tipo.name,
        'ruta': ruta,
      };

  factory Medio.fromJson(Map<String, dynamic> json) => Medio(
        tipo: json['tipo'] == 'video' ? TipoMedio.video : TipoMedio.foto,
        ruta: json['ruta'] as String? ?? '',
      );

  /// Cuántos de cada cosa admite una cata. Dos fotos y un vídeo: suficiente
  /// para contar la croqueta y poco suficiente para que nadie convierta la
  /// ficha en un álbum.
  static const int maxFotos = 2;
  static const int maxVideos = 1;
  static const Duration duracionMaxima = Duration(seconds: 15);
}
