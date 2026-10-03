import 'package:catacroket/core/models/cata.dart';
import 'package:catacroket/core/models/corte.dart';
import 'package:catacroket/core/models/sabor.dart';
import 'package:flutter_test/flutter_test.dart';

/// De quién es una cata.
///
/// Esto estaba mal y no se veía: `autorId` vale `'tu'` en TODOS los móviles,
/// porque es un identificador local de antes de que hubiera cuentas. Una cata
/// que llegaba de la mesa de otra persona traía `autorId: 'tu'` igualmente,
/// así que compararlo decía que era tuya. Consecuencias reales: el perfil
/// contaba las croquetas de los demás como propias —con sus medallas, sus
/// países y su racha—, el filtro «Mías» de La Vitrina enseñaba las ajenas, y
/// la ficha de una cata de otro te ofrecía los botones de editar y borrar.
Cata _cata({String autorId = 'tu', String? autorUid}) => Cata(
      id: 'c1',
      sitio: 'Bar',
      ciudad: 'Sevilla',
      corte: const Corte.media(),
      sabores: const <Sabor>[Sabor(rellenoId: 'jamon')],
      autorId: autorId,
      autorUid: autorUid,
      mesas: const <String>['m1'],
      fecha: DateTime(2026),
    );

void main() {
  group('Cata.esMia', () {
    test('con uid, manda el uid', () {
      expect(_cata(autorUid: 'abc').esMia('abc'), isTrue);
    });

    test('la cata de otro NO es tuya aunque traiga autorId «tu»', () {
      // El caso exacto que estaba roto: así llega por la nube.
      expect(_cata(autorUid: 'de-otro').esMia('abc'), isFalse);
    });

    test('sin sesión, lo que hay en este móvil es tuyo', () {
      // Cambió a propósito. Sin cuenta no llega nada de fuera —las catas de
      // tu gente viajan por una conexión que exige sesión—, así que lo que
      // esté en este disco es tuyo, lleve el uid que lleve. Antes se exigía
      // que el uid cuadrara, y entrar con otra cuenta en el mismo móvil
      // —después de perder la contraseña, por ejemplo— te dejaba el diario
      // vacío, el perfil a cero y el Croquetómetro a cero, con las catas
      // intactas en el disco. Indistinguible de haberlas perdido.
      expect(_cata(autorUid: 'de-otra-sesion').esMia(null), isTrue);
    });

    test('sin uid es local, y entonces autorId sí dice la verdad', () {
      expect(_cata().esMia(null), isTrue);
      expect(_cata().esMia('abc'), isTrue);
    });

    test('sin uid y de otra persona de la libreta, no es tuya', () {
      expect(_cata(autorId: 'marta').esMia(null), isFalse);
    });
  });
}
