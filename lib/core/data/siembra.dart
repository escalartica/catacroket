// `kReleaseMode` vive en foundation y material NO lo re-exporta. Importar
// solo material compila en el analizador y revienta al compilar de verdad.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;

import '../capturas.dart';
import '../models/cata.dart';
import '../models/mesa.dart';
import '../models/persona.dart';
import 'datos_demo.dart';

/// Con qué arranca la app la primera vez.
///
/// En desarrollo, con el catálogo de demostración: una app de catas sin catas
/// no se puede enseñar ni ajustar. En la app publicada, VACÍA.
///
/// Esto no es una preferencia de diseño, es lo que hay que hacer. Alguien que
/// se baja Catacroket no puede encontrarse dieciocho croquetas que no ha
/// comido, dos mesas a las que no pertenece y cuatro amigos inventados. No
/// sabría cuáles son suyas, ni si son de otra persona, ni si la app le ha
/// leído algo. Y las borraría una a una antes de empezar.
///
/// El interruptor es [kReleaseMode], no una constante a mano: así es
/// imposible subir a la tienda una compilación con datos dentro por haberse
/// olvidado de cambiar un booleano. Para probar el arranque limpio sin
/// compilar en release:
///
///     flutter run --dart-define=CATACROKET_VACIA=true
abstract final class Siembra {
  /// Si se siembran los datos de ejemplo.
  ///
  /// El modo capturas siembra aunque sea release, porque una ficha de tienda
  /// con la app vacía no enseña nada. Ver `core/capturas.dart`.
  static const bool conEjemplos =
      paraCapturas || (!kReleaseMode && !_forzarVacia);

  static const bool _forzarVacia = bool.fromEnvironment('CATACROKET_VACIA');

  static List<Cata> catas() => catasCon(conEjemplos);
  static List<Recuerdo> recuerdos() => recuerdosCon(conEjemplos);
  static List<Mesa> get mesas => mesasCon(conEjemplos);
  static List<Persona> get personas => personasCon(conEjemplos);

  // ── Lo de arriba sólo elige rama. Lo de abajo es lo que hace el trabajo,
  // y toma la decisión como argumento para que los tests puedan comprobar
  // las DOS ramas. Con `kReleaseMode` metido dentro no habría forma de
  // probar la rama que va a la tienda, que es justo la que importa.

  /// Ninguna. Se empieza por la primera.
  @visibleForTesting
  static List<Cata> catasCon(bool ejemplos) =>
      ejemplos ? DatosDemo.catas() : <Cata>[];

  @visibleForTesting
  static List<Recuerdo> recuerdosCon(bool ejemplos) =>
      ejemplos ? DatosDemo.recuerdos() : <Recuerdo>[];

  /// Sólo tu libreta.
  ///
  /// La libreta no es un dato de ejemplo: es la estructura. Es donde caen las
  /// catas que no van a ninguna mesa, y sin ella la primera cata no tendría
  /// dónde guardarse. Lo que se va son las dos mesas inventadas con gente que
  /// el usuario no conoce.
  @visibleForTesting
  static List<Mesa> mesasCon(bool ejemplos) =>
      ejemplos ? DatosDemo.mesas : <Mesa>[libreta];

  static const Mesa libreta = Mesa(
    id: Mesa.libretaId,
    nombre: 'Mi libreta',
    descripcion: 'Sólo tú. Lo que catas sin contárselo a nadie.',
    colorHex: 0xFFFFC93C,
    miembros: <String>[DatosDemo.yo],
  );

  /// Sólo tú.
  ///
  /// Los nombres de los demás llegarán con las cuentas. Hasta entonces, los
  /// acompañantes de una cata se escriben a mano y no salen de aquí.
  @visibleForTesting
  static List<Persona> personasCon(bool ejemplos) => ejemplos
      ? DatosDemo.personas
      : const <Persona>[
          Persona(id: DatosDemo.yo, nombre: 'Tú', color: _amarillo),
        ];

  static const Color _amarillo = Color(0xFFFFC93C);
}
