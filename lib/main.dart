import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router.dart';
import 'core/errores.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/tokens/app_colors.dart';

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
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.superficie,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    const ProviderScope(
      observers: <ProviderObserver>[ObservadorErrores()],
      child: CatacroketApp(),
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
