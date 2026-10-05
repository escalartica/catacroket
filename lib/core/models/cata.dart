import '../data/paises.dart';
import '../data/rellenos.dart';
import 'alergeno.dart';
import 'corte.dart';
import 'dieta.dart';
import 'medio.dart';
import 'persona.dart';
import 'racion.dart';
import 'receta.dart';
import 'tiro_al_plato.dart';
import 'sabor.dart';

/// Una croqueta catada, en cualquier parte del mundo.
///
/// La ubicación es ciudad + país y no barrio: una croqueta de Lisboa o de
/// Ciudad de México cuenta igual que una de Triana, y "barrio" sólo tenía
/// sentido mientras la app fuera de Sevilla. El país se guarda como código
/// ISO de dos letras para que la bandera se calcule sola y el dato sirva
/// luego para agrupar y comparar.
///
/// `mesas` dice QUIÉN LA VE, y no dónde está guardada. Una cata siempre es
/// tuya y siempre está en tu diario: la lista vacía quiere decir que no la ve
/// nadie más, y cada identificador que lleve es una mesa cuya gente la ve.
///
/// Antes era un `mesaId` suelto y una cata vivía en un único sitio: o en tu
/// libreta o en una mesa, nunca en las dos. Eso obligaba a elegir entre
/// guardarla para ti o enseñarla, y a la gente le salía la cuenta al revés:
/// apuntaban la croqueta, se iba a la libreta y su mesa no la veía nunca.
class Cata {
  const Cata({
    required this.id,
    required this.sitio,
    required this.ciudad,
    required this.corte,
    required this.sabores,
    required this.autorId,
    required this.fecha,
    this.mesas = const <String>[],
    this.autorUid,
    this.pais = Paises.porDefecto,
    this.precio,
    this.nota = '',
    this.mordiscos = 0,
    this.acompanantes = const <String>[],
    this.lat,
    this.lon,
    this.medios = const <Medio>[],
    this.aptas = const <Dieta>{},
    this.receta,
    this.tiro,
    this.formato = Formato.sinDecir,
    this.unidades = 0,
  });

  final String id;
  final String sitio;
  final String ciudad;

  /// Código ISO de dos letras.
  final String pais;

  final Corte corte;

  /// Uno si es una croqueta suelta, varios si es un surtido. Nunca vacío.
  final List<Sabor> sabores;
  final String autorId;

  /// Las mesas cuya gente ve esta cata. Vacía: sólo tú.
  final List<String> mesas;

  final DateTime fecha;

  /// Quién la apuntó, con su identificador de cuenta.
  ///
  /// [autorId] es local y sólo vale dentro de un móvil: en el tuyo, tus catas
  /// y las de tu gente pueden tener el mismo. Para saber de quién es una cata
  /// que llegó de otro teléfono hace falta esto, que es lo que guardan los
  /// miembros de una mesa. Nulo en las catas apuntadas sin cuenta.
  final String? autorUid;

  /// Precio por unidad. Nulo cuando no se apuntó.
  final double? precio;

  /// Tapa, media ración o ración.
  final Formato formato;

  /// Cuántas croquetas traía. Cero si no se apuntó.
  final int unidades;

  bool get sabemosLaRacion => formato.seDijo || unidades > 0;

  /// Lo que costó el plato entero, si hay precio y unidades.
  double? get precioTotal =>
      precio == null || unidades <= 0 ? null : precio! * unidades;

  /// "Ración de 6", "Tapa de 2", "3 croquetas".
  String get racion {
    if (formato.seDijo && unidades > 0) {
      return '${formato.nombre} de $unidades';
    }
    if (formato.seDijo) return formato.nombre;
    if (unidades > 0) return '$unidades croquetas';
    return '';
  }

  /// La nota escrita, no la numérica.
  final String nota;

  final int mordiscos;

  /// Con quién te las comiste, por su nombre.
  ///
  /// Nombres escritos a mano y no identificadores: hasta que no haya cuentas
  /// no hay a quién apuntar, y obligar a elegir entre cinco personas de
  /// mentira era pedirle al usuario que mintiera sobre con quién come.
  final List<String> acompanantes;

  List<Persona> get gente =>
      acompanantes.map(Persona.deNombre).toList();
  final double? lat;
  final double? lon;

  /// Hasta dos fotos y un vídeo de 15 segundos.
  final List<Medio> medios;

  /// Cómo estaba hecha: bechamel, rebozado y freidora. Nulo si no se apuntó.
  ///
  /// De aquí salen las dietas y los alérgenos. Es la diferencia entre que la
  /// app sepa algo y que repita una etiqueta que alguien marcó a ojo.
  final Receta? receta;

  /// La prueba del tiro al plato, si se hizo. Es un apunte, no una nota: no
  /// entra en el CataScore ni cambia el dibujo.
  final TiroAlPlato? tiro;

  /// Las dietas marcadas a mano en las catas anteriores a la receta.
  ///
  /// Se conserva para no perder lo que ya estaba apuntado, pero no se pide en
  /// el formulario: ahora se preguntan hechos y las dietas se deducen.
  final Set<Dieta> aptas;

  double get puntuacion => corte.nota;

  /// Un surtido es, simplemente, una cata con más de un sabor. No hace falta
  /// una bandera aparte: el dato ya lo dice.
  bool get esSurtido => sabores.length > 1;

  /// El sabor que manda: el mejor valorado. Es el que da color a la tarjeta y
  /// el que se dibuja cuando sólo cabe un corte.
  Sabor get saborPrincipal => sabores.isEmpty
      ? const Sabor(rellenoId: 'otro')
      : sabores.reduce((Sabor a, Sabor b) =>
          b.veredicto.valor > a.veredicto.valor ? b : a);

  /// Se mantiene para todo lo que pinta una croqueta sola (tarjetas, platos,
  /// El Corte); así el resto de la app no necesita saber si hay surtido.
  String get rellenoId => saborPrincipal.rellenoId;

  /// Media de los veredictos del surtido. Nula si sólo hay un sabor: ahí la
  /// nota que vale es el CataScore, no una media de uno.
  double? get mediaSabores {
    if (!esSurtido) return null;
    double suma = 0;
    for (final Sabor s in sabores) {
      suma += s.veredicto.valor;
    }
    return suma / sabores.length;
  }

  /// El mejor y el peor del surtido. Es lo que de verdad quiere contar quien
  /// pide una ración variada.
  Sabor? get mejorSabor => esSurtido ? saborPrincipal : null;

  Sabor? get peorSabor => esSurtido
      ? sabores.reduce((Sabor a, Sabor b) =>
          b.veredicto.valor < a.veredicto.valor ? b : a)
      : null;

  bool get tieneUbicacion => lat != null && lon != null;

  Pais get paisInfo => Paises.de(pais);

  /// "Sevilla 🇪🇸" — lo que se pinta debajo del nombre del sitio.
  String get lugar => ciudad.isEmpty
      ? paisInfo.nombre
      : '$ciudad ${paisInfo.bandera}';

  /// "Bar Manoli · Sevilla 🇪🇸"
  String get sitioYLugar => '$sitio · $lugar';

  List<Medio> get fotos =>
      medios.where((Medio m) => m.tipo == TipoMedio.foto).toList();

  List<Medio> get videos =>
      medios.where((Medio m) => m.tipo == TipoMedio.video).toList();

  bool get tieneMedios => medios.isNotEmpty;

  /// Todos los ingredientes de la cata, sin repetir.
  ///
  /// Un sabor puede llevar varios, así que aquí se aplanan: una croqueta de
  /// jamón y boletus no es vegana, y con sólo mirar el principal lo habría
  /// sido si el principal era el boletus.
  /// Todo lo que se sabe que lleva, en palabras sueltas.
  ///
  /// Es contra esto contra lo que se mira la lista de "no me pongas". Son
  /// sólo los rellenos, no la nota: en la nota la gente escribe "el sésamo
  /// del pan de al lado" y una coincidencia ahí sería una falsa alarma, que
  /// en un aviso de alergias es lo que hace que se deje de mirar.
  List<String> get loQueLleva =>
      <String>[for (final Sabor s in sabores) ...s.nombres];

  /// Los textos por los que se puede encontrar esta cata al buscar.
  ///
  /// Van sueltos y no pegados en una sola cadena para que una palabra no case
  /// a caballo entre dos campos: con «Bar Manoli» y «Sevilla» juntos, buscar
  /// «manoli sevilla» encontraría algo que en la ficha no se lee así.
  ///
  /// La nota sí entra, al revés que en [loQueLleva]. Son dos cosas distintas:
  /// allí una coincidencia en la nota sería una falsa alarma de alergia, y
  /// aquí es justo lo que se busca —«aquella que ponía que picaba»—, porque
  /// la búsqueda la pide el usuario y la lee él.
  List<String> get paraBuscar => <String>[
        sitio,
        ciudad,
        nota,
        ...loQueLleva,
        ...acompanantes,
      ];

  List<Relleno> get rellenos => sabores
      .expand((Sabor s) => s.idsParaDietas)
      .toSet()
      .map(Rellenos.de)
      .toList();

  /// Para quién vale.
  ///
  /// Si hay receta se deduce de ella; si no, se enseña lo que se marcó a mano
  /// en su día. Nunca se mezclan las dos cosas: una lista mitad deducida y
  /// mitad a ojo no se puede explicar en la ficha, y aquí explicar por qué
  /// algo es apto es la mitad del valor.
  Set<Dieta> get aptasCalculadas => receta == null
      ? aptas
      : Dieta.deducir(receta: receta!, rellenos: rellenos);

  /// Las dietas en el orden de [Dieta.values], que es el orden con el que se
  /// pintan en toda la app.
  List<Dieta> get dietas => Dieta.ordenar(aptasCalculadas);

  bool get tieneDietas => aptasCalculadas.isNotEmpty;

  /// Las dietas que se pueden descartar con lo apuntado. Ver [Dieta.descartar].
  Set<Dieta> get descartadas => receta == null
      ? const <Dieta>{}
      : Dieta.descartar(receta: receta!, rellenos: rellenos);

  /// Todo lo que lleva, junte lo que junte el relleno y la base.
  Set<Alergeno> get alergenos => <Alergeno>{
        for (final Relleno r in rellenos) ...r.alergenos,
        ...?receta?.alergenos,
      };

  /// Lo que no se puede descartar porque no se preguntó.
  Set<Alergeno> get alergenosDudosos => receta?.dudosos ?? const <Alergeno>{};

  /// ¿Puede comérsela quien come así?
  ///
  /// Tres respuestas y no dos, porque "no lo sé" no es "no": una cata sin
  /// receta apuntada no es una cata que no te valga, es una de la que nadie
  /// preguntó. Meterlas en el mismo saco esconde las que sí te valdrían si
  /// alguien se molestara en preguntar.
  Encaje encajeCon(Set<Dieta> mias) {
    if (mias.isEmpty) return Encaje.sinSaber;
    if (receta == null && aptas.isEmpty) return Encaje.sinSaber;

    // Un «no» sólo cuando hay un hecho apuntado que lo contradice.
    //
    // Antes bastaba con que la dieta no estuviera entre las deducidas, y eso
    // mete en el mismo saco «lleva gluten» y «nadie preguntó de qué era la
    // bechamel». Con la receta a medias —que es como se apuntan casi todas:
    // relleno «a mi manera», bechamel «no lo sé»— no se deduce nada, así que
    // la app le contestaba «⛔ No te vale» a un celíaco sobre una croqueta de
    // la que no sabía absolutamente nada. Eso es lo contrario de lo que esta
    // sección promete, y esconde justo las que se habría comido preguntando.
    if (mias.intersection(descartadas).isNotEmpty) return Encaje.no;

    // Lo que no se descarta pero tampoco se afirma es una pregunta, no un no.
    if (mias.difference(aptasCalculadas).isNotEmpty) return Encaje.ojo;

    if (riesgoDeFreidora && mias.contains(Dieta.sinGluten)) return Encaje.ojo;

    final bool dudaQueMeAfecta = mias.any(
      (Dieta d) => d.alergeno != null && alergenosDudosos.contains(d.alergeno),
    );
    return dudaQueMeAfecta ? Encaje.ojo : Encaje.vale;
  }

  /// Sale sin gluten en la receta, pero se fríe donde todo lo demás.
  ///
  /// Merece un aviso propio en la ficha: es la trampa que más veces se lleva
  /// por delante a un celíaco en un bar, y la receta sola no la ve.
  bool get riesgoDeFreidora =>
      aptasCalculadas.contains(Dieta.sinGluten) &&
      receta != null &&
      receta!.freidora != Freidora.aparte;

  /// Vale para todas las dietas pedidas. Con el filtro vacío vale cualquiera:
  /// así la pantalla de la Barra Libre no necesita un caso aparte.
  /// Por [aptasCalculadas] y no por [aptas].
  ///
  /// `aptas` son las que alguien marcó a mano, y están vacías en todo lo que
  /// se apunta hoy. Comparando contra ésas, la Barra Libre enseñaba la lista
  /// entera sin filtro y CERO en cuanto marcabas «sin gluten», aunque
  /// hubiera diez deducidas de su receta como sin gluten. A un celíaco le
  /// decía que no hay nada para él.
  bool valePara(Set<Dieta> pedidas) => pedidas.every(aptasCalculadas.contains);

  /// La misma cata con dueño de cuenta.
  ///
  /// Aparte de [copyWith] porque esto no es una corrección del usuario: es
  /// la app apuntando quién la escribió, y conviene que se lea distinto.
  /// La primera foto de verdad, si la hay.
  ///
  /// Vídeos fuera: lo que se quiere aquí es una imagen fija que se pueda
  /// pintar en una estampa o en una miniatura sin reproducir nada.
  Medio? get primeraFoto {
    for (final Medio m in medios) {
      if (m.tipo == TipoMedio.foto) return m;
    }
    return null;
  }

  /// Si esta cata la apuntaste tú, estés en el móvil que estés.
  ///
  /// Hay que preguntarlo así y no mirando [autorId], porque [autorId] vale
  /// `'tu'` en TODOS los teléfonos: es un identificador de andar por casa.
  /// Una cata que llega de la mesa de otra persona trae `autorId: 'tu'`
  /// igualmente, así que compararlo contaba las croquetas de los demás como
  /// tuyas —en el perfil, en las medallas, en el filtro «Mías»— y te ponía
  /// el botón de borrar encima de una cata que no era tuya.
  ///
  /// [autorUid] manda siempre que lo haya. Sólo es nulo en las catas
  /// apuntadas en este móvil antes de que hubiera cuentas, y ésas nunca
  /// han salido de aquí: si no tiene uid, es local, y entonces [autorId]
  /// sí dice la verdad.
  /// Si no la ve nadie más que tú.
  bool get esSoloMia => mesas.isEmpty;

  /// Si la gente de esa mesa la ve.
  bool estaEn(String mesaId) => mesas.contains(mesaId);

  /// La misma cata, vista por quien la recibe desde una mesa concreta.
  ///
  /// Hace falta porque el documento del servidor no puede llevar la lista
  /// entera: en qué OTRAS mesas tienes puesta una cata es cosa tuya, y no
  /// tiene por qué saberlo la gente de ésta.
  Cata soloEnLaMesa(String mesaId) => copyWith(mesas: <String>[mesaId]);

  bool esMia(String? miUid) {
    // Sin sesión manda el identificador local: sin cuenta no llega nada de
    // fuera, así que lo que hay en este móvil es tuyo.
    if (miUid == null) return autorId == 'tu';
    if (autorUid == null) return autorId == 'tu';
    return autorUid == miUid;
  }

  Cata conAutorUid(String uid) => Cata(
        id: id,
        sitio: sitio,
        ciudad: ciudad,
        pais: pais,
        sabores: sabores,
        corte: corte,
        autorId: autorId,
        autorUid: uid,
        mesas: mesas,
        fecha: fecha,
        precio: precio,
        nota: nota,
        mordiscos: mordiscos,
        acompanantes: acompanantes,
        lat: lat,
        lon: lon,
        medios: medios,
        aptas: aptas,
        receta: receta,
        tiro: tiro,
        formato: formato,
        unidades: unidades,
      );

  Cata copyWith({
    String? sitio,
    String? ciudad,
    String? pais,
    List<Sabor>? sabores,
    Corte? corte,
    List<String>? mesas,
    double? precio,
    String? nota,
    int? mordiscos,
    List<String>? acompanantes,
    double? lat,
    double? lon,
    List<Medio>? medios,
    Set<Dieta>? aptas,
    Receta? receta,
    TiroAlPlato? tiro,
    Formato? formato,
    int? unidades,
  }) {
    return Cata(
      id: id,
      sitio: sitio ?? this.sitio,
      ciudad: ciudad ?? this.ciudad,
      pais: pais ?? this.pais,
      sabores: sabores ?? this.sabores,
      corte: corte ?? this.corte,
      autorId: autorId,
      autorUid: autorUid,
      mesas: mesas ?? this.mesas,
      fecha: fecha,
      precio: precio ?? this.precio,
      nota: nota ?? this.nota,
      mordiscos: mordiscos ?? this.mordiscos,
      acompanantes: acompanantes ?? this.acompanantes,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      medios: medios ?? this.medios,
      aptas: aptas ?? this.aptas,
      receta: receta ?? this.receta,
      tiro: tiro ?? this.tiro,
      formato: formato ?? this.formato,
      unidades: unidades ?? this.unidades,
    );
  }

  /// En qué mesas está, leyendo tanto el formato nuevo como el viejo.
  static List<String> _mesasDesdeJson(Map<String, dynamic> json) {
    final Object? nuevo = json['mesas'];
    if (nuevo is List<dynamic>) {
      return <String>[
        for (final dynamic m in nuevo)
          if (m.toString().isNotEmpty && m.toString() != 'libreta')
            m.toString(),
      ];
    }

    final String viejo = json['mesaId'] as String? ?? 'libreta';
    return viejo == 'libreta' ? const <String>[] : <String>[viejo];
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'sitio': sitio,
        'ciudad': ciudad,
        'pais': pais,
        'sabores': sabores.map((Sabor s) => s.toJson()).toList(),
        'corte': corte.toJson(),
        'autorId': autorId,
        'autorUid': autorUid,
        'mesas': mesas,
        'fecha': fecha.toIso8601String(),
        'precio': precio,
        'nota': nota,
        'mordiscos': mordiscos,
        'acompanantes': acompanantes,
        'lat': lat,
        'lon': lon,
        'medios': medios.map((Medio m) => m.toJson()).toList(),
        'aptas': aptas.map((Dieta d) => d.id).toList(),
        'receta': receta?.toJson(),
        'tiro': tiro?.id,
        'formato': formato.name,
        'unidades': unidades,
      };

  factory Cata.fromJson(Map<String, dynamic> json) => Cata(
        id: json['id'] as String,
        sitio: json['sitio'] as String? ?? 'Sitio sin nombre',
        // Las catas guardadas antes de abrir la app al mundo tienen `barrio`
        // y no `ciudad`. Se leen igual y el barrio pasa a ser la ciudad: es
        // más útil que perder el dato, y el usuario puede corregirlo.
        // Las catas guardadas antes del arreglo llevan el literal 'Sin
        // ciudad' escrito en el campo. Al leerlas se limpia: si no, la ficha
        // sigue diciendo "SIN CIUDAD 🇪🇸 · Bar Manoli" como si hubiera un
        // pueblo con ese nombre, y esa cata sigue contando como una ciudad
        // en el Croquetómetro y acercando la medalla de las diez.
        ciudad: _ciudadLimpia(
          json['ciudad'] as String? ?? json['barrio'] as String? ?? '',
        ),
        pais: json['pais'] as String? ?? Paises.porDefecto,
        corte: Corte.fromJson(
          Map<String, dynamic>.from(json['corte'] as Map<dynamic, dynamic>),
        ),
        // Las catas guardadas antes de los surtidos tienen un `rellenoId`
        // suelto. Se convierte en un sabor único, con el veredicto que
        // corresponde a la nota que ya tenían.
        sabores: _saboresDesdeJson(json),
        autorId: json['autorId'] as String? ?? 'tu',
        autorUid: json['autorUid'] as String?,
        // Puente con lo guardado antes: entonces había un `mesaId` suelto
        // y la libreta era un destino más. Una cata que estaba en la libreta
        // pasa a no estar en ninguna mesa —que es lo mismo: sólo la ves tú—
        // y una que estaba en una mesa pasa a estar en esa y nada más.
        mesas: _mesasDesdeJson(json),
        fecha: DateTime.tryParse(json['fecha'] as String? ?? '') ??
            DateTime.now(),
        precio: (json['precio'] as num?)?.toDouble(),
        nota: json['nota'] as String? ?? '',
        mordiscos: (json['mordiscos'] as num?)?.toInt() ?? 0,
        // Las catas viejas guardaban el id de una persona del catálogo de
        // demostración ('marta'). Se traduce a su nombre para no perder con
        // quién estabas; lo que no esté, se queda tal cual.
        acompanantes: (json['acompanantes'] as List<dynamic>? ?? <dynamic>[])
            .map((dynamic e) => Persona.nombreGuardado(e.toString()))
            .toList(),
        lat: (json['lat'] as num?)?.toDouble(),
        lon: (json['lon'] as num?)?.toDouble(),
        medios: (json['medios'] as List<dynamic>? ?? <dynamic>[])
            .map((dynamic e) =>
                Medio.fromJson(Map<String, dynamic>.from(e as Map<dynamic, dynamic>)))
            .toList(),
        // Las catas guardadas antes de la Barra Libre no tienen dietas. Se
        // quedan sin ninguna marcada, que es la verdad: nadie las miró.
        aptas: Dieta.desdeJson(json['aptas']),
        // Las catas anteriores a la receta no tienen: se quedan con las
        // dietas que se marcaron a mano, que es lo que había.
        receta: json['receta'] == null
            ? null
            : Receta.fromJson(
                Map<String, dynamic>.from(
                  json['receta'] as Map<dynamic, dynamic>,
                ),
              ),
        formato: Formato.deNombre(json['formato'] as String? ?? ''),
        unidades: (json['unidades'] as num?)?.toInt() ?? 0,
        // Las catas de antes de la prueba del tiro no la llevan, y las de
        // una versión más nueva podrían traer un valor que aquí no existe.
        // En los dos casos se queda sin apunte, que es la verdad.
        tiro: TiroAlPlato.desdeId(json['tiro']),
      );

  static List<Sabor> _saboresDesdeJson(Map<String, dynamic> json) {
    final List<dynamic>? lista = json['sabores'] as List<dynamic>?;
    if (lista != null && lista.isNotEmpty) {
      return lista
          .map((dynamic e) =>
              Sabor.fromJson(Map<String, dynamic>.from(e as Map<dynamic, dynamic>)))
          .toList();
    }

    final Corte corte = Corte.fromJson(
      Map<String, dynamic>.from(json['corte'] as Map<dynamic, dynamic>),
    );
    return <Sabor>[
      Sabor(
        rellenoId: json['rellenoId'] as String? ?? 'jamon',
        veredicto: Veredicto.deValor(corte.nota),
      ),
    ];
  }

  /// Quita las repetidas, quedándose con la primera de cada id.
  ///
  /// Dos catas con el mismo id no deberían existir, pero pueden: una copia de
  /// seguridad restaurada dos veces, una sincronización a medias, un guardado
  /// que se cruzó. Y cuando existen no dan un error claro, sino tres rarezas
  /// sueltas: el Croquetómetro cuenta de más, una mesa enseña la misma
  /// croqueta dos veces y —la peor— al tocar una de las dos la app se cierra,
  /// porque el dibujo que vuela de la lista a la ficha necesita saber cuál de
  /// las dos despega y no puede.
  ///
  /// Se quita al leer y no al guardar: lo guardado ya puede estar así.
  static List<Cata> sinRepetidas(Iterable<Cata> catas) {
    final Set<String> vistas = <String>{};
    return <Cata>[
      for (final Cata c in catas)
        if (vistas.add(c.id)) c,
    ];
  }
}


/// Quita los literales que alguna versión vieja escribía en el campo ciudad.
///
/// Vacío es la respuesta correcta para "no lo dijo": `Cata.lugar` ya sabe
/// enseñar el país en ese caso.
String _ciudadLimpia(String ciudad) {
  const Set<String> inventados = <String>{'sin ciudad', 'sin sitio', '-', '—'};
  final String limpia = ciudad.trim();
  return inventados.contains(limpia.toLowerCase()) ? '' : limpia;
}
