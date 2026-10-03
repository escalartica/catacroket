import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/datos_demo.dart';
import '../data/siembra.dart';
import '../errores.dart';
import '../models/cata.dart';
import '../theme/tokens/app_colors.dart';
import 'cuenta_provider.dart';
import 'mesas_provider.dart';
import 'nube_provider.dart';
import '../services/nube_service.dart';
import 'dart:async';
import '../models/dieta.dart';
import '../models/medio.dart';
import '../models/mesa.dart';
import '../models/persona.dart';
import '../services/medios_service.dart';
import '../utils/texto.dart';
import 'evitar_provider.dart';
import 'mi_dieta_provider.dart';
import 'yo_provider.dart';

/// Almacén de catas.
///
/// En la v1 vive en el móvil: arranca con los datos de demostración y guarda
/// en `SharedPreferences` cada cambio. El contrato de este notifier (añadir,
/// mordisco, borrar) es el mismo que tendrá cuando detrás haya Firestore, así
/// que las pantallas no se tocarán al migrar.
class CatasNotifier extends StateNotifier<List<Cata>> {
  CatasNotifier(this._ref) : super(Siembra.catas()) {
    _cargar();
  }

  final Ref _ref;

  /// Manda la cata a su mesa si esa mesa está compartida.
  ///
  /// Nunca espera a que termine ni deja que un fallo se note: guardar una
  /// cata tiene que funcionar en un bar sin cobertura, y que el servidor no
  /// conteste no puede impedir apuntar una croqueta. La cata ya está en el
  /// móvil; subirla es un extra que llega cuando llega.
  void _subirSiToca(Cata cata) {
    if (cata.mesas.isEmpty) return;
    unawaited(_subirACadaMesa(cata));
  }

  /// Sube la cata a cada una de sus mesas, una detrás de otra.
  ///
  /// Se apunta en la cola ANTES de intentarlo, y se quita al confirmar. Al
  /// revés —apuntando sólo en el `onError`— había dos agujeros: el error de
  /// red tarda doce segundos en llegar, así que apuntar la croqueta en un bar
  /// sin línea y cerrar la app a los tres segundos la dejaba sin subir y sin
  /// rastro; y si la lista de mesas aún no se había leído del disco, la mesa
  /// se saltaba en silencio y tampoco quedaba apuntada. `reintentarPendientes`
  /// ya sabe tirar solo lo que no toca subir.
  ///
  /// En fila y no todas a la vez: las dos colas se leen, se modifican y se
  /// reescriben, así que dos subidas simultáneas se pisaban el apunte y una
  /// de las mesas se quedaba sin recibir la cata.
  Future<void> _subirACadaMesa(Cata cata) async {
    for (final String mesaId in cata.mesas) {
      await _apuntarEnLaCola('$mesaId/${cata.id}');
    }

    List<Medio>? medios;
    for (final String mesaId in cata.mesas) {
      if (!_estaEnLaNube(mesaId)) continue;
      try {
        // Una sola vez para todas las mesas.
        medios ??= await NubeService.prepararFotos(cata);
        await NubeService.subirCata(cata, mesaId, yaPreparados: medios);
        await _apuntarMinis(cata.id, medios);
        await _quitarDeLaCola('$mesaId/${cata.id}');
      } catch (_) {
        // Sigue apuntada para la próxima.
      }
    }
  }

  /// Si esa mesa está subida y su gente puede ver lo que se escriba ahí.
  bool _estaEnLaNube(String mesaId) {
    final Mesa? mesa =
        _ref.read(mesasProvider).where((Mesa m) => m.id == mesaId).firstOrNull;
    return mesa != null && mesa.enLaNube;
  }

  /// Quita del servidor las copias de las mesas de las que se ha sacado.
  ///
  /// Hace falta desde que una cata puede estar en varias: al quitarle una
  /// mesa, la copia que ya está allí no se va sola, y su gente la seguiría
  /// viendo para siempre aunque tú creyeras haberla sacado.
  void _retirarDeLasQueSalen(Cata antes, Cata ahora) {
    for (final String mesaId in antes.mesas) {
      if (ahora.mesas.contains(mesaId)) continue;
      unawaited(_quitarDeLaCola('$mesaId/${antes.id}'));
      if (!_estaEnLaNube(mesaId)) continue;
      unawaited(
        NubeService.borrarCataDe(mesaId, antes.id).catchError(
          (Object _) => _apuntarBorradoPendiente(mesaId, antes.id),
        ),
      );
    }
  }

  /// Guarda las miniaturas que ya se prepararon para viajar.
  ///
  /// No pasa por [actualizar] a propósito: aquello vuelve a llamar a la
  /// subida, y subir para guardar lo subido es una pescadilla que se muerde
  /// la cola. Aquí sólo se apunta el resultado.
  ///
  /// La ruta local se conserva: el móvil que hizo la foto sigue pintando su
  /// fichero, que es instantáneo y no gasta datos.
  Future<void> _apuntarMinis(String id, List<Medio> medios) async {
    final Cata? cata = _buscar(id);
    if (cata == null) return;

    final bool algoNuevo = medios.any((Medio m) => m.viaja) &&
        !_mismasMinis(cata.medios, medios);
    if (!algoNuevo) return;

    state = <Cata>[
      for (final Cata c in state)
        if (c.id == id) c.copyWith(medios: medios) else c,
    ];
    await _guardar();
  }

  static bool _mismasMinis(List<Medio> a, List<Medio> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].viaja != b[i].viaja) return false;
    }
    return true;
  }

  /// Las catas que no han conseguido subir todavía, como «mesaId/cataId».
  ///
  /// Se guardan en el disco porque el motivo más normal para no subir es no
  /// tener cobertura, y de ahí a cerrar la app hay un paso.
  ///
  /// Con la mesa delante desde que una cata puede estar en varias: puede
  /// haber subido a una y haber fallado en otra, y con sólo el identificador
  /// de la cata no había forma de saber cuál faltaba. La `v2` es porque el
  /// formato cambió: lo apuntado con el viejo se descarta solo al no llevar
  /// barra, y como mucho se pierde un reintento.
  static const String _claveCola = 'catacroket.catas.pendientes.v2';

  /// Las escrituras de las dos colas, de una en una.
  ///
  /// Las dos son leer-modificar-escribir sobre la misma clave del disco. Sin
  /// esto, dos escrituras a la vez leen el mismo conjunto y la que termina
  /// última borra el apunte de la otra: esa mesa no recibe la cata nunca.
  Future<void> _turno = Future<void>.value();

  Future<T> _enFila<T>(Future<T> Function() faena) {
    final Future<T> mio = _turno.then((_) => faena());
    _turno = mio.then((_) {}, onError: (Object _) {});
    return mio;
  }

  Future<Set<String>> _cola() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return (prefs.getStringList(_claveCola) ?? const <String>[]).toSet();
    } catch (_) {
      return <String>{};
    }
  }

  Future<void> _apuntarEnLaCola(String id) => _enFila(() async {
    try {
      final Set<String> cola = await _cola()..add(id);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_claveCola, cola.toList());
    } catch (_) {}
  });

  Future<void> _quitarDeLaCola(String id) => _enFila(() async {
    try {
      final Set<String> cola = await _cola();
      if (!cola.remove(id)) return;
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_claveCola, cola.toList());
    } catch (_) {}
  });

  /// Vuelve a intentar las catas que se quedaron sin subir.
  ///
  /// Se llama al entrar con la cuenta y al abrir las mesas. Devuelve cuántas
  /// han subido, que es lo que miran los tests: sin esto, una cata apuntada
  /// sin cobertura no llegaba nunca a su mesa.
  Future<int> reintentarPendientes() async {
    final Set<String> cola = await _cola();
    if (cola.isEmpty) return 0;

    int subidas = 0;
    for (final String apunte in cola) {
      final (String mesaId, String cataId)? partes = _partir(apunte);
      if (partes == null) {
        await _quitarDeLaCola(apunte);
        continue;
      }
      final (String mesaId, String cataId) = partes;

      final Cata? cata = _buscar(cataId);
      // Si ya no existe, o ya no está en esa mesa, o esa mesa no se comparte:
      // no hay nada que subir, y quedarse en la cola sería eterno.
      if (cata == null || !cata.estaEn(mesaId) || !_estaEnLaNube(mesaId)) {
        await _quitarDeLaCola(apunte);
        continue;
      }

      try {
        await _apuntarMinis(cataId, await NubeService.subirCata(cata, mesaId));
        await _quitarDeLaCola(apunte);
        subidas++;
      } catch (_) {
        // Sigue en la cola para la próxima.
      }
    }
    return subidas;
  }

  /// Parte un apunte «mesaId/cataId». Nulo si no tiene esa forma.
  static (String, String)? _partir(String apunte) {
    final int barra = apunte.indexOf('/');
    if (barra <= 0 || barra == apunte.length - 1) return null;
    return (apunte.substring(0, barra), apunte.substring(barra + 1));
  }

  void _borrarDeLaNubeSiToca(Cata cata) {
    try {
      for (final String mesaId in cata.mesas) {
        // Las fotos no hay que borrarlas aparte: viajan dentro de la cata,
        // así que se van con ella.

        // Fuera de la cola de subidas: una cata borrada que se reintenta
        // volvería a subirse sola después de haberla borrado.
        unawaited(_quitarDeLaCola('$mesaId/${cata.id}'));

        if (!_estaEnLaNube(mesaId)) continue;

        // Y si el borrado no llega al servidor, a la cola de borrados. Antes
        // el fallo se tiraba: la cata desaparecía del móvil, el servidor no
        // se enteraba y al volver la cobertura la cata regresaba al feed. Y
        // ya no había manera de quitarla, porque borrarla otra vez buscaba
        // en la lista local, donde ya no estaba.
        unawaited(
          NubeService.borrarCataDe(mesaId, cata.id).catchError(
            (Object _) => _apuntarBorradoPendiente(mesaId, cata.id),
          ),
        );
      }
    } catch (_) {}
  }

  // ── La cola de borrados ───────────────────────────────────────────────
  //
  // Hermana de la de subidas y por el mismo motivo: sin cobertura, lo que no
  // se apunta se pierde. Se guarda «mesaId/cataId» porque para borrar en el
  // servidor hacen falta los dos y la cata ya no está en el móvil para
  // preguntárselo.

  static const String _claveColaBorrados = 'catacroket.catas.borradas.v1';

  Future<Set<String>> _colaBorrados() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return (prefs.getStringList(_claveColaBorrados) ?? const <String>[])
          .toSet();
    } catch (_) {
      return <String>{};
    }
  }

  Future<void> _apuntarBorradoPendiente(String mesaId, String cataId) =>
      _enFila(() async {
    try {
      final Set<String> cola = await _colaBorrados()..add('$mesaId/$cataId');
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_claveColaBorrados, cola.toList());
    } catch (_) {}
  });

  Future<void> _quitarDeLaColaBorrados(String apunte) => _enFila(() async {
    try {
      final Set<String> cola = await _colaBorrados();
      if (!cola.remove(apunte)) return;
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_claveColaBorrados, cola.toList());
    } catch (_) {}
  });

  /// Vuelve a intentar los borrados que se quedaron sin llegar.
  ///
  /// Devuelve cuántos se han completado.
  Future<int> reintentarBorrados() async {
    final Set<String> cola = await _colaBorrados();
    if (cola.isEmpty) return 0;

    int hechos = 0;
    for (final String apunte in cola) {
      final (String mesaId, String cataId)? partes = _partir(apunte);
      if (partes == null) {
        await _quitarDeLaColaBorrados(apunte);
        continue;
      }
      final (String mesaId, String cataId) = partes;

      // La mesa ya no se comparte desde este móvil: no hay a dónde ir, y
      // quedarse en la cola sería eterno.
      if (!_estaEnLaNube(mesaId)) {
        await _quitarDeLaColaBorrados(apunte);
        continue;
      }

      try {
        await NubeService.borrarCataDe(mesaId, cataId);
        await _quitarDeLaColaBorrados(apunte);
        hechos++;
      } catch (_) {
        // Sigue en la cola para la próxima.
      }
    }
    return hechos;
  }

  static const String _clave = 'catacroket.catas.v1';

  /// Donde se aparta un guardado que no se ha podido interpretar.
  ///
  /// Existe porque faltaba, y era el fallo más grave que tenía la app. Al no
  /// poder leer, el estado se quedaba con los datos de demostración; en cuanto
  /// el usuario tocaba cualquier cosa se llamaba a `_guardar()`, y guardar
  /// escribía la demostración encima de la única copia que había de sus catas.
  /// Sin aviso y sin vuelta atrás.
  ///
  /// Y no hace falta un disco roto para llegar ahí: basta con que una versión
  /// futura cambie el tipo de un campo y `Cata.fromJson` reviente. Eso no le
  /// pasa a un usuario con mala suerte, le pasa a todos el mismo día.
  ///
  /// Lo apartado viaja en la copia de seguridad (ver `Copia.claves`). El
  /// fichero es JSON legible a ojo a propósito, así que unas catas que la app
  /// no entiende se pueden rescatar a mano desde ahí.
  static const String _claveIlegible = 'catacroket.catas.ilegible.v1';

  /// Si ya se ha leído el disco.
  ///
  /// Hace falta porque el notifier arranca con la lista vacía y `_cargar` es
  /// asíncrono, así que el PRIMER fotograma de La Vitrina siempre tenía cero
  /// catas: a alguien con cuarenta se le enseñaba «Aquí irán tus croquetas,
  /// dale al botón rojo y apunta la primera», y la pantalla pegaba un salto
  /// al llegar los datos. Con esto se puede esperar en vez de mentir.
  bool get cargado => _cargado;
  bool _cargado = false;

  Future<void> _cargar() async {
    String? crudo;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      crudo = prefs.getString(_clave);
      if (crudo == null || crudo.isEmpty) return;

      final List<dynamic> lista = jsonDecode(crudo) as List<dynamic>;
      final List<Cata> leidas = Cata.sinRepetidas(
        lista.map((dynamic e) =>
            Cata.fromJson(Map<String, dynamic>.from(e as Map<dynamic, dynamic>))),
      );

      if (leidas.isNotEmpty) state = leidas;
    } catch (error, pila) {
      // Un guardado corrupto no puede dejar la app en blanco: se sigue con lo
      // que haya en memoria. Pero tampoco puede desaparecer, así que primero
      // se aparta tal cual, antes de que nadie pueda pisarlo.
      await _apartarIlegible(crudo);
      Errores.registrar(error, pila, origen: 'catas.cargar');
    } finally {
      _cargado = true;
      // Un toque al estado para que quien lo observe se entere de que ya no
      // estamos esperando. La lista es la misma; lo que cambia es que ahora
      // significa lo que dice.
      if (mounted) state = <Cata>[...state];
    }
  }

  /// Guarda tal cual un texto que no se ha podido interpretar.
  ///
  /// Si ya hay uno apartado no se toca: el primero es el del usuario, y
  /// cualquier otro vendría de la app funcionando ya con la demostración.
  Future<void> _apartarIlegible(String? crudo) async {
    if (crudo == null || crudo.isEmpty) return;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_claveIlegible) != null) return;
      await prefs.setString(_claveIlegible, crudo);
    } catch (_) {
      // Si tampoco se puede escribir esto, no hay nada más que hacer aquí, y
      // reventar dejaría la app sin arrancar por algo que ya iba mal.
    }
  }

  /// Guarda y dice si de verdad se ha escrito.
  ///
  /// El booleano no es por gusto: `setString` no lanza cuando no puede
  /// guardar, devuelve false. Ese false se ignoraba, así que una cata podía no
  /// llegar al disco sin excepción, sin aviso y sin nada que apuntar.
  Future<bool> _guardar() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final bool escrito = await prefs.setString(
        _clave,
        jsonEncode(state.map((Cata c) => c.toJson()).toList()),
      );

      if (!escrito) {
        Errores.registrar(
          StateError('el móvil ha rechazado guardar las catas'),
          null,
          origen: 'catas.guardar',
        );
      }
      return escrito;
    } catch (error, pila) {
      // La sesión sigue funcionando, pero esto no es inofensivo: la cata está
      // en memoria y no en el disco, así que la app dice «guardada» y al
      // reiniciar no está. El caso realista no es un disco roto, es un móvil
      // sin espacio. Al menos queda apuntado en la bitácora, que el usuario
      // puede mandar desde Ajustes.
      Errores.registrar(error, pila, origen: 'catas.guardar');
      return false;
    }
  }

  /// Apunta una cata nueva. Devuelve si ha quedado guardada en el disco.
  ///
  /// La pantalla necesita saberlo: hasta ahora daba por hecho que sí, lanzaba
  /// confeti y limpiaba el formulario. Si no se había guardado, el usuario
  /// perdía el trabajo dos veces —la cata y lo que había escrito— y encima con
  /// una celebración por delante.
  /// Le pone tu identificador de cuenta si entraste y aún no lo lleva.
  ///
  /// Sin esto, una cata tuya llega a la mesa de tu gente sin dueño: el móvil
  /// de al lado no tiene forma de saber que la apuntaste tú, y el ranking te
  /// cuenta cero catas.
  Cata _conMiCuenta(Cata cata) {
    if (cata.autorUid != null) return cata;
    final String? miUid = _ref.read(miUidProvider);
    if (miUid == null) return cata;
    return cata.conAutorUid(miUid);
  }

  Future<bool> anadir(Cata entrante) async {
    final Cata cata = _conMiCuenta(entrante);
    state = <Cata>[cata, ...state];
    final bool guardada = await _guardar();
    if (guardada) _subirSiToca(cata);
    return guardada;
  }

  /// Guarda una cata corregida en el sitio que ya ocupaba.
  ///
  /// No la mueve al principio del feed: corregir una falta de ortografía de
  /// hace un mes no es una cata nueva y no debería reordenarle el feed a
  /// nadie. La fecha tampoco se toca; es la de cuando te la comiste.
  /// Devuelve si ha quedado guardada, igual que [anadir].
  Future<bool> actualizar(Cata entrante) async {
    final Cata cata = _conMiCuenta(entrante);
    final Cata? antes = _buscar(cata.id);
    state = <Cata>[
      for (final Cata c in state)
        if (c.id == cata.id) cata else c,
    ];
    final bool guardada = await _guardar();
    if (guardada) {
      _subirSiToca(cata);
      // Y fuera de las que ya no la ven. Sin esto, quitarle una mesa a una
      // cata la quitaba de tu pantalla y la dejaba intacta en la de su
      // gente: tú creías haberla sacado y ellos seguían viéndola.
      if (antes != null) _retirarDeLasQueSalen(antes, cata);
    }

    // Las fotos que se quitaron al editar ya no las referencia nadie. Sólo si
    // el cambio ha llegado al disco: si no, la cata sigue siendo la de antes y
    // borrar sus fotos dejaría una ficha con huecos al reiniciar.
    if (antes != null && guardada) await _limpiarMedios(antes, cata.medios);
    return guardada;
  }

  Cata? _buscar(String id) {
    for (final Cata c in state) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Borra del disco los ficheros de [antes] que no estén en [siguen].
  Future<void> _limpiarMedios(Cata antes, List<Medio> siguen) async {
    final Set<String> vivas = siguen.map((Medio m) => m.ruta).toSet();
    for (final Medio m in antes.medios) {
      if (!vivas.contains(m.ruta)) await MediosService.borrar(m);
    }
  }

  /// Un mordisco es lo único que no devuelve si se guardó, y a propósito: no
  /// hay nada que decirle al usuario ni nada que deshacer. Si no se guarda, el
  /// contador se queda como estaba al reiniciar. Queda apuntado en la bitácora
  /// como todo lo demás.
  Future<void> darMordisco(String id) async {
    state = <Cata>[
      for (final Cata c in state)
        if (c.id == id) c.copyWith(mordiscos: c.mordiscos + 1) else c,
    ];
    await _guardar();
  }

  /// Borra una cata y, con ella, sus fotos y su vídeo.
  ///
  /// Dejar los ficheros en disco llenaría el móvil de medios de catas que ya
  /// no existen y que el usuario no puede ver ni borrar desde ninguna parte.
  /// Sólo se tocan los ficheros si el borrado ha llegado al disco. Si no, la
  /// cata reaparece al reiniciar, y entonces la habríamos dejado sin sus fotos:
  /// una ficha con huecos es peor que un fichero de más.
  Future<bool> borrar(String id) async {
    final Cata? fuera = _buscar(id);
    state = state.where((Cata c) => c.id != id).toList();
    final bool guardado = await _guardar();

    if (fuera != null && guardado) {
      _borrarDeLaNubeSiToca(fuera);
      await _limpiarMedios(fuera, const <Medio>[]);
    }
    return guardado;
  }

  /// Vuelve a los datos de demostración. Está en el perfil, en ajustes.
  /// Deja la app como recién instalada.
  ///
  /// En desarrollo vuelven los datos de ejemplo; en la app publicada la deja
  /// vacía, que es lo que significa "restablecer" para quien la usa. Devolver
  /// dieciocho croquetas ajenas a alguien que acaba de pedir borrar las suyas
  /// sería lo contrario de lo que pidió.
  ///
  /// Se lleva también las fotos y los vídeos. Durante un tiempo no lo hacía, y
  /// era el peor sitio donde faltaba: esto lo pulsa precisamente quien quiere
  /// recuperar espacio, así que la app se quedaba con cientos de megas de
  /// vídeos de catas que ya no existen y que no hay forma de borrar desde
  /// ninguna pantalla.
  Future<bool> restablecer() async {
    final List<Cata> habia = state;
    state = Siembra.catas();
    final bool guardado = await _guardar();

    // Igual que en [borrar]: si no se ha podido guardar, las catas volverán al
    // reiniciar y sus fotos tienen que seguir ahí.
    if (!guardado) return false;

    // Se compara con lo que queda, no se borra a ciegas: los datos de
    // demostración podrían apuntar a alguna de las mismas rutas, y borrar un
    // fichero que sigue en uso dejaría una ficha con un hueco.
    final List<Medio> siguen = <Medio>[
      for (final Cata c in state) ...c.medios,
    ];
    for (final Cata c in habia) {
      await _limpiarMedios(c, siguen);
    }
    return true;
  }
}

final catasProvider = StateNotifierProvider<CatasNotifier, List<Cata>>(
  (ref) => CatasNotifier(ref),
);

/// Si las catas del disco ya están leídas.
///
/// Mientras sea falso, una lista vacía no quiere decir «no tienes catas»:
/// quiere decir «todavía no lo sé». Son dos cosas muy distintas y la
/// pantalla de La Vitrina las enseñaba igual.
final catasCargadasProvider = Provider<bool>((ref) {
  ref.watch(catasProvider);
  return ref.read(catasProvider.notifier).cargado;
});

/// Catas de la más reciente a la más antigua. Es el orden del feed y el de
/// todas las listas de la app; nunca se ordena a mano en una pantalla.
final catasRecientesProvider = Provider<List<Cata>>((ref) {
  final List<Cata> mias = ref.watch(catasProvider);

  // Las de tu gente, si las hay. Mientras el servidor no haya contestado
  // —o no haya sesión, o no haya mesas compartidas— esto es una lista vacía
  // y el feed enseña lo tuyo, igual que antes de que existiera la nube. Que
  // el feed espere a una respuesta de internet para pintar sería romper la
  // app para quien no comparte nada.
  final List<Cata> deOtros = ref.watch(catasDeOtrosProvider).maybeWhen(
        data: (List<Cata> c) => c,
        orElse: () => const <Cata>[],
      );

  return juntarCatas(mias, deOtros);
});

/// Una cata por su identificador, sea tuya o de tu gente.
///
/// Mira la lista junta y no sólo el móvil. Buscando únicamente en lo local,
/// tocar la cata de otro —o una tuya recuperada del servidor tras reinstalar—
/// llevaba a «Esta cata ya no está», que además es mentira: la cata existe y
/// se estaba viendo un dedo más arriba, en la lista.
final cataProvider = Provider.family<Cata?, String>((ref, String id) {
  for (final Cata c in ref.watch(catasRecientesProvider)) {
    if (c.id == id) return c;
  }
  return null;
});

/// Las catas que se ven en esa mesa.
///
/// La libreta es un caso aparte y no un identificador más: ya no es una caja
/// donde se guardan unas catas sí y otras no, es TU diario, y ahí está todo
/// lo que has catado, lo compartas o no. Es el cambio que pedía el usuario y
/// el que hace que apuntar una croqueta deje de obligar a elegir entre
/// guardarla para ti o enseñarla.
final catasDeMesaProvider = Provider.family<List<Cata>, String>((ref, String mesaId) {
  if (mesaId == Mesa.libretaId) {
    // La lista del móvil tal cual, sin filtrar por cuenta. Tu diario es lo
    // que has apuntado en este teléfono: filtrándolo por el uid de la sesión,
    // entrar con otra cuenta —por ejemplo tras perder la contraseña— te lo
    // dejaba vacío, el perfil a cero y el Croquetómetro a cero, con las
    // catas intactas en el disco. Indistinguible de haberlas perdido.
    return ref.watch(catasProvider);
  }
  return ref
      .watch(catasRecientesProvider)
      .where((Cata c) => c.estaEn(mesaId))
      .toList();
});

/// La mejor cata registrada. Es la "croqueta del día" de La Vitrina.
final croquetaDelDiaProvider = Provider<Cata?>((ref) {
  final List<Cata> catas = ref.watch(catasProvider);
  if (catas.isEmpty) return null;
  return catas.reduce(
    (Cata a, Cata b) => b.puntuacion > a.puntuacion ? b : a,
  );
});

/// Gente. Cuando entre Firebase esto lo servirá el perfil de cada usuario.
final personasProvider = Provider<Map<String, Persona>>((ref) {
  final Map<String, Persona> todas = <String, Persona>{
    for (final Persona p in Siembra.personas) p.id: p,
  };

  // Tu nombre y tu foto pisan los de la demo. Así, cambiarlos en el perfil
  // se nota al momento en el feed, en las mesas y en la estampa que se
  // comparte, sin que ninguna de esas pantallas sepa que existe un ajuste.
  final Yo yo = ref.watch(yoProvider);
  final Persona? mia = todas[DatosDemo.yo];
  if (mia != null) {
    todas[DatosDemo.yo] = mia.copiaCon(nombre: yo.nombre, foto: yo.foto);
  }

  // Tu gente de las mesas compartidas, que se conoce por su identificador de
  // cuenta y no por el de la libreta. Sin esto salían todos como «Alguien».
  final String? miUid = ref.watch(miUidProvider);
  if (miUid != null) {
    // Tú, bajo tu identificador de cuenta: tus propias catas compartidas
    // vienen firmadas así y si no, no te reconocerías en tu propia mesa.
    todas[miUid] = Persona(
      id: miUid,
      nombre: yo.nombre,
      color: mia?.color ?? AppColors.sol,
      foto: yo.foto,
    );

    final Map<String, String> nombres =
        ref.watch(nombresDeLaGenteProvider).maybeWhen(
              data: (Map<String, String> n) => n,
              orElse: () => const <String, String>{},
            );
    for (final MapEntry<String, String> e in nombres.entries) {
      todas[e.key] = Persona(
        id: e.key,
        nombre: e.value,
        // Un color estable sacado del identificador: el mismo amigo sale
        // siempre del mismo color, sin guardarlo en ninguna parte.
        color: AppColors.deSemilla(e.key),
      );
    }
  }

  return todas;
});

/// Resuelve una persona sin poder fallar. Una cata de alguien que ya no está
/// en la mesa sigue teniendo que pintarse.
Persona personaDe(WidgetRef ref, String id) =>
    ref.read(personasProvider)[id] ?? Persona.desconocida;

/// Media de una lista de catas. Nulo si no hay ninguna, para que la pantalla
/// pueda decidir si pinta un guion o un número.
double? mediaDe(List<Cata> catas) {
  if (catas.isEmpty) return null;
  double suma = 0;
  for (final Cata c in catas) {
    suma += c.puntuacion;
  }
  return suma / catas.length;
}

/// Filtros del feed de La Vitrina.
enum FiltroVitrina { todo, misMesas, mias }

final filtroVitrinaProvider = StateProvider<FiltroVitrina>((ref) => FiltroVitrina.todo);

/// Desde cuántas catas aparece la caja de buscar en La Vitrina.
///
/// Por debajo se ven todas bajando un poco el dedo, y la caja sería un mueble
/// más en una cabecera que ya lleva la racha, la croqueta del día, la Barra
/// Libre y tres filtros. Cada cosa de una pantalla tiene que ganarse el sitio.
const int catasParaBuscar = 12;

/// La regla vive aquí, al lado del feed, y no en la pantalla: si la caja no se
/// ve, lo que hubiera escrito en ella no puede seguir filtrando por detrás.
final sePuedeBuscarProvider = Provider<bool>(
  (ref) => ref.watch(catasProvider).length >= catasParaBuscar,
);

/// Lo escrito en la caja de buscar de La Vitrina.
///
/// Existe porque sin esto la app no cumplía lo que promete. El argumento es
/// «meses después ves dónde estaba aquella que no se te olvida», y con
/// doscientas catas la única forma de encontrarla era bajar con el dedo.
final busquedaVitrinaProvider = StateProvider<String>((ref) => '');

final feedProvider = Provider<List<Cata>>((ref) {
  final List<Cata> catas = ref.watch(catasRecientesProvider);
  final String? miUid = ref.watch(miUidProvider);

  final List<Cata> delFiltro = switch (ref.watch(filtroVitrinaProvider)) {
    FiltroVitrina.todo => catas,
    FiltroVitrina.misMesas =>
      catas.where((Cata c) => c.mesas.isNotEmpty).toList(),
    FiltroVitrina.mias =>
      catas.where((Cata c) => c.esMia(miUid)).toList(),
  };

  // La búsqueda se aplica después del filtro y no al revés: los dos son del
  // usuario y los ve a la vez, así que tienen que cumplirse los dos.
  final String busca = ref.watch(busquedaVitrinaProvider);
  if (!ref.watch(sePuedeBuscarProvider)) return delFiltro;
  if (Texto.normalizar(busca).isEmpty) return delFiltro;

  return delFiltro
      .where((Cata c) => Texto.contieneEnAlguno(c.paraBuscar, busca))
      .toList();
});

// ── Barra Libre ─────────────────────────────────────────────────────────────

/// Dietas marcadas en el filtro. Vacío quiere decir "enséñamelo todo".
final filtroDietaProvider = StateProvider<Set<Dieta>>((ref) => const <Dieta>{});

/// Las catas de la Barra Libre.
///
/// Sólo entran las que alguien marcó. Una cata sin dietas apuntadas no es
/// "no apta": es que nadie lo miró, y colarla aquí sería decirle a un celíaco
/// algo que no sabemos.
final catasLibresProvider = Provider<List<Cata>>((ref) {
  final Set<Dieta> filtro = ref.watch(filtroDietaProvider);
  final Set<String> fuera = ref.watch(evitarProvider);

  return ref
      .watch(catasRecientesProvider)
      .where((Cata c) =>
          c.tieneDietas &&
          c.valePara(filtro) &&
          Evitar.coincidencias(fuera, c.loQueLleva).isEmpty)
      .toList();
});

/// Cuántas catas hay de cada dieta, para los contadores del filtro.
final recuentoDietasProvider = Provider<Map<Dieta, int>>((ref) {
  final Map<Dieta, int> cuenta = <Dieta, int>{
    for (final Dieta d in Dieta.values) d: 0,
  };
  // Por las dietas DEDUCIDAS de la receta, y sobre la lista junta.
  //
  // Contaba las marcadas a mano, que están vacías en todo lo que se apunta
  // hoy, así que las seis pastillas decían «0» aunque debajo hubiera catas
  // listadas. Y miraba sólo tus catas, no las de tu mesa, que es la mitad de
  // lo que hay en esta pantalla.
  for (final Cata c in ref.watch(catasRecientesProvider)) {
    for (final Dieta d in c.aptasCalculadas) {
      cuenta[d] = (cuenta[d] ?? 0) + 1;
    }
  }
  return cuenta;
});

/// Cuántas catas llevan al menos una dieta marcada.
///
/// Ojo con lo que significa: son las catas a las que alguien apuntó la
/// receta, no las que le valen a nadie en concreto. Una puede ser sin gluten
/// y llevar jamón.
final totalLibresProvider = Provider<int>((ref) => ref
    .watch(catasRecientesProvider)
    .where((Cata c) => c.tieneDietas)
    .length);

/// Cuántas catas le valen a quien usa la app, según la dieta de su perfil.
///
/// Sin dieta marcada devuelve nulo, no cero: "no lo he mirado" y "ninguna te
/// vale" son respuestas distintas y la de arriba no se puede dar sin saber
/// para quién. La pantalla decide qué frase enseña con eso.
final totalParaMiProvider = Provider<int?>((ref) {
  final Set<Dieta> mia = ref.watch(miDietaProvider);
  if (mia.isEmpty) return null;
  return ref
      .watch(catasRecientesProvider)
      .where((Cata c) => c.tieneDietas && c.valePara(mia))
      .length;
});
