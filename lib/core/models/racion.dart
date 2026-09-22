/// Cómo te la sirvieron.
///
/// Va al principio del paso 2 porque es lo primero que sabes: lo dices al
/// pedir, antes incluso de probarla. Y no es un dato decorativo — con las
/// unidades, el precio por croqueta deja de ser una cuenta de cabeza.
///
/// Hasta ahora la ficha decía "Ración de 6" a fuego, daba igual lo que
/// hubieras pedido. Era mentira seis de cada siete veces.
enum Formato {
  tapa('Tapa', '🍢', 2),
  mediaRacion('Media ración', '🍽️', 5),
  racion('Ración', '🥘', 10),
  sinDecir('No lo digo', '🤷', 0);

  const Formato(this.nombre, this.emoji, this.unidadesTipicas);

  final String nombre;
  final String emoji;

  /// Lo que suele traer. Se usa como propuesta al elegir el formato, no como
  /// verdad: el número que manda es el que ponga el usuario.
  final int unidadesTipicas;

  bool get seDijo => this != sinDecir;

  static Formato deNombre(String nombre) => Formato.values.firstWhere(
        (Formato f) => f.name == nombre,
        orElse: () => sinDecir,
      );
}
