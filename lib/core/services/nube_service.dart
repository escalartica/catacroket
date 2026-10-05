import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../errores.dart';
import '../models/cata.dart';
import '../models/medio.dart';
import '../models/mesa.dart';
import 'cuenta_service.dart';
import '../utils/archivos.dart';

/// Una mesa tal y como está en el servidor ahora mismo.
typedef MesaViva = ({
  String? nombre,
  String? descripcion,
  int? colorHex,
  List<String> miembros,
});

/// Lo que puede salir mal al compartir, ya traducido.
class FalloNube implements Exception {
  const FalloNube(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Compartir mesas entre móviles.
///
/// Esto es lo ÚNICO de la app que sale a internet. Tus catas de la libreta
/// privada no pasan por aquí nunca: sólo viajan las de una mesa que hayas
/// compartido a propósito.
///
/// Las fotos sí viajan, pero en pequeño y dentro de la propia cata: se
/// reducen a 800 píxeles y se meten codificadas en el mismo documento,
/// porque guardar ficheros aparte exigiría otro servicio —y su factura—.
/// El dibujo del corte no viaja como imagen: sale de los cuatro números y se
/// repinta en cada móvil.
class NubeService {
  const NubeService._();

  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _mesas =>
      _db.collection('mesas');

  /// Lo que se espera a que el servidor conteste antes de rendirse.
  ///
  /// Hace falta porque el `Future` de una escritura de Firestore no se
  /// resuelve hasta que el servidor confirma: sin cobertura no falla, es que
  /// no vuelve nunca. Sin esto, pulsar «Activar el código» en un bar sin
  /// línea dejaba el botón en «Activando…» para siempre, sin error y sin
  /// vuelta atrás, y la cola de pendientes —que existe justo para eso— no
  /// se enteraba porque el `catch` tampoco llegaba a ejecutarse.
  static const Duration _tope = Duration(seconds: 12);

  static Future<T> _conTope<T>(Future<T> faena) => faena.timeout(
        _tope,
        onTimeout: () => throw const FalloNube(
          'Sin conexión. Inténtalo cuando vuelva la cobertura.',
        ),
      );

  static String get _uid {
    final String? uid = CuentaService.quien?.uid;
    if (uid == null) {
      throw const FalloNube('Para esto hace falta entrar con tu cuenta.');
    }
    return uid;
  }

  // ── Compartir una mesa ────────────────────────────────────────────────

  /// Sube una mesa tuya y la deja abierta a quien tenga el código.
  ///
  /// El código se guarda aparte, en su propia colección, porque quien todavía
  /// no es miembro no puede leer la mesa —lo impiden las reglas— y tiene que
  /// poder traducir el código en un identificador para pedir entrar.
  /// Devuelve el código con el que se invita a la mesa.
  ///
  /// Devolverlo no es un detalle: quien comparte necesita verlo en la
  /// pantalla inmediatamente después, para dictarlo o copiarlo. Antes esto
  /// no devolvía nada y la mesa local se quedaba sin código hasta la
  /// siguiente sincronización, así que la pantalla enseñaba
  /// «MESA COMPARTIDA · null» y el botón de copiar copiaba una cadena vacía.
  static Future<String> compartir(Mesa mesa) async {
    if (mesa.esLibreta) {
      throw const FalloNube('La libreta es tuya y no se comparte.');
    }

    // El código se aparta ANTES de escribir la mesa, y el orden importa.
    // Al revés, una colisión dejaba la mesa ya escrita con un código que es
    // de otra mesa, y ese código llevaba al sitio equivocado. Así, si no hay
    // código libre, no se escribe nada.
    //
    // Y SIEMPRE se aparta, aunque la mesa ya traiga código. Una mesa recién
    // creada ya lleva uno puesto en el móvil —se enseña antes de compartir—,
    // así que dar por reservado el que trae significaba no escribir nunca el
    // documento del código, y entonces quien lo tecleaba recibía «ese código
    // no existe». El código local es una PREFERENCIA, no una reserva.
    final String codigo = await _reservarCodigo(mesa.id, mesa.codigo);

    // ¿Existe ya en el servidor? Se pregunta en vez de fiarse de `enLaNube`,
    // que es una marca del móvil y puede mentir: basta con vaciar la base de
    // datos —cosa que hay que hacer antes de publicar la app— para que el
    // móvil siga creyendo que la mesa está subida cuando ya no está.
    //
    // Importa porque las reglas sólo dejan poner `creadoPor` al crear: si lo
    // mandáramos siempre, volver a compartir la mesa de otro se rechazaría,
    // y si no lo mandáramos nunca, crearla se rechazaría también.
    bool esNueva = true;
    try {
      esNueva = !(await _conTope(_mesas.doc(mesa.id).get())).exists;
    } on FirebaseException {
      // Si no se puede comprobar, se intenta como nueva: crearla es lo que
      // falla de forma limpia y recuperable si resulta que ya estaba.
    }

    try {
      await _conTope(_mesas.doc(mesa.id).set(
        <String, dynamic>{
          'nombre': mesa.nombre,
          'descripcion': mesa.descripcion,
          'colorHex': mesa.colorHex,
          'codigo': codigo,
          // arrayUnion y no una lista nueva: compartir otra vez una mesa que
          // ya tiene gente dentro NO puede echarla. Con `[_uid]` a secas, la
          // segunda vez que alguien pulsaba compartir se quedaba solo.
          'miembros': FieldValue.arrayUnion(<String>[_uid]),
          // Sólo al crearla. Yendo en el merge siempre, volver a pulsar
          // compartir reescribía la fecha de creación en cada pulsación y
          // chocaría con las reglas, que protegen al dueño de la mesa.
          if (esNueva) ...<String, dynamic>{
            'creadoPor': _uid,
            'creada': FieldValue.serverTimestamp(),
          },
        },
        SetOptions(merge: true),
      ));
    } on FirebaseException catch (e) {
      // Queda un código apuntando a una mesa que no llegó a escribirse. No se
      // puede limpiar —las reglas no dejan borrar códigos, a propósito— pero
      // es inofensivo: quien lo teclee recibe un «no se pudo entrar», que es
      // mucho mejor que entrar en la mesa de otro.
      throw FalloNube(_traducir(e));
    }

    return codigo;
  }

  /// Aparta un código de seis letras que no tenga nadie.
  ///
  /// Se apoya en las reglas del servidor: dejan CREAR un documento de código
  /// pero no modificar uno que ya exista. O sea que escribir sobre un código
  /// cogido falla, y ese fallo es justo lo que avisa de la colisión.
  ///
  /// Con 31 letras y seis huecos son 887 millones de combinaciones, así que
  /// esto casi nunca dará una segunda vuelta. Casi nunca no es nunca.
  static Future<String> _reservarCodigo(String mesaId, String? preferido) async {
    // Primero el que la mesa ya enseña en el móvil, para no cambiárselo a
    // quien quizá ya lo tenga apuntado.
    if (preferido != null && await _apartar(preferido, mesaId)) return preferido;

    for (int intento = 0; intento < 5; intento++) {
      final String codigo = Mesa.nuevoCodigo();
      if (await _apartar(codigo, mesaId)) return codigo;
    }

    throw const FalloNube(
      'No se ha podido crear el código de la mesa. Inténtalo otra vez.',
    );
  }

  /// Intenta escribir el documento del código. `true` si queda apartado para
  /// esta mesa, `false` si lo tiene otra.
  ///
  /// Las reglas dejan CREAR un código pero no modificar uno que exista, así
  /// que escribir sobre uno cogido falla, y ese fallo es el que avisa.
  static Future<bool> _apartar(String codigo, String mesaId) async {
    try {
      await _conTope(_db.collection('codigos').doc(codigo).set(<String, dynamic>{
        'mesaId': mesaId,
        'creadoPor': _uid,
      }));
      return true;
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') throw FalloNube(_traducir(e));
    }

    // Puede ser de otra mesa… o de ÉSTA, de una vez anterior. Volver a
    // compartir una mesa ya compartida tiene que seguir funcionando.
    try {
      final DocumentSnapshot<Map<String, dynamic>> ya =
          await _conTope(_db.collection('codigos').doc(codigo).get());
      return ya.exists && ya.data()?['mesaId'] == mesaId;
    } on FirebaseException catch (e) {
      // Que no se pueda leer no significa que el código sea de otro. Darlo
      // por ocupado gastaba los cinco intentos contra el mismo muro y
      // acababa en «no se ha podido crear el código», que no dice nada de
      // lo que de verdad pasa, que es que no hay internet.
      throw FalloNube(_traducir(e));
    }
  }

  // ── Quién es quién ────────────────────────────────────────────────────

  /// Publica tu nombre para que tu gente lo vea en sus mesas.
  ///
  /// Sin esto, los demás miembros de una mesa salían todos como «Alguien»:
  /// el móvil sólo conocía los nombres de su propia libreta, y el de una
  /// cuenta ajena no estaba en ninguna parte. Se llama al entrar y al
  /// cambiarte el nombre en el perfil.
  ///
  /// Si falla no se avisa: es un extra, y no poder publicarlo no puede
  /// impedirte usar la app.
  static Future<void> publicarNombre(String nombre) async {
    try {
      await _conTope(_db.collection('usuarios').doc(_uid).set(<String, dynamic>{
        'nombre': nombre,
      }, SetOptions(merge: true)));
    } catch (error, pila) {
      // Sigue sin molestar al usuario, pero ahora queda apuntado: cuando
      // alguien dice «a mi gente le sigo saliendo como Alguien», esto es lo
      // primero que hay que mirar y antes no dejaba ni rastro.
      Errores.registrar(error, pila, origen: 'nube.publicarNombre');
    }
  }

  /// Los nombres de esa gente, por su identificador de cuenta.
  ///
  /// Devuelve sólo los que encuentra: quien no haya abierto la app desde que
  /// existe esto no tiene nombre publicado todavía, y su sitio en la mesa se
  /// pinta como «Alguien» igual que antes.
  /// Los nombres de esa gente, y los que vayan cambiando.
  ///
  /// En vivo y no de una vez, y la diferencia se nota: con una sola consulta,
  /// quien se ponía nombre después de que tú abrieras la app te seguía
  /// saliendo como «Alguien» hasta que la cerrabas y la volvías a abrir.
  /// Justo el caso normal — dos personas estrenando una mesa a la vez.
  ///
  /// Va por tandas de 30 porque es el tope de `whereIn` de Firestore, y se
  /// acumulan: cada tanda que responde completa el mapa sin pisar a las otras.
  static Stream<Map<String, String>> nombresVivosDe(List<String> uids) {
    if (uids.isEmpty) return Stream<Map<String, String>>.value(const <String, String>{});

    final Map<String, String> acumulado = <String, String>{};
    final List<StreamSubscription<QuerySnapshot<Map<String, dynamic>>>> hilos =
        <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];
    late final StreamController<Map<String, String>> salida;

    salida = StreamController<Map<String, String>>(
      // En `onListen` y no sueltas aquí mismo: escuchando al construir, una
      // pantalla de mesas que se abre y se cierra de golpe —o un cambio de
      // cuenta al arrancar— dejaba las consultas vivas sin que nadie llegara
      // a suscribirse, así que `onCancel` no saltaba nunca y se quedaban
      // hablando con Firestore hasta cerrar la app.
      onListen: () {
        for (int i = 0; i < uids.length; i += 30) {
          final List<String> tanda =
              uids.sublist(i, i + 30 > uids.length ? uids.length : i + 30);
          hilos.add(
            _db
                .collection('usuarios')
                .where(FieldPath.documentId, whereIn: tanda)
                .snapshots()
                .listen(
              (QuerySnapshot<Map<String, dynamic>> foto) {
                for (final QueryDocumentSnapshot<Map<String, dynamic>> d
                    in foto.docs) {
                  final String? nombre = d.data()['nombre'] as String?;
                  if (nombre != null && nombre.trim().isNotEmpty) {
                    acumulado[d.id] = nombre.trim();
                  }
                }
                if (!salida.isClosed) {
                  salida.add(Map<String, String>.from(acumulado));
                }
              },
              // Que una tanda falle no puede dejar sin nombre a las demás.
              onError: (Object _) {},
            ),
          );
        }
      },
      onCancel: () async {
        for (final StreamSubscription<QuerySnapshot<Map<String, dynamic>>> h
            in hilos) {
          await h.cancel();
        }
        hilos.clear();
        await salida.close();
      },
    );

    return salida.stream;
  }

  /// Las mesas compartidas en las que estás, según el servidor.
  ///
  /// Hace falta porque las mesas vivían SÓLO en el móvil: quien reinstalaba
  /// la app o estrenaba teléfono se quedaba sin ellas aunque siguieran en el
  /// servidor y siguiera siendo miembro, y la única salida era pedir otra vez
  /// el código a alguien. Al entrar con tu cuenta se recuperan solas.
  ///
  /// Si falla devuelve una lista vacía: no poder consultar el servidor no
  /// puede impedirte abrir la app con lo que ya tienes en el móvil.
  static Future<List<Mesa>> misMesas() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> s = await _conTope(
        _mesas.where('miembros', arrayContains: _uid).get(),
      );

      final List<Mesa> mesas = <Mesa>[];
      for (final QueryDocumentSnapshot<Map<String, dynamic>> d in s.docs) {
        // Una mesa con un campo corrupto no puede dejarte sin las demás.
        try {
          final Map<String, dynamic> m = d.data();
          mesas.add(
            Mesa(
              id: d.id,
              nombre: m['nombre'] as String? ?? 'Mesa',
              descripcion: m['descripcion'] as String? ?? '',
              colorHex: (m['colorHex'] as num?)?.toInt() ?? 0xFFFFC93C,
              miembros: <String>[
                for (final dynamic x
                    in (m['miembros'] as List<dynamic>? ?? const <dynamic>[]))
                  x.toString(),
              ],
              codigo: m['codigo'] as String?,
              enLaNube: true,
            ),
          );
        } catch (_) {}
      }
      return mesas;
    } catch (error, pila) {
      Errores.registrar(error, pila, origen: 'nube.misMesas');
      return const <Mesa>[];
    }
  }

  /// Entra en la mesa de otro con su código de seis letras.
  ///
  /// Devuelve la mesa ya montada, lista para guardarla en el móvil.
  static Future<Mesa> entrarCon(String codigo) async {
    final String limpio = codigo.trim().toUpperCase();
    if (limpio.length != 6) {
      throw const FalloNube('El código son seis letras.');
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>> ref =
          await _conTope(_db.collection('codigos').doc(limpio).get());

      // Un «no existe» que sale de la caché no significa que no exista:
      // significa que este móvil nunca lo ha visto. Firestore guarda copia
      // local y sin red contesta desde ella, así que el mensaje de antes
      // mandaba a comprobar un código bien escrito, y la culpa parecía de
      // quien lo tecleaba en vez de de la cobertura del bar.
      if (!ref.exists && ref.metadata.isFromCache) {
        throw const FalloNube(
          'Sin conexión. Inténtalo cuando vuelva la cobertura.',
        );
      }
      if (!ref.exists) {
        throw const FalloNube('Ese código no existe. Compruébalo.');
      }

      // Sin `!`: un documento de código sin `mesaId` lanzaría un TypeError,
      // que no es FirebaseException y se escapaba de todos los `catch` de
      // aquí y de la hoja. El usuario pulsaba «Entrar» y no pasaba nada:
      // ni mensaje, ni avance, ni pista.
      final Object? quizaId = ref.data()?['mesaId'];
      if (quizaId is! String || quizaId.isEmpty) {
        throw const FalloNube(
          'Ese código está roto. Pide otro a quien te invitó.',
        );
      }
      final String mesaId = quizaId;

      // Añadirse a sí mismo. Las reglas del servidor comprueban que sea
      // exactamente eso y nada más: quien tiene un código no puede renombrar
      // la mesa ni echar a nadie.
      await _conTope(_mesas.doc(mesaId).update(<String, dynamic>{
        'miembros': FieldValue.arrayUnion(<String>[_uid]),
      }));

      final DocumentSnapshot<Map<String, dynamic>> doc =
          await _conTope(_mesas.doc(mesaId).get());
      final Map<String, dynamic>? d = doc.data();
      if (d == null) {
        throw const FalloNube('Esa mesa ya no existe.');
      }

      return Mesa(
        id: mesaId,
        nombre: d['nombre'] as String? ?? 'Mesa',
        descripcion: d['descripcion'] as String? ?? '',
        colorHex: (d['colorHex'] as num?)?.toInt() ?? 0xFFFFC93C,
        miembros: <String>[
          for (final dynamic m in (d['miembros'] as List<dynamic>? ?? const <dynamic>[]))
            m.toString(),
        ],
        codigo: limpio,
      );
    } on FirebaseException catch (e) {
      throw FalloNube(_traducir(e));
    }
  }

  // ── Las catas de una mesa ─────────────────────────────────────────────

  // ── Las fotos ─────────────────────────────────────────────────────────

  /// El ancho al que se reduce una foto para que viaje.
  ///
  /// 800 píxeles se ven bien en la lista de una mesa y en la ficha, y en un
  /// móvil normal ni se nota. Más grande no cabe: las fotos van dentro de la
  /// propia cata, en Firestore, y ahí el techo es 1 MB por cata.
  static const int _anchoMini = 800;

  /// Lo máximo que puede pesar una miniatura YA codificada en base64.
  ///
  /// Ya codificada, y la palabra importa: antes se medían los bytes crudos
  /// del JPEG y se decía que el engorde de base64 estaba contado. Estaba
  /// contado al revés. 320 KB crudos son 427 KB codificados, dos fotos son
  /// 854 KB, y con el texto de la cata encima eso se come el techo de 1 MiB
  /// por documento de Firestore. La cata fallaba al subir con un error que
  /// no se entendía y se quedaba reintentando para siempre, mientras su
  /// autora la veía guardada y su mesa no la recibía nunca.
  ///
  /// 360 KB por foto deja ~280 KB para todo lo demás.
  static const int _pesoMaximoMini = 440 * 1024;

  /// Los apretones que se prueban, de mejor a peor, hasta que la foto quepa.
  ///
  /// El primero es el de siempre y es el que acierta en casi todas: una foto
  /// de móvil a 800 píxeles de ancho y calidad 72 pesa bastante menos del
  /// tope. Los otros dos son para las raras —un panorama, una captura enorme—
  /// que antes se quedaban sin viajar sin que nadie se enterara.
  static const List<(int, int)> _apreturas = <(int, int)>[
    (_anchoMini, 72),
    (_anchoMini, 55),
    (600, 45),
  ];

  /// Comprime las fotos que aún no viajan y las devuelve con su miniatura.
  ///
  /// Sólo fotos: un vídeo no cabe en una cata ni comprimido, y meterlo ahí
  /// sería reventar el límite en la primera.
  ///
  /// Las que ya tienen miniatura no se vuelven a comprimir: esto se llama
  /// también al corregir una cata, y rehacer la foto cada vez que alguien
  /// arregla una falta de ortografía es trabajo tirado.
  ///
  /// Lo que no se pueda comprimir se devuelve tal cual, y la cata se comparte
  /// sin esa foto. Mejor una cata sin foto que ninguna cata.
  static Future<List<Medio>> prepararFotos(Cata cata) async {
    final List<Medio> listos = <Medio>[];

    for (final Medio m in cata.medios) {
      if (m.esVideo || m.viaja || m.ruta.isEmpty) {
        listos.add(m);
        continue;
      }

      try {
        if (!Archivos.fichero(m.ruta).existsSync()) {
          listos.add(m);
          continue;
        }

        // Se aprieta hasta que quepa, en vez de rendirse a la primera.
        //
        // Antes, una foto que no cabía se quedaba en casa sin avisar, y lo
        // que veía quien la recibía era una cata sin foto y ningún motivo.
        // Una foto algo peor se parece mucho más a la foto que hiciste que
        // ninguna foto.
        String? codificada;
        for (final (int ancho, int calidad) in _apreturas) {
          final Uint8List? datos = await FlutterImageCompress.compressWithFile(
            Archivos.enDisco(m.ruta),
            minWidth: ancho,
            minHeight: ancho,
            quality: calidad,
            format: CompressFormat.jpeg,
          );
          if (datos == null) break;

          // Se mide lo que de verdad viaja, no lo que sale del compresor:
          // base64 engorda un tercio y el techo de Firestore es por documento.
          final String intento = base64Encode(datos);
          if (intento.length <= _pesoMaximoMini) {
            codificada = intento;
            break;
          }
        }

        // Ni al mínimo cabe: un panorama larguísimo, por ejemplo. Antes que
        // romper el guardado de la cata entera, esa foto se queda en casa.
        if (codificada == null) {
          listos.add(m);
          continue;
        }

        listos.add(m.conMini(codificada));
      } catch (_) {
        listos.add(m);
      }
    }

    return listos;
  }

  /// Sube una cata a su mesa compartida.
  ///
  /// Se le quitan los medios: son rutas de ficheros de ESTE móvil y en otro
  /// no existen. Mandar una ruta que el receptor no puede abrir es peor que
  /// no mandar nada, porque su app intentaría enseñar una foto rota.
  /// Devuelve los medios con sus urls, para que quien la subió guarde en su
  /// móvil lo que ya está en la nube y no lo vuelva a subir.
  /// Se sube UNA mesa por llamada. Una cata puede estar en varias, y en
  /// Firestore cada mesa guarda su propia copia —las catas cuelgan de la
  /// mesa, que es lo que permite que las reglas digan quién puede leerlas—.
  /// Quien llama recorre las mesas; aquí sólo se escribe una.
  static Future<List<Medio>> subirCata(
    Cata cata,
    String mesaId, {
    List<Medio>? yaPreparados,
  }) async {
    // Las fotos primero: si suben, la cata viaja con ellas; si no, viaja sin
    // ellas y se reintenta luego. Lo que no puede pasar es que la cata se
    // quede sin subir por culpa de una foto.
    //
    // `yaPreparados` evita comprimirlas una vez por mesa: una cata en tres
    // mesas apretaba la misma foto tres veces y gastaba el triple de batería
    // y de datos para subir exactamente lo mismo.
    final List<Medio> medios = yaPreparados ?? await prepararFotos(cata);

    try {
      final Map<String, dynamic> datos = Map<String, dynamic>.from(
        cata.toJson(),
      )
        // Sólo la parte de nube: la ruta local es de ESTE móvil y en otro no
        // abre nada. Antes se quitaban los medios enteros y por eso la gente
        // de una mesa nunca veía las fotos de los demás.
        ..['medios'] = <Map<String, dynamic>>[
          for (final Medio m in medios)
            if (m.viaja) m.paraViajar.toJsonParaLaNube(),
        ]
        ..['autorUid'] = _uid
        // Sólo esta mesa, no la lista entera: en qué OTRAS mesas tienes
        // puesta una cata es cosa tuya, y la gente de ésta no tiene por qué
        // saberlo. Quien la reciba la verá donde le toca y en ningún sitio
        // más.
        ..['mesas'] = <String>[mesaId]
        // Y el campo viejo, un par de versiones más. Un móvil sin actualizar
        // sólo entiende `mesaId`, y sin esto mete la cata que le llega de la
        // mesa en su libreta privada y firmada como suya. Durante el tiempo
        // en que unos han actualizado y otros no, que es siempre, eso es lo
        // peor que puede pasar.
        ..['mesaId'] = mesaId
        ..['subida'] = FieldValue.serverTimestamp();

      // Con merge: un móvil con una versión vieja de la app que corrige una
      // cata guardada por una nueva se llevaba por delante los campos que
      // su `toJson` todavía no conoce. Los medios van explícitos justo
      // arriba, así que quitar una foto sigue quitándola.
      await _conTope(
        _mesas
            .doc(mesaId)
            .collection('catas')
            .doc(cata.id)
            .set(datos, SetOptions(merge: true)),
      );

      return medios;
    } on FirebaseException catch (e) {
      throw FalloNube(_traducir(e));
    }
  }

  /// Borra una cata de su mesa compartida.
  ///
  /// Lanza si no se puede. Antes se tragaba el fallo «para no asustar», y lo
  /// que pasaba era peor que un susto: borrabas una cata sin cobertura,
  /// desaparecía del móvil, el servidor no se enteraba y al volver la red la
  /// cata regresaba al feed. Intentar borrarla otra vez no hacía nada —ya no
  /// estaba en la lista local— así que se quedaba ahí para siempre. Quien
  /// llama decide qué hacer; hoy, apuntarla en la cola de borrados.
  static Future<void> borrarCataDe(String mesaId, String cataId) async {
    try {
      await _conTope(
        _mesas.doc(mesaId).collection('catas').doc(cataId).delete(),
      );
    } on FirebaseException catch (e) {
      throw FalloNube(_traducir(e));
    }
  }

  /// Quién hay en esa mesa, según va entrando gente.
  ///
  /// La mesa se leía una sola vez, al entrar con el código, y nunca más. El
  /// resultado era que quien la creaba seguía viendo «tú sola» para siempre
  /// aunque los demás ya estuvieran dentro: el servidor lo sabía y el móvil
  /// no se enteraba. Sólo se escuchan los miembros; el nombre y el color son
  /// de quien la creó y no se pisan desde aquí.
  static Stream<MesaViva?> miembrosDe(String mesaId) {
    return _mesas.doc(mesaId).snapshots().map(
      (DocumentSnapshot<Map<String, dynamic>> d) {
        final Map<String, dynamic>? m = d.data();
        if (m == null) return null;
        return (
          nombre: m['nombre'] as String?,
          descripcion: m['descripcion'] as String?,
          colorHex: (m['colorHex'] as num?)?.toInt(),
          miembros: <String>[
            for (final dynamic x
                in (m['miembros'] as List<dynamic>? ?? const <dynamic>[]))
              x.toString(),
          ],
        );
      },
    );
  }

  /// Te saca de una mesa compartida.
  ///
  /// Hacía falta porque borrar una mesa sólo la quitaba de TU móvil. El
  /// servidor seguía teniéndote como miembro, así que al siguiente arranque
  /// `misMesas()` te la devolvía —con su código activo y las catas de la
  /// otra persona— pero vacía por tu lado, porque tus catas ya se habían
  /// salido de ella. Una mesa zombi que no había manera de quitar.
  /// Siempre quitándote de la lista, también si la creaste: borrar el
  /// documento entero le quitaría la mesa a los demás sin avisarles, y «me la
  /// quito de encima» no es lo mismo que «que desaparezca para todos».
  static Future<void> salirDe(Mesa mesa) async {
    try {
      await _conTope(_mesas.doc(mesa.id).update(<String, dynamic>{
        'miembros': FieldValue.arrayRemove(<String>[_uid]),
      }));
    } on FirebaseException catch (e) {
      throw FalloNube(_traducir(e));
    }
  }

  /// Sube el nombre, la descripción y el color de una mesa que ya existe.
  ///
  /// Faltaba del todo: cambiarle el nombre a una mesa compartida sólo lo
  /// cambiaba en TU móvil. El servidor no se enteraba y tu gente seguía
  /// viendo el nombre viejo para siempre, sin manera de arreglarlo.
  ///
  /// No se tocan ni los miembros ni quién la creó: las reglas lo prohíben a
  /// propósito, y ésa es justo la protección que impide que alguien con el
  /// código se quede con la mesa.
  static Future<void> renombrarMesa(Mesa mesa) async {
    try {
      await _conTope(_mesas.doc(mesa.id).set(<String, dynamic>{
        'nombre': mesa.nombre,
        'descripcion': mesa.descripcion,
        'colorHex': mesa.colorHex,
      }, SetOptions(merge: true)));
    } on FirebaseException catch (e) {
      throw FalloNube(_traducir(e));
    }
  }

  /// Las catas que hay en esa mesa, según van llegando.
  ///
  /// Con tope y de la más nueva a la más vieja. Sin tope, abrir una mesa
  /// viva de doscientas catas con foto se descarga entero —y las fotos van
  /// dentro de cada cata— cada vez que se abre la app. El plan gratuito da
  /// 10 GiB de salida al mes, así que esto no es una optimización: es la
  /// diferencia entre que la mesa funcione a final de mes o no.
  static Stream<List<Cata>> catasDe(String mesaId, {int tope = 150}) {
    return _mesas
        .doc(mesaId)
        .collection('catas')
        .orderBy('fecha', descending: true)
        .limit(tope)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> s) {
      final List<Cata> catas = <Cata>[];
      for (final QueryDocumentSnapshot<Map<String, dynamic>> d in s.docs) {
        // Una cata con un campo corrupto no puede tumbar el feed entero de
        // la mesa: se salta esa y se enseñan las demás.
        try {
          // `soloEnLaMesa` y no lo que venga: el documento se escribió con
          // esta mesa y nada más, pero una copia antigua podría traer otra
          // cosa, y una cata que dijera estar en una mesa que este móvil no
          // conoce ensuciaría la lista de quien la recibe.
          catas.add(
            Cata.fromJson(<String, dynamic>{...d.data(), 'id': d.id})
                .soloEnLaMesa(mesaId),
          );
        } catch (_) {}
      }
      return catas;
    });
  }

  static String _traducir(FirebaseException e) => switch (e.code) {
        'permission-denied' =>
          'No tienes acceso a esa mesa. Pide el código a quien la creó.',
        // 'network-request-failed' era un código de Firebase Auth, no de
        // Firestore: rama muerta. El caso real es 'unavailable'.
        'unavailable' => 'Sin conexión. Inténtalo cuando vuelva la cobertura.',
        // Una cata que no cabe no se arregla reintentándola.
        'invalid-argument' =>
          'Esa cata pesa demasiado para enviarla. Quítale una foto.',
        'not-found' => 'Esa mesa ya no existe.',
        _ => 'No se ha podido. Inténtalo otra vez.',
      };
}
