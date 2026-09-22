import 'dart:convert';

/// Los cuatro ejes de una cata.
///
/// Los pesos no son iguales a propósito: el crujiente y el relleno se
/// perciben, pero lo que decide si una croqueta se recuerda es la bechamel y
/// el sabor. Suman 1,0; si se tocan hay que revisar que sigan sumando.
class Corte {
  const Corte({
    required this.crujiente,
    required this.cremosidad,
    required this.sabor,
    required this.relleno,
  });

  const Corte.media()
      : crujiente = 5,
        cremosidad = 5,
        sabor = 5,
        relleno = 5;

  /// La costra.
  final int crujiente;

  /// La bechamel.
  final int cremosidad;

  /// Lo que se recuerda.
  final int sabor;

  /// Cantidad y calidad del relleno.
  final int relleno;

  static const double pesoCrujiente = 0.25;
  static const double pesoCremosidad = 0.30;
  static const double pesoSabor = 0.30;
  static const double pesoRelleno = 0.15;

  /// El CataScore, de 0 a 10.
  double get nota =>
      crujiente * pesoCrujiente +
      cremosidad * pesoCremosidad +
      sabor * pesoSabor +
      relleno * pesoRelleno;

  /// El eje por el que gana esta croqueta. Sirve para el "Gana por..." de la
  /// ficha, que es lo que convierte cuatro números en una frase.
  String get ejeFuerte {
    final Map<String, int> ejes = <String, int>{
      'crujiente': crujiente,
      'cremosidad': cremosidad,
      'sabor': sabor,
      'relleno': relleno,
    };
    return ejes.entries.reduce((a, b) => b.value > a.value ? b : a).key;
  }

  Corte copyWith({int? crujiente, int? cremosidad, int? sabor, int? relleno}) {
    return Corte(
      crujiente: crujiente ?? this.crujiente,
      cremosidad: cremosidad ?? this.cremosidad,
      sabor: sabor ?? this.sabor,
      relleno: relleno ?? this.relleno,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'crujiente': crujiente,
        'cremosidad': cremosidad,
        'sabor': sabor,
        'relleno': relleno,
      };

  factory Corte.fromJson(Map<String, dynamic> json) => Corte(
        crujiente: (json['crujiente'] as num?)?.toInt() ?? 5,
        cremosidad: (json['cremosidad'] as num?)?.toInt() ?? 5,
        sabor: (json['sabor'] as num?)?.toInt() ?? 5,
        relleno: (json['relleno'] as num?)?.toInt() ?? 5,
      );

  @override
  String toString() => jsonEncode(toJson());
}
