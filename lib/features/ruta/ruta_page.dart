import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// latlong2 exporta su propia clase `Path`, que taparía la de dart:ui y
// rompería el pico del globo. Aquí sólo hace falta LatLng.
import 'package:latlong2/latlong.dart' show LatLng;

import '../../core/models/cata.dart';
import '../../core/models/lugar.dart';
import '../../core/models/persona.dart';
import '../../core/providers/catas_provider.dart';
import '../../core/services/ubicacion_service.dart';
import '../../core/theme/components/boton.dart';
import '../../core/theme/components/cabecera.dart';
import '../../core/theme/components/campo.dart';
import '../../core/theme/components/mapa_mini.dart';
import '../../core/theme/components/pegatina.dart';
import '../../core/theme/tokens/app_colors.dart';
import '../../core/theme/tokens/app_shape.dart';
import '../../core/theme/tokens/app_spacing.dart';
import '../../core/theme/tokens/app_typography.dart';
import '../../core/utils/formato.dart';
import '../vitrina/widgets/tarjeta_cata.dart';
import '../../core/providers/visto_provider.dart';
import '../../core/theme/components/pista.dart';
import 'agrupacion.dart';
import 'ruta_providers.dart';

/// RUTA CROQUETERA — el mapa.
///
/// Usa OpenStreetMap a través de flutter_map: no hace falta clave de API ni
/// facturación, así que la app funciona desde el primer `flutter run`.
///
/// Sólo salen aquí las catas que tienen punto. Las que no lo tienen se
/// cuentan abajo en vez de esconderse: si tienes tres catas sin sitio, lo
/// mejor que puede hacer esta pantalla es decírtelo.
class RutaPage extends ConsumerStatefulWidget {
  const RutaPage({super.key, this.cataInicial});

  /// La cata que hay que enseñar al abrir, si se llega desde su ficha.
  final String? cataInicial;

  @override
  ConsumerState<RutaPage> createState() => _RutaPageState();
}

class _RutaPageState extends ConsumerState<RutaPage> {
  final MapController _mapa = MapController();
  Timer? _vigilante;
  final ScrollController _lista = ScrollController();
  String? _seleccionada;
  bool _plegada = false;

  /// El zoom al que está el mapa ahora mismo.
  ///
  /// Hace falta para agrupar: dos bares de la misma calle se pisan vistos
  /// desde la ciudad y se separan al acercarse, así que la agrupación tiene
  /// que rehacerse cada vez que el mapa se mueve.
  double _zoom = 13;
  bool _buscandoGps = false;
  LatLng? _yo;

  /// Por qué no cargan las teselas, si es que no cargan.
  ///
  /// Un mapa en blanco no se distingue de un mapa sobre el mar: el usuario no
  /// sabe si es la app, su cobertura o que ahí no hay nada. Se guarda el
  /// primer motivo y se enseña.
  String? _falloTeselas;

  /// Cuántas teselas ha llegado a pedir la capa y cuántas han fallado.
  ///
  /// Los dos fallos posibles se ven igual de grises y se arreglan de formas
  /// opuestas: si se piden y no llegan, es red, servidor o User-Agent; si no
  /// se pide ninguna, la capa no está puesta o la cámara está en un sitio
  /// imposible. Sin este contador no hay manera de saber cuál de los dos es.
  int _pedidas = 0;
  int _fallidas = 0;

  void _teselaPedida() {
    _pedidas++;
    _vigilante?.cancel();
  }

  void _teselaFallida(Object error) {
    _fallidas++;
    if (!mounted || _falloTeselas != null) return;
    // Un solo aviso: si falla el mapa fallan cien teselas a la vez.
    setState(() => _falloTeselas = error.toString());
  }

  /// El estado del mapa, en crudo. Sólo en depuración: esto no se publica.
  void _diagnostico() {
    final MapCamera c = _mapa.camera;
    showDialog<void>(
      context: context,
      builder: (BuildContext d) => AlertDialog(
        backgroundColor: AppColors.superficie,
        title: const Text('Estado del mapa'),
        content: SelectableText(
          <String>[
            'zoom: ${c.zoom.toStringAsFixed(2)}',
            'centro: ${c.center.latitude.toStringAsFixed(3)}, '
                '${c.center.longitude.toStringAsFixed(3)}',
            'tamaño: ${c.size.width.toInt()}x${c.size.height.toInt()}',
            'teselas pedidas: $_pedidas',
            'teselas fallidas: $_fallidas',
            'catas con sitio: ${ref.read(catasProvider).where((Cata x) => x.tieneUbicacion).length}',
            'url: ${Mapas.teselas}',
            if (_falloTeselas != null) 'error: $_falloTeselas',
          ].join('\n'),
          style: AppTypography.cuerpoS.copyWith(fontSize: 12),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(d).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Si a los seis segundos la capa no ha pedido ni una tesela, el problema
    // no es que no lleguen: es que no se piden. Son dos averías distintas y
    // se ven exactamente igual de grises, así que el aviso lo dice.
    _vigilante = Timer(const Duration(seconds: 6), () {
      if (!mounted || _pedidas > 0 || _falloTeselas != null) return;
      setState(() {
        _falloTeselas = 'La capa del mapa no ha pedido ninguna tesela.';
      });
    });
  }

  @override
  void dispose() {
    _vigilante?.cancel();
    _lista.dispose();
    _mapa.dispose();
    super.dispose();
  }

  double get _alturaHoja => MediaQuery.sizeOf(context).height * 0.42;

  /// Hueco que se le deja al encuadre para que ningún globo caiga debajo de
  /// la interfaz.
  ///
  /// Arriba, las pastillas de filtro. Abajo, la hoja de resultados entera:
  /// sin ese hueco el mapa centraría los globos justo donde la hoja los tapa.
  ///
  /// NO SUBIR ESTOS VALORES. Se intentó dos veces y las dos salió peor:
  ///
  /// - Arriba a 114, para despegar los globos de las pastillas.
  /// - Abajo +62, para que el marcador más al sur no lo cortara la hoja.
  ///
  /// Las dos veces pasó lo mismo. Este mapa tiene un viewport diminuto —la
  /// hoja se come el 42 % y la cabecera otro tanto—, así que cada píxel de
  /// margen sale caro en zoom, y al alejarse los doce bares del centro caen
  /// dentro de un solo marcador y el mapa se queda en un punto naranja.
  ///
  /// Lo que separa los globos es agruparlos (agrupacion.dart), no alejarse.
  /// Un marcador rozando el borde de la hoja cuesta mucho menos que perder
  /// el mapa entero.
  EdgeInsets get _margenEncuadre =>
      EdgeInsets.fromLTRB(56, 76, 56, _alturaHoja + 32);

  /// El encuadre inicial, para que lo aplique flutter_map cuando toca.
  ///
  /// Esto no se hace desde `onMapReady`. Parece el sitio natural y no lo es:
  /// `onMapReady` salta en un post-frame de `initState`, antes de que el mapa
  /// se haya medido, y encuadrar contra un tamaño cero deja una cámara
  /// degenerada. `initialCameraFit` existe justo para esto.
  CameraFit? _encuadreInicial(List<Cata> catas) {
    // Con menos de dos puntos no hay nada que encuadrar, y un `bounds` de un
    // solo punto pide un zoom infinito.
    if (catas.length < 2) return null;
    return CameraFit.bounds(
      bounds: LatLngBounds.fromPoints(
        catas.map((Cata c) => LatLng(c.lat!, c.lon!)).toList(),
      ),
      padding: _margenEncuadre,
    );
  }

  /// Reencuadra a mano. Vale cuando el mapa ya está en pantalla y medido:
  /// al cambiar de filtro, por ejemplo.
  void _encuadrar(List<Cata> catas) {
    if (!mounted || catas.isEmpty) return;

    if (catas.length == 1) {
      _mapa.move(LatLng(catas.first.lat!, catas.first.lon!), 15);
      return;
    }

    _mapa.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(
          catas.map((Cata c) => LatLng(c.lat!, c.lon!)).toList(),
        ),
        padding: _margenEncuadre,
      ),
    );
  }

  /// La cata con la que se llega desde una ficha, si sigue estando.
  Cata? _inicial(List<Cata> visibles) {
    final String? id = widget.cataInicial;
    if (id == null) return null;
    for (final Cata c in visibles) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Al abrir sólo se marca el globo y se coloca la lista. La cámara ya la
  /// ha puesto `initialCenter` o `initialCameraFit`: moverla aquí es lo que
  /// dejaba el mapa en blanco.
  void _alAbrir(List<Cata> ordenadas) {
    final Cata? cata = _inicial(ordenadas);
    if (cata == null) return;
    setState(() => _seleccionada = cata.id);
    final int indice = ordenadas.indexWhere((Cata c) => c.id == cata.id);
    if (indice >= 0 && _lista.hasClients) {
      _lista.jumpTo((indice * 116).toDouble());
    }
  }

  void _seleccionar(Cata cata, List<Cata> ordenadas) {
    HapticFeedback.selectionClick();
    setState(() {
      _seleccionada = cata.id;
      _plegada = false;
    });

    if (cata.tieneUbicacion) {
      _mapa.move(LatLng(cata.lat!, cata.lon!), 15);
    }

    final int indice = ordenadas.indexWhere((Cata c) => c.id == cata.id);
    if (indice >= 0 && _lista.hasClients) {
      _lista.animateTo(
        (indice * 116).toDouble(),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    }
  }

  /// El centro de un grupo de catas. Nulo si el grupo está vacío.
  LatLng? _centroDe(List<Cata> grupo) {
    if (grupo.isEmpty) return null;
    final double lat =
        grupo.map((Cata c) => c.lat!).reduce((double a, double b) => a + b) /
            grupo.length;
    final double lon =
        grupo.map((Cata c) => c.lon!).reduce((double a, double b) => a + b) /
            grupo.length;
    return LatLng(lat, lon);
  }

  /// Acerca el mapa hasta que las catas de un grupo dejen de pisarse.
  ///
  /// No abre una lista ni una hoja: acercarse es lo que el usuario ya iba a
  /// hacer, y así el mapa sigue siendo el mapa.
  ///
  /// Encuadra en vez de mover la cámara a pelo: un `move` centra en el
  /// viewport entero, y el centro del viewport está medio tapado por las
  /// pastillas de filtro y por la hoja de resultados, así que los globos
  /// aterrizaban debajo. `_encuadrar` ya sabe descontar ese hueco.
  void _abrirGrupo(Grupo grupo) {
    HapticFeedback.selectionClick();
    setState(() => _seleccionada = null);
    _encuadrar(grupo.catas);
  }

  void _cambiarFiltro(FiltroRuta filtro, List<Cata> conSitio) {
    HapticFeedback.selectionClick();
    ref.read(filtroRutaProvider.notifier).state = filtro;
    setState(() => _seleccionada = null);
    // Un frame de margen para que la lista ya filtrada esté construida.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _encuadrar(grupoMayoritario(filtrarRuta(conSitio, filtro)));
    });
  }

  /// Centra el mapa donde estás. No guarda nada ni lo sube a ningún sitio:
  /// es para orientarte, y por eso el punto azul se va al salir de aquí.
  Future<void> _centrarEnMi() async {
    if (_buscandoGps) return;
    setState(() => _buscandoGps = true);

    final ResultadoUbicacion resultado = await UbicacionService.dondeEstoy();
    if (!mounted) return;
    setState(() => _buscandoGps = false);

    switch (resultado) {
      case UbicacionLista(:final Lugar lugar):
        setState(() => _yo = LatLng(lugar.lat, lugar.lon));
        _mapa.move(LatLng(lugar.lat, lugar.lon), 15);
      case UbicacionApagada():
        _decir('Tienes la ubicación apagada en el móvil.');
      case UbicacionSinPermiso():
        _decir('Sin permiso de ubicación no puedo centrarte en el mapa.');
      case UbicacionFallida(:final String mensaje):
        _decir(mensaje);
    }
  }

  void _decir(String texto) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    // Todo lo derivado vive en providers (ruta_providers.dart) y no aquí:
    // esta pantalla tiene estado local —globo elegido, hoja plegada, GPS— y
    // cada setState volvía a filtrar y a ordenar la lista entera.
    final List<Cata> conSitio = ref.watch(catasConSitioProvider);
    final int sinSitio = ref.watch(catasSinSitioProvider);
    final FiltroRuta filtro = ref.watch(filtroRutaProvider);
    final List<Cata> visibles = ref.watch(catasVisiblesProvider);
    final List<Cata> porNota = ref.watch(catasRutaOrdenadasProvider);
    final ResumenRuta resumen = ref.watch(resumenRutaProvider);

    final Map<String, Persona> personas = ref.watch(personasProvider);
    final Cata? inicial = _inicial(visibles);

    // Con qué abre el mapa si no se llega desde una ficha: el sitio donde más
    // has catado, no todas las catas del mundo.
    final List<Cata> grupo = ref.watch(grupoInicialRutaProvider);

    return Column(
      children: <Widget>[
        Cabecera(
          titulo: 'Ruta croquetera',
          // Sólo en depuración: en una compilación de release no existe.
          accion: kDebugMode
              ? BotonRedondo(
                  icono: Icons.bug_report_rounded,
                  etiqueta: 'Estado del mapa',
                  onTap: _diagnostico,
                )
              : null,
          // La flecha sólo cuando se llega desde una ficha: si no, esto es una
          // pestaña y de una pestaña no se "vuelve".
          volver: widget.cataInicial == null ? null : () => context.pop(),
          subtitulo: conSitio.isEmpty
              ? 'Aún no has apuntado dónde catabas'
              : '${Formato.plural(conSitio.length, 'cata', 'catas')} · '
                  '${Formato.plural(resumen.ciudades, 'ciudad', 'ciudades')} · '
                  '${Formato.plural(resumen.paises, 'país', 'países')}',
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pantalla,
            0,
            AppSpacing.pantalla,
            0,
          ),
          child: const Pista(
            que: Visto.pistaRuta,
            emoji: '📍',
            texto: 'El mapa de los bares donde has catado. Cada globo es uno, '
                'y el número es la nota que le pusiste. Tócalo para abrir la '
                'cata.',
          ),
        ),
        Expanded(
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: _CapaMapa(
                  controlador: _mapa,
                  inicial: inicial,
                  visibles: visibles,
                  yo: _yo,
                  seleccionada: _seleccionada,
                  encuadreInicial: _encuadreInicial(grupo),
                  centroDelGrupo: _centroDe(grupo),
                  zoom: _zoom,
                  onListo: () => _alAbrir(porNota),
                  onZoom: (double z) {
                    if ((z - _zoom).abs() > 0.05) setState(() => _zoom = z);
                  },
                  onGlobo: (Cata c) => _seleccionar(c, porNota),
                  onGrupo: _abrirGrupo,
                  onTeselaPedida: _teselaPedida,
                  onTeselaFallida: _teselaFallida,
                ),
              ),
              // Sin una sola cata con sitio, ningún filtro va a enseñar
              // nada nunca: son tres pastillas para filtrar el vacío.
              if (conSitio.isNotEmpty)
                _Filtros(
                  activo: filtro,
                  onElegir: (FiltroRuta f) => _cambiarFiltro(f, conSitio),
                ),
              if (_falloTeselas != null)
                _AvisoMapaCaido(motivo: _falloTeselas!, pedidas: _pedidas),
              _BotonCentrarme(
                abajo: (_plegada ? 96 : _alturaHoja) + AppSpacing.m,
                buscando: _buscandoGps,
                onTap: _centrarEnMi,
              ),
              _HojaResultados(
                sinNingunSitio: conSitio.isEmpty,
                plegada: _plegada,
                altura: _alturaHoja,
                catas: porNota,
                personas: personas,
                filtro: filtro,
                sinSitio: sinSitio,
                controlador: _lista,
                onTirador: () => setState(() => _plegada = !_plegada),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// El mapa y lo que se pinta encima: tu punto y un globo por cata.
class _CapaMapa extends StatelessWidget {
  const _CapaMapa({
    required this.controlador,
    required this.inicial,
    required this.visibles,
    required this.yo,
    required this.seleccionada,
    required this.encuadreInicial,
    required this.centroDelGrupo,
    required this.zoom,
    required this.onListo,
    required this.onZoom,
    required this.onGlobo,
    required this.onGrupo,
    required this.onTeselaPedida,
    required this.onTeselaFallida,
  });

  /// Dónde se abre si no se llega desde ninguna ficha.
  static const LatLng _sevilla = LatLng(37.3886, -5.9885);

  final MapController controlador;
  final Cata? inicial;
  final List<Cata> visibles;
  final LatLng? yo;
  final String? seleccionada;
  /// Encuadre del grupo de apertura. Nulo cuando es una sola cata.
  final CameraFit? encuadreInicial;

  /// El centro del sitio donde más has catado. Nulo si no hay ninguna.
  final LatLng? centroDelGrupo;

  /// El zoom actual. Decide qué catas se pisan y por tanto se agrupan.
  final double zoom;

  final VoidCallback onListo;
  final ValueChanged<double> onZoom;
  final ValueChanged<Cata> onGlobo;
  final ValueChanged<Grupo> onGrupo;
  final VoidCallback onTeselaPedida;
  final ValueChanged<Object> onTeselaFallida;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: controlador,
      options: MapOptions(
        // Si se llega desde una ficha, el mapa abre en ese bar. Si no,
        // encuadra el sitio donde más has catado. Sevilla cuando no hay nada.
        //
        // El encuadre no sobra, aunque lo parezca: el centro del mapa cae
        // detrás de la hoja de resultados, y su margen inferior es lo único
        // que sube los globos hasta la franja que se ve.
        initialCenter: inicial != null
            ? LatLng(inicial!.lat!, inicial!.lon!)
            : (centroDelGrupo ?? _sevilla),
        initialZoom: inicial != null ? 15 : 13,
        initialCameraFit: inicial == null ? encuadreInicial : null,
        minZoom: 2,
        maxZoom: 18,
        // El gris de fábrica de flutter_map parecía una pantalla rota. Con el
        // crema de la app, un mapa que tarda se ve como un mapa que tarda.
        backgroundColor: AppColors.fondo,
        onMapReady: onListo,
        onPositionChanged: (MapCamera camara, bool _) => onZoom(camara.zoom),
      ),
      children: <Widget>[
        teselasOsm(onFallo: onTeselaFallida, onPedida: onTeselaPedida),
        if (yo != null)
          MarkerLayer(
            markers: <Marker>[
              Marker(
                point: yo!,
                width: 26,
                height: 26,
                child: const _PuntoYo(),
              ),
            ],
          ),
        MarkerLayer(
          markers: <Marker>[
            // Un marcador por grupo y no por cata: diez bares del mismo
            // barrio dejaban los números en muñones ("8,", "9,", "0") justo
            // debajo del cartel que promete "el número es la nota".
            for (final Grupo g in agruparCatas(visibles, zoom))
              Marker(
                point: LatLng(g.lat, g.lon),
                width: 78,
                height: 62,
                alignment: Alignment.topCenter,
                child: g.esUna
                    ? _Globo(
                        cata: g.unica,
                        activo: seleccionada == g.unica.id,
                        apagado: seleccionada != null &&
                            seleccionada != g.unica.id,
                        onTap: () => onGlobo(g.unica),
                      )
                    : _Racimo(
                        grupo: g,
                        apagado: seleccionada != null,
                        onTap: () => onGrupo(g),
                      ),
              ),
          ],
        ),
        const AtribucionOsm(),
      ],
    );
  }
}

/// Las pastillas de filtro, flotando sobre la franja de arriba del mapa.
class _Filtros extends StatelessWidget {
  const _Filtros({required this.activo, required this.onElegir});

  final FiltroRuta activo;
  final ValueChanged<FiltroRuta> onElegir;

  /// Texto, emoji y color de cada filtro.
  static const Map<FiltroRuta, (String, String, Color)> _opciones =
      <FiltroRuta, (String, String, Color)>{
    FiltroRuta.todas: ('Todas', '🗺️', AppColors.sol),
    FiltroRuta.mias: ('Mías', '✍️', AppColors.chicle),
    FiltroRuta.libres: ('Barra Libre', '🌱', AppColors.menta),
  };

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: AppSpacing.s,
      left: 0,
      right: 0,
      // Un `Wrap` y no un carrusel: tres pastillas caben en el móvil más
      // estrecho, un scroll horizontal aquí le robaría al mapa los arrastres
      // de la franja de arriba, y si algún día no cupieran, pasan a una
      // segunda línea en vez de desbordar.
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pantalla),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.s,
          runSpacing: AppSpacing.s,
          children: <Widget>[
            for (final MapEntry<FiltroRuta, (String, String, Color)> e
                in _opciones.entries)
              OpcionPildora(
                texto: e.value.$1,
                emoji: e.value.$2,
                activa: activo == e.key,
                colorActiva: e.value.$3,
                onTap: () => onElegir(e.key),
              ),
          ],
        ),
      ),
    );
  }
}

/// Lo que se dice cuando las teselas no llegan.
///
/// Un mapa en blanco no se distingue de un mapa sobre el mar. Esto separa los
/// dos fallos posibles: si se pidieron teselas y no llegaron, es la conexión;
/// si no se pidió ninguna, el problema está antes.
class _AvisoMapaCaido extends StatelessWidget {
  const _AvisoMapaCaido({required this.motivo, required this.pedidas});

  final String motivo;
  final int pedidas;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 64,
      left: AppSpacing.pantalla,
      right: AppSpacing.pantalla,
      child: Pegatina(
        color: AppColors.sol,
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'El mapa no carga',
              style: AppTypography.tituloS.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              pedidas == 0
                  ? 'Los globos están donde tienen que estar, pero el dibujo '
                      'del mapa ni siquiera se ha llegado a pedir.'
                  : 'Los globos con las notas siguen estando donde tienen que '
                      'estar; lo que no llega es el dibujo del mapa. Suele ser '
                      'la conexión.',
              style: AppTypography.cuerpoS.copyWith(
                fontSize: 12.5,
                height: 1.3,
                color: AppColors.tinta,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              motivo,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.etiqueta.copyWith(
                fontSize: 10.5,
                color: AppColors.tinta,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// El botón de centrarse. Sube y baja con la hoja para no quedar debajo.
class _BotonCentrarme extends StatelessWidget {
  const _BotonCentrarme({
    required this.abajo,
    required this.buscando,
    required this.onTap,
  });

  final double abajo;
  final bool buscando;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      right: AppSpacing.pantalla,
      bottom: abajo,
      child: BotonRedondo(
        icono: buscando
            ? Icons.hourglass_top_rounded
            : Icons.my_location_rounded,
        etiqueta: 'Centrar donde estoy',
        onTap: onTap,
      ),
    );
  }
}

/// La hoja de abajo: las catas visibles ordenadas por nota.
class _HojaResultados extends StatelessWidget {
  const _HojaResultados({
    required this.sinNingunSitio,
    required this.plegada,
    required this.altura,
    required this.catas,
    required this.personas,
    required this.filtro,
    required this.sinSitio,
    required this.controlador,
    required this.onTirador,
  });

  /// Si no hay ni una cata con punto en el mapa. Es el primer día.
  final bool sinNingunSitio;

  final bool plegada;
  final double altura;
  final List<Cata> catas;
  final Map<String, Persona> personas;
  final FiltroRuta filtro;
  final int sinSitio;
  final ScrollController controlador;
  final VoidCallback onTirador;

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      left: 0,
      right: 0,
      bottom: plegada ? -(MediaQuery.sizeOf(context).height * 0.34) : 0,
      height: altura,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.fondo,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppShape.radioXL),
          ),
          border: Border(
            top: BorderSide(color: AppColors.tinta, width: AppShape.borde),
            left: BorderSide(color: AppColors.tinta, width: AppShape.borde),
            right: BorderSide(color: AppColors.tinta, width: AppShape.borde),
          ),
        ),
        child: Column(
          children: <Widget>[
            _Tirador(plegada: plegada, onTap: onTirador),
            // "Ordenadas por nota" encima de nada no ordena nada.
            if (!sinNingunSitio) ...<Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pantalla,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'ORDENADAS POR NOTA',
                        style: AppTypography.antetitulo.copyWith(
                          color: AppColors.tintaSuave,
                        ),
                      ),
                    ),
                    if (sinSitio > 0)
                      Text(
                        '$sinSitio sin sitio',
                        style: AppTypography.etiqueta.copyWith(
                          fontSize: 11,
                          color: AppColors.tintaSuave,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.m),
            ],
            Expanded(
              child: catas.isEmpty
                  ? _Vacio(filtro: filtro, sinSitio: sinSitio)
                  : ListView.separated(
                      controller: controlador,
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.pantalla,
                        0,
                        AppSpacing.pantalla,
                        AppSpacing.huecoBarra,
                      ),
                      itemCount: catas.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.m),
                      itemBuilder: (BuildContext context, int i) {
                        final Cata c = catas[i];
                        return TarjetaCata(
                          cata: c,
                          autor: personas[c.autorId] ?? Persona.desconocida,
                          onTap: () => context.push('/cata/${c.id}'),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// El asa de la hoja. Se toca en 45 px: antes eran 27 y había que afinar.
class _Tirador extends StatelessWidget {
  const _Tirador({required this.plegada, required this.onTap});

  final bool plegada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: plegada
          ? 'Abrir la lista de catas'
          : 'Plegar la lista de catas',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 19),
          alignment: Alignment.center,
          child: Container(
            width: 56,
            height: 7,
            decoration: BoxDecoration(
              color: AppColors.tinta,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
      ),
    );
  }
}

class _Vacio extends StatelessWidget {
  const _Vacio({required this.filtro, required this.sinSitio});

  final FiltroRuta filtro;
  final int sinSitio;

  @override
  Widget build(BuildContext context) {
    final String texto = switch (filtro) {
      FiltroRuta.mias => 'Ninguna de tus catas tiene sitio todavía.',
      FiltroRuta.libres => 'Ninguna cata apta tiene sitio todavía.',
      FiltroRuta.todas => sinSitio > 0
          ? 'Hay $sinSitio catas sin sitio. Ábrelas, dale a corregir y '
              'ponles el punto: aparecen aquí al momento.'
          : 'Aún no hay catas. La primera que apuntes con sitio sale aquí.',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.l,
      ),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: AppTypography.cuerpo,
      ),
    );
  }
}

/// Dónde estás. Azul y redondo, como en todos los mapas del mundo: aquí no
/// hay que inventar nada, la convención ya está aprendida.
class _PuntoYo extends StatelessWidget {
  const _PuntoYo();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cielo,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.crema, width: 3.5),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.tinta.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

/// El globo de nota sobre el mapa. La nota se lee sin abrir nada: es lo único
/// que hace falta para decidir a qué bar ir.
/// Varias catas que a este zoom caen en el mismo sitio.
///
/// Sólo la cuenta. Llevaba también la mejor nota y ocupaba 104 de ancho, y
/// ese ancho es justo lo que decide cuántos racimos caben: con doce bares
/// repartidos por una ciudad, sólo cabía uno y el mapa se quedaba en un
/// punto. Redondo y estrecho caben varios, que es lo que hace que un mapa
/// parezca un mapa. La nota se ve al acercarse, que es a un toque.
class _Racimo extends StatelessWidget {
  const _Racimo({
    required this.grupo,
    required this.apagado,
    required this.onTap,
  });

  final Grupo grupo;
  final bool apagado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final int cuantas = grupo.catas.length;

    return Semantics(
      button: true,
      label: '$cuantas catas juntas, la mejor '
          '${Formato.nota(grupo.mejorNota)} de 10. Toca para acercarte',
      child: ExcludeSemantics(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              // Mango y redondo: un racimo no es una cata, y se distingue
              // antes por la forma que por el número.
              color: apagado ? AppColors.superficie : AppColors.mango,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.tinta,
                width: AppShape.borde,
              ),
              boxShadow: AppShape.sombra(const Offset(2, 2)),
            ),
            child: Text(
              '$cuantas',
              style: AppTypography.cifraS.copyWith(fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}

class _Globo extends StatelessWidget {
  const _Globo({
    required this.cata,
    required this.activo,
    required this.apagado,
    required this.onTap,
  });

  final Cata cata;
  final bool activo;
  final bool apagado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: activo,
      label: '${cata.sitio}, ${Formato.nota(cata.puntuacion)} de 10',
      child: ExcludeSemantics(
        child: GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: activo ? 1.12 : 1,
        duration: const Duration(milliseconds: 180),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: apagado ? AppColors.superficie : AppColors.sol,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: AppColors.tinta,
                  width: AppShape.borde,
                ),
                boxShadow: AppShape.sombra(const Offset(2, 2)),
              ),
              child: Text(
                Formato.nota(cata.puntuacion),
                style: AppTypography.cifraS.copyWith(fontSize: 15),
              ),
            ),
            CustomPaint(size: const Size(14, 9), painter: const _Pico()),
            if (activo)
              Container(
                margin: const EdgeInsets.only(top: 3),
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.tinta,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  cata.sitio,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.etiqueta.copyWith(
                    fontSize: 10.5,
                    color: AppColors.crema,
                  ),
                ),
              ),
          ],
        ),
      ),
        ),
      ),
    );
  }
}

class _Pico extends CustomPainter {
  const _Pico();

  @override
  void paint(Canvas canvas, Size size) {
    final Path pico = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(pico, Paint()..color = AppColors.tinta);
  }

  @override
  bool shouldRepaint(_Pico viejo) => false;
}
