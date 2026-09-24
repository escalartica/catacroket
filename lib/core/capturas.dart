/// Modo capturas: la app como la verá la gente, pero con catas dentro.
///
/// Existe por un problema concreto. Las capturas de la ficha de tienda tienen
/// que enseñar la app de verdad, y hay dos cosas que lo impiden a la vez:
///
/// - En release no hay datos de ejemplo (ver `Siembra`), y una app de catas
///   sin catas no se puede fotografiar.
/// - En depuración sí hay datos, pero también hay herramientas que en la
///   tienda no existen —el botón de diagnóstico del mapa—, y fotografiar un
///   botón que nadie va a tener es enseñar otra app.
///
/// Lo suyo sería compilar en release, que no tiene ninguna de las dos cosas.
/// Pero el simulador de iOS no admite release ni profile —lo dice él mismo:
/// «Release mode is not supported by ...»— y las capturas de la App Store se
/// hacen en el simulador, porque es donde se tiene el tamaño exacto de cada
/// modelo. Así que hay que hacerlo en depuración y quitar lo que sobra.
///
///     flutter run --dart-define=CATACROKET_CAPTURAS=true
///
/// Qué puede hacer esto: sembrar datos de ejemplo y esconder herramientas de
/// depuración. Qué NO puede hacer nunca: cambiar la interfaz que se está
/// fotografiando. Una captura que enseña algo que la app no hace es publicidad
/// engañosa, y además la revisión de Apple lo mira.
///
/// No se puede colar en una compilación de tienda por descuido: hay que
/// escribirlo entero en la línea de órdenes. Que los datos no aparezcan solos
/// en release lo sigue garantizando `kReleaseMode`.
const bool paraCapturas = bool.fromEnvironment('CATACROKET_CAPTURAS');
