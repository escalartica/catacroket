import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../data/datos_demo.dart';
import '../data/siembra.dart';
import '../models/cata.dart';
import '../models/mesa.dart';
import '../errores.dart';
import 'catas_provider.dart';

/// Mesas del usuario.
///
/// La libreta privada es siempre la primera, no se puede borrar ni renombrar
/// y no tiene código: es el sitio donde acaba una cata cuando no eliges nada,
/// y una app en la que ese sitio puede desaparecer es una app en la que
/// puedes perder catas sin querer.
///
/// Como las catas, esto vive en el móvil y se guarda en `SharedPreferences`.
/// Antes no se guardaba: una mesa creada se perdía al cerrar la app.
class MesasNotifier extends StateNotifier<List<Mesa>> {
  MesasNotifier(this._ref) : super(Siembra.mesas) {
    _cargar();
  }

  final Ref _ref;

  static const String _clave = 'catacroket.mesas.v1';

  Future<void> _cargar() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? crudo = prefs.getString(_clave);
      if (crudo == null || crudo.isEmpty) return;

      final List<dynamic> lista = jsonDecode(crudo) as List<dynamic>;
      final List<Mesa> leidas = lista
          .map((dynamic e) =>
              Mesa.fromJson(Map<String, dynamic>.from(e as Map<dynamic, dynamic>)))
          .toList();

      // Si un guardado viejo no trae la libreta, se le pone delante: sin ella
      // las catas sin mesa no tendrían dónde caer.
      if (leidas.isNotEmpty) {
        state = leidas.any((Mesa m) => m.esLibreta)
            ? leidas
            : <Mesa>[Siembra.libreta, ...leidas];
      }
    } catch (error, pila) {
      // Un guardado corrupto no puede dejar al usuario sin mesas.
      Errores.registrar(error, pila, origen: 'mesas.cargar');
    }
  }

  Future<void> _guardar() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _clave,
        jsonEncode(state.map((Mesa m) => m.toJson()).toList()),
      );
    } catch (error, pila) {
      // Best-effort, como en las catas, y apuntado por lo mismo: una mesa que
      // creaste y desaparece al reiniciar tiene que dejar rastro.
      Errores.registrar(error, pila, origen: 'mesas.guardar');
    }
  }

  /// Crea una mesa con su código. Devuelve la mesa para que la pantalla pueda
  /// llevarte a ella sin volver a buscarla.
  Future<Mesa> crear({
    required String nombre,
    required String descripcion,
    required int colorHex,
  }) async {
    final Mesa mesa = Mesa(
      id: const Uuid().v4(),
      nombre: nombre.trim().isEmpty ? 'Mesa sin nombre' : nombre.trim(),
      descripcion: descripcion.trim(),
      colorHex: colorHex,
      miembros: const <String>[DatosDemo.yo],
      codigo: Mesa.nuevoCodigo(),
    );
    state = <Mesa>[...state, mesa];
    await _guardar();
    return mesa;
  }

  Future<void> editar(
    String id, {
    String? nombre,
    String? descripcion,
    int? colorHex,
  }) async {
    state = <Mesa>[
      for (final Mesa m in state)
        if (m.id == id)
          m.copyWith(
            nombre: nombre?.trim(),
            descripcion: descripcion?.trim(),
            colorHex: colorHex,
          )
        else
          m,
    ];
    await _guardar();
  }

  /// Borra una mesa y devuelve sus catas a la libreta.
  ///
  /// Borrar la mesa NO borra lo que catasteis: son dos cosas distintas y
  /// confundirlas sería la peor pérdida de datos posible en esta app. La
  /// libreta no se puede borrar.
  Future<int> borrar(String id) async {
    if (id == Mesa.libretaId) return 0;

    final List<Cata> suyas = _ref
        .read(catasProvider)
        .where((Cata c) => c.mesaId == id)
        .toList();

    for (final Cata c in suyas) {
      await _ref
          .read(catasProvider.notifier)
          .actualizar(c.copyWith(mesaId: Mesa.libretaId));
    }

    state = state.where((Mesa m) => m.id != id).toList();
    await _guardar();
    return suyas.length;
  }

  Future<void> anadirMiembro(String mesaId, String personaId) async {
    state = <Mesa>[
      for (final Mesa m in state)
        if (m.id == mesaId && !m.miembros.contains(personaId))
          m.copyWith(miembros: <String>[...m.miembros, personaId])
        else
          m,
    ];
    await _guardar();
  }

  Future<void> quitarMiembro(String mesaId, String personaId) async {
    state = <Mesa>[
      for (final Mesa m in state)
        if (m.id == mesaId)
          m.copyWith(
            miembros: m.miembros.where((String p) => p != personaId).toList(),
          )
        else
          m,
    ];
    await _guardar();
  }

  /// Deja las mesas como recién instaladas: en la app publicada, sólo tu
  /// libreta. Va con el "restablecer" de ajustes.
  Future<void> restablecer() async {
    state = Siembra.mesas;
    await _guardar();
  }
}

final mesasProvider = StateNotifierProvider<MesasNotifier, List<Mesa>>(
  (ref) => MesasNotifier(ref),
);

final mesaProvider = Provider.family<Mesa?, String>((ref, String id) {
  for (final Mesa m in ref.watch(mesasProvider)) {
    if (m.id == id) return m;
  }
  return null;
});

final recuerdosProvider = Provider.family<List<Recuerdo>, String>((ref, String mesaId) {
  final List<Recuerdo> todos = Siembra.recuerdos()
      .where((Recuerdo r) => r.mesaId == mesaId)
      .toList();
  todos.sort((Recuerdo a, Recuerdo b) => b.cuando.compareTo(a.cuando));
  return todos;
});
