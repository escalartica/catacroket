import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/yo_provider.dart';
import '../../../core/theme/components/boton.dart';
import '../../../core/theme/components/campo.dart';
import '../../../core/theme/tokens/app_colors.dart';
import '../../../core/theme/tokens/app_shape.dart';
import '../../../core/theme/tokens/app_spacing.dart';
import '../../../core/theme/tokens/app_typography.dart';

/// Tu foto, tu nombre y tu rango, arriba del Croquetómetro.
///
/// La foto y el nombre se tocan y se cambian. Antes eran una C y la palabra
/// «Cehache» escritas en el código: lo primero que mira cualquiera al abrir
/// su perfil, y no se podía tocar.
class Identidad extends ConsumerWidget {
  const Identidad({super.key, required this.rango});

  final String rango;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Yo yo = ref.watch(yoProvider);

    return Column(
      children: <Widget>[
        _Retrato(yo: yo),
        const SizedBox(height: AppSpacing.m),
        Semantics(
          button: true,
          label: 'Cambiar tu nombre. Ahora es ${yo.nombre}',
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _editarNombre(context, ref, yo.nombre),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(yo.nombre, style: AppTypography.tituloL),
                const SizedBox(width: 8),
                const Icon(
                  Icons.edit_rounded,
                  size: 18,
                  color: AppColors.tintaSuave,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Transform.rotate(
          angle: -0.03,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.menta,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.tinta, width: 2),
            ),
            child: Text(
              rango,
              style: AppTypography.etiqueta.copyWith(fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _editarNombre(
    BuildContext context,
    WidgetRef ref,
    String actual,
  ) async {
    final String? nuevo = await showDialog<String>(
      context: context,
      builder: (BuildContext _) => _DialogoNombre(inicial: actual),
    );
    if (nuevo != null) await ref.read(yoProvider.notifier).ponerNombre(nuevo);
  }
}

/// La chapa redonda con la foto o la inicial, y el botón de la cámara.
class _Retrato extends ConsumerWidget {
  const _Retrato({required this.yo});

  final Yo yo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const double lado = 112;

    return SizedBox(
      width: lado + 14,
      height: lado + 10,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned(
            left: 0,
            top: 0,
            child: Semantics(
              button: true,
              label: yo.tieneFoto ? 'Cambiar tu foto' : 'Poner tu foto',
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _hoja(context, ref),
                child: Transform.rotate(
                  angle: -0.07,
                  child: Container(
                    width: lado,
                    height: lado,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.sol,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.tinta,
                        width: AppShape.borde,
                      ),
                      boxShadow: AppShape.sombra(AppShape.sombraGrande),
                    ),
                    // El recorte va dentro del borde y no fuera: así la foto
                    // queda enmarcada por la línea de tinta en vez de taparla.
                    child: ClipOval(
                      child: yo.tieneFoto
                          ? Image.file(
                              File(yo.foto!),
                              width: lado,
                              height: lado,
                              fit: BoxFit.cover,
                              // Si la foto desaparece del disco (el sistema
                              // limpia, el usuario la borra) no se rompe la
                              // pantalla: vuelve la inicial.
                              errorBuilder: (_, _, _) => _Inicial(letra: yo.inicial),
                            )
                          : _Inicial(letra: yo.inicial),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // La cámara, en la esquina. Es el único aviso de que la chapa se
          // toca: sin ella nadie adivina que ahí se pone una foto.
          Positioned(
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.superficie,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.tinta,
                    width: AppShape.bordeFino,
                  ),
                ),
                child: Icon(
                  yo.tieneFoto ? Icons.edit_rounded : Icons.photo_camera_rounded,
                  size: 17,
                  color: AppColors.tinta,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Pide la foto y, si no se puede, lo dice.
  ///
  /// Un botón que no hace nada visible es lo peor que puede pasar aquí: el
  /// usuario no sabe si ha fallado él, la app o el móvil.
  Future<void> _pedirFoto(
    BuildContext context,
    WidgetRef ref, {
    required bool camara,
  }) async {
    final ResultadoFoto resultado =
        await ref.read(yoProvider.notifier).ponerFoto(camara: camara);

    final String? aviso = resultado.aviso;
    if (aviso == null || !context.mounted) return;

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(aviso)));
  }

  Future<void> _hoja(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      // Por el Navigator raíz: dentro de la concha, la barra de pestañas se
      // dibuja encima de la hoja y le tapa los botones de abajo.
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext hoja) => _HojaFoto(
        tieneFoto: yo.tieneFoto,
        onCamara: () {
          Navigator.of(hoja).pop();
          _pedirFoto(context, ref, camara: true);
        },
        onGaleria: () {
          Navigator.of(hoja).pop();
          _pedirFoto(context, ref, camara: false);
        },
        onQuitar: () {
          Navigator.of(hoja).pop();
          ref.read(yoProvider.notifier).quitarFoto();
        },
      ),
    );
  }
}

class _Inicial extends StatelessWidget {
  const _Inicial({required this.letra});

  final String letra;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.sol,
      alignment: Alignment.center,
      child: Text(letra, style: AppTypography.cifra),
    );
  }
}

/// Cámara, galería y quitar. Las mismas tres opciones y en el mismo orden
/// que en el formulario de una cata.
class _HojaFoto extends StatelessWidget {
  const _HojaFoto({
    required this.tieneFoto,
    required this.onCamara,
    required this.onGaleria,
    required this.onQuitar,
  });

  final bool tieneFoto;
  final VoidCallback onCamara;
  final VoidCallback onGaleria;
  final VoidCallback onQuitar;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.pantalla),
        padding: const EdgeInsets.all(AppSpacing.l),
        decoration: BoxDecoration(
          color: AppColors.crema,
          borderRadius: BorderRadius.circular(AppShape.radioL),
          border: Border.all(color: AppColors.tinta, width: AppShape.borde),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              tieneFoto ? 'Cambiar tu foto' : 'Tu foto',
              style: AppTypography.tituloM,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.l),
            BotonPegatina(
              texto: 'Cámara',
              icono: Icons.photo_camera_rounded,
              onTap: onCamara,
            ),
            const SizedBox(height: AppSpacing.m),
            BotonPegatina.fantasma(
              texto: 'Elegir de la galeria',
              icono: Icons.photo_library_rounded,
              onTap: onGaleria,
            ),
            if (tieneFoto) ...<Widget>[
              const SizedBox(height: AppSpacing.m),
              BotonPegatina.fantasma(
                texto: 'Quitar la foto',
                icono: Icons.delete_outline_rounded,
                onTap: onQuitar,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DialogoNombre extends StatefulWidget {
  const _DialogoNombre({required this.inicial});

  final String inicial;

  @override
  State<_DialogoNombre> createState() => _DialogoNombreState();
}

class _DialogoNombreState extends State<_DialogoNombre> {
  late String _texto = widget.inicial;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.pantalla),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.l),
        decoration: BoxDecoration(
          color: AppColors.crema,
          borderRadius: BorderRadius.circular(AppShape.radioL),
          border: Border.all(color: AppColors.tinta, width: AppShape.borde),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Cómo te llamas', style: AppTypography.tituloM),
            const SizedBox(height: 6),
            Text(
              'Es lo que verán en tus catas los de tu mesa.',
              style: AppTypography.cuerpoS.copyWith(height: 1.35),
            ),
            const SizedBox(height: AppSpacing.m),
            Campo(
              etiqueta: 'Tu nombre',
              valor: _texto,
              autofoco: true,
              onCambio: (String v) => setState(() => _texto = v),
            ),
            const SizedBox(height: AppSpacing.l),
            Row(
              children: <Widget>[
                Expanded(
                  child: BotonPegatina.fantasma(
                    texto: 'Cancelar',
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: BotonPegatina(
                    texto: 'Guardar',
                    onTap: _texto.trim().isEmpty
                        ? null
                        : () => Navigator.of(context).pop(_texto),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
