import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../models/cata.dart';
import '../models/medio.dart';
import '../models/mesa.dart';
import 'cuenta_service.dart';

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
/// Las fotos NO viajan. Son ficheros del móvil y mandarlas exigiría otro
/// servicio de almacenamiento —y su factura—. Lo que sí llega es el dibujo
/// del corte, porque sale de los cuatro números y se pinta en cada móvil.
/// Quien mira una cata de otro ve la croqueta, la nota y el sitio.
class NubeService {
  const NubeService._();

  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _mesas =>
      _db.collection('mesas');

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

    try {
      await _mesas.doc(mesa.id).set(
        <String, dynamic>{
          'nombre': mesa.nombre,
          'descripcion': mesa.descripcion,
          'colorHex': mesa.colorHex,
          'codigo': codigo,
          // arrayUnion y no una lista nueva: compartir otra vez una mesa que
          // ya tiene gente dentro NO puede echarla. Con `[_uid]` a secas, la
          // segunda vez que alguien pulsaba compartir se quedaba solo.
          'miembros': FieldValue.arrayUnion(<String>[_uid]),
          'creadoPor': _uid,
          'creada': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
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
      await _db.collection('codigos').doc(codigo).set(<String, dynamic>{
        'mesaId': mesaId,
        'creadoPor': _uid,
      });
      return true;
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') throw FalloNube(_traducir(e));
    }

    // Puede ser de otra mesa… o de ÉSTA, de una vez anterior. Volver a
    // compartir una mesa ya compartida tiene que seguir funcionando.
    try {
      final DocumentSnapshot<Map<String, dynamic>> ya =
          await _db.collection('codigos').doc(codigo).get();
      return ya.exists && ya.data()?['mesaId'] == mesaId;
    } on FirebaseException {
      return false;
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
      await _db.collection('usuarios').doc(_uid).set(<String, dynamic>{
        'nombre': nombre,
      });
    } catch (_) {}
  }

  /// Los nombres de esa gente, por su identificador de cuenta.
  ///
  /// Devuelve sólo los que encuentra: quien no haya abierto la app desde que
  /// existe esto no tiene nombre publicado todavía, y su sitio en la mesa se
  /// pinta como «Alguien» igual que antes.
  static Future<Map<String, String>> nombresDe(List<String> uids) async {
    final Map<String, String> nombres = <String, String>{};
    for (final String uid in uids) {
      try {
        final DocumentSnapshot<Map<String, dynamic>> d =
            await _db.collection('usuarios').doc(uid).get();
        final String? nombre = d.data()?['nombre'] as String?;
        if (nombre != null && nombre.trim().isNotEmpty) {
          nombres[uid] = nombre.trim();
        }
      } catch (_) {
        // Uno que falle no puede dejar sin nombre a los demás.
      }
    }
    return nombres;
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
      final QuerySnapshot<Map<String, dynamic>> s = await _mesas
          .where('miembros', arrayContains: _uid)
          .get();

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
    } catch (_) {
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
          await _db.collection('codigos').doc(limpio).get();
      if (!ref.exists) {
        throw const FalloNube('Ese código no existe. Compruébalo.');
      }

      final String mesaId = ref.data()!['mesaId'] as String;

      // Añadirse a sí mismo. Las reglas del servidor comprueban que sea
      // exactamente eso y nada más: quien tiene un código no puede renombrar
      // la mesa ni echar a nadie.
      await _mesas.doc(mesaId).update(<String, dynamic>{
        'miembros': FieldValue.arrayUnion(<String>[_uid]),
      });

      final DocumentSnapshot<Map<String, dynamic>> doc =
          await _mesas.doc(mesaId).get();
      final Map<String, dynamic> d = doc.data()!;

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

  /// Lo máximo que puede pesar una miniatura ya codificada.
  ///
  /// El tope de Firestore es 1 MB por documento y una cata admite dos fotos,
  /// así que 320 KB cada una deja sitio de sobra para el texto, los sabores y
  /// lo que venga después. Base64 engorda un tercio, y eso ya está contado.
  static const int _pesoMaximoMini = 320 * 1024;

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
        if (!File(m.ruta).existsSync()) {
          listos.add(m);
          continue;
        }

        final Uint8List? datos = await FlutterImageCompress.compressWithFile(
          m.ruta,
          minWidth: _anchoMini,
          minHeight: _anchoMini,
          quality: 72,
          format: CompressFormat.jpeg,
        );

        // Una foto rarísima —un panorama larguísimo— podría seguir sin caber
        // después de comprimir. Antes que romper el guardado de la cata
        // entera, esa foto se queda en casa.
        if (datos == null || datos.length > _pesoMaximoMini) {
          listos.add(m);
          continue;
        }

        listos.add(m.conMini(base64Encode(datos)));
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
  static Future<List<Medio>> subirCata(Cata cata) async {
    // Las fotos primero: si suben, la cata viaja con ellas; si no, viaja sin
    // ellas y se reintenta luego. Lo que no puede pasar es que la cata se
    // quede sin subir por culpa de una foto.
    final List<Medio> medios = await prepararFotos(cata);

    try {
      final Map<String, dynamic> datos = Map<String, dynamic>.from(
        cata.toJson(),
      )
        // Sólo la parte de nube: la ruta local es de ESTE móvil y en otro no
        // abre nada. Antes se quitaban los medios enteros y por eso la gente
        // de una mesa nunca veía las fotos de los demás.
        ..['medios'] = <Map<String, dynamic>>[
          for (final Medio m in medios)
            if (m.viaja) m.paraViajar.toJson(),
        ]
        ..['autorUid'] = _uid
        ..['subida'] = FieldValue.serverTimestamp();

      await _mesas
          .doc(cata.mesaId)
          .collection('catas')
          .doc(cata.id)
          .set(datos);

      return medios;
    } on FirebaseException catch (e) {
      throw FalloNube(_traducir(e));
    }
  }

  static Future<void> borrarCata(Cata cata) async {
    try {
      await _mesas
          .doc(cata.mesaId)
          .collection('catas')
          .doc(cata.id)
          .delete();
    } on FirebaseException catch (_) {
      // Si no se puede borrar del servidor no se le cuenta a nadie: en el
      // móvil ya está borrada y reventar aquí sólo asustaría.
    }
  }

  /// Quién hay en esa mesa, según va entrando gente.
  ///
  /// La mesa se leía una sola vez, al entrar con el código, y nunca más. El
  /// resultado era que quien la creaba seguía viendo «tú sola» para siempre
  /// aunque los demás ya estuvieran dentro: el servidor lo sabía y el móvil
  /// no se enteraba. Sólo se escuchan los miembros; el nombre y el color son
  /// de quien la creó y no se pisan desde aquí.
  static Stream<List<String>> miembrosDe(String mesaId) {
    return _mesas.doc(mesaId).snapshots().map(
          (DocumentSnapshot<Map<String, dynamic>> d) => <String>[
            for (final dynamic m
                in (d.data()?['miembros'] as List<dynamic>? ??
                    const <dynamic>[]))
              m.toString(),
          ],
        );
  }

  /// Las catas que hay en esa mesa, según van llegando.
  static Stream<List<Cata>> catasDe(String mesaId) {
    return _mesas
        .doc(mesaId)
        .collection('catas')
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> s) {
      final List<Cata> catas = <Cata>[];
      for (final QueryDocumentSnapshot<Map<String, dynamic>> d in s.docs) {
        // Una cata con un campo corrupto no puede tumbar el feed entero de
        // la mesa: se salta esa y se enseñan las demás.
        try {
          catas.add(Cata.fromJson(<String, dynamic>{...d.data(), 'id': d.id}));
        } catch (_) {}
      }
      return catas;
    });
  }

  static String _traducir(FirebaseException e) => switch (e.code) {
        'permission-denied' =>
          'No tienes acceso a esa mesa. Pide el código a quien la creó.',
        'unavailable' || 'network-request-failed' =>
          'Sin conexión. Se enviará cuando vuelva.',
        'not-found' => 'Esa mesa ya no existe.',
        _ => 'No se ha podido. Inténtalo otra vez.',
      };
}
