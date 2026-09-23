import 'package:catacroket/core/models/cata.dart';
import 'package:catacroket/core/models/corte.dart';
import 'package:catacroket/core/models/mesa.dart';
import 'package:catacroket/core/models/persona.dart';
import 'package:catacroket/core/models/sabor.dart';
import 'package:catacroket/core/theme/tokens/app_colors.dart';
import 'package:catacroket/features/mesas/mesas_providers.dart';
import 'package:flutter_test/flutter_test.dart';

Cata cata({
  required String autorId,
  String id = 'x',
  int crujiente = 7,
}) =>
    Cata(
      id: id,
      sitio: 'Bar',
      ciudad: 'Sevilla',
      corte: Corte(crujiente: crujiente, cremosidad: 7, sabor: 7, relleno: 7),
      sabores: const <Sabor>[Sabor(rellenoId: 'jamon')],
      autorId: autorId,
      mesaId: 'mesa',
      fecha: DateTime(2026),
    );

Persona persona(String id) => Persona(
      id: id,
      nombre: id,
      color: AppColors.sol,
    );

Mesa mesa(List<String> miembros) => Mesa(
      id: 'mesa',
      nombre: 'La mesa',
      descripcion: '',
      colorHex: 0xFFFFCC00,
      miembros: miembros,
    );

void main() {
  final Map<String, Persona> gente = <String, Persona>{
    'ana': persona('ana'),
    'beto': persona('beto'),
    'cris': persona('cris'),
  };

  group('rankingDe', () {
    test('manda quien más cata, no quien mejor puntúa', () {
      // Beto se comió una y le puso un diez. Ana se comió tres del montón.
      // Esto es una mesa de amigos, no un jurado: va primero Ana.
      final List<Puesto> ranking = rankingDe(
        mesa(<String>['ana', 'beto']),
        <Cata>[
          cata(autorId: 'ana', id: 'a1', crujiente: 5),
          cata(autorId: 'ana', id: 'a2', crujiente: 5),
          cata(autorId: 'ana', id: 'a3', crujiente: 5),
          cata(autorId: 'beto', id: 'b1', crujiente: 10),
        ],
        gente,
      );

      expect(ranking.first.persona.id, 'ana');
      expect(ranking.first.catas, 3);
    });

    test('a igualdad de catas, desempata la media', () {
      final List<Puesto> ranking = rankingDe(
        mesa(<String>['ana', 'beto']),
        <Cata>[
          cata(autorId: 'ana', id: 'a1', crujiente: 4),
          cata(autorId: 'beto', id: 'b1', crujiente: 9),
        ],
        gente,
      );

      expect(ranking.first.persona.id, 'beto');
    });

    test('quien no ha catado nada sale, pero el último', () {
      final List<Puesto> ranking = rankingDe(
        mesa(<String>['ana', 'beto', 'cris']),
        <Cata>[cata(autorId: 'ana', id: 'a1')],
        gente,
      );

      expect(ranking, hasLength(3));
      expect(ranking.first.persona.id, 'ana');
      expect(ranking.last.catas, 0);
      expect(ranking.last.media, isNull);
    });

    test('sale toda la mesa aunque nadie haya catado', () {
      final List<Puesto> ranking = rankingDe(
        mesa(<String>['ana', 'beto']),
        <Cata>[],
        gente,
      );

      expect(ranking, hasLength(2));
      expect(ranking.every((Puesto p) => p.catas == 0), isTrue);
    });

    test('las catas de quien no está en la mesa no cuentan', () {
      final List<Puesto> ranking = rankingDe(
        mesa(<String>['ana']),
        <Cata>[
          cata(autorId: 'ana', id: 'a1'),
          cata(autorId: 'forastero', id: 'f1'),
        ],
        gente,
      );

      expect(ranking, hasLength(1));
      expect(ranking.first.catas, 1);
    });

    test('un miembro desconocido no deja la fila sin persona', () {
      final List<Puesto> ranking = rankingDe(
        mesa(<String>['fantasma']),
        <Cata>[],
        gente,
      );

      expect(ranking.first.persona, Persona.desconocida);
    });
  });
}
