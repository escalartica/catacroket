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

  group('Agrupar los globos del mapa', () {
    test('con 500 catas cabe en un fotograma', () {
      // Esto se recalcula en cada movimiento del mapa, y a 60 fps hay 16 ms
      // por fotograma. Pasarse significa que el mapa se arrastra a tirones
      // al arrastrarlo, que es la peor forma de ir lento.
      final List<Cata> muchas = porLaCiudad(500);

      final int milis = milisEn(() => agruparCatas(muchas, 12));

      expect(
        milis,
        lessThan(16),
        reason: 'agrupar 500 catas ha tardado $milis ms y el fotograma dura '
            '16: el mapa se movería a tirones',
      );
    });

    test('el tiempo no se dispara al doblar las catas', () {
      // La comprobación que de verdad importa. Si al doblar los datos el
      // tiempo se multiplica por mucho más de cuatro, hay algo que crece
      // peor que al cuadrado y lo que hoy son 500 mañana no se aguanta.
      final int con250 = milisEn(() => agruparCatas(porLaCiudad(250), 12));
      final int con500 = milisEn(() => agruparCatas(porLaCiudad(500), 12));

      // Con tiempos pequeños el ruido de medida manda, así que se compara
      // sólo si hay algo que medir.
      if (con250 >= 5) {
        expect(
          con500,
          lessThan(con250 * 8),
          reason: 'de 250 a 500 catas el tiempo ha pasado de $con250 ms a '
              '$con500 ms: crece demasiado deprisa',
        );
      }
    });

    test('a zoom de calle, que es el caso peor, tampoco', () {
      // Aquí cada cata es su propio grupo, así que se compara todo con todo
      // para descubrir que está lejos. Tardaba 207 ms con 500 catas; ahora 6.
      final List<Cata> muchas = porLaCiudad(500);

      final int milis = milisEn(() => agruparCatas(muchas, 17));

      expect(milis, lessThan(30), reason: 'ha tardado $milis ms');
    });

    test('con 2.000 catas sigue siendo usable', () {
      // Alguien que lleve años. Si aquí se dispara, la app se vuelve
      // inservible justo para quien más la ha usado.
      final List<Cata> muchisimas = porLaCiudad(2000);

      final int milis = milisEn(() => agruparCatas(muchisimas, 17));

      expect(
        milis,
        lessThan(60),
        reason: 'agrupar 2.000 catas ha tardado $milis ms',
      );
    });

    test('el tiempo deja de crecer con el número de catas', () {
      // Este test existe por un fallo mío. Al acelerar esto cambié dos cosas
      // a la vez y atribuí la mejora a la que no era; al revertir una para
      // comprobarlo, los otros tests siguieron pasando, porque sus umbrales
      // están justo al filo de lo que tarda la versión a medias.
      //
      // Con 6.000 la diferencia ya no cabe en el ruido: agrupando por
      // casillas vecinas son 23 ms, y comparando todas las parejas unos 585,
      // porque eso crece al cuadrado y esto no. Si alguien deshace la parte
      // de las casillas, aquí se entera.
      final List<Cata> muchisimas = porLaCiudad(6000);

      final int milis = milisEn(() => agruparCatas(muchisimas, 17));

      expect(
        milis,
        lessThan(120),
        reason: 'agrupar 6.000 catas ha tardado $milis ms. Si son cientos, '
            'es que se están comparando todas las parejas otra vez',
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
