import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Leer del disco no puede pisar lo que el usuario acaba de hacer.
///
/// Todos estos providers arrancan igual: el constructor deja un valor de
/// partida y lanza una lectura de `SharedPreferences` que termina más tarde.
/// Entre una cosa y otra hay una ventana —corta, pero real— en la que el
/// usuario ya puede tocar la pantalla. Si en esa ventana bloquea a alguien o
/// desmarca una dieta, la lectura llegaba después y lo deshacía sin decir
/// nada: el usuario veía su toque aplicarse y volver atrás solo.
///
/// No era teórico. El test `bloquear_test` lo pilló: bloqueaba a alguien y
/// sus catas seguían ahí, porque la carga había aterrizado en medio.
///
/// La regla es que manda el usuario. Cualquier escritura en `state` que no
/// venga del disco marca el notifier como tocado, y a partir de ahí lo que
/// se leyó se descarta. Así los mutadores no cambian: siguen escribiendo
/// `state` como siempre, y es la carga la que se aparta.
mixin CargaInicial<T> on StateNotifier<T> {
  bool _tocado = false;
  bool _leyendo = false;

  @override
  set state(T valor) {
    if (!_leyendo) _tocado = true;
    super.state = valor;
  }

  /// Pone lo que venía del disco, salvo que ya haya ganado el usuario.
  ///
  /// Devuelve si se ha aplicado, por si quien llama necesita saberlo.
  bool desdeDisco(T valor) {
    if (_tocado || !mounted) return false;
    _leyendo = true;
    state = valor;
    _leyendo = false;
    return true;
  }
}
