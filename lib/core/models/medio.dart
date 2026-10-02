/// Una foto o un vídeo de una cata.
enum TipoMedio { foto, video }

/// Una foto o un vídeo, en el móvil y —si la cata se comparte— también
/// comprimido dentro de la propia cata.
///
/// [ruta] es local al dispositivo: el fichero se copia a la carpeta de la app
/// al elegirlo, así que no depende de que la foto siga en la galería ni de
/// permisos posteriores. Pero una ruta de este teléfono en otro no abre nada,
/// y por eso la gente de una mesa compartida no veía las croquetas de los
/// demás.
///
/// [mini] es la foto reducida y en base64, y es lo que viaja. Va dentro de la
/// cata, en Firestore, en vez de en un almacén de ficheros: así funciona en el
/// plan gratuito, sin tarjeta. Firestore admite 1 MB por cata, de ahí que la
/// miniatura vaya a 800 píxeles y no a tamaño completo.
///
/// Conviven a propósito. Quien hizo la foto sigue pintando su fichero, que es
/// instantáneo, no gasta datos y se ve entero; quien la recibe pinta la
/// miniatura. Y al reinstalar la app, la ruta local muere pero la miniatura
/// sigue, que es lo que impedía que las fotos sobrevivieran a cambiar de
/// móvil.
class Medio {
  const Medio({required this.tipo, required this.ruta, this.mini});

  final TipoMedio tipo;
  final String ruta;

  /// La foto reducida, en base64. Nula mientras la cata no se haya compartido.
  final String? mini;

  bool get esVideo => tipo == TipoMedio.video;

  /// Si hay algo que pintar, aquí o en lo que viajó.
  bool get sePuedeVer => ruta.isNotEmpty || viaja;

  /// Si ya tiene miniatura y no hay que volver a comprimirla.
  bool get viaja => mini != null && mini!.isNotEmpty;

  Medio conMini(String mini) => Medio(tipo: tipo, ruta: ruta, mini: mini);

  /// El mismo medio sin su ruta local, para mandárselo a otro móvil donde esa
  /// ruta no existe.
  Medio get paraViajar => Medio(tipo: tipo, ruta: '', mini: mini);

  /// Lo que se guarda en el móvil.
  ///
  /// La miniatura NO se guarda aquí: en el móvil que hizo la foto ya está el
  /// fichero entero, y duplicarla en disco engordaría el guardado de todas
  /// las catas sin que nadie la mire nunca.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'tipo': tipo.name,
        'ruta': ruta,
        if (mini != null) 'mini': mini,
      };

  factory Medio.fromJson(Map<String, dynamic> json) => Medio(
        tipo: json['tipo'] == 'video' ? TipoMedio.video : TipoMedio.foto,
        ruta: json['ruta'] as String? ?? '',
        mini: json['mini'] as String?,
      );

  /// Cuántos de cada cosa admite una cata. Dos fotos y un vídeo: suficiente
  /// para contar la croqueta y poco suficiente para que nadie convierta la
  /// ficha en un álbum.
  static const int maxFotos = 2;
  static const int maxVideos = 1;
  static const Duration duracionMaxima = Duration(seconds: 15);
}
