import 'package:catacroket/core/data/rellenos.dart';
import 'package:catacroket/core/models/alergeno.dart';
import 'package:catacroket/core/models/dieta.dart';
import 'package:catacroket/core/models/receta.dart';
import 'package:flutter_test/flutter_test.dart';

/// Atajo para leer los casos sin ruido.
Set<Dieta> deducir(Receta receta, List<String> rellenos) => Dieta.deducir(
      receta: receta,
      rellenos: rellenos.map(Rellenos.de).toList(),
    );

void main() {
  group('No inventarse nada', () {
    test('una receta sin contestar no dice nada', () {
      expect(deducir(const Receta(), <String>['boletus']), isEmpty);
    });

    test('contestar sólo la freidora no da derecho a hablar de alérgenos', () {
      // El fallo que destapó esta tanda de tests: con la bechamel sin saber,
      // la app presumía de "sin frutos secos" porque el boletus no lleva. Sin
      // saber de qué es la bechamel no se sabe nada: podía ser de almendra.
      final Set<Dieta> d = deducir(
        const Receta(freidora: Freidora.compartida),
        <String>['boletus'],
      );
      expect(d, isNot(contains(Dieta.sinFrutosSecos)));
      expect(d, isEmpty);
    });

    test('bechamel vegetal sin saber de qué, no descarta soja ni almendra', () {
      final Set<Dieta> d = deducir(
        const Receta(
          bechamel: Bechamel.vegetal,
          rebozadoConGluten: false,
          rebozadoConHuevo: false,
        ),
        <String>['calabaza'],
      );
      expect(d, contains(Dieta.vegana));
      expect(d, contains(Dieta.sinGluten));
      expect(d, isNot(contains(Dieta.sinFrutosSecos)));
    });
  });

  group('Vegana', () {
    test('un relleno vegano con bechamel de leche NO es vegana', () {
      // El caso de casi todos los bares, y el que la versión de etiquetas a
      // mano dejaba marcar sin rechistar.
      final Set<Dieta> d = deducir(
        const Receta(bechamel: Bechamel.leche),
        <String>['boletus'],
      );
      expect(d, isNot(contains(Dieta.vegana)));
      expect(d, contains(Dieta.vegetariana));
    });

    test('hacen falta las tres cosas: relleno, bechamel y rebozado', () {
      const Receta casi = Receta(
        bechamel: Bechamel.vegetal,
        bebida: BebidaVegetal.avena,
      );
      // Con huevo en el rebozado todavía no lo es.
      expect(deducir(casi, <String>['calabaza']),
          isNot(contains(Dieta.vegana)));
      expect(
        deducir(casi.copyWith(rebozadoConHuevo: false), <String>['calabaza']),
        contains(Dieta.vegana),
      );
    });

    test('un relleno de carne nunca es vegana por mucha bechamel vegetal', () {
      final Set<Dieta> d = deducir(
        const Receta(
          bechamel: Bechamel.vegetal,
          bebida: BebidaVegetal.avena,
          rebozadoConHuevo: false,
        ),
        <String>['jamon'],
      );
      expect(d, isNot(contains(Dieta.vegana)));
      expect(d, isNot(contains(Dieta.vegetariana)));
    });
  });

  group('Vegana no es sin gluten', () {
    test('el seitán es vegano y es trigo', () {
      final Set<Dieta> d = deducir(
        const Receta(
          bechamel: Bechamel.vegetal,
          bebida: BebidaVegetal.avena,
          rebozadoConGluten: false,
          rebozadoConHuevo: false,
        ),
        <String>['seitan'],
      );
      expect(d, contains(Dieta.vegana));
      expect(d, isNot(contains(Dieta.sinGluten)),
          reason: 'el seitán es gluten de trigo, por muy vegetal que sea todo '
              'lo demás');
    });
  });

  group('Sin lactosa no es sin leche', () {
    test('la leche sin lactosa vale', () {
      expect(
        deducir(const Receta(bechamel: Bechamel.sinLactosa), <String>['jamon']),
        contains(Dieta.sinLactosa),
      );
    });

    test('pero sigue llevando leche como alérgeno', () {
      expect(
        const Receta(bechamel: Bechamel.sinLactosa).alergenos,
        contains(Alergeno.leche),
      );
    });

    test('un relleno de queso lo estropea aunque la bechamel sea vegetal', () {
      expect(
        deducir(
          const Receta(bechamel: Bechamel.vegetal, bebida: BebidaVegetal.avena),
          <String>['queso'],
        ),
        isNot(contains(Dieta.sinLactosa)),
      );
    });
  });

  group('Alérgenos del relleno', () {
    test('los piñones de las espinacas cuentan', () {
      expect(
        deducir(
          const Receta(
            bechamel: Bechamel.vegetal,
            bebida: BebidaVegetal.avena,
            rebozadoConGluten: false,
            rebozadoConHuevo: false,
          ),
          <String>['espinaca'],
        ),
        isNot(contains(Dieta.sinFrutosSecos)),
      );
    });

    test('el pescado y el marisco tumban lo vegetariano', () {
      for (final String r in <String>['bacalao', 'gamba', 'chipiron']) {
        expect(
          deducir(const Receta(bechamel: Bechamel.leche), <String>[r]),
          isNot(contains(Dieta.vegetariana)),
          reason: r,
        );
      }
    });

    test('"a mi manera" no se clasifica: sin saber qué lleva, nada', () {
      // Ni lo vegano ni lo vegetariano, que eso ya lo bloqueaba el perfil,
      // pero tampoco ningún "sin X": un relleno que nadie ha descrito puede
      // llevar nueces o gluten igual que puede no llevarlos.
      final Set<Dieta> d = deducir(
        const Receta(
          bechamel: Bechamel.vegetal,
          bebida: BebidaVegetal.avena,
          rebozadoConGluten: false,
          rebozadoConHuevo: false,
        ),
        <String>['otro'],
      );
      expect(d, isEmpty);
    });

    test('un surtido con un sabor sin describir arrastra a todo el surtido', () {
      expect(
        deducir(
          const Receta(
            bechamel: Bechamel.vegetal,
            bebida: BebidaVegetal.avena,
            rebozadoConGluten: false,
            rebozadoConHuevo: false,
          ),
          <String>['calabaza', 'otro'],
        ),
        isEmpty,
      );
    });
  });

  group('Surtidos', () {
    test('manda el peor sabor: uno de jamón tumba el surtido entero', () {
      expect(
        deducir(
          const Receta(
            bechamel: Bechamel.vegetal,
            bebida: BebidaVegetal.avena,
            rebozadoConHuevo: false,
          ),
          <String>['calabaza', 'puerro', 'jamon'],
        ),
        isNot(contains(Dieta.vegana)),
      );
    });

    test('un surtido entero vegano sí lo es', () {
      expect(
        deducir(
          const Receta(
            bechamel: Bechamel.vegetal,
            bebida: BebidaVegetal.avena,
            rebozadoConHuevo: false,
          ),
          <String>['calabaza', 'puerro', 'boletus'],
        ),
        contains(Dieta.vegana),
      );
    });
  });
}
