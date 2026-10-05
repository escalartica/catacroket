import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router.dart';
import 'core/bitacora.dart';
import 'core/errores.dart';
import 'core/providers/catas_provider.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'core/utils/archivos.dart';

void main() {
  // Todo el arranque va dentro de la zona vigilada, no sólo el runApp: el
  // binding tiene que inicializarse en la misma zona que luego lo usa.
  Errores.arrancar(_arrancar);
}

Future<void> _arrancar() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Antes que nada: las fotos se guardan con la ruta relativa a esta
  // carpeta, y hace falta saber cómo se llama hoy para poder abrirlas.
  await Archivos.preparar();
  Errores.instalar();

  // Firebase arranca en un try, y no es pereza: la cuenta es OPCIONAL.
  //
  // Apuntar tus catas no necesita servidor ni conexión, así que si Firebase
  // no levanta —sin red, configuración mal puesta, el servicio caído— la app
  // tiene que seguir funcionando entera en local. Lo único que se pierde es
  // compartir con tu mesa, y eso ya se avisa donde toca.
  //
  // Dejarlo sin try significaría que un fallo del servidor de Google impide
  // apuntar una croqueta en un bar sin cobertura. Eso no.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, pila) {
    Errores.registrar(e, pila, origen: 'arranque de Firebase');
  }

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

class CatacroketApp extends ConsumerStatefulWidget {
  const CatacroketApp({super.key});

  @override
  ConsumerState<CatacroketApp> createState() => _CatacroketAppState();
}

class _CatacroketAppState extends ConsumerState<CatacroketApp> {
  /// Reintenta lo que se quedó sin subir cada vez que la app vuelve.
  ///
  /// Hacía falta porque los reintentos de arranque corren UNA vez por sesión
  /// y sólo si pasas por Mesas. El caso normal es justo el otro: apuntas tres
  /// croquetas en un bar sin cobertura, abres la app en el metro —falla—, y
  /// ya no se vuelve a intentar en toda la sesión aunque salgas a la calle y
  /// uses la app una hora. Sólo subían cerrando y volviendo a abrir.
  late final AppLifecycleListener _vigia = AppLifecycleListener(
    onResume: () {
      final CatasNotifier catas = ref.read(catasProvider.notifier);
      unawaited(catas.reintentarPendientes().catchError((Object _) => 0));
      unawaited(catas.reintentarBorrados().catchError((Object _) => 0));
    },
  );

  @override
  void initState() {
    super.initState();
    _vigia; // Se crea al arrancar, no en el primer build.
  }

  @override
  void dispose() {
    _vigia.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Catacroket',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.tema,
      routerConfig: router,

      // El tamaño de letra del sistema se respeta hasta el doble.
      //
      // Estaba topado en 1,3, y eso incumple la norma de accesibilidad
      // (WCAG 1.4.4 pide llegar al 200% sin perder contenido): quien tiene
      // el móvil al 200% porque lo necesita recibía un 130%. No es una
      // degradación suave, es que la app se niega a crecer.
      //
      // Lo que lo hacía peligroso eran dos sitios sin `FittedBox`: las
      // cifras del Croquetómetro y el nombre del perfil. Los dos están
      // arreglados, y el resto de filas de la app ya lo llevaban puesto a
      // propósito desde antes.
      builder: (BuildContext context, Widget? child) {
        final MediaQueryData media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: media.textScaler.clamp(
              minScaleFactor: 0.9,
              maxScaleFactor: 2.0,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
