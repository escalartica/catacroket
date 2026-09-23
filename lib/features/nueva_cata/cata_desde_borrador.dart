import 'package:uuid/uuid.dart';

import '../../core/data/datos_demo.dart';
import '../../core/models/cata.dart';
import '../../core/models/sabor.dart';
import '../../core/providers/borrador_provider.dart';

/// Convierte lo que se ha ido rellenando en el formulario en una cata.
///
/// Estaba dentro de un método privado de la pantalla, y ahí no se podía
/// probar: son las reglas de qué pasa cuando el formulario se deja a medias
/// y qué se conserva al corregir, que es justo lo que hay que fijar.
///
/// [original] es la cata que se está corrigiendo, o nulo si es nueva.
///
/// [nuevoId] y [ahora] se pueden pasar para que un test sea determinista; en
/// la app llevan sus valores de siempre.
Cata cataDesdeBorrador(
  Borrador b, {
  Cata? original,
  String Function()? nuevoId,
  DateTime Function()? ahora,
}) {
  // Un formulario a medias no puede dejar una cata sin nombre: la lista la
  // enseñaría en blanco y no habría manera de reconocerla.
  final String sitio =
      b.sitio.trim().isEmpty ? 'Sitio sin nombre' : b.sitio.trim();

  // La ciudad, en cambio, se queda vacía si no se dice. Antes se rellenaba
  // con el literal 'Sin ciudad' y eso hacía tres destrozos a la vez:
  //
  // - `Cata.lugar` ya sabe qué hacer con una ciudad vacía —enseña el país—,
  //   pero esa rama no se ejecutaba nunca, así que la ficha decía
  //   "SIN CIUDAD 🇪🇸 · Bar Manoli", como si hubiera un pueblo llamado así.
  // - 'Sin ciudad' no está vacío, así que contaba como ciudad: con tres
  //   catas sin rellenar, el Croquetómetro decía "1 ciudad".
  // - Y por lo mismo, acercaba la medalla de las diez ciudades.
  final String ciudad = b.ciudad.trim();
  final List<Sabor> sabores =
      b.sabores.isEmpty ? const <Sabor>[Sabor(rellenoId: 'otro')] : b.sabores;

  // En español se escribe 2,20 y no 2.20.
  final double? precio = double.tryParse(b.precio.replaceAll(',', '.'));

  return Cata(
    // Al corregir se conserva lo que el formulario no pregunta: quién la
    // cató, cuándo y los mordiscos que le dieron.
    id: original?.id ?? (nuevoId ?? const Uuid().v4)(),
    sitio: sitio,
    ciudad: ciudad,
    pais: b.pais,
    sabores: sabores,
    corte: b.corteFinal,
    autorId: original?.autorId ?? DatosDemo.yo,
    mesaId: b.mesaId,
    fecha: original?.fecha ?? (ahora ?? DateTime.now)(),
    precio: precio,
    nota: b.nota.trim(),
    mordiscos: original?.mordiscos ?? 0,
    acompanantes: b.acompanantes,
    // El punto del formulario manda. Si no se ha tocado al corregir, el
    // borrador ya trae el que tenía la cata.
    lat: b.lat ?? original?.lat,
    lon: b.lon ?? original?.lon,
    medios: b.medios,
    aptas: b.aptas,
    // Sin contestar nada no se guarda receta: una receta vacía diría
    // "bechamel desconocida, rebozado con gluten" como si fuera un dato, y
    // no lo es.
    receta: b.receta.sinRellenar ? null : b.receta,
    formato: b.formato,
    unidades: b.unidades,
    tiro: b.tiro,
  );
}
