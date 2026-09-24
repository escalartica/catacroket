import 'package:catacroket/core/models/cata.dart';
import 'package:catacroket/core/models/corte.dart';
import 'package:catacroket/core/models/sabor.dart';
import 'package:catacroket/core/providers/catas_provider.dart';
import 'package:catacroket/core/utils/texto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Buscar entre tus catas.
///
/// Es la promesa de la app —«meses después ves dónde estaba aquella que no se
/// te olvida»— y no había forma de hacerlo: con doscientas catas, encontrar
/// una era bajar con el dedo hasta dar con ella.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Cata cata({
    required String id,
    String sitio = 'Bar de relleno',
    String ciudad = 'Sevilla',
    String nota = '',
    List<String> acompanantes = const <String>[],
    List<Sabor> sabores = const <Sabor>[Sabor(rellenoId: 'jamon')],
    String autorId = 'tu',
    String mesaId = 'libreta',
  }) =>
      Cata(
        id: id,
        sitio: sitio,
        ciudad: ciudad,
        corte: const Corte(crujiente: 8, cremosidad: 7, sabor: 9, relleno: 6),
        sabores: sabores,
        autorId: autorId,
        mesaId: mesaId,
        fecha: DateTime(2026, 3, 14),
        nota: nota,
        acompanantes: acompanantes,
      );

  /// Relleno para pasar del mínimo desde el que se puede buscar.
  ///
  /// La caja no aparece con cuatro catas, y el filtrado tampoco se aplica: si
  /// el usuario no puede ver la caja, lo que hubiera escrito en ella no puede
  /// seguir filtrando por detrás. Así que aquí hace falta una libreta de
  /// verdad para probar nada.
  List<Cata> conBastantes(List<Cata> suyas) => <Cata>[
        ...suyas,
        for (int i = 0; i < catasParaBuscar; i++) cata(id: 'relleno-$i'),
      ];

  /// Un contenedor con las catas puestas a mano.
  ProviderContainer conCatas(List<Cata> catas) {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final ProviderContainer c = ProviderContainer();
    // Se escribe directo en el estado del notifier: montar el disco para esto
    // sólo añadiría esperas a un test que no va del disco.
    c.read(catasProvider.notifier).state = catas;
    return c;
  }

  List<String> buscar(List<Cata> catas, String que) {
    final ProviderContainer c = conCatas(conBastantes(catas));
    c.read(busquedaVitrinaProvider.notifier).state = que;
    final List<String> ids =
        c.read(feedProvider).map((Cata x) => x.id).toList();
    c.dispose();
    return ids;
  }

  group('Por dónde se encuentra una cata', () {
    test('por el nombre del bar', () {
      final List<Cata> catas = <Cata>[
        cata(id: 'la-buena', sitio: 'Casa Ricardo'),
      ];

      expect(buscar(catas, 'Ricardo'), contains('la-buena'));
    });

    test('por la ciudad', () {
      final List<Cata> catas = <Cata>[
        cata(id: 'la-de-granada', ciudad: 'Granada'),
      ];

      expect(buscar(catas, 'granada'), contains('la-de-granada'));
    });

    test('por el relleno', () {
      final List<Cata> catas = <Cata>[
        cata(
          id: 'la-de-boletus',
          sabores: const <Sabor>[Sabor(rellenoId: 'boletus')],
        ),
      ];

      expect(buscar(catas, 'boletus'), contains('la-de-boletus'));
    });

    test('por lo que apuntaste', () {
      // «Aquella que ponía que picaba». Es la forma en que de verdad se
      // recuerda una cata de hace meses.
      final List<Cata> catas = <Cata>[
        cata(id: 'la-que-picaba', nota: 'Picaba un montón'),
      ];

      expect(buscar(catas, 'picaba'), contains('la-que-picaba'));
    });

    test('por con quién estabas', () {
      final List<Cata> catas = <Cata>[
        cata(id: 'con-marta', acompanantes: <String>['Marta']),
      ];

      expect(buscar(catas, 'marta'), contains('con-marta'));
    });
  });

  group('Se escribe deprisa y con una mano', () {
    test('sin tildes encuentra con tildes', () {
      // Nadie pone la tilde buscando con el móvil en una mano.
      final List<Cata> catas = <Cata>[
        cata(id: 'la-del-jamon', sitio: 'Bar Jamón Jamón'),
      ];

      expect(buscar(catas, 'jamon'), contains('la-del-jamon'));
    });

    test('con tildes encuentra sin tildes', () {
      final List<Cata> catas = <Cata>[
        cata(id: 'sin-tilde', sitio: 'Bar Jamon'),
      ];

      expect(buscar(catas, 'jamón'), contains('sin-tilde'));
    });

    test('da igual cómo se escriban las mayúsculas', () {
      final List<Cata> catas = <Cata>[
        cata(id: 'la-buena', sitio: 'Casa Ricardo'),
      ];

      expect(buscar(catas, 'CASA ricardo'), contains('la-buena'));
    });

    test('un trozo de palabra vale', () {
      final List<Cata> catas = <Cata>[
        cata(id: 'la-buena', sitio: 'El Rinconcito de Ana'),
      ];

      expect(buscar(catas, 'rincon'), contains('la-buena'));
    });
  });

  group('Lo que no debe pasar', () {
    test('sin escribir nada salen todas', () {
      final List<Cata> catas = <Cata>[cata(id: 'la-buena')];

      expect(buscar(catas, ''), hasLength(catasParaBuscar + 1));
      expect(buscar(catas, '   '), hasLength(catasParaBuscar + 1));
    });

    test('no encuentra a caballo entre dos campos', () {
      // «Bar Manoli» y «Sevilla» pegados formarían «bar manoli sevilla», y
      // buscar «manoli sevilla» encontraría algo que en la ficha no se lee
      // así. Cada campo se mira por separado.
      final List<Cata> catas = <Cata>[
        cata(id: 'la-buena', sitio: 'Bar Manoli', ciudad: 'Sevilla'),
      ];

      expect(buscar(catas, 'manoli sevilla'), isNot(contains('la-buena')));
      expect(buscar(catas, 'manoli'), contains('la-buena'));
    });

    test('lo que no está, no sale', () {
      final List<Cata> catas = <Cata>[cata(id: 'la-buena', sitio: 'Casa Ricardo')];

      expect(buscar(catas, 'zamora'), isEmpty);
    });

    test('con pocas catas la búsqueda no filtra nada', () {
      // La caja no se enseña por debajo del mínimo. Si aun así hubiera algo
      // escrito —por ejemplo porque el usuario borró catas después de
      // buscar—, no puede seguir escondiendo la lista por detrás.
      final ProviderContainer c = conCatas(<Cata>[
        cata(id: 'la-unica', sitio: 'Casa Ricardo'),
      ]);
      c.read(busquedaVitrinaProvider.notifier).state = 'zamora';

      expect(c.read(sePuedeBuscarProvider), isFalse);
      expect(c.read(feedProvider), hasLength(1));
      c.dispose();
    });
  });

  group('La búsqueda y el filtro se cumplen los dos', () {
    test('buscar dentro de «Mías» no saca las de otros', () {
      final ProviderContainer c = conCatas(conBastantes(<Cata>[
        cata(id: 'mia', sitio: 'Casa Ricardo', autorId: 'tu'),
        cata(id: 'de-otro', sitio: 'Casa Ricardo', autorId: 'marta'),
      ]));

      c.read(filtroVitrinaProvider.notifier).state = FiltroVitrina.mias;
      c.read(busquedaVitrinaProvider.notifier).state = 'Ricardo';
      final List<String> ids =
          c.read(feedProvider).map((Cata x) => x.id).toList();
      c.dispose();

      expect(ids, contains('mia'));
      expect(ids, isNot(contains('de-otro')));
    });
  });

  group('La regla de comparar textos', () {
    // Estaba escrita dos veces en la app y ya no hacían lo mismo: una cubría
    // la ã y la õ y la otra no.
    test('quita tildes y baja a minúsculas', () {
      expect(Texto.normalizar('JAMÓN'), 'jamon');
      expect(Texto.normalizar('Açaí'), 'acai');
      expect(Texto.normalizar('São Paulo'), 'sao paulo');
    });

    test('la ñ pasa a n, a propósito', () {
      expect(Texto.normalizar('Peñíscola'), 'peniscola');
    });

    test('una búsqueda vacía encuentra siempre', () {
      expect(Texto.contiene('lo que sea', ''), isTrue);
      expect(Texto.contiene('lo que sea', '   '), isTrue);
    });

    test('no se lía con textos vacíos en la lista', () {
      expect(
        Texto.contieneEnAlguno(<String>['', 'Casa Ricardo', ''], 'ricardo'),
        isTrue,
      );
      expect(Texto.contieneEnAlguno(<String>['', ''], 'ricardo'), isFalse);
    });
  });
}
