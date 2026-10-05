import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../data/datos_demo.dart';
import '../data/siembra.dart';
import '../errores.dart';
import '../models/cata.dart';
import '../models/mesa.dart';
import '../services/nube_service.dart';
import 'carga_inicial.dart';
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
class MesasNotifier extends StateNotifier<List<Mesa>>
    with CargaInicial<List<Mesa>> {
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
        desdeDisco(leidas.any((Mesa m) => m.esLibreta)
            ? leidas
            : <Mesa>[Siembra.libreta, ...leidas]);
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
    String? foto,
  }) async {
    final Mesa mesa = Mesa(
      id: const Uuid().v4(),
      nombre: nombre.trim().isEmpty ? 'Mesa sin nombre' : nombre.trim(),
      descripcion: descripcion.trim(),
      colorHex: colorHex,
      miembros: const <String>[DatosDemo.yo],
      codigo: Mesa.nuevoCodigo(),
      foto: foto,
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
    String? foto,
    bool quitarFoto = false,
  }) async {
    state = <Mesa>[
      for (final Mesa m in state)
        if (m.id == id)
          m.copyWith(
            nombre: nombre?.trim(),
            descripcion: descripcion?.trim(),
            colorHex: colorHex,
            foto: foto,
            quitarFoto: quitarFoto,
          )
        else
          m,
    ];
    await _guardar();

    // Y al servidor, si la mesa es compartida. Esto faltaba entero: cambiarle
    // el nombre a una mesa sólo lo cambiaba en TU móvil, el servidor no se
    // enteraba y tu gente seguía viendo el nombre viejo para siempre.
    //
    // Sin esperar y sin molestar si falla: el nombre ya está cambiado en el
    // móvil y no poder avisar al servidor no puede dejarte la pantalla
    // colgada. Queda en la bitácora.
    final Mesa? ahora = state.where((Mesa m) => m.id == id).firstOrNull;
    if (ahora == null || !ahora.enLaNube) return;
    unawaited(
      NubeService.renombrarMesa(ahora).catchError(
        (Object error, StackTrace pila) =>
            Errores.registrar(error, pila, origen: 'mesas.renombrar'),
      ),
    );
  }

  /// Guarda lo que dice el servidor de una mesa compartida.
  ///
  /// Para una mesa que se comparte, el servidor manda: es el único sitio
  /// donde los dos móviles se ponen de acuerdo. No vuelve a subir nada —sería
  /// una pescadilla— y no toca nada si no ha cambiado nada, que es lo que
  /// evita reescribir el disco en cada latido del servidor.
  Future<void> apuntarDeLaNube(String mesaId, MesaViva viva) async {
    final Mesa? mesa = state.where((Mesa m) => m.id == mesaId).firstOrNull;
    if (mesa == null) return;

    final String nombre = (viva.nombre ?? mesa.nombre).trim();
    final String descripcion = (viva.descripcion ?? mesa.descripcion).trim();
    final int colorHex = viva.colorHex ?? mesa.colorHex;
    // Una lista de miembros vacía es casi siempre un documento a medio llegar,
    // no una mesa sin nadie: quien la lee es miembro por definición.
    final List<String> miembros =
        viva.miembros.isEmpty ? mesa.miembros : viva.miembros;

    final bool igual = nombre == mesa.nombre &&
        descripcion == mesa.descripcion &&
        colorHex == mesa.colorHex &&
        miembros.length == mesa.miembros.length &&
        mesa.miembros.toSet().containsAll(miembros);
    if (igual) return;

    state = <Mesa>[
      for (final Mesa m in state)
        if (m.id == mesaId)
          m.copyWith(
            nombre: nombre,
            descripcion: descripcion,
            colorHex: colorHex,
            miembros: miembros,
          )
        else
          m,
    ];
    await _guardar();
  }

  /// Sube una mesa para que su gente pueda verla.
  ///
  /// Si el servidor falla, la mesa NO se marca como compartida: quedarse con
  /// la marca puesta haría creer que la gente la ve cuando no está subida, y
  /// las catas se apuntarían pensando que llegan a alguien.
  Future<void> compartir(String id) async {
    final Mesa? mesa = state.where((Mesa m) => m.id == id).firstOrNull;
    if (mesa == null || mesa.esLibreta) return;

    // Ojo: NO se sale si la mesa ya está marcada como subida. Si la subida
    // anterior se quedó a medias —la mesa escrita y el código no, que es
    // exactamente lo que pasó— volver a pulsar tiene que poder arreglarlo.
    // Subir es idempotente: ni duplica la mesa ni echa a los miembros.

    final String codigo = await NubeService.compartir(mesa);

    state = <Mesa>[
      for (final Mesa m in state)
        if (m.id == id) m.copyWith(enLaNube: true, codigo: codigo) else m,
    ];
    await _guardar();
  }

  /// Entra en la mesa de otro con su código.
  ///
  /// Devuelve la mesa recién añadida. Si ya estabas dentro no la duplica:
  /// dar dos veces al mismo código es lo más fácil del mundo cuando el
  /// primero pareció no responder.
  Future<Mesa> entrarCon(String codigo) async {
    final Mesa mesa = await NubeService.entrarCon(codigo);

    final bool yaEstaba = state.any((Mesa m) => m.id == mesa.id);
    state = yaEstaba
        ? <Mesa>[
            for (final Mesa m in state)
              if (m.id == mesa.id) mesa.copyWith(enLaNube: true) else m,
          ]
        : <Mesa>[...state, mesa.copyWith(enLaNube: true)];

    await _guardar();
    return mesa;
  }

  /// Recupera del servidor las mesas compartidas en las que estás.
  ///
  /// Se llama al entrar con la cuenta. Las que ya tienes en el móvil no se
  /// tocan: lo tuyo manda, porque puedes haberle puesto foto o haberla
  /// renombrado sin cobertura. Sólo se añaden las que faltan, que son las
  /// que se perdían al reinstalar o al cambiar de móvil.
  Future<int> recuperarDeLaNube() async {
    final List<Mesa> suyas = await NubeService.misMesas();
    if (suyas.isEmpty) return 0;

    final Set<String> yaEstan = state.map((Mesa m) => m.id).toSet();
    final List<Mesa> nuevas =
        suyas.where((Mesa m) => !yaEstan.contains(m.id)).toList();
    if (nuevas.isEmpty) return 0;

    state = <Mesa>[...state, ...nuevas];
    await _guardar();
    return nuevas.length;
  }

  /// Apunta quién hay en una mesa, según lo que dice el servidor.
  ///
  /// No toca nada más de la mesa: el nombre, el color y la foto son de quien
  /// la creó y viven en el móvil. Si la lista no cambia no se guarda, porque
  /// esto llega cada vez que el servidor respira y reescribir el disco por
  /// nada sobra.
  Future<void> apuntarMiembros(String mesaId, List<String> miembros) async {
    final Mesa? mesa = state.where((Mesa m) => m.id == mesaId).firstOrNull;
    if (mesa == null) return;

    final bool igual = mesa.miembros.length == miembros.length &&
        mesa.miembros.toSet().containsAll(miembros);
    if (igual) return;

    state = <Mesa>[
      for (final Mesa m in state)
        if (m.id == mesaId) m.copyWith(miembros: miembros) else m,
    ];
    await _guardar();
  }

  /// Borra una mesa. Las catas que estaban en ella se quedan en tu diario.
  ///
  /// Borrar la mesa NO borra lo que catasteis: son dos cosas distintas y
  /// confundirlas sería la peor pérdida de datos posible en esta app. Lo que
  /// se pierde es que esa gente las vea; tuyas siguen siendo. La libreta no
  /// se puede borrar.
  Future<int> borrar(String id) async {
    if (id == Mesa.libretaId) return 0;

    final Mesa? mesa = state.where((Mesa m) => m.id == id).firstOrNull;

    // El orden importa, y estaba al revés.
    //
    // Sacar tus catas de la mesa es BORRARLAS del servidor, y para borrar en
    // una mesa hay que ser miembro de ella. Saliendo primero, cada uno de
    // esos borrados se encontraba un «permiso denegado», caía en la cola de
    // pendientes y de ahí se tiraba al siguiente reintento, porque la mesa ya
    // no estaba en el móvil. Resultado: tus catas —con su nota, sus fotos y
    // sus coordenadas exactas— se quedaban en el servidor para siempre, a la
    // vista de los que seguían dentro, y sin ninguna forma de borrarlas desde
    // la app. Justo lo contrario de lo que promete la política de privacidad.
    //
    // Así que primero lo tuyo, mientras todavía puedes, y salir al final.
    final List<Cata> suyas = _ref
        .read(catasProvider)
        .where((Cata c) => c.estaEn(id))
        .toList();

    for (final Cata c in suyas) {
      await _ref.read(catasProvider.notifier).actualizar(
            c.copyWith(
              mesas: <String>[
                for (final String m in c.mesas)
                  if (m != id) m,
              ],
            ),
          );
    }

    // Y ahora el servidor. Si esto falla, la mesa NO se borra del móvil: sin
    // esta llamada el servidor te seguiría teniendo dentro y al siguiente
    // arranque la mesa volvería sola —con su código activo— pero vacía.
    if (mesa != null && mesa.enLaNube) {
      await NubeService.salirDe(mesa);
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
