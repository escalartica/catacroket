import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router.dart';
import 'core/bitacora.dart';
import 'core/errores.dart';
import 'core/theme/app_theme.dart';

void main() {
  // Todo el arranque va dentro de la zona vigilada, no sólo el runApp: el
  // binding tiene que inicializarse en la misma zona que luego lo usa.
  Errores.arrancar(_arrancar);
}

Future<void> _arrancar() async {
  WidgetsFlutterBinding.ensureInitialized();
  Errores.instalar();

  // La app está pensada en vertical: el formulario de cata y el mapa con la
  // hoja de resultados no tienen sentido apaisados en un móvil.
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);

  // Barra de estado transparente con iconos oscuros: el fondo de la app es
  // crema, así que los iconos blancos por defecto de Android desaparecerían.
  // En Android 15+ el edge-to-edge está forzado: systemNavigationBarColor se
  // ignora y la app debe extenderse debajo de la barra del sistema. Con
  // extendBody:true y el padding dinámico de _BarraPestanas ya está resuelto;
  // poner Colors.transparent aquí evita un rectángulo de otro color en los
  // Androids donde sí se aplica.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // El contenedor se crea a mano para poder enchufarle el embudo de errores
  // antes de que exista una sola pantalla: los fallos de arranque son justo
  // los que más importa no perder.
  final ProviderContainer contenedor = ProviderContainer(
    observers: <ProviderObserver>[const ObservadorErrores()],
  );
  Errores.apuntarEn(
    (Object error, StackTrace? pila, String origen) => contenedor
        .read(bitacoraProvider.notifier)
        .apuntar(error, pila, origen),
  );

  runApp(
    UncontrolledProviderScope(
      container: contenedor,
      child: const CatacroketApp(),
    ),
  );
}

class CatacroketApp extends StatelessWidget {
  const CatacroketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Catacroket',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.tema,
      routerConfig: router,

      // El tamaño de letra del sistema se respeta, pero con tope: por encima
      // de 1,3 los bloques con contorno y sombra empiezan a romperse, y es
      // preferible un texto algo menor que una pantalla ilegible.
      builder: (BuildContext context, Widget? child) {
        final MediaQueryData media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: media.textScaler.clamp(
              minScaleFactor: 0.9,
              maxScaleFactor: 1.3,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
