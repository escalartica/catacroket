import '../data/rellenos.dart';

/// Cómo estaba una croqueta concreta, en palabras.
///
/// Es la escala que ya usaba Palito, puesta en orden. Allí "Basura" venía
/// detrás de "Religiosas", así que la lista no se podía leer de un vistazo ni
/// servía para calcular nada. Aquí va de peor a mejor y cada peldaño tiene su
/// número, que es lo que permite sacar la media de un surtido.
///
/// Siete peldaños y no cinco: entre "Buenas" y "Religiosas" hay mucho trecho,
/// y ese trecho es justo donde vive la conversación de un croquetero.
enum Veredicto {
  basura('Basura', '🗑️', 0.5),
  meh('Meh', '😐', 3),
  mediocres('Mediocres', '🙁', 4.5),
  buenas('Buenas', '👍', 6.5),
  muyBuenas('Muy buenas', '⭐', 8),
  emocionantes('Emocionantes', '🔥', 9),
  religiosas('Religiosas', '✨', 10);

  const Veredicto(this.nombre, this.emoji, this.valor);

  final String nombre;
  final String emoji;

  /// De 0 a 10. Es lo que entra en la media del surtido.
  final double valor;

  static const Veredicto porDefecto = Veredicto.buenas;

  static Veredicto deNombre(String nombre) => Veredicto.values.firstWhere(
        (Veredicto v) => v.name == nombre,
        orElse: () => porDefecto,
      );

  /// El veredicto que corresponde a una nota numérica. Sirve para convertir
  /// las catas antiguas, que sólo tenían los cuatro ejes.
  static Veredicto deValor(double nota) {
    Veredicto elegido = Veredicto.basura;
    for (final Veredicto v in Veredicto.values) {
      if (nota >= v.valor - 0.75) elegido = v;
    }
    return elegido;
  }
}

/// Un sabor dentro de una cata.
///
/// Una cata normal tiene uno. Un surtido tiene varios, y cada uno lleva su
/// propio veredicto porque es exactamente lo que pasa en la vida real: te
/// ponen seis, las de calamar están para llorar y las de jamón son de
/// cartón. Una nota única para las seis no cuenta nada.
///
/// Y un sabor puede llevar varios ingredientes. Una croqueta de jamón y
/// boletus existe, y hasta ahora había que elegir uno de los dos y mentir
/// sobre el otro —lo cual, además, le mentía a la deducción de dietas—.
/// Hay un [rellenoId] principal porque alguien tiene que decidir el color y
/// el dibujo de la croqueta, y es el primero que se elige; los demás van en
/// [otros] y cuentan igual para los alérgenos.
class Sabor {
  const Sabor({
    required this.rellenoId,
    this.otros = const <String>[],
    this.propio = '',
    this.veredicto = Veredicto.porDefecto,
    this.apunte = '',
  });

  /// El que manda: da color a la tarjeta y dibuja El Corte. Es el primero
  /// que se eligió, sin más misterio.
  final String rellenoId;

  /// Los demás ingredientes del catálogo.
  final List<String> otros;

  /// Un ingrediente escrito a mano, para lo que no está en la lista.
  ///
  /// Una croqueta de carrillada o de pulpo a la gallega es una croqueta de
  /// verdad y el catálogo nunca las va a tener todas. Eso sí: lo que se
  /// escribe aquí la app no sabe qué lleva, así que a efectos de dietas y
  /// alérgenos cuenta como un relleno sin describir.
  final String propio;

  final Veredicto veredicto;

  /// Una frase corta para ese sabor en concreto. Opcional.
  final String apunte;

  bool get tienePropio => propio.trim().isNotEmpty;

  /// Los ids del catálogo, el principal primero.
  List<String> get ids => <String>[rellenoId, ...otros];

  /// Lo que hay que mirar para deducir dietas y alérgenos. Un ingrediente
  /// escrito a mano arrastra al genérico, que no promete nada.
  List<String> get idsParaDietas =>
      <String>[...ids, if (tienePropio) 'otro'];

  /// Los nombres, listos para leer.
  ///
  /// Si hay ingrediente escrito a mano se cae "A mi manera" de la lista:
  /// "A mi manera y carrillada" no lo diría nadie.
  List<String> get nombres => <String>[
        for (final String id in ids)
          if (!(tienePropio && id == 'otro')) Rellenos.de(id).nombre,
        if (tienePropio) propio.trim(),
      ];

  /// "Jamón ibérico", "Jamón ibérico y boletus", "Jamón, boletus y calabaza".
  String get nombre {
    final List<String> partes = nombres;
    if (partes.isEmpty) return Rellenos.de(rellenoId).nombre;
    if (partes.length == 1) return partes.first;
    return '${partes.sublist(0, partes.length - 1).join(', ')} y ${partes.last}';
  }

  Sabor copyWith({
    String? rellenoId,
    List<String>? otros,
    String? propio,
    Veredicto? veredicto,
    String? apunte,
  }) =>
      Sabor(
        rellenoId: rellenoId ?? this.rellenoId,
        otros: otros ?? this.otros,
        propio: propio ?? this.propio,
        veredicto: veredicto ?? this.veredicto,
        apunte: apunte ?? this.apunte,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'rellenoId': rellenoId,
        'otros': otros,
        'propio': propio,
        'veredicto': veredicto.name,
        'apunte': apunte,
      };

  factory Sabor.fromJson(Map<String, dynamic> json) => Sabor(
        rellenoId: json['rellenoId'] as String? ?? 'jamon',
        // Las catas de antes no tienen estos dos: se quedan con un solo
        // ingrediente, que es lo que tenían.
        otros: (json['otros'] as List<dynamic>? ?? <dynamic>[])
            .map((dynamic e) => e.toString())
            .toList(),
        propio: json['propio'] as String? ?? '',
        veredicto: Veredicto.deNombre(json['veredicto'] as String? ?? ''),
        apunte: json['apunte'] as String? ?? '',
      );
}
