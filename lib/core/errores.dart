import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Recogida de errores de toda la app en un único sitio.
///
/// La app no manda nada a ningún servidor: aquí sólo se registran. Lo que
/// importa es que exista **un** embudo por el que pase todo, para que el día
/// que se quiera enchufar un Sentry o un Crashlytics se toque una función y
/// no cuarenta ficheros.
class Errores {
  const Errores._();

  /// Embudo único. Todo error de la app termina aquí.
  ///
  /// [origen] dice de qué parte viene (framework, plataforma, provider) para
  /// poder distinguirlos de un vistazo en la consola.
  static void registrar(
    Object error,
    StackTrace? pila, {
    String origen = 'app',
  }) {
    developer.log(
      error.toString(),
      name: 'catacroket.$origen',
      error: error,
      stackTrace: pila,
      level: 1000, // SEVERE
    );
  }

  /// Engancha los dos canales por los que Flutter escupe errores no capturados.
  ///
  /// Sin esto, un fallo dentro de un `build()` sale por consola en debug y
  /// desaparece en release, y un fallo en el motor ni siquiera llega.
  static void instalar() {
    // Errores del framework: build, layout, paint, gestos.
    final FlutterExceptionHandler? anterior = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails detalles) {
      // Se conserva el comportamiento de fábrica (pantalla roja en debug)
      // y además se registra.
      anterior?.call(detalles);
      registrar(detalles.exception, detalles.stack, origen: 'flutter');
    };

    // Errores asíncronos que llegan desde la plataforma y no pasan por zona.
    PlatformDispatcher.instance.onError = (Object error, StackTrace pila) {
      registrar(error, pila, origen: 'plataforma');
      return true; // Tratado: que no tumbe el proceso.
    };
  }

  /// Arranca [cuerpo] dentro de una zona que captura lo que se escape.
  ///
  /// El binding de Flutter tiene que inicializarse en esta misma zona, así
  /// que el `main` entero va aquí dentro, no sólo el `runApp`.
  static void arrancar(void Function() cuerpo) {
    runZonedGuarded<void>(
      cuerpo,
      (Object error, StackTrace pila) =>
          registrar(error, pila, origen: 'zona'),
    );
  }
}

/// Observa los providers de Riverpod y registra los que revientan.
///
/// Un `StateNotifier` que lanza dentro de un método deja el estado a medias
/// sin avisar a nadie. Esto al menos lo deja anotado.
class ObservadorErrores extends ProviderObserver {
  const ObservadorErrores();

  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    Errores.registrar(
      error,
      stackTrace,
      origen: 'provider:${provider.name ?? provider.runtimeType}',
    );
  }
}
