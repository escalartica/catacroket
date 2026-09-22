import 'package:flutter/material.dart';

import '../theme/tokens/app_colors.dart';

/// Alguien que está en una mesa. En la v1 son locales; cuando entre Firebase
/// esto pasa a ser el perfil público de un usuario.
class Persona {
  const Persona({
    required this.id,
    required this.nombre,
    required this.color,
    this.foto,
  });

  final String id;
  final String nombre;
  final Color color;

  /// Ruta de su foto, si la hay.
  ///
  /// Hoy sólo la tienes tú, porque eres el único que puede elegirla: no hay
  /// cuentas todavía. Va en [Persona] y no suelto en la pantalla del perfil
  /// para que el avatar sea el mismo componente en todas partes, y para que
  /// el día que haya cuentas las fotos de los demás entren por aquí sin
  /// tocar ni una pantalla.
  final String? foto;

  Persona copiaCon({String? nombre, String? foto}) => Persona(
        id: id,
        nombre: nombre ?? this.nombre,
        color: color,
        foto: foto ?? this.foto,
      );

  /// Inicial para el avatar. Se saca del nombre para que nunca haya que
  /// mantener dos campos sincronizados.
  String get inicial =>
      nombre.isEmpty ? '?' : nombre.substring(0, 1).toUpperCase();

  static const Persona desconocida = Persona(
    id: 'nadie',
    nombre: 'Alguien',
    color: AppColors.superficieHonda,
  );

  /// Alguien de quien sólo sabemos el nombre.
  ///
  /// Los acompañantes de una cata se escriben a mano: no hay cuentas todavía
  /// y obligar a elegir entre cinco personas inventadas era pedirle al
  /// usuario que mintiera sobre con quién come. El color sale del nombre, así
  /// que tu hermana es siempre del mismo color sin guardar nada.
  factory Persona.deNombre(String nombre) {
    final String limpio = nombre.trim();
    return Persona(
      id: 'nombre:${limpio.toLowerCase()}',
      nombre: limpio.isEmpty ? 'Alguien' : limpio,
      color: _colorDe(limpio),
    );
  }

  static const List<Color> _paleta = <Color>[
    AppColors.chicle,
    AppColors.menta,
    AppColors.cielo,
    AppColors.uva,
    AppColors.lima,
    AppColors.mango,
    AppColors.sol,
  ];

  /// Los identificadores del catálogo de demostración, traducidos a nombres.
  ///
  /// Existe sólo para no perder el "con quién" de las catas guardadas antes
  /// de que los acompañantes fueran nombres libres. Está copiado aquí a
  /// propósito en vez de leerlo de `DatosDemo`: son datos congelados de un
  /// formato viejo, y si mañana cambian los nombres de la demo, lo que se
  /// guardó entonces sigue significando lo mismo.
  static const Map<String, String> _idsViejos = <String, String>{
    'tu': 'Tú',
    'marta': 'Marta',
    'jose': 'Jose',
    'alvaro': 'Álvaro',
    'rocio': 'Rocío',
    'curro': 'Curro',
  };

  static String nombreGuardado(String valor) => _idsViejos[valor] ?? valor;

  static Color _colorDe(String nombre) {
    if (nombre.isEmpty) return AppColors.superficieHonda;
    int suma = 0;
    for (final int unidad in nombre.toLowerCase().runes) {
      suma = (suma + unidad * 31) % 100003;
    }
    return _paleta[suma % _paleta.length];
  }
}
