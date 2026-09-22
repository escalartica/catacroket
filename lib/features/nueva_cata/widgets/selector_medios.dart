import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/medio.dart';
import '../../../core/providers/borrador_provider.dart';
import '../../../core/services/medios_service.dart';
import '../../../core/theme/tokens/app_colors.dart';
import '../../../core/theme/tokens/app_shape.dart';
import '../../../core/theme/tokens/app_spacing.dart';
import '../../../core/theme/tokens/app_typography.dart';
import '../../../core/theme/components/pegatina.dart';

/// Fotos y vídeo de la cata.
///
/// Los límites (dos fotos, un vídeo de 15 s) no se explican con un texto de
/// ayuda: los botones simplemente desaparecen cuando se alcanzan. Una regla
/// que se ve es mejor que una regla que se lee.
class SelectorMedios extends ConsumerWidget {
  const SelectorMedios({super.key});

  Future<void> _anadir(
    BuildContext context,
    WidgetRef ref,
    Future<ResultadoMedio> Function() elegir,
  ) async {
    final ResultadoMedio resultado = await elegir();
    if (!context.mounted) return;

    switch (resultado) {
      case MedioListo(:final Medio medio):
        ref.read(borradorProvider.notifier).anadirMedio(medio);
      case MedioCancelado():
        break;
      case MedioRechazado(:final String motivo):
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(motivo)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Medio> medios = ref.watch(borradorProvider).medios;
    final int fotos = medios.where((Medio m) => !m.esVideo).length;
    final int videos = medios.where((Medio m) => m.esVideo).length;

    final bool cabenFotos = fotos < Medio.maxFotos;
    final bool cabenVideos = videos < Medio.maxVideos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('LA CROQUETA', style: AppTypography.antetitulo),
        const SizedBox(height: 7),

        if (medios.isNotEmpty) ...<Widget>[
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: medios.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s),
              itemBuilder: (BuildContext context, int i) => _Miniatura(
                medio: medios[i],
                // El fichero lo borra el notifier, y sólo si esa foto se
                // añadió ahora: las que venían con la cata sobreviven a un
                // arrepentimiento.
                onQuitar: () =>
                    ref.read(borradorProvider.notifier).quitarMedio(medios[i]),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.m),
        ],

        Wrap(
          spacing: AppSpacing.s,
          runSpacing: AppSpacing.s,
          children: <Widget>[
            if (cabenFotos)
              _BotonMedio(
                emoji: '📷',
                texto: 'Cámara',
                color: AppColors.sol,
                onTap: () => _anadir(
                  context,
                  ref,
                  () => MediosService.foto(camara: true),
                ),
              ),
            if (cabenFotos)
              _BotonMedio(
                emoji: '🖼️',
                texto: 'Galería',
                color: AppColors.cielo,
                onTap: () => _anadir(
                  context,
                  ref,
                  () => MediosService.foto(camara: false),
                ),
              ),
            if (cabenVideos)
              _BotonMedio(
                emoji: '🎬',
                texto: 'Vídeo 15 s',
                color: AppColors.chicle,
                onTap: () => _mostrarOpcionesVideo(context, ref),
              ),
          ],
        ),

        if (!cabenFotos && !cabenVideos) ...<Widget>[
          const SizedBox(height: AppSpacing.s),
          Text(
            'Ya tienes dos fotos y un vídeo. Con eso se entiende.',
            style: AppTypography.cuerpoS.copyWith(
              fontSize: 12.5,
              color: AppColors.tintaSuave,
            ),
          ),
        ] else ...<Widget>[
          const SizedBox(height: AppSpacing.s),
          Text(
            'Opcional: si no pones nada, tu croqueta se dibuja sola.',
            style: AppTypography.cuerpoS.copyWith(
              fontSize: 12.5,
              color: AppColors.tintaSuave,
            ),
          ),
        ],
      ],
    );
  }

  void _mostrarOpcionesVideo(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext hoja) => Container(
        margin: const EdgeInsets.all(AppSpacing.m),
        padding: const EdgeInsets.all(AppSpacing.l),
        decoration: BoxDecoration(
          color: AppColors.fondo,
          borderRadius: BorderRadius.circular(AppShape.radioXL),
          border: Border.all(color: AppColors.tinta, width: AppShape.borde),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('Vídeo de 15 segundos', style: AppTypography.tituloM),
            const SizedBox(height: AppSpacing.s),
            Text(
              'Lo justo para el corte y el primer bocado.',
              style: AppTypography.cuerpoS.copyWith(
                color: AppColors.tintaSuave,
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            _BotonMedio(
              emoji: '🎥',
              texto: 'Grabar ahora',
              color: AppColors.chicle,
              ancho: true,
              onTap: () {
                Navigator.of(hoja).pop();
                _anadir(context, ref, () => MediosService.video(camara: true));
              },
            ),
            const SizedBox(height: AppSpacing.s),
            _BotonMedio(
              emoji: '🖼️',
              texto: 'Elegir de la galería',
              color: AppColors.superficie,
              ancho: true,
              onTap: () {
                Navigator.of(hoja).pop();
                _anadir(context, ref, () => MediosService.video(camara: false));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BotonMedio extends StatelessWidget {
  const _BotonMedio({
    required this.emoji,
    required this.texto,
    required this.color,
    required this.onTap,
    this.ancho = false,
  });

  final String emoji;
  final String texto;
  final Color color;
  final VoidCallback onTap;
  final bool ancho;

  @override
  Widget build(BuildContext context) {
    return Pegatina(
      color: color,
      radio: AppShape.radioPildora,
      sombra: const Offset(2, 2),
      ancho: ancho ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: onTap,
      alineacion: ancho ? Alignment.center : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(texto, style: AppTypography.etiqueta.copyWith(fontSize: 13.5)),
        ],
      ),
    );
  }
}

class _Miniatura extends StatelessWidget {
  const _Miniatura({required this.medio, required this.onQuitar});

  final Medio medio;
  final VoidCallback onQuitar;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Container(
            width: 88,
            height: 88,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.superficieCalida,
              borderRadius: BorderRadius.circular(AppShape.radioM),
              border: Border.all(color: AppColors.tinta, width: AppShape.borde),
              boxShadow: AppShape.sombra(const Offset(2, 2)),
            ),
            child: medio.esVideo
                ? const Center(
                    child: Icon(
                      Icons.play_circle_fill_rounded,
                      size: 34,
                      color: AppColors.tinta,
                    ),
                  )
                : Image.file(
                    File(medio.ruta),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Center(
                      child: Icon(Icons.broken_image_rounded),
                    ),
                  ),
          ),
          // El círculo se ve de 26 px, pero se toca en 44: dibujar más
          // grande la cruz de "quitar" la convertiría en lo más llamativo de
          // la miniatura, y lo que importa es la foto.
          Positioned(
            top: -13,
            right: -9,
            child: Semantics(
              button: true,
              label: 'Quitar',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onQuitar,
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.tomate,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.tinta, width: 2),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 15,
                        color: Colors.white,
                      ),
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
