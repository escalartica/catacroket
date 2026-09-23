import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../../../core/models/lugar.dart';
import '../../../core/providers/borrador_provider.dart';
import '../../../core/services/ubicacion_service.dart';
import '../../../core/theme/components/boton.dart';
import '../../../core/theme/components/mapa_mini.dart';
import '../../../core/theme/components/pegatina.dart';
import '../../../core/theme/tokens/app_colors.dart';
import '../../../core/theme/tokens/app_shape.dart';
import '../../../core/theme/tokens/app_spacing.dart';
import '../../../core/theme/tokens/app_typography.dart';

/// Dónde está el bar.
///
/// Es opcional, pero es lo que decide si la cata existe en la Ruta o no, así
/// que el bloque lo dice en voz alta en vez de esconderlo. Hay tres maneras
/// de poner el punto y cada una resuelve un momento distinto: estás en el bar
/// (GPS), te acuerdas del nombre (buscador) o lo sabes de vista (mapa).
class SelectorUbicacion extends ConsumerStatefulWidget {
  const SelectorUbicacion({super.key});

  @override
  ConsumerState<SelectorUbicacion> createState() => _SelectorUbicacionState();
}

class _SelectorUbicacionState extends ConsumerState<SelectorUbicacion> {
  bool _buscandoGps = false;

  void _decir(String texto, {String? accion, VoidCallback? alTocar}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(texto),
          action: accion == null || alTocar == null
              ? null
              : SnackBarAction(label: accion, onPressed: alTocar),
        ),
      );
  }

  Future<void> _estoyAqui() async {
    if (_buscandoGps) return;
    setState(() => _buscandoGps = true);

    final ResultadoUbicacion resultado = await UbicacionService.dondeEstoy();
    if (!mounted) return;
    setState(() => _buscandoGps = false);

    switch (resultado) {
      case UbicacionLista(:final Lugar lugar):
        ref.read(borradorProvider.notifier).ponerLugar(lugar);
      case UbicacionApagada():
        _decir('Tienes la ubicación apagada en el móvil.');
      case UbicacionSinPermiso(definitivo: true):
        _decir(
          'Catacroket no tiene permiso de ubicación.',
          accion: 'Ajustes',
          alTocar: Geolocator.openAppSettings,
        );
      case UbicacionSinPermiso():
        _decir('Sin permiso no puedo saber dónde estás. Puedes buscarlo.');
      case UbicacionFallida(:final String mensaje):
        _decir(mensaje);
    }
  }

  Future<void> _buscar() async {
    final Borrador b = ref.read(borradorProvider);
    final Lugar? elegido = await showModalBottomSheet<Lugar>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => _HojaBuscar(
        inicial: <String>[b.sitio.trim(), b.ciudad.trim()]
            .where((String s) => s.isNotEmpty)
            .join(', '),
      ),
    );
    if (elegido != null && mounted) {
      ref.read(borradorProvider.notifier).ponerLugar(elegido);
    }
  }

  Future<void> _ajustar(Lugar? actual) async {
    final Lugar? elegido = await Navigator.of(context).push<Lugar>(
      MaterialPageRoute<Lugar>(
        builder: (BuildContext context) => AjustarPuntoPage(inicial: actual),
        fullscreenDialog: true,
      ),
    );
    if (elegido != null && mounted) {
      ref.read(borradorProvider.notifier).ponerLugar(elegido);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Lugar? lugar = ref.watch(borradorProvider).lugar;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text('EN EL MAPA', style: AppTypography.antetitulo),
        const SizedBox(height: 7),
        if (lugar == null) _SinPunto(
          buscandoGps: _buscandoGps,
          onGps: _estoyAqui,
          onBuscar: _buscar,
          onMapa: () => _ajustar(null),
        ) else _ConPunto(
          lugar: lugar,
          buscandoGps: _buscandoGps,
          onGps: _estoyAqui,
          onBuscar: _buscar,
          onAjustar: () => _ajustar(lugar),
          onQuitar: () => ref.read(borradorProvider.notifier).quitarLugar(),
        ),
      ],
    );
  }
}

class _SinPunto extends StatelessWidget {
  const _SinPunto({
    required this.buscandoGps,
    required this.onGps,
    required this.onBuscar,
    required this.onMapa,
  });

  final bool buscandoGps;
  final VoidCallback onGps;
  final VoidCallback onBuscar;
  final VoidCallback onMapa;

  @override
  Widget build(BuildContext context) {
    return Pegatina(
      discontinuo: true,
      color: Colors.transparent,
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Sin punto en el mapa esta cata no sale en la Ruta croquetera.',
            style: AppTypography.cuerpoS.copyWith(fontSize: 12.5, height: 1.3),
          ),
          const SizedBox(height: AppSpacing.m),
          BotonPegatina(
            texto: buscandoGps ? 'Buscando el GPS…' : 'Estoy aquí',
            icono: Icons.my_location_rounded,
            pequeno: true,
            color: AppColors.menta,
            onTap: buscandoGps ? null : onGps,
          ),
          const SizedBox(height: AppSpacing.s),
          Row(
            children: <Widget>[
              Expanded(
                child: BotonPegatina.fantasma(
                  texto: 'Buscar el bar',
                  icono: Icons.search_rounded,
                  pequeno: true,
                  onTap: onBuscar,
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: BotonPegatina.fantasma(
                  texto: 'En el mapa',
                  icono: Icons.map_rounded,
                  pequeno: true,
                  onTap: onMapa,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConPunto extends StatelessWidget {
  const _ConPunto({
    required this.lugar,
    required this.buscandoGps,
    required this.onGps,
    required this.onBuscar,
    required this.onAjustar,
    required this.onQuitar,
  });

  final Lugar lugar;
  final bool buscandoGps;
  final VoidCallback onGps;
  final VoidCallback onBuscar;
  final VoidCallback onAjustar;
  final VoidCallback onQuitar;

  @override
  Widget build(BuildContext context) {
    return Pegatina(
      padding: const EdgeInsets.all(AppSpacing.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(
            button: true,
            label: 'Ajustar el punto en el mapa',
            excludeSemantics: true,
            child: GestureDetector(
              onTap: onAjustar,
              child: MapaMini(lat: lugar.lat, lon: lugar.lon),
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        lugar.nombre,
                        style: AppTypography.tituloS.copyWith(fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        lugar.coordenadas,
                        style: AppTypography.cuerpoS.copyWith(
                          fontSize: 11.5,
                          color: AppColors.tintaSuave,
                        ),
                      ),
                    ],
                  ),
                ),
                BotonRedondo(
                  icono: Icons.close_rounded,
                  etiqueta: 'Quitar el punto',
                  onTap: onQuitar,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Row(
            children: <Widget>[
              Expanded(
                child: BotonPegatina.fantasma(
                  texto: buscandoGps ? 'Buscando…' : 'Estoy aquí',
                  icono: Icons.my_location_rounded,
                  pequeno: true,
                  onTap: buscandoGps ? null : onGps,
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: BotonPegatina.fantasma(
                  texto: 'Cambiar',
                  icono: Icons.search_rounded,
                  pequeno: true,
                  onTap: onBuscar,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// El buscador de sitios.
///
/// Espera a que dejes de escribir antes de consultar: Nominatim es un
/// servicio público y gratuito que pide no pasar de una consulta por segundo,
/// y disparar una por letra sería abusar de algo que nos están regalando.
class _HojaBuscar extends StatefulWidget {
  const _HojaBuscar({required this.inicial});

  final String inicial;

  @override
  State<_HojaBuscar> createState() => _HojaBuscarState();
}

class _HojaBuscarState extends State<_HojaBuscar> {
  late final TextEditingController _control =
      TextEditingController(text: widget.inicial);
  List<Lugar> _resultados = const <Lugar>[];
  bool _buscando = false;
  bool _buscado = false;
  int _peticion = 0;

  @override
  void initState() {
    super.initState();
    if (widget.inicial.trim().length >= 3) _lanzar(widget.inicial);
  }

  @override
  void dispose() {
    _control.dispose();
    super.dispose();
  }

  Future<void> _lanzar(String texto) async {
    final int mia = ++_peticion;
    setState(() => _buscando = true);

    final List<Lugar> lugares = await UbicacionService.buscar(texto);

    // Otra búsqueda ha salido después que ésta: sus resultados son los
    // buenos, y pintar los míos encima sería enseñar lo que no se pidió.
    if (!mounted || mia != _peticion) return;
    setState(() {
      _resultados = lugares;
      _buscando = false;
      _buscado = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.s),
        padding: const EdgeInsets.all(AppSpacing.l),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.78,
        ),
        decoration: BoxDecoration(
          color: AppColors.fondo,
          borderRadius: BorderRadius.circular(AppShape.radioXL),
          border: Border.all(color: AppColors.tinta, width: AppShape.borde),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('Buscar el bar', style: AppTypography.tituloM),
            const SizedBox(height: AppSpacing.m),
            TextField(
              controller: _control,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onSubmitted: _lanzar,
              style: AppTypography.cuerpo,
              decoration: InputDecoration(
                hintText: 'Bar Manoli, Sevilla',
                filled: true,
                fillColor: AppColors.superficie,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search_rounded),
                  color: AppColors.tinta,
                  onPressed: () => _lanzar(_control.text),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppShape.radioM),
                  borderSide: const BorderSide(
                    color: AppColors.tinta,
                    width: AppShape.borde,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppShape.radioM),
                  borderSide: const BorderSide(
                    color: AppColors.tinta,
                    width: AppShape.borde,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppShape.radioM),
                  borderSide: const BorderSide(
                    color: AppColors.tinta,
                    width: AppShape.borde,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.m),
            Flexible(
              child: _buscando
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.tomate,
                        ),
                      ),
                    )
                  : _resultados.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.l,
                          ),
                          child: Text(
                            _buscado
                                ? 'Nada. Prueba con el nombre de la calle, o '
                                    'pon el punto a mano en el mapa.'
                                : 'Escribe el bar y la ciudad.',
                            style: AppTypography.cuerpoS,
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: _resultados.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.s),
                          itemBuilder: (BuildContext context, int i) {
                            final Lugar l = _resultados[i];
                            return Pegatina(
                              padding: const EdgeInsets.all(AppSpacing.m),
                              sombra: AppShape.sombraChica,
                              onTap: () => Navigator.of(context).pop(l),
                              child: Row(
                                children: <Widget>[
                                  const Text('📍',
                                      style: TextStyle(fontSize: 18)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        Text(
                                          l.nombre,
                                          style: AppTypography.tituloS
                                              .copyWith(fontSize: 15),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          l.ciudad.isEmpty
                                              ? l.coordenadas
                                              : l.ciudad,
                                          style: AppTypography.cuerpoS.copyWith(
                                            fontSize: 12,
                                            color: AppColors.tinta
                                                .withValues(alpha: 0.6),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
            const SizedBox(height: AppSpacing.s),
            BotonPegatina.fantasma(
              texto: 'Cerrar',
              pequeno: true,
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Poner el punto a mano: el mapa se mueve y la chincheta se queda quieta en
/// el centro.
///
/// Es al revés de arrastrar la chincheta, y es mejor: el dedo nunca tapa lo
/// que estás intentando señalar.
class AjustarPuntoPage extends StatefulWidget {
  const AjustarPuntoPage({super.key, this.inicial});

  final Lugar? inicial;

  @override
  State<AjustarPuntoPage> createState() => _AjustarPuntoPageState();
}

class _AjustarPuntoPageState extends State<AjustarPuntoPage> {
  final MapController _mapa = MapController();
  bool _resolviendo = false;

  static const LatLng _sevilla = LatLng(37.3886, -5.9885);

  @override
  void dispose() {
    _mapa.dispose();
    super.dispose();
  }

  Future<void> _usarEste() async {
    if (_resolviendo) return;
    setState(() => _resolviendo = true);

    final LatLng centro = _mapa.camera.center;
    // Pedimos el nombre, pero si no hay red se devuelve el punto igual: las
    // coordenadas son lo que va al mapa, el nombre es un adorno.
    final Lugar? conNombre =
        await UbicacionService.inverso(centro.latitude, centro.longitude);

    if (!mounted) return;
    Navigator.of(context).pop(
      conNombre ??
          Lugar(
            nombre: 'Punto en el mapa',
            lat: centro.latitude,
            lon: centro.longitude,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final LatLng centro = widget.inicial == null
        ? _sevilla
        : LatLng(widget.inicial!.lat, widget.inicial!.lon);

    return Scaffold(
      backgroundColor: AppColors.fondo,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapa,
              options: MapOptions(
                initialCenter: centro,
                initialZoom: widget.inicial == null ? 12 : 17,
                minZoom: 3,
                maxZoom: 19,
              ),
              children: <Widget>[teselasOsm(), const AtribucionOsm()],
            ),
          ),

          // La chincheta va fuera del mapa, clavada en el centro de la
          // pantalla: así no se mueve nunca y el punto es exactamente el
          // centro de la cámara.
          const IgnorePointer(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 38),
                child: Chincheta(tamano: 40),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.pantalla),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      BotonRedondo(
                        icono: Icons.close_rounded,
                        etiqueta: 'Cancelar',
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: AppSpacing.m),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.crema,
                            borderRadius:
                                BorderRadius.circular(AppShape.radioM),
                            border: Border.all(
                              color: AppColors.tinta,
                              width: AppShape.bordeFino,
                            ),
                          ),
                          child: Text(
                            'Mueve el mapa hasta poner la croqueta encima '
                            'del bar.',
                            style: AppTypography.cuerpoS.copyWith(
                              fontSize: 12.5,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  BotonPegatina(
                    texto: _resolviendo ? 'Un momento…' : 'Usar este punto',
                    color: AppColors.tomate,
                    icono: Icons.check_rounded,
                    onTap: _resolviendo ? null : _usarEste,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
