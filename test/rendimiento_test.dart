import 'package:catacroket/core/models/cata.dart';
import 'package:catacroket/core/models/corte.dart';
import 'package:catacroket/core/models/sabor.dart';
import 'package:catacroket/features/ruta/agrupacion.dart';
import 'package:flutter_test/flutter_test.dart';

/// Qué pasa cuando la libreta se llena.
///
/// Una app de apuntar cosas se usa durante años: la que hoy tiene doce catas
/// mañana tiene quinientas. Lo que aquí se mide no es si es rápida, sino si
/// hay algo que crece peor que el número de catas, porque eso es lo que se
/// convierte en una app congelada sin avisar.
void main() {
  Cata cata({
    required String id,
    required double lat,
    required double lon,
  }) =>
      Cata(
        id: id,
        sitio: 'Bar $id',
        ciudad: 'Sevilla',
        corte: const Corte(crujiente: 7, cremosidad: 7, sabor: 7, relleno: 7),
        sabores: const <Sabor>[Sabor(rellenoId: 'jamon')],
        autorId: 'tu',
        mesaId: 'libreta',
        fecha: DateTime(2026),
        lat: lat,
        lon: lon,
      );

  /// Catas repartidas por una ciudad, como las de alguien que lleva años.
  List<Cata> porLaCiudad(int cuantas) => <Cata>[
        for (int i = 0; i < cuantas; i++)
          cata(
            id: '$i',
            // Una rejilla apretada dentro de Sevilla: el caso peor para
            // agrupar, porque casi todas se pisan entre sí.
            lat: 37.36 + (i % 25) * 0.0012,
            lon: -6.02 + (i ~/ 25) * 0.0012,
          ),
      ];

  int milisEn(void Function() algo) {
    // Una vuelta en vacío antes de medir. Sin esto, la primera llamada
    // carga el coste de arranque de la VM y la medida sale disparada: la
    // primera versión de este test daba 17 ms para 100 catas y 1 ms para
    // 250, que es imposible, y por eso pasaba o fallaba según el orden.
    algo();

    final Stopwatch reloj = Stopwatch()..start();
    algo();
    reloj.stop();
    return reloj.elapsedMilliseconds;
  }

  /// En microsegundos, para comparar dos tamaños. En milisegundos enteros el
  /// más pequeño puede dar 12 o 13 y eso mueve la proporción un 8% sin que
  /// haya pasado nada.
  int microsEn(void Function() algo) {
    algo();

    final Stopwatch reloj = Stopwatch()..start();
    algo();
    reloj.stop();
    return reloj.elapsedMicroseconds;
  }

  group('Agrupar los globos del mapa', () {
    // Sobre medir tiempos en un test: la suite ejecuta varios ficheros a la
    // vez, así que la CPU va cargada y un umbral en milisegundos puede fallar
    // sin que nadie haya tocado nada. Ya pasó aquí. Por eso queda un solo
    // umbral absoluto, con holgura de sobra, y la comprobación de que no
    // crece al cuadrado se hace por proporción entre dos tamaños, que es
    // inmune a la carga: infla las dos medidas por igual y se cancela.

    test('agrupar 500 catas no bloquea el mapa', () {
      // Esto se recalcula en cada movimiento del mapa, y a 60 fps hay 16 ms
      // por fotograma. Tarda entre 1 y 6 ms; el umbral es muy superior a
      // propósito, para que no falle por la carga de la máquina. Aun así
      // pilla lo que venía a pillar: antes de arreglarlo eran 207 ms.
      final List<Cata> muchas = porLaCiudad(500);

      final int milis = milisEn(() => agruparCatas(muchas, 17));

      expect(
        milis,
        lessThan(80),
        reason: 'agrupar 500 catas ha tardado $milis ms. El fotograma dura '
            '16, así que el mapa se arrastraría a tirones al arrastrarlo',
      );
    });

    test('el tiempo no crece al cuadrado', () {
      // La comprobación que de verdad importa, y que faltaba. Los umbrales
      // absolutos de antes quedaban justo al filo: al revertir a mano la
      // mejora que evita el crecimiento cuadrático, seguían pasando.
      //
      // Con cuatro veces más catas: agrupando por casillas vecinas el tiempo
      // se multiplica por 2,9 (12 ms -> 36); comparando todas las parejas,
      // por 18,7 (129 ms -> 2.419). Un tope de 7 deja sitio de sobra para el
      // ruido y muy lejos de lo otro. Comprobado deshaciendo el cambio.
      final List<Cata> pocas = porLaCiudad(3000);
      final List<Cata> cuatroVeces = porLaCiudad(12000);

      final int conPocas = microsEn(() => agruparCatas(pocas, 17));
      final int conMuchas = microsEn(() => agruparCatas(cuatroVeces, 17));

      final double razon = conMuchas / conPocas;
      expect(
        razon,
        lessThan(7),
        reason: 'al cuadruplicar las catas el tiempo se ha multiplicado por '
            '${razon.toStringAsFixed(1)} (${conPocas}us -> ${conMuchas}us). '
            'Eso es crecimiento cuadrático: probablemente se están '
            'comparando todas las parejas otra vez, en vez de sólo las '
            'casillas vecinas',
      );
    });

    test('no pierde ni duplica ninguna con 500', () {
      // Que sea rápida no vale de nada si se deja catas por el camino.
      final List<Cata> muchas = porLaCiudad(500);

      for (final double zoom in <double>[10, 13, 16, 18]) {
        final List<Grupo> grupos = agruparCatas(muchas, zoom);
        final List<String> ids = <String>[
          for (final Grupo g in grupos) ...g.catas.map((Cata c) => c.id),
        ];

        expect(ids.toSet(), hasLength(500), reason: 'al zoom $zoom');
      }
    });
  });

  group('Ordenar y filtrar la libreta', () {
    test('ordenar 2.000 catas por nota es instantáneo', () {
      final List<Cata> muchas = porLaCiudad(2000);

      final int milis = milisEn(() {
        final List<Cata> copia = <Cata>[...muchas]
          ..sort((Cata a, Cata b) => b.puntuacion.compareTo(a.puntuacion));
        expect(copia, hasLength(2000));
      });

      expect(milis, lessThan(100), reason: 'ha tardado $milis ms');
    });

    test('filtrar 2.000 catas también', () {
      final List<Cata> muchas = porLaCiudad(2000);

      final int milis = milisEn(() {
        final List<Cata> conSitio =
            muchas.where((Cata c) => c.tieneUbicacion).toList();
        expect(conSitio, hasLength(2000));
      });

      expect(milis, lessThan(50), reason: 'ha tardado $milis ms');
    });
  });
}
