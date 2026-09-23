import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../core/models/medio.dart';
import '../../../core/theme/tokens/app_colors.dart';
import '../../../core/theme/tokens/app_shape.dart';
import '../../../core/theme/tokens/app_spacing.dart';
import '../../../core/theme/tokens/app_typography.dart';

/// Las fotos y el vídeo de una cata, en una tira horizontal.
///
/// No sustituye a El Corte: el dibujo sigue siendo lo que cuenta cómo era la
/// croqueta por dentro, y esto es lo que cuenta cómo era por fuera. Por eso
/// va encima de la ficha y no en el feed, donde el dibujo tiene que mandar
/// para que todas las tarjetas se lean igual.
class CarruselMedios extends StatelessWidget {
  const CarruselMedios({super.key, required this.medios});

  final List<Medio> medios;

  @override
  Widget build(BuildContext context) {
    if (medios.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pantalla),
        itemCount: medios.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.m),
        itemBuilder: (BuildContext context, int i) {
          final Medio medio = medios[i];
          // "Foto 1 de 3" en vez de silencio: sin esto el carrusel entero no
          // existe para quien no ve las imágenes.
          return Semantics(
            label: medio.esVideo
                ? 'Vídeo ${i + 1} de ${medios.length}'
                : 'Foto ${i + 1} de ${medios.length}',
            image: !medio.esVideo,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppShape.radioL),
              child: Container(
                width: 200,
                decoration: BoxDecoration(
                  color: AppColors.superficieCalida,
                  borderRadius: BorderRadius.circular(AppShape.radioL),
                  border: Border.all(color: AppColors.tinta, width: AppShape.borde),
                ),
                child: medio.esVideo
                    ? _Video(ruta: medio.ruta)
                    // La miniatura recorta para llenar la tarjeta, así que
                    // de una foto apaisada se pierden los lados. Tocarla la
                    // abre entera: hasta ahora el recorte era lo único que
                    // se llegaba a ver de una foto propia.
                    : GestureDetector(
                        onTap: () => _verEntera(context, medios, i),
                        child: Image.file(
                          File(medio.ruta),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const _MedioRoto(),
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Abre las fotos a pantalla completa, empezando por la que se ha tocado.
void _verEntera(BuildContext context, List<Medio> medios, int desde) {
  final List<Medio> fotos =
      medios.where((Medio m) => !m.esVideo).toList();
  if (fotos.isEmpty) return;

  // El índice viene de la lista entera, que puede llevar vídeos por medio.
  final int inicio = fotos.indexOf(medios[desde]).clamp(0, fotos.length - 1);

  Navigator.of(context, rootNavigator: true).push<void>(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: AppColors.tinta.withValues(alpha: 0.92),
      pageBuilder: (_, _, _) => _Visor(fotos: fotos, inicio: inicio),
      transitionsBuilder: (_, Animation<double> animacion, _, Widget hijo) =>
          FadeTransition(opacity: animacion, child: hijo),
      transitionDuration: const Duration(milliseconds: 180),
    ),
  );
}

/// La foto, entera y sin recortar.
///
/// `BoxFit.contain` y no `cover`: aquí el objetivo es justo el contrario que
/// en la miniatura. Allí se recorta para que todas las tarjetas midan lo
/// mismo; aquí se enseña lo que hay, aunque sobren franjas a los lados.
class _Visor extends StatefulWidget {
  const _Visor({required this.fotos, required this.inicio});

  final List<Medio> fotos;
  final int inicio;

  @override
  State<_Visor> createState() => _VisorState();
}

class _VisorState extends State<_Visor> {
  late final PageController _paginas =
      PageController(initialPage: widget.inicio);
  late int _actual = widget.inicio;

  @override
  void dispose() {
    _paginas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool varias = widget.fotos.length > 1;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: <Widget>[
          // Tocar el fondo cierra. Es lo que todo el mundo intenta primero.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
              child: PageView.builder(
                controller: _paginas,
                itemCount: widget.fotos.length,
                onPageChanged: (int i) => setState(() => _actual = i),
                itemBuilder: (BuildContext context, int i) => Semantics(
                  label: 'Foto ${i + 1} de ${widget.fotos.length}',
                  image: true,
                  excludeSemantics: true,
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: Center(
                      child: Image.file(
                        File(widget.fotos[i].ruta),
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const _MedioRoto(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Cuántas son y cuál estás viendo. Sólo si hay más de una.
          if (varias)
            Positioned(
              bottom: AppSpacing.xl,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.crema,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: AppColors.tinta,
                      width: AppShape.bordeFino,
                    ),
                  ),
                  child: Text(
                    '${_actual + 1} de ${widget.fotos.length}',
                    style: AppTypography.etiqueta,
                  ),
                ),
              ),
            ),

          Positioned(
            top: AppSpacing.m,
            right: AppSpacing.pantalla,
            child: SafeArea(
              child: Semantics(
                button: true,
                label: 'Cerrar la foto',
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.crema,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.tinta,
                        width: AppShape.bordeFino,
                      ),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: AppColors.tinta,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedioRoto extends StatelessWidget {
  const _MedioRoto();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.broken_image_rounded, color: AppColors.tinta),
          const SizedBox(height: 6),
          Text('No se encuentra', style: AppTypography.etiqueta),
        ],
      ),
    );
  }
}

/// Reproductor mínimo: toca para reproducir o pausar, y se repite solo.
///
/// Son quince segundos; meter barra de progreso, volumen y pantalla completa
/// sería más interfaz que vídeo.
class _Video extends StatefulWidget {
  const _Video({required this.ruta});

  final String ruta;

  @override
  State<_Video> createState() => _VideoState();
}

class _VideoState extends State<_Video> {
  VideoPlayerController? _control;
  bool _listo = false;

  @override
  void initState() {
    super.initState();
    _preparar();
  }

  Future<void> _preparar() async {
    try {
      final VideoPlayerController control =
          VideoPlayerController.file(File(widget.ruta));
      await control.initialize();
      await control.setLooping(true);
      if (!mounted) {
        await control.dispose();
        return;
      }
      setState(() {
        _control = control;
        _listo = true;
      });
    } catch (_) {
      if (mounted) setState(() => _listo = false);
    }
  }

  @override
  void dispose() {
    _control?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final VideoPlayerController? control = _control;

    if (!_listo || control == null) {
      return const Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
      );
    }

    return Semantics(
      button: true,
      toggled: control.value.isPlaying,
      label: control.value.isPlaying ? 'Pausar el vídeo' : 'Reproducir el vídeo',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () {
          setState(() {
            control.value.isPlaying ? control.pause() : control.play();
          });
        },
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: control.value.size.width,
                height: control.value.size.height,
                child: VideoPlayer(control),
              ),
            ),
            if (!control.value.isPlaying)
              Container(
                color: AppColors.tinta.withValues(alpha: 0.28),
                child: const Center(
                  child: Icon(
                    Icons.play_circle_fill_rounded,
                    size: 54,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
