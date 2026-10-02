import 'dart:io';
import 'dart:math';

/// Un grupo de catas. Puede ser privada (la libreta de uno) o compartida.
///
/// El código de seis letras es la única forma de entrar. No hay invitaciones
/// por correo ni solicitudes pendientes: eso es precisamente lo que la gente
/// no entendía en Palito.
class Mesa {
  const Mesa({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.colorHex,
    required this.miembros,
    this.codigo,
    this.foto,
    this.enLaNube = false,
  });

  /// Identificador fijo de la libreta privada. Existe siempre y no se puede
  /// borrar ni compartir.
  static const String libretaId = 'libreta';

  final String id;
  final String nombre;
  final String descripcion;
  final int colorHex;
  final List<String> miembros;

  /// Nulo en la libreta privada.
  final String? codigo;

  /// Ruta de la foto de la mesa dentro de la carpeta de la app, o nulo.
  ///
  /// Se copia a la carpeta de la app y no se guarda la ruta que devuelve el
  /// carrete: ésa vive en una caché temporal que el sistema borra cuando
  /// quiere, y guardarla es garantizar una foto rota en unas semanas.
  final String? foto;

  bool get tieneFoto => foto != null && File(foto!).existsSync();

  /// Si esta mesa está subida y su gente puede verla.
  ///
  /// No es lo mismo que tener código: TODAS las mesas nacen con uno, porque
  /// generarlo al compartir obligaría a cambiarlo si algún día se comparte y
  /// se deja de compartir. Esto dice si además está en el servidor.
  ///
  /// Mientras sea `false`, esa mesa y sus catas no han salido del móvil.
  final bool enLaNube;

  bool get esPrivada => codigo == null;

  bool get esLibreta => id == libretaId;

  Mesa copyWith({
    String? nombre,
    String? descripcion,
    int? colorHex,
    List<String>? miembros,
    String? foto,
    bool quitarFoto = false,
    bool? enLaNube,
    String? codigo,
  }) {
    return Mesa(
      id: id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      colorHex: colorHex ?? this.colorHex,
      miembros: miembros ?? this.miembros,
      codigo: codigo ?? this.codigo,
      foto: quitarFoto ? null : (foto ?? this.foto),
      enLaNube: enLaNube ?? this.enLaNube,
    );
  }

  /// Las letras con las que se hacen los códigos.
  ///
  /// Fuera el alfabeto conflictivo: sin I ni L ni O, sin 0 ni 1. Este código
  /// se dicta en voz alta en una barra de bar con ruido, y una I que alguien
  /// oye como L es una mesa a la que no entras.
  ///
  /// Vive aquí y no dentro de [nuevoCodigo] porque quien teclea un código
  /// necesita el mismo alfabeto para avisar antes de ir al servidor.
  static const String alfabetoCodigo = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

  /// Genera un código de seis letras.
  ///
  /// Por defecto usa `Random.secure()`, no el `Random()` normal: este código
  /// es la llave de una mesa, y el generador corriente es predecible si
  /// alguien conoce la semilla. No cuesta nada y cierra la puerta.
  ///
  /// Los tests le pasan su propio [azar] con semilla fija, que es para lo
  /// que está el parámetro.
  static String nuevoCodigo([Random? azar]) {
    const String alfabeto = alfabetoCodigo;
    final Random r = azar ?? Random.secure();
    return List<String>.generate(
      6,
      (_) => alfabeto[r.nextInt(alfabeto.length)],
    ).join();
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'nombre': nombre,
        'descripcion': descripcion,
        'colorHex': colorHex,
        'miembros': miembros,
        'codigo': codigo,
        'foto': foto,
        'enLaNube': enLaNube,
      };

  factory Mesa.fromJson(Map<String, dynamic> json) => Mesa(
        id: json['id'] as String,
        nombre: json['nombre'] as String? ?? 'Mesa',
        descripcion: json['descripcion'] as String? ?? '',
        colorHex: (json['colorHex'] as num?)?.toInt() ?? 0xFFFFC93C,
        miembros: (json['miembros'] as List<dynamic>? ?? <dynamic>[])
            .map((dynamic e) => e.toString())
            .toList(),
        codigo: json['codigo'] as String?,
        foto: json['foto'] as String?,
        enLaNube: json['enLaNube'] as bool? ?? false,
      );
}

/// Una quedada: varias catas del mismo día contadas como una historia.
class Recuerdo {
  const Recuerdo({
    required this.id,
    required this.mesaId,
    required this.titulo,
    required this.texto,
    required this.cuando,
    required this.lugar,
    required this.catas,
    required this.quien,
  });

  final String id;
  final String mesaId;
  final String titulo;
  final String texto;
  final DateTime cuando;
  final String lugar;
  final List<String> catas;
  final List<String> quien;
}
