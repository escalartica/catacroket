import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../arte/corte_painter.dart';
import '../../../core/data/rellenos.dart';
import '../../../core/models/cata.dart';
import '../../../core/theme/components/foto_medio.dart';
import '../../../core/models/medio.dart';
import '../../../core/models/dieta.dart';
import '../../../core/providers/evitar_provider.dart';
import '../../../core/providers/mi_dieta_provider.dart';
import '../../../core/models/sabor.dart';
import '../../../core/models/persona.dart';
import '../../../core/theme/components/chip.dart';
import '../../../core/theme/components/nota.dart';
import '../../../core/theme/components/pegatina.dart';
import '../../../core/theme/components/vuelo.dart';
import '../../../core/theme/tokens/app_colors.dart';
import '../../../core/theme/tokens/app_shape.dart';
import '../../../core/theme/tokens/app_typography.dart';
import '../../../core/utils/formato.dart';

/// La tarjeta del feed. Es la pieza que más se repite en la app, así que aquí
/// se decide cómo se lee una cata de un vistazo: dibujo, qué es, dónde y
/// cuánto.
class TarjetaCata extends ConsumerWidget {
  const TarjetaCata({
    super.key,
    required this.cata,
    required this.autor,
    this.onTap,
  });

  final Cata cata;
  final Persona autor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Relleno relleno = Rellenos.de(cata.rellenoId);
    final Encaje encaje = cata.encajeCon(ref.watch(miDietaProvider));

    // Lo que has dicho que no quieres y esta croqueta lleva apuntado. Va
    // delante de todo lo demás: si lleva marisco, el resto de las pastillas
    // ya no te interesan.
    final List<String> lleva = Evitar.coincidencias(
      ref.watch(evitarProvider),
      cata.loQueLleva,
    );

    // Cómo se oye la tarjeta entera.
    //
    // Sin esto se anunciaban sus textos sueltos en el orden en que cayeran:
    // el dibujo, la nota, el autor, las pastillas. Aquí manda el mismo orden
    // que manda en la pantalla, y lo primero es lo que no quieres que te
    // pongan: si lleva marisco, lo demás ya no importa.
    final String enVoz = <String>[
      if (lleva.isNotEmpty) 'Ojo, lleva ${lleva.join(', ')}',
      cata.esSurtido
          ? 'Surtido de ${cata.sabores.length} sabores'
          : cata.saborPrincipal.nombre,
      cata.sitioYLugar,
      'nota ${Formato.nota(cata.puntuacion)} de 10',
      'de ${autor.nombre}',
      Formato.relativo(cata.fecha),
      if (encaje != Encaje.sinSaber) encaje.nombre,
    ].join('. ');

    return Semantics(
      button: onTap != null,
      label: enVoz,
      excludeSemantics: true,
      onTap: onTap,
      child: Pegatina(
      onTap: onTap,
      padding: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Vuelo(id: cata.id, child: _Plato(cata: cata, color: relleno.color)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  cata.esSurtido
                      ? 'Surtido de ${cata.sabores.length}'
                      : '${relleno.emoji}  ${cata.saborPrincipal.nombre}',
                  style: AppTypography.tituloS,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (cata.esSurtido)
                  // Sin esto, el lector de pantalla recita los emoji uno a
                  // uno ("hamburguesa, pescado, seta") sin decir qué son.
                  Semantics(
                    label: 'Sabores: ${cata.sabores.map((Sabor s) => Rellenos.de(s.rellenoId).nombre).join(', ')}',
                    excludeSemantics: true,
                    child: Text(
                      cata.sabores
                          .map((Sabor s) => Rellenos.de(s.rellenoId).emoji)
                          .join(' '),
                      style: const TextStyle(fontSize: 13),
                      maxLines: 1,
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  cata.sitioYLugar,
                  style: AppTypography.cuerpoS.copyWith(
                    color: AppColors.tintaSuave,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Nota(valor: cata.puntuacion),
                    if (lleva.isNotEmpty)
                      ChipCata(
                        texto: 'Lleva ${lleva.first.toLowerCase()}',
                        emoji: '⚠️',
                        color: AppColors.mango,
                        compacto: true,
                      ),
                    ChipCata(texto: autor.nombre, punto: autor.color, compacto: true),
                    ChipCata(texto: Formato.relativo(cata.fecha), compacto: true),
                    // Si la ve alguien más, o no.
                    //
                    // En el feed están mezcladas las que sólo ves tú y las
                    // que ve tu mesa, y hasta aquí no había forma de
                    // distinguirlas sin entrar en cada una. Es la diferencia
                    // entre apuntar para ti y enseñar, que es justo lo que la
                    // app no estaba dejando claro en ninguna pantalla.
                    if (cata.esSoloMia)
                      const ChipCata(
                        texto: 'Sólo yo',
                        emoji: '🔒',
                        color: AppColors.superficieCalida,
                        compacto: true,
                      )
                    else
                      ChipCata(
                        texto: cata.mesas.length == 1
                            ? 'Compartida'
                            : 'En ${cata.mesas.length} mesas',
                        emoji: '👀',
                        color: AppColors.menta,
                        compacto: true,
                      ),
                    if (cata.tieneMedios)
                      ChipCata(
                        texto: cata.videos.isNotEmpty ? 'Vídeo' : 'Foto',
                        emoji: cata.videos.isNotEmpty ? '🎬' : '📷',
                        color: AppColors.superficieHonda,
                        compacto: true,
                      ),
                    // Una pregunta, una respuesta.
                    //
                    // Con "mi dieta" puesta, lo que importa no es qué dietas
                    // cumple la croqueta sino si TE vale, y esa pastilla sola
                    // lo contesta: poner además las etiquetas sería repetir
                    // lo mismo con más ruido. Sin dieta puesta se enseñan las
                    // etiquetas, que es lo único informativo que queda.
                    if (encaje.seEnsena)
                      ChipCata(
                        texto: encaje.nombre,
                        emoji: encaje.emoji,
                        color: encaje.color,
                        compacto: true,
                      )
                    else ...<Widget>[
                      for (final Dieta d in cata.dietas.take(2))
                        ChipCata(
                          texto: d.corto,
                          emoji: d.emoji,
                          color: d.color,
                          compacto: true,
                        ),
                      if (cata.dietas.length > 2)
                        ChipCata(
                          texto: '+${cata.dietas.length - 2}',
                          color: AppColors.superficieCalida,
                          compacto: true,
                        ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _Plato extends StatelessWidget {
  const _Plato({required this.cata, required this.color});

  final Cata cata;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final Medio? foto = cata.fotos.isEmpty ? null : cata.fotos.first;

    return Container(
      width: 86,
      height: 86,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppShape.radioM),
        border: Border.all(color: AppColors.tinta, width: AppShape.bordeFino),
      ),
      child: foto == null
          ? Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Positioned.fill(
                  child: CustomPaint(painter: const _PuntosPlato()),
                ),
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: ElCorte(
                    corte: cata.corte,
                    rellenoId: cata.rellenoId,
                    semilla: cata.id,
                    vapor: false,
                  ),
                ),
              ],
            )
          // Con foto manda la foto, y sólo la foto.
          //
          // Antes una foto tuya se reducía a una pastillita que ponía «📷
          // Foto» y el plato enseñaba el dibujo igualmente: quien se molesta
          // en fotografiar su croqueta no volvía a verla en el feed. Eso se
          // arregló poniendo la foto.
          //
          // Lo que había encima, un sello con el dibujo en la esquina, se ha
          // quitado. La idea era que todas las tarjetas se leyeran igual,
          // pero medía 30 px: a ese tamaño El Corte no se distingue, la
          // esquina redondeada de la miniatura le comía un trozo y lo que
          // quedaba parecía un fallo de pintado encima de la foto. El dibujo
          // sigue mandando en todas las catas sin foto y en la ficha
          // completa, que es donde se ve de verdad.
          : Stack(
              fit: StackFit.expand,
              children: <Widget>[
                // Por [FotoMedio] y no por Image.file: la foto puede estar
                // en este móvil, en la nube, o en ninguno de los dos. La de
                // tu gente sólo está en la nube, y la tuya también después de
                // reinstalar la app.
                FotoMedio(
                  medio: foto,
                  fit: BoxFit.cover,
                  // Sin foto que valga, el dibujo, que nunca falta.
                  siFalla: () => Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      Positioned.fill(
                        child: CustomPaint(painter: const _PuntosPlato()),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: ElCorte(
                          corte: cata.corte,
                          rellenoId: cata.rellenoId,
                          semilla: cata.id,
                          vapor: false,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _PuntosPlato extends CustomPainter {
  const _PuntosPlato();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint pincel = Paint()..color = Colors.white.withValues(alpha: 0.32);
    const double paso = 14;
    for (double y = paso / 2; y < size.height; y += paso) {
      for (double x = paso / 2; x < size.width; x += paso) {
        canvas.drawCircle(Offset(x, y), 2, pincel);
      }
    }
  }

  @override
  bool shouldRepaint(_PuntosPlato viejo) => false;
}
