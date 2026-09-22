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

  bool get esPrivada => codigo == null;

  bool get esLibreta => id == libretaId;

  Mesa copyWith({
    String? nombre,
    String? descripcion,
    int? colorHex,
    List<String>? miembros,
  }) {
    return Mesa(
      id: id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      colorHex: colorHex ?? this.colorHex,
      miembros: miembros ?? this.miembros,
      codigo: codigo,
    );
  }

  /// Genera un código de seis letras.
  ///
  /// Fuera el alfabeto conflictivo: sin I ni L ni O, sin 0 ni 1. Este código
  /// se dicta en voz alta en una barra de bar con ruido, y una I que alguien
  /// oye como L es una mesa a la que no entras.
  static String nuevoCodigo([Random? azar]) {
    const String alfabeto = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
    final Random r = azar ?? Random();
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
