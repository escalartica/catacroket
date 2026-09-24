import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Carga las fuentes de la app antes de ejecutar ningún test.
///
/// Flutter lo llama solo: basta con que este fichero exista y se llame así.
///
/// Por qué hace falta. En un test no se cargan las fuentes del `pubspec`, así
/// que todo el texto se dibuja con una de reemplazo cuyas letras no miden lo
/// que las de Fredoka. Y esta app comprueba desbordamientos en los tests —un
/// `RenderFlex` que se sale no lo ve el analizador y en el móvil son rayas
/// amarillas y negras—, o sea que estaba midiendo anchos que no son los que
/// verá nadie. Eso corta por los dos lados: inventa desbordamientos que no
/// existen y, lo que importa de verdad, tapa los que sí.
///
/// Se descubrió midiendo una pantalla a 440 de ancho: el test decía que una
/// pastilla se salía 40 píxeles y en el simulador, con la misma anchura, no se
/// salía nada.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Las dos familias del pubspec. Si se añade una tercera, va aquí también:
  // una fuente que falte no rompe nada y por eso no se nota, sólo deja de
  // medirse lo que se dibuja con ella.
  await _cargar('Fredoka', <String>[
    'fonts/Fredoka-Regular.ttf',
    'fonts/Fredoka-Medium.ttf',
    'fonts/Fredoka-SemiBold.ttf',
    'fonts/Fredoka-Bold.ttf',
  ]);
  await _cargar('Nunito', <String>[
    'fonts/Nunito-Regular.ttf',
    'fonts/Nunito-SemiBold.ttf',
    'fonts/Nunito-Bold.ttf',
    'fonts/Nunito-ExtraBold.ttf',
    'fonts/Nunito-Black.ttf',
  ]);

  return testMain();
}

/// Si una fuente no está, se sigue sin ella: quedarse sin poder ejecutar la
/// suite entera por un fichero que falta sería peor que medir de más.
Future<void> _cargar(String familia, List<String> rutas) async {
  final FontLoader cargador = FontLoader(familia);
  bool alguna = false;

  for (final String ruta in rutas) {
    final File f = File(ruta);
    if (!f.existsSync()) continue;
    alguna = true;
    cargador.addFont(
      f.readAsBytes().then((Uint8List bytes) => ByteData.view(bytes.buffer)),
    );
  }

  if (alguna) await cargador.load();
}
