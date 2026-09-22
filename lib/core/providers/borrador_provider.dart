import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/paises.dart';
import '../models/cata.dart';
import '../models/corte.dart';
import '../models/dieta.dart';
import '../models/lugar.dart';
import '../models/racion.dart';
import '../models/receta.dart';
import '../data/rellenos.dart';
import '../models/alergeno.dart';
import '../models/medio.dart';
import '../models/sabor.dart';
import '../services/medios_service.dart';
import '../models/mesa.dart';

/// La cata que se está escribiendo.
///
/// Vive en su propio notifier y no en el `State` de la pantalla porque el
/// formulario son cuatro pantallas distintas: si el borrador viviera en una
/// de ellas, ir y volver entre pasos perdería lo escrito.
class Borrador {
  const Borrador({
    this.sitio = '',
    this.ciudad = '',
    this.pais = Paises.porDefecto,
    this.sabores = const <Sabor>[],
    this.surtido = false,
    this.corte = const Corte.media(),
    this.precio = '',
    this.mesaId = Mesa.libretaId,
    this.nota = '',
    this.acompanantes = const <String>[],
    this.medios = const <Medio>[],
    this.aptas = const <Dieta>{},
    this.editando,
    this.mediosOriginales = const <String>{},
    this.lugar,
    this.receta = const Receta(),
    this.formato = Formato.sinDecir,
    this.unidades = 0,
    this.unidadesTocadas = false,
  });

  final String sitio;
  final String ciudad;
  final String pais;
  /// Los sabores de esta cata. Uno si es una croqueta suelta.
  final List<Sabor> sabores;

  /// Lo que el usuario ha dicho que está catando. No se deduce del número de
  /// sabores porque hay un momento —surtido elegido, ningún sabor añadido
  /// todavía— en el que hay que saberlo y la lista está vacía.
  final bool surtido;
  final Corte corte;
  final String precio;
  final String mesaId;
  final String nota;
  final List<String> acompanantes;

  /// Fotos y vídeo ya copiados a la carpeta de la app.
  final List<Medio> medios;

  /// Para quién vale. Opcional: la cata se publica igual sin marcar nada.
  final Set<Dieta> aptas;

  /// El id de la cata que se está corrigiendo, o nulo si es una cata nueva.
  /// Es lo único que distingue los dos modos del formulario.
  final String? editando;

  /// Las rutas de los medios que ya venían con la cata.
  ///
  /// Quitar una foto en el formulario NO borra su fichero si estaba aquí: si
  /// el usuario se arrepiente y cierra sin guardar, la cata tiene que seguir
  /// teniendo su foto. Los ficheros que sobran se limpian al guardar, cuando
  /// ya se sabe qué se queda.
  final Set<String> mediosOriginales;

  bool get esEdicion => editando != null;

  /// Dónde está el bar. Opcional: una cata sin punto se publica igual, sólo
  /// que no sale en la Ruta.
  final Lugar? lugar;

  double? get lat => lugar?.lat;
  double? get lon => lugar?.lon;

  /// Cómo está hecha: bechamel, rebozado y freidora.
  final Receta receta;

  /// Tapa, media ración o ración, y cuántas croquetas traía.
  final Formato formato;
  final int unidades;

  /// Si el usuario ha tocado el contador con la mano.
  ///
  /// Sin esto, elegir "Tapa" ponía 2 y cambiar luego a "Ración" lo dejaba en
  /// 2, porque la propuesta sólo entraba si el contador estaba a cero. Cada
  /// formato tiene que proponer lo suyo mientras nadie lo contradiga; en
  /// cuanto lo contradices, manda tu número y ya no se mueve.
  final bool unidadesTocadas;

  /// Para quién vale, según lo que se lleve contestado. Se recalcula a cada
  /// toque para que el formulario lo enseñe en vivo: contestar "bechamel
  /// vegetal" y ver aparecer la pastilla de "vegana" explica la regla mejor
  /// que cualquier texto de ayuda.
  Set<Dieta> get dietasDeducidas => Dieta.deducir(
        receta: receta,
        rellenos: sabores
            .expand((Sabor s) => s.idsParaDietas)
            .toSet()
            .map(Rellenos.de)
            .toList(),
      );

  Set<Alergeno> get alergenosDeducidos => <Alergeno>{
        for (final Sabor s in sabores)
          for (final String id in s.idsParaDietas) ...Rellenos.de(id).alergenos,
        ...receta.alergenos,
      };

  /// El relleno que se dibuja mientras se rellena el formulario.
  String get rellenoVisible =>
      sabores.isEmpty ? 'jamon' : sabores.first.rellenoId;

  /// Media de los veredictos del surtido, de 0 a 10.
  double get mediaSabores {
    if (sabores.isEmpty) return 0;
    double suma = 0;
    for (final Sabor s in sabores) {
      suma += s.veredicto.valor;
    }
    return suma / sabores.length;
  }

  /// El corte que se guarda.
  ///
  /// En una croqueta suelta son los cuatro ejes tal cual. En un surtido, el
  /// usuario sólo puntúa crujiente y cremosidad —que son cosa del cocinero y
  /// valen para toda la bandeja— y los ejes de sabor y relleno los pone la
  /// media de los veredictos. Así no hay que pedir veinte sliders ni inventar
  /// una segunda fórmula para el CataScore.
  Corte get corteFinal {
    if (!surtido || sabores.isEmpty) return corte;
    final int media = mediaSabores.round().clamp(0, 10);
    return corte.copyWith(sabor: media, relleno: media);
  }

  /// Qué hace falta para poder pasar de cada paso. La regla vive aquí y no en
  /// el botón para que los cuatro pasos la consulten igual.
  bool puedeAvanzarDesde(int paso) {
    switch (paso) {
      case 1:
        return sitio.trim().isNotEmpty;
      case 2:
        return sabores.isNotEmpty;
      default:
        return true;
    }
  }

  Borrador copyWith({
    String? sitio,
    String? ciudad,
    String? pais,
    List<Sabor>? sabores,
    bool? surtido,
    Corte? corte,
    String? precio,
    String? mesaId,
    String? nota,
    List<String>? acompanantes,
    List<Medio>? medios,
    Set<Dieta>? aptas,
    String? editando,
    Set<String>? mediosOriginales,
    Lugar? lugar,
    bool quitarLugar = false,
    Receta? receta,
    Formato? formato,
    int? unidades,
    bool? unidadesTocadas,
  }) {
    return Borrador(
      sitio: sitio ?? this.sitio,
      ciudad: ciudad ?? this.ciudad,
      pais: pais ?? this.pais,
      sabores: sabores ?? this.sabores,
      surtido: surtido ?? this.surtido,
      corte: corte ?? this.corte,
      precio: precio ?? this.precio,
      mesaId: mesaId ?? this.mesaId,
      nota: nota ?? this.nota,
      acompanantes: acompanantes ?? this.acompanantes,
      medios: medios ?? this.medios,
      aptas: aptas ?? this.aptas,
      editando: editando ?? this.editando,
      mediosOriginales: mediosOriginales ?? this.mediosOriginales,
      // Un `??` no sabe distinguir "no lo toques" de "bórralo", y aquí hace
      // falta poder borrarlo.
      lugar: quitarLugar ? null : (lugar ?? this.lugar),
      receta: receta ?? this.receta,
      formato: formato ?? this.formato,
      unidades: unidades ?? this.unidades,
      unidadesTocadas: unidadesTocadas ?? this.unidadesTocadas,
    );
  }
}

class BorradorNotifier extends StateNotifier<Borrador> {
  BorradorNotifier() : super(const Borrador());

  void limpiar() => state = const Borrador();

  /// Carga una cata publicada para corregirla.
  ///
  /// El formulario es el mismo de siempre: corregir una cata es rellenar los
  /// cuatro pasos otra vez, sólo que ya vienen escritos. Mantener dos
  /// formularios —uno para crear y otro para editar— es la forma más segura
  /// de que acaben divergiendo.
  void desdeCata(Cata cata) {
    state = Borrador(
      sitio: cata.sitio,
      ciudad: cata.ciudad,
      pais: cata.pais,
      sabores: cata.sabores,
      surtido: cata.esSurtido,
      corte: cata.corte,
      precio: cata.precio == null
          ? ''
          : cata.precio!.toStringAsFixed(2).replaceAll('.', ','),
      mesaId: cata.mesaId,
      nota: cata.nota,
      acompanantes: cata.acompanantes,
      medios: cata.medios,
      aptas: cata.aptas,
      editando: cata.id,
      mediosOriginales: cata.medios.map((Medio m) => m.ruta).toSet(),
      receta: cata.receta ?? const Receta(),
      formato: cata.formato,
      unidades: cata.unidades,
      // Al corregir, el número que hay es el que puso alguien: no se toca.
      unidadesTocadas: true,
      lugar: cata.tieneUbicacion
          ? Lugar(
              nombre: cata.sitio,
              lat: cata.lat!,
              lon: cata.lon!,
              ciudad: cata.ciudad,
              pais: cata.pais,
            )
          : null,
    );
  }

  void sitio(String v) => state = state.copyWith(sitio: v);
  void ciudad(String v) => state = state.copyWith(ciudad: v);
  void pais(String v) => state = state.copyWith(pais: v);
  /// Cambiar de modo vacía los sabores: mezclar lo elegido en un modo con el
  /// otro sólo produce sorpresas.
  void modoSurtido(bool v) =>
      state = state.copyWith(surtido: v, sabores: const <Sabor>[]);

  /// En modo croqueta suelta hay un sabor, con uno o varios ingredientes.
  ///
  /// El primero que se elige manda: es el que da color y el que se dibuja.
  /// Quitar el principal asciende al siguiente, y quitarlos todos deja la
  /// cata sin sabor, que es lo que bloquea el paso.
  void alternarRelleno(String id) {
    final Sabor? actual = state.sabores.isEmpty ? null : state.sabores.first;
    if (actual == null) {
      state = state.copyWith(sabores: <Sabor>[Sabor(rellenoId: id)]);
      return;
    }

    final List<String> ids = <String>[...actual.ids];
    ids.contains(id) ? ids.remove(id) : ids.add(id);

    if (ids.isEmpty) {
      state = actual.tienePropio
          ? state.copyWith(
              sabores: <Sabor>[actual.copyWith(rellenoId: 'otro', otros: const <String>[])],
            )
          : state.copyWith(sabores: const <Sabor>[]);
      return;
    }

    state = state.copyWith(
      sabores: <Sabor>[
        actual.copyWith(rellenoId: ids.first, otros: ids.sublist(1)),
      ],
    );
  }

  /// El ingrediente escrito a mano de una croqueta suelta.
  void rellenoPropio(String texto) {
    final Sabor actual = state.sabores.isEmpty
        ? const Sabor(rellenoId: 'otro')
        : state.sabores.first;
    state = state.copyWith(
      sabores: <Sabor>[actual.copyWith(propio: texto)],
    );
  }

  void anadirSabor(Sabor sabor) =>
      state = state.copyWith(sabores: <Sabor>[...state.sabores, sabor]);

  void quitarSabor(int indice) {
    final List<Sabor> lista = <Sabor>[...state.sabores]..removeAt(indice);
    state = state.copyWith(sabores: lista);
  }

  void veredictoDe(int indice, Veredicto veredicto) {
    final List<Sabor> lista = <Sabor>[...state.sabores];
    lista[indice] = lista[indice].copyWith(veredicto: veredicto);
    state = state.copyWith(sabores: lista);
  }
  /// Pone el punto en el mapa.
  ///
  /// Rellena ciudad y país sólo si están vacíos: lo que escribió el usuario
  /// manda siempre sobre lo que deduzca OpenStreetMap, que a veces llama
  /// "Dos Hermanas" a algo que el usuario llamaría Sevilla.
  void ponerLugar(Lugar lugar) {
    state = state.copyWith(
      lugar: lugar,
      ciudad: state.ciudad.trim().isEmpty && lugar.ciudad.isNotEmpty
          ? lugar.ciudad
          : state.ciudad,
      pais: state.pais == Paises.porDefecto && lugar.tienePais
          ? lugar.pais
          : state.pais,
    );
  }

  void quitarLugar() => state = state.copyWith(quitarLugar: true);

  void bechamel(Bechamel v) => state = state.copyWith(
        receta: state.receta.copyWith(bechamel: v),
      );

  void bebida(BebidaVegetal v) => state = state.copyWith(
        receta: state.receta.copyWith(bebida: v),
      );

  void rebozadoConGluten(bool v) => state = state.copyWith(
        receta: state.receta.copyWith(rebozadoConGluten: v),
      );

  void rebozadoConHuevo(bool v) => state = state.copyWith(
        receta: state.receta.copyWith(rebozadoConHuevo: v),
      );

  void freidora(Freidora v) => state = state.copyWith(
        receta: state.receta.copyWith(freidora: v),
      );

  void alternarAlergeno(Alergeno a) {
    final Set<Alergeno> lista = <Alergeno>{...state.receta.extra};
    lista.contains(a) ? lista.remove(a) : lista.add(a);
    state = state.copyWith(receta: state.receta.copyWith(extra: lista));
  }

  /// Elegir formato propone sus unidades habituales. Si ya has puesto tú un
  /// número, se respeta.
  void formato(Formato f) => state = state.copyWith(
        formato: f,
        unidades: state.unidadesTocadas ? state.unidades : f.unidadesTipicas,
      );

  void unidades(int n) => state = state.copyWith(
        unidades: n.clamp(0, 99),
        unidadesTocadas: true,
      );

  void precio(String v) => state = state.copyWith(precio: v);
  void mesa(String v) => state = state.copyWith(mesaId: v);
  void nota(String v) => state = state.copyWith(nota: v);

  void eje(String eje, int valor) {
    final Corte c = state.corte;
    state = state.copyWith(
      corte: switch (eje) {
        'crujiente' => c.copyWith(crujiente: valor),
        'cremosidad' => c.copyWith(cremosidad: valor),
        'sabor' => c.copyWith(sabor: valor),
        _ => c.copyWith(relleno: valor),
      },
    );
  }

  void anadirMedio(Medio medio) =>
      state = state.copyWith(medios: <Medio>[...state.medios, medio]);

  /// Quita un medio de la cata que se está escribiendo.
  ///
  /// Borra el fichero sólo si se añadió en esta sesión. Si venía con la cata,
  /// el fichero se queda: hasta que no se guarde, la cata publicada sigue
  /// siendo la de antes y tiene que poder enseñar su foto.
  void quitarMedio(Medio medio) {
    if (!state.mediosOriginales.contains(medio.ruta)) {
      unawaited(MediosService.borrar(medio));
    }
    state = state.copyWith(
      medios: state.medios.where((Medio m) => m.ruta != medio.ruta).toList(),
    );
  }

  /// Añade a alguien por su nombre, sin repetir y sin distinguir mayúsculas:
  /// "marta" y "Marta" son la misma persona.
  void anadirAcompanante(String nombre) {
    final String limpio = nombre.trim();
    if (limpio.isEmpty) return;
    final bool yaEsta = state.acompanantes.any(
      (String x) => x.toLowerCase() == limpio.toLowerCase(),
    );
    if (yaEsta) return;
    state = state.copyWith(
      acompanantes: <String>[...state.acompanantes, limpio],
    );
  }

  void quitarAcompanante(String nombre) => state = state.copyWith(
        acompanantes:
            state.acompanantes.where((String x) => x != nombre).toList(),
      );
}

final borradorProvider =
    StateNotifierProvider<BorradorNotifier, Borrador>((ref) => BorradorNotifier());

/// Paso actual del formulario, de 1 a 4.
final pasoProvider = StateProvider<int>((ref) => 1);
