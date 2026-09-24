import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lo que ya se ha enseñado una vez y no hace falta repetir.
///
/// Una sola lista para todo lo que se explica al entrar: la pregunta de como
/// comes y las pistas de cada apartado. Tenerlo junto permite una cosa que
/// se agradece: "volver a ver las explicaciones" es vaciar esta lista.
enum Visto {
  comoComes('comoComes'),
  pistaVitrina('pista.vitrina'),
  pistaRuta('pista.ruta'),
  pistaMesas('pista.mesas'),
  pistaPerfil('pista.perfil');

  const Visto(this.id);

  final String id;
}

class VistoNotifier extends StateNotifier<Set<String>> {
  VistoNotifier() : super(const <String>{}) {
    _cargar();
  }

  static const String _clave = 'catacroket.visto.v1';

  /// Mientras no se sepa que hay guardado no se decide nada.
  ///
  /// Sin esto, al arrancar se enseñaría la pantalla de "cómo comes" durante
  /// una milésima a quien ya la contestó hace meses, porque leer del disco
  /// tarda y el primer fotograma llega antes.
  bool get cargado => _cargado;
  bool _cargado = false;

  Future<void> _cargar() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final Set<String> guardado = <String>{...?prefs.getStringList(_clave)};
      _cargado = true;
      state = guardado;
    } catch (_) {
      _cargado = true;
      state = const <String>{};
    }
  }

  Future<void> marcar(Visto que) async {
    if (state.contains(que.id)) return;
    state = <String>{...state, que.id};
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_clave, state.toList());
    } catch (_) {
      // Best-effort: si no se guarda, se volverá a enseñar. Molesta, no rompe.
      //
      // A propósito no se apunta en la bitácora, y no es un olvido: si el
      // almacenamiento se rompe fallan todos los providers a la vez, y la
      // bitácora sólo guarda veinte entradas. Llenarla con esto taparía el
      // «catas.guardar», que es el que hay que poder leer.
    }
  }

  /// Volver a ver todas las explicaciones.
  Future<void> olvidar() async {
    state = const <String>{};
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_clave);
    } catch (_) {
      // Igual que arriba.
    }
  }
}

final vistoProvider =
    StateNotifierProvider<VistoNotifier, Set<String>>((_) => VistoNotifier());

/// Si toca enseñar algo. Familia para no repetir el `contains` en cada
/// pantalla y para que la regla de "todavía no se ha leído el disco" viva en
/// un solo sitio.
final tocaEnsenarProvider = Provider.family<bool, Visto>((ref, Visto que) {
  final Set<String> visto = ref.watch(vistoProvider);
  if (!ref.read(vistoProvider.notifier).cargado) return false;
  return !visto.contains(que.id);
});
