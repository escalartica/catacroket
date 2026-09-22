import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lo que quien usa la app no quiere encontrarse.
///
/// Va aparte de `miDietaProvider` a proposito, y la diferencia importa:
///
/// Las dietas se **deducen** de la receta. La app sabe si la bechamel llevaba
/// leche porque alguien lo apunto, asi que puede decir "esta te vale".
///
/// Esto otro es texto escrito a mano -marisco, sesamo, boletus, cilantro- y
/// con eso solo se puede hacer una cosa: mirar si el nombre de lo que lleva
/// la croqueta lo menciona. Si lo menciona, se avisa. Si no lo menciona, eso
/// **no** quiere decir que no lleve: puede ir dentro sin que nadie lo
/// escribiera. Por eso esta lista solo sirve para avisar y para filtrar, y
/// nunca para decir que algo vale. Una app que le diga "libre de marisco" a
/// quien tiene anafilaxia porque nadie escribio la palabra hace dano.
///
/// Sirve igual para alergias que para manias, que por dentro es lo mismo:
/// "esto no me lo pongas".
class EvitarNotifier extends StateNotifier<Set<String>> {
  EvitarNotifier() : super(const <String>{}) {
    _cargar();
  }

  static const String _clave = 'catacroket.evitar.v1';

  /// Cuantas caben. No es una limitacion tecnica: una lista de treinta cosas
  /// deja de filtrar y empieza a esconderlo todo.
  static const int maximo = 12;

  Future<void> _cargar() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      state = <String>{...?prefs.getStringList(_clave)};
    } catch (_) {
      // Si no se puede leer, no se evita nada. Es el fallo mas inofensivo.
    }
  }

  Future<void> _guardar() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_clave, state.toList());
    } catch (_) {
      // Best-effort, como el resto del almacenamiento local.
    }
  }

  Future<void> anadir(String texto) async {
    final String limpio = texto.trim();
    if (limpio.isEmpty || state.length >= maximo) return;

    // Se compara sin tildes y en minusculas, asi que "Sesamo" y "sesamo" son
    // lo mismo y no se apuntan dos veces.
    final String clave = Evitar.normalizar(limpio);
    if (clave.isEmpty) return;
    if (state.any((String x) => Evitar.normalizar(x) == clave)) return;

    state = <String>{...state, limpio};
    await _guardar();
  }

  Future<void> quitar(String texto) async {
    state = <String>{...state}..remove(texto);
    await _guardar();
  }

  Future<void> limpiar() async {
    state = const <String>{};
    await _guardar();
  }
}

final evitarProvider =
    StateNotifierProvider<EvitarNotifier, Set<String>>((_) => EvitarNotifier());

/// Las comparaciones. Estan aqui y no repartidas por las pantallas para que
/// buscar y guardar usen exactamente la misma regla.
abstract final class Evitar {
  /// Minusculas y sin tildes. Lo justo para que "jamon" encuentre "Jamon".
  static String normalizar(String texto) {
    const String con = 'aaaaaeeeeiiiiooooouuuunc';
    const String conTildes = 'áàäâãéèëêíìïîóòöôõúùüûñç';

    final StringBuffer salida = StringBuffer();
    for (final int unidad in texto.toLowerCase().runes) {
      final String letra = String.fromCharCode(unidad);
      final int i = conTildes.indexOf(letra);
      salida.write(i == -1 ? letra : con[i]);
    }
    return salida.toString().trim();
  }

  /// Cuales de [evitar] aparecen en [textos].
  ///
  /// Devuelve las palabras tal y como las escribio el usuario, para poder
  /// decirle "lleva boletus" con su propia palabra.
  static List<String> coincidencias(
    Set<String> evitar,
    Iterable<String> textos,
  ) {
    if (evitar.isEmpty) return const <String>[];

    final String todo = textos.map(normalizar).join(' | ');
    if (todo.trim().isEmpty) return const <String>[];

    return <String>[
      for (final String palabra in evitar)
        if (normalizar(palabra).isNotEmpty && todo.contains(normalizar(palabra)))
          palabra,
    ];
  }
}
