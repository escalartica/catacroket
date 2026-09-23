import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../arte/corte_painter.dart';
import '../../arte/croqui.dart';
import '../../core/data/rellenos.dart';
import '../../core/models/cata.dart';
import '../../core/models/dieta.dart';
import '../../core/models/persona.dart';
import '../../core/models/sabor.dart';
import '../../core/services/compartir_service.dart';
import '../../core/theme/components/boton.dart';
import '../../core/theme/components/chip.dart';
import '../../core/theme/components/nota.dart';
import '../../core/theme/components/pegatina.dart';
import '../../core/theme/tokens/app_colors.dart';
import '../../core/theme/tokens/app_shape.dart';
import '../../core/theme/tokens/app_spacing.dart';
import '../../core/theme/tokens/app_typography.dart';
import '../../core/data/enlaces.dart';
import '../../core/utils/formato.dart';

/// Medidas de la estampa. 4:5 es el formato que ni Instagram ni WhatsApp
/// recortan, y a ×3 salen 1080×1350, que es lo que pide Instagram.
const double _anchoEstampa = 360;
const double _altoEstampa = 450;
const double _densidad = 3;

/// Enseña la estampa de una cata y, si el usuario quiere, la comparte.
///
/// La vista previa no es un adorno: lo que se comparte sale de la app del
/// usuario con su nombre encima, así que tiene derecho a ver exactamente qué
/// va a salir antes de que salga.
Future<void> compartirCata(
  BuildContext context, {
  required Cata cata,
  required Persona autor,
}) {
  return showModalBottomSheet<void>(
    context: context,
    // Por el Navigator raíz: si no, la hoja se abre dentro de la concha y la
    // barra de pestañas se dibuja encima, tapando los botones de abajo. En la
    // de crear una mesa dejaba "Crear la mesa" y "Cancelar" inalcanzables.
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) => _HojaCompartir(cata: cata, autor: autor),
  );
}

class _HojaCompartir extends StatefulWidget {
  const _HojaCompartir({required this.cata, required this.autor});

  final Cata cata;
  final Persona autor;

  @override
  State<_HojaCompartir> createState() => _HojaCompartirState();
}

class _HojaCompartirState extends State<_HojaCompartir> {
  final GlobalKey _lienzo = GlobalKey();
  bool _trabajando = false;

  Future<void> _compartir() async {
    if (_trabajando) return;
    setState(() => _trabajando = true);
    HapticFeedback.selectionClick();

    try {
      // Un frame de margen: si el SVG de la marca acaba de cargarse, todavía
      // no está en la capa y la estampa saldría sin logo.
      await WidgetsBinding.instance.endOfFrame;

      final RenderRepaintBoundary? caja =
          _lienzo.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (caja == null) throw StateError('la estampa no está pintada');

      final ui.Image imagen = await caja.toImage(pixelRatio: _densidad);
      final ByteData? datos =
          await imagen.toByteData(format: ui.ImageByteFormat.png);
      imagen.dispose();
      if (datos == null) throw StateError('no se pudo codificar el PNG');

      final Directory carpeta = await getTemporaryDirectory();
      final File fichero = File(
        '${carpeta.path}/catacroket-${widget.cata.id}.png',
      );
      await fichero.writeAsBytes(datos.buffer.asUint8List(), flush: true);

      if (!mounted) return;
      // En iPad la hoja de compartir sale anclada a algo; sin esto, peta.
      final RenderBox? origen = context.findRenderObject() as RenderBox?;

      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[XFile(fichero.path, mimeType: 'image/png')],
          text: _pie(widget.cata),
          subject: 'Croqueta de ${widget.cata.sitio}',
          sharePositionOrigin: origen == null
              ? null
              : origen.localToGlobal(Offset.zero) & origen.size,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('No se ha podido crear la imagen.')),
        );
    } finally {
      if (mounted) setState(() => _trabajando = false);
    }
  }

  /// WhatsApp directo, sólo con el texto.
  ///
  /// Es el camino del momento: estás comiéndotela y quieres que el grupo se
  /// entere ya. No lleva imagen a propósito — una imagen hay que generarla,
  /// guardarla y pasar por la hoja del sistema, y eso son tres segundos y dos
  /// pantallas más de las que tienes ganas con la croqueta enfriándose.
  Future<void> _porWhatsApp() async {
    HapticFeedback.selectionClick();
    final bool abierto = await CompartirService.porWhatsApp(
      CompartirService.cata(widget.cata),
    );
    if (!mounted) return;
    if (!abierto) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('No se ha podido abrir WhatsApp.')),
        );
      return;
    }
    Navigator.of(context).pop();
  }

  /// El texto que acompaña a la imagen.
  ///
  /// Lleva el enlace de la tienda en cuanto exista. Esto es lo que más se
  /// comparte de toda la app, así que era el único sitio donde de verdad
  /// importaba: quien recibe la estampa en el grupo ve una croqueta con
  /// buena pinta y, si no hay enlace, no tiene dónde ir.
  ///
  /// La imagen ya lleva el nombre dentro, así que aunque alguien la reenvíe
  /// suelta se sabe de dónde salió. El enlace es para quien recibe el
  /// mensaje entero.
  static String _pie(Cata cata) {
    final String loQueFue =
        '${Formato.nota(cata.puntuacion)} en ${cata.sitio} (${cata.lugar}). '
        'Catado con Catacroket.';

    return Enlaces.hayTienda ? '$loQueFue\n${Enlaces.tienda}' : loQueFue;
  }

  @override
  Widget build(BuildContext context) {
    final Size pantalla = MediaQuery.sizeOf(context);
    final double ancho = pantalla.width;
    // El lienzo mide siempre lo mismo y se encoge sólo para enseñarlo: la
    // imagen que sale tiene que pesar igual en un iPhone SE que en un Max.
    final double escala =
        ((ancho - AppSpacing.pantalla * 2) / _anchoEstampa).clamp(0.5, 1.0);

    return SafeArea(
      top: false,
      // La hoja se acota en alto. Sin esto, el Column de dentro crecía todo
      // lo que le pedía su contenido y se salía por abajo: en un iPhone 16
      // Pro la vista previa dejaba el último botón debajo de las rayas
      // amarillas y negras de desbordamiento, que las veía el usuario.
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: pantalla.height * 0.92),
        child: Container(
        margin: const EdgeInsets.all(AppSpacing.s),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.l,
          AppSpacing.m,
          AppSpacing.l,
          AppSpacing.l,
        ),
        decoration: BoxDecoration(
          color: AppColors.fondo,
          borderRadius: BorderRadius.circular(AppShape.radioXL),
          border: Border.all(color: AppColors.tinta, width: AppShape.borde),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 52,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.tinta.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: AppSpacing.m),
            Text('Así se va a ver', style: AppTypography.tituloM),
            const SizedBox(height: AppSpacing.m),

            // El lienzo, a tamaño real, encogido sólo para la vista previa.
            //
            // Flexible y no un alto fijo: el ancho no es la única
            // restricción. Calculando la escala sólo con el ancho, en una
            // pantalla baja la vista previa se comía el sitio de los
            // botones. Así se lleva el hueco que sobre y el FittedBox de
            // dentro la encoge hasta caber.
            Flexible(
              child: SizedBox(
              width: _anchoEstampa * escala,
              height: _altoEstampa * escala,
              child: FittedBox(
                fit: BoxFit.contain,
                child: RepaintBoundary(
                  key: _lienzo,
                  // El tamaño de letra del sistema NO entra aquí. La estampa
                  // es un PNG fijo de 360x450 que se le manda a otra gente:
                  // con la letra al 1,3 el nombre de un bar largo se recorta
                  // en la imagen que llega al grupo, y quien la envía lo ve
                  // bien en su previsualización. La imagen tiene que salir
                  // igual sea cual sea el ajuste de quien la comparte.
                  child: MediaQuery.withNoTextScaling(
                    // Y se anuncia como lo que es: una imagen, entera, no
                    // los veinte trozos de texto que la componen.
                    child: Semantics(
                      label: 'Estampa de la cata de ${widget.cata.sitio}, '
                          'nota ${Formato.nota(widget.cata.puntuacion)} de 10',
                      image: true,
                      excludeSemantics: true,
                      child: _Estampa(
                        cata: widget.cata,
                        autor: widget.autor,
                      ),
                    ),
                  ),
                ),
              ),
              ),
            ),

            const SizedBox(height: AppSpacing.l),
            BotonPegatina(
              texto: _trabajando ? 'Preparando la imagen…' : 'Compartir la estampa',
              icono: Icons.ios_share_rounded,
              color: AppColors.tomate,
              onTap: _trabajando ? null : _compartir,
            ),
            const SizedBox(height: AppSpacing.s),
            BotonPegatina(
              texto: 'Al grupo, sin foto',
              icono: Icons.chat_bubble_rounded,
              color: AppColors.menta,
              pequeno: true,
              onTap: _trabajando ? null : _porWhatsApp,
            ),
            const SizedBox(height: AppSpacing.s),
            BotonPegatina.fantasma(
              texto: 'Ahora no',
              pequeno: true,
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

/// La estampa que sale de la app.
///
/// Lleva El Corte y no una foto: el dibujo es de esta croqueta y de ninguna
/// otra, se ve igual de bien en un feed que a pantalla completa, y no depende
/// de que el usuario hiciera una buena foto en la barra de un bar.
class _Estampa extends StatelessWidget {
  const _Estampa({required this.cata, required this.autor});

  final Cata cata;
  final Persona autor;

  @override
  Widget build(BuildContext context) {
    final Relleno relleno = Rellenos.de(cata.rellenoId);

    return SizedBox(
      width: _anchoEstampa,
      height: _altoEstampa,
      child: FondoLunares(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const MarcaMini(tamano: 32),
                  const SizedBox(width: 8),
                  const NombreCatacroket(alto: 15),
                  const Spacer(),
                  ChipCata(
                    texto: Formato.relativo(cata.fecha),
                    compacto: true,
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // El corte, centrado, con la nota pisándole una esquina.
              Expanded(
                child: Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: <Widget>[
                      ElCorte(
                        corte: cata.corte,
                        rellenoId: cata.rellenoId,
                        semilla: cata.id,
                        ancho: 176,
                      ),
                      Positioned(
                        right: -6,
                        bottom: 2,
                        child: Nota(valor: cata.puntuacion, grande: true),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 6),
              Text(
                cata.sitio,
                style: AppTypography.tituloM.copyWith(fontSize: 24),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                cata.lugar,
                style: AppTypography.cuerpoS.copyWith(
                  fontSize: 13,
                  color: AppColors.tintaSuave,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: <Widget>[
                  ChipCata(
                    texto: cata.esSurtido
                        ? 'Surtido de ${cata.sabores.length}'
                        : cata.saborPrincipal.nombre,
                    emoji: cata.esSurtido
                        ? '🍽️'
                        : relleno.emoji,
                    color: relleno.color,
                    compacto: true,
                  ),
                  if (cata.esSurtido)
                    ChipCata(
                      texto: cata.sabores
                          .map((Sabor s) => Rellenos.de(s.rellenoId).emoji)
                          .join(' '),
                      compacto: true,
                    ),
                  for (final Dieta d in cata.dietas.take(2))
                    ChipCata(
                      texto: d.corto,
                      emoji: d.emoji,
                      color: d.color,
                      compacto: true,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: autor.color,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.tinta, width: 1.4),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      cata.nota.isEmpty
                          ? 'Catada por ${autor.nombre}'
                          : '“${cata.nota}”',
                      style: AppTypography.cuerpoS.copyWith(
                        fontSize: 12.5,
                        height: 1.25,
                        color: AppColors.tintaSuave,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
