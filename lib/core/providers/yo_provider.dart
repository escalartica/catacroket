import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../errores.dart';

/// Quién eres tú: nombre y foto.
///
/// Hasta ahora el nombre estaba escrito a fuego en la pantalla («Cehache») y
/// el avatar era la letra C. Servía para enseñar el diseño, pero es lo
/// primero que mira cualquiera al abrir el perfil, y no poder tocarlo hace
/// que la app parezca una maqueta.
///
/// Va aparte de [Persona] a propósito: Persona describe a cualquiera de tu
/// mesa y es de sólo lectura; esto es lo tuyo, se edita y se guarda. Cuando
/// entre Firebase, esto pasa a ser tu perfil público y lo demás no cambia.
class Yo {
  const Yo({this.nombre = 'Tú', this.foto});

  final String nombre;

  /// Ruta de la foto en la carpeta de la app, o nulo si no hay.
  ///
  /// Nulo NO es un fallo: la inicial sobre color es un avatar perfectamente
  /// digno y muchísima gente no va a poner foto nunca.
  final String? foto;

  bool get tieneFoto => foto != null && File(foto!).existsSync();

  String get inicial =>
      nombre.trim().isEmpty ? '?' : nombre.trim().substring(0, 1).toUpperCase();

  Yo copiaCon({String? nombre, String? foto, bool quitarFoto = false}) => Yo(
        nombre: nombre ?? this.nombre,
        foto: quitarFoto ? null : (foto ?? this.foto),
      );
}

class YoNotifier extends StateNotifier<Yo> {
  YoNotifier() : super(const Yo()) {
    _cargar();
  }

  static const String _claveNombre = 'catacroket.yo.nombre.v1';
  static const String _claveFoto = 'catacroket.yo.foto.v1';

  static final ImagePicker _selector = ImagePicker();

  Future<void> _cargar() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      state = Yo(
        nombre: prefs.getString(_claveNombre) ?? 'Tú',
        foto: prefs.getString(_claveFoto),
      );
    } catch (_) {
      // Sin nada guardado se queda el valor de partida.
    }
  }

  Future<void> ponerNombre(String nombre) async {
    final String limpio = nombre.trim();
    if (limpio.isEmpty) return;

    state = state.copiaCon(nombre: limpio);
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_claveNombre, limpio);
    } catch (error, pila) {
      Errores.registrar(error, pila, origen: 'yo.guardar');
    }
  }

  /// Qué pasó al pedir la foto.
  ///
  /// Tres cosas distintas y la pantalla tiene que decir cosas distintas:
  /// listo (no dice nada, se ve la foto), cancelado (tampoco: cancelar es
  /// una decisión, no un error) y fallo (sí, porque si no el usuario toca y
  /// no pasa nada). El caso que importa es el tercero: si deniegas el
  /// permiso de cámara, image_picker lanza y antes esto se tragaba la
  /// excepción — tocabas, no ocurría nada y no había forma de saber por qué.

  /// Elige una foto y la deja lista.
  ///
  /// La foto se COPIA a la carpeta de la app. Lo que devuelve image_picker
  /// vive en una caché temporal que el sistema borra cuando quiere, así que
  /// guardar esa ruta es garantizar un avatar roto dentro de unas semanas.
  Future<ResultadoFoto> ponerFoto({required bool camara}) async {
    try {
      final XFile? elegida = await _selector.pickImage(
        source: camara ? ImageSource.camera : ImageSource.gallery,
        // Se ve a 104 px como mucho. 800 sobra de largo y deja sitio para
        // que un día se pueda ampliar sin volver a pedirla.
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 88,
      );
      if (elegida == null) return ResultadoFoto.cancelado;

      final Directory carpeta = await getApplicationDocumentsDirectory();
      final Directory perfil = Directory('${carpeta.path}/perfil');
      if (!perfil.existsSync()) perfil.createSync(recursive: true);

      final String destino =
          '${perfil.path}/yo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(elegida.path).copy(destino);

      final String? anterior = state.foto;
      state = state.copiaCon(foto: destino);

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_claveFoto, destino);

      // La anterior se borra después de guardar la nueva, nunca antes: si
      // algo falla a mitad, es preferible dejar un fichero de sobra que
      // quedarse sin ninguna de las dos.
      await _borrar(anterior);
      return ResultadoFoto.listo;
    } catch (_) {
      return camara ? ResultadoFoto.sinCamara : ResultadoFoto.sinGaleria;
    }
  }

  Future<void> quitarFoto() async {
    final String? anterior = state.foto;
    state = state.copiaCon(quitarFoto: true);
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_claveFoto);
    } catch (_) {
      // Best-effort.
    }
    await _borrar(anterior);
  }

  static Future<void> _borrar(String? ruta) async {
    if (ruta == null) return;
    try {
      final File f = File(ruta);
      if (f.existsSync()) await f.delete();
    } catch (_) {
      // Un huérfano ocupa unos KB. Reventar aquí sí se notaría.
    }
  }
}

final yoProvider = StateNotifierProvider<YoNotifier, Yo>((_) => YoNotifier());

/// En qué quedó el intento de poner foto.
enum ResultadoFoto {
  listo(null),
  cancelado(null),
  sinCamara('No se pudo abrir la cámara. Míralo en Ajustes → Catacroket.'),
  sinGaleria('No se pudo abrir la galería. Míralo en Ajustes → Catacroket.');

  const ResultadoFoto(this.aviso);

  /// Qué decirle al usuario, o nulo si no hay nada que decir.
  final String? aviso;
}
