import 'package:catacroket/core/models/alergeno.dart';
import 'package:catacroket/core/models/cata.dart';
import 'package:catacroket/core/models/corte.dart';
import 'package:catacroket/core/models/dieta.dart';
import 'package:catacroket/core/models/medio.dart';
import 'package:catacroket/core/models/receta.dart';
import 'package:catacroket/core/models/sabor.dart';
import 'package:catacroket/core/providers/nube_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// Dos cosas que la app daba por sabidas sin saberlas.
void main() {
  Cata cata({
    Receta? receta,
    String relleno = 'jamon',
    List<Medio> medios = const <Medio>[],
  }) =>
      Cata(
        id: 'c1',
        sitio: 'Bar',
        ciudad: 'Sevilla',
        corte: const Corte(crujiente: 7, cremosidad: 7, sabor: 7, relleno: 7),
        sabores: <Sabor>[Sabor(rellenoId: relleno)],
        autorId: 'tu',
        fecha: DateTime(2026, 3, 14),
        receta: receta,
        medios: medios,
      );

  group('«no lo sé» no es «no te vale»', () {
    test('con la receta a medias se pregunta, no se niega', () {
      // El caso real: relleno «a mi manera» y bechamel «no lo sé». De ahí no
      // se deduce ninguna dieta, y eso NO quiere decir que no valga: quiere
      // decir que nadie preguntó. Decir «⛔ No te vale» esconde justo las
      // croquetas que un celíaco se habría comido preguntando en la barra.
      final Cata c = cata(
        relleno: 'otro',
        receta: const Receta(
          bechamel: Bechamel.sinSaber,
          rebozadoConGluten: false,
          rebozadoConHuevo: false,
        ),
      );

      expect(c.aptasCalculadas, isEmpty, reason: 'no se deduce nada');
      expect(c.descartadas, isEmpty, reason: 'tampoco se descarta nada');
      expect(c.encajeCon(<Dieta>{Dieta.sinGluten}), Encaje.ojo);
    });

    test('cuando sí se sabe que lleva, se dice que no', () {
      final Cata c = cata(
        receta: const Receta(
          bechamel: Bechamel.leche,
          rebozadoConGluten: true,
          rebozadoConHuevo: true,
        ),
      );

      expect(c.descartadas, contains(Dieta.sinGluten));
      expect(c.encajeCon(<Dieta>{Dieta.sinGluten}), Encaje.no);
      expect(c.encajeCon(<Dieta>{Dieta.sinHuevo}), Encaje.no);
      expect(c.encajeCon(<Dieta>{Dieta.sinLactosa}), Encaje.no);
    });

    test('sin receta ninguna sigue siendo «no lo sé», no una pregunta', () {
      // A una cata que nadie miró no se le pone pastilla: una app llena de
      // «pregunta» en cada tarjeta deja de querer decir nada.
      expect(cata().encajeCon(<Dieta>{Dieta.sinGluten}), Encaje.sinSaber);
    });

    test('un relleno sin describir no descarta por sí solo', () {
      // «A mi manera» puede ser cualquier cosa, y cualquier cosa incluye que
      // valga. Lo que descarta es lo que está apuntado.
      final Cata c = cata(
        relleno: 'otro',
        receta: const Receta(
          bechamel: Bechamel.vegetal,
          bebida: BebidaVegetal.avena,
          rebozadoConGluten: false,
          rebozadoConHuevo: false,
        ),
      );

      expect(c.descartadas, isEmpty);
      expect(c.encajeCon(<Dieta>{Dieta.vegana}), Encaje.ojo);
    });

    test('lo apuntado a mano también descarta', () {
      final Cata c = cata(
        relleno: 'otro',
        receta: const Receta(
          bechamel: Bechamel.sinSaber,
          rebozadoConGluten: false,
          rebozadoConHuevo: false,
          extra: <Alergeno>{Alergeno.frutosCascara},
        ),
      );

      expect(c.descartadas, contains(Dieta.sinFrutosSecos));
      expect(c.encajeCon(<Dieta>{Dieta.sinFrutosSecos}), Encaje.no);
    });

    test('la Barra Libre sigue sin colar lo dudoso', () {
      // «Pregunta» no es «vale»: en la lista de lo que puedes comer sólo
      // entra lo que se afirma.
      final Cata c = cata(
        relleno: 'otro',
        receta: const Receta(bechamel: Bechamel.sinSaber),
      );

      expect(c.valePara(<Dieta>{Dieta.sinGluten}), isFalse);
      expect(c.tieneDietas, isFalse);
    });
  });

  group('la foto que sólo está en la nube', () {
    const Medio sinMini = Medio(tipo: TipoMedio.foto, ruta: '/vieja/foto.jpg');
    const Medio conMini =
        Medio(tipo: TipoMedio.foto, ruta: '/vieja/foto.jpg', mini: 'XXXX');

    test('la copia del móvil se queda con la miniatura del servidor', () {
      // El fallo de «han desaparecido algunas fotos»: la miniatura no se
      // guarda en este teléfono a propósito, así que vive sólo en el
      // servidor. Al pisar la copia del servidor con la del móvil se tiraba,
      // y después de reinstalar la app no quedaba NADA que pintar.
      final List<Cata> juntas = juntarCatas(
        <Cata>[cata(medios: const <Medio>[sinMini])],
        <Cata>[cata(medios: const <Medio>[conMini])],
      );

      expect(juntas, hasLength(1));
      expect(juntas.first.medios.first.mini, 'XXXX');
    });

    test('empareja por posición cuando la ruta ya no coincide', () {
      // Al reinstalar en iOS cambia el nombre de la carpeta de la app, así
      // que la ruta guardada hace meses puede no casar con ninguna.
      const Medio otraRuta =
          Medio(tipo: TipoMedio.foto, ruta: '/otra/foto.jpg', mini: 'YYYY');
      final List<Cata> juntas = juntarCatas(
        <Cata>[cata(medios: const <Medio>[sinMini])],
        <Cata>[cata(medios: const <Medio>[otraRuta])],
      );

      expect(juntas.first.medios.first.mini, 'YYYY');
    });

    test('no se inventa una miniatura de otro tipo de medio', () {
      const Medio video =
          Medio(tipo: TipoMedio.video, ruta: '/otra/x.mp4', mini: 'ZZZZ');
      final List<Cata> juntas = juntarCatas(
        <Cata>[cata(medios: const <Medio>[sinMini])],
        <Cata>[cata(medios: const <Medio>[video])],
      );

      expect(juntas.first.medios.first.mini, isNull);
    });

    test('lo demás de la cata sigue mandándolo el móvil', () {
      // La corrección que hiciste sin cobertura no se puede perder: por eso
      // gana la del móvil en todo lo que no sea la miniatura.
      final List<Cata> juntas = juntarCatas(
        <Cata>[cata(medios: const <Medio>[sinMini]).copyWith(sitio: 'Corregido')],
        <Cata>[cata(medios: const <Medio>[conMini])],
      );

      expect(juntas.first.sitio, 'Corregido');
      expect(juntas.first.medios.first.mini, 'XXXX');
    });
  });
}
