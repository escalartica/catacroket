import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Un fallo, tal como se guarda.
class Fallo {
  const Fallo({
    required this.cuando,
    required this.origen,
    required this.que,
    required this.pila,
  });

  factory Fallo.fromJson(Map<String, dynamic> json) => Fallo(
        cuando: DateTime.fromMillisecondsSinceEpoch(json['t'] as int? ?? 0),
        origen: json['o'] as String? ?? 'app',
        que: json['q'] as String? ?? '',
        pila: json['p'] as String? ?? '',
      );

  final DateTime cuando;

  /// De qué parte viene: flutter, plataforma, zona, provider.
  final String origen;

  /// El error, en una línea.
  final String que;

  /// Las primeras líneas de la pila. No entera: no cabe y no hace falta.
  final String pila;

  Map<String, dynamic> toJson() => <String, dynamic>{
        't': cuando.millisecondsSinceEpoch,
        'o': origen,
        'q': que,
        'p': pila,
      };

  /// Cómo se lee en el informe que el usuario manda.
  String get enTexto {
    final String fecha = cuando.toIso8601String().substring(0, 19);
    return '[$fecha] $origen\n$que${pila.isEmpty ? '' : '\n$pila'}';
  }
}

/// Los últimos fallos, guardados en el móvil.
///
/// Por qué existe: sin esto, un fallo en release desaparecía. La app no manda
/// nada a ningún servidor —es una decisión de diseño, no un descuido—, así
/// que la única forma de enterarse de un problema es que el usuario lo
/// cuente. Esto le da algo concreto que contar en vez de "no me funciona".
///
/// Lo que NO guarda: nada que el usuario haya escrito. Sólo lo que el propio
/// error trae consigo. Si algún día un error llevara texto suyo dentro,
/// habría que recortarlo aquí antes de guardarlo.
///
/// Está acotada a [_maximo] a propósito: un fallo que se repite en bucle
/// —y los hay— llenaría el disco en minutos.
class BitacoraNotifier extends StateNotifier<List<Fallo>> {
  BitacoraNotifier() : super(const <Fallo>[]) {
    _cargar();
  }

  static const String _clave = 'catacroket.bitacora.v1';

  /// Cuántos se guardan. Los más nuevos primero.
  static const int _maximo = 20;

  /// Cuántas líneas de pila se conservan de cada uno.
  ///
  /// Con las cinco primeras se sabe de dónde salió. Enteras ocupan miles de
  /// caracteres cada una y el informe se vuelve ilegible.
  static const int _lineasDePila = 5;

  Future<void> _cargar() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? crudo = prefs.getString(_clave);
      if (crudo == null || crudo.isEmpty) return;

      final List<dynamic> lista = jsonDecode(crudo) as List<dynamic>;
      state = lista
          .map((dynamic e) =>
              Fallo.fromJson(Map<String, dynamic>.from(e as Map<dynamic, dynamic>)))
          .toList();
    } catch (_) {
      // Una bitácora corrupta no puede impedir que la app arranque: es lo
      // menos importante que hay aquí dentro.
    }
  }

  Future<void> _guardar() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _clave,
        jsonEncode(state.map((Fallo f) => f.toJson()).toList()),
      );
    } catch (_) {
      // Best-effort, como el resto del almacenamiento local.
    }
  }

  /// Apunta un fallo. Los más nuevos van delante.
  Future<void> apuntar(Object error, StackTrace? pila, String origen) async {
    final Fallo fallo = Fallo(
      cuando: DateTime.now(),
      origen: origen,
      que: error.toString(),
      pila: _recortar(pila),
    );

    state = <Fallo>[fallo, ...state].take(_maximo).toList();
    await _guardar();
  }

  /// Borra la bitácora. Está en ajustes, junto a restablecer.
  Future<void> limpiar() async {
    state = const <Fallo>[];
    await _guardar();
  }

  static String _recortar(StackTrace? pila) {
    if (pila == null) return '';
    return pila
        .toString()
        .split('\n')
        .take(_lineasDePila)
        .map((String l) => l.trim())
        .where((String l) => l.isNotEmpty)
        .join('\n');
  }
}

final bitacoraProvider =
    StateNotifierProvider<BitacoraNotifier, List<Fallo>>(
  (Ref ref) => BitacoraNotifier(),
);

/// El informe entero, listo para pegar en un correo o un mensaje.
String informeDe(List<Fallo> fallos, {required String version}) {
  if (fallos.isEmpty) return 'Catacroket $version — sin fallos apuntados.';

  return <String>[
    'Catacroket $version',
    '${fallos.length} ${fallos.length == 1 ? 'fallo' : 'fallos'} apuntados',
    '',
    ...fallos.map((Fallo f) => f.enTexto),
  ].join('\n');
}
