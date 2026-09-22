import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/dieta.dart';

/// Cómo come quien usa la app.
///
/// Se guarda aparte del perfil (que se calcula a partir de las catas) porque
/// esto no se deduce de nada: lo dice el usuario y no cambia solo.
///
/// Con esto puesto, la app deja de ser un catálogo con una sección para
/// dietas y pasa a saber para quién está trabajando: cada cata dice si te
/// vale, si hay que preguntar o si no, y la Barra Libre abre ya filtrada por
/// lo tuyo. Vacío es un estado legítimo y es el de por defecto: quien come de
/// todo no tiene que configurar nada.
class MiDietaNotifier extends StateNotifier<Set<Dieta>> {
  MiDietaNotifier() : super(const <Dieta>{}) {
    _cargar();
  }

  static const String _clave = 'catacroket.midieta.v1';

  Future<void> _cargar() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String>? ids = prefs.getStringList(_clave);
      if (ids == null) return;
      state = Dieta.desdeJson(ids);
    } catch (_) {
      // Si no se puede leer, se come de todo. Es el fallo más inofensivo.
    }
  }

  Future<void> _guardar() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _clave,
        state.map((Dieta d) => d.id).toList(),
      );
    } catch (_) {
      // Best-effort, como el resto del almacenamiento local.
    }
  }

  Future<void> alternar(Dieta dieta) async {
    final Set<Dieta> nuevo = <Dieta>{...state};
    nuevo.contains(dieta) ? nuevo.remove(dieta) : nuevo.add(dieta);
    state = nuevo;
    await _guardar();
  }

  Future<void> limpiar() async {
    state = const <Dieta>{};
    await _guardar();
  }
}

final miDietaProvider =
    StateNotifierProvider<MiDietaNotifier, Set<Dieta>>((ref) => MiDietaNotifier());
