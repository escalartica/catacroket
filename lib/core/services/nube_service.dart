import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cata.dart';
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
  static Future<void> compartir(Mesa mesa) async {
    if (mesa.esLibreta) {
      throw const FalloNube('La libreta es tuya y no se comparte.');
    }
    final String codigo = mesa.codigo ?? Mesa.nuevoCodigo();

    try {
      await _mesas.doc(mesa.id).set(<String, dynamic>{
        'nombre': mesa.nombre,
        'descripcion': mesa.descripcion,
        'colorHex': mesa.colorHex,
        'codigo': codigo,
        'miembros': <String>[_uid],
        'creadoPor': _uid,
        'creada': FieldValue.serverTimestamp(),
      });

      await _db.collection('codigos').doc(codigo).set(<String, dynamic>{
        'mesaId': mesa.id,
        'creadoPor': _uid,
      });
    } on FirebaseException catch (e) {
      throw FalloNube(_traducir(e));
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

  /// Sube una cata a su mesa compartida.
  ///
  /// Se le quitan los medios: son rutas de ficheros de ESTE móvil y en otro
  /// no existen. Mandar una ruta que el receptor no puede abrir es peor que
  /// no mandar nada, porque su app intentaría enseñar una foto rota.
  static Future<void> subirCata(Cata cata) async {
    try {
      final Map<String, dynamic> datos = Map<String, dynamic>.from(
        cata.toJson(),
      )
        ..remove('medios')
        ..['autorUid'] = _uid
        ..['subida'] = FieldValue.serverTimestamp();

      await _mesas
          .doc(cata.mesaId)
          .collection('catas')
          .doc(cata.id)
          .set(datos);
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
