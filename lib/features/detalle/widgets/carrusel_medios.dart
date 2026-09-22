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
          return ClipRRect(
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
                  : Image.file(
                      File(medio.ruta),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const _MedioRoto(),
                    ),
            ),
          );
        },
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

    return GestureDetector(
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
    );
  }
}
