import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../errores.dart';
import 'carga_inicial.dart';

/// La gente a la que no quieres volver a leer.
///
/// Las mesas son privadas y se entra con un código, así que aquí no hay
/// desconocidos: es gente que tú has invitado o que invitó quien te invitó a
/// ti. Aun así hace falta poder cortar sin montar una escena, porque en un
/// grupo de amigos salirse de la mesa es un gesto que se nota y bloquear a
/// alguien no tiene por qué notarse.
///
/// Y hace falta por otra razón: Apple lo exige. Toda app que enseñe cosas
/// escritas por otras personas tiene que dejar denunciar una publicación y
/// bloquear a quien la escribió. Sin eso la devuelven en revisión.
///
/// Se guarda SÓLO en este móvil y no viaja a ninguna parte, igual que la
/// lista de «esto no me lo pongas». Bloquear a alguien es asunto tuyo: la
/// otra persona no se entera, sigue en la mesa y sus catas le siguen
/// existiendo. Lo único que cambia es que tú dejas de verlas.
class BloqueadosNotifier extends StateNotifier<Set<String>>
    with CargaInicial<Set<String>> {
  BloqueadosNotifier() : super(const <String>{}) {
    _cargar();
  }

  static const String _clave = 'catacroket.bloqueados.v1';

  Future<void> _cargar() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      desdeDisco(<String>{...?prefs.getStringList(_clave)});
    } catch (error, pila) {
      // No poder leer esto significa volver a enseñar a alguien a quien
      // habías bloqueado. Conviene poder verlo luego.
      Errores.registrar(error, pila, origen: 'bloqueados.cargar');
    }
  }

  Future<void> _guardar() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_clave, state.toList());
    } catch (error, pila) {
      Errores.registrar(error, pila, origen: 'bloqueados.guardar');
    }
  }

  /// Por identificador de cuenta y no por nombre: el nombre se lo cambia
  /// cualquiera en dos toques, y entonces el bloqueo se caería solo.
  Future<void> bloquear(String uid) async {
    if (uid.trim().isEmpty || state.contains(uid)) return;
    state = <String>{...state, uid};
    await _guardar();
  }

  Future<void> desbloquear(String uid) async {
    if (!state.contains(uid)) return;
    state = <String>{...state}..remove(uid);
    await _guardar();
  }
}

final bloqueadosProvider =
    StateNotifierProvider<BloqueadosNotifier, Set<String>>(
  (ref) => BloqueadosNotifier(),
);
