import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../arte/corte_painter.dart';
import '../../../core/data/rellenos.dart';
import '../../../core/models/corte.dart';
import '../../../core/models/sabor.dart';
import '../../../core/providers/borrador_provider.dart';
import '../../../core/theme/components/campo.dart';
import '../../../core/theme/components/pildoras_relleno.dart';
import '../../../core/theme/components/pegatina.dart';
import '../../../core/theme/components/segmentado.dart';
import '../widgets/selector_racion.dart';
import '../../../core/theme/tokens/app_colors.dart';
import '../../../core/theme/tokens/app_shape.dart';
import '../../../core/theme/tokens/app_spacing.dart';
import '../../../core/theme/tokens/app_typography.dart';
import '../../../core/utils/formato.dart';

/// Paso 2: qué has pedido.
///
/// Una croqueta o un surtido. Es la pregunta que cambia toda la cata, y por
/// eso va antes que nada: en un surtido no tiene sentido pedir "el relleno",
/// porque hay cuatro, y la gracia está justo en que no todos valen lo mismo.
class PasoSabores extends ConsumerWidget {
  const PasoSabores({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Borrador borrador = ref.watch(borradorProvider);
    final BorradorNotifier notifier = ref.read(borradorProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SelectorRacion(),
        const SizedBox(height: AppSpacing.xl),
        Segmentado<bool>(
          seleccion: borrador.surtido,
          onCambio: notifier.modoSurtido,
          colorActivo: AppColors.tomate,
          opciones: const <bool, String>{
            false: 'Una croqueta',
            true: 'Un surtido',
          },
        ),
        const SizedBox(height: AppSpacing.l),
        if (borrador.surtido)
          const _Surtido()
        else
          const _CroquetaSuelta(),
      ],
    );
  }
}

/// ─────────────────────────────── una sola ───────────────────────────────
class _CroquetaSuelta extends ConsumerWidget {
  const _CroquetaSuelta();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Borrador borrador = ref.watch(borradorProvider);
    final BorradorNotifier notifier = ref.read(borradorProvider.notifier);
    final Sabor? sabor =
        borrador.sabores.isEmpty ? null : borrador.sabores.first;
    final Set<String> elegidos = sabor?.ids.toSet() ?? <String>{};
    final bool vacia = sabor == null;
    final Relleno relleno = Rellenos.de(borrador.rellenoVisible);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Elige lo que lleva. Puedes marcar varios: una croqueta de jamón y '
          'boletus es una croqueta de jamón y boletus. El primero que elijas '
          'le da el color en toda la app.',
          style: AppTypography.cuerpoS.copyWith(
            color: AppColors.tintaSuave,
            height: 1.35,
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        PildorasRelleno(
          elegidos: elegidos,
          onAlternar: notifier.alternarRelleno,
          propio: sabor?.propio ?? '',
          onPropio: notifier.rellenoPropio,
        ),
        const SizedBox(height: AppSpacing.xl),
        Pegatina(
          color: vacia
              ? AppColors.superficie
              : Color.lerp(relleno.color, Colors.white, 0.78)!,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.l),
          child: vacia
              ? Text(
                  'Elige un relleno y aparece aquí',
                  textAlign: TextAlign.center,
                  style: AppTypography.cuerpoS.copyWith(
                    color: AppColors.tintaSuave,
                  ),
                )
              : Column(
                  children: <Widget>[
                    ElCorte(
                      corte: borrador.corte,
                      rellenoId: relleno.id,
                      semilla: 'vista-${relleno.id}',
                      ancho: 180,
                    ),
                    const SizedBox(height: AppSpacing.s),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.m,
                      ),
                      child: Text(
                        '${relleno.emoji}  ${sabor.nombre}',
                        textAlign: TextAlign.center,
                        style: AppTypography.tituloS,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

/// ──────────────────────────────── surtido ───────────────────────────────
class _Surtido extends ConsumerStatefulWidget {
  const _Surtido();

  @override
  ConsumerState<_Surtido> createState() => _SurtidoState();
}

class _SurtidoState extends ConsumerState<_Surtido> {
  /// En orden: el primero manda y da el color.
  final List<String> _rellenos = <String>[];
  String _propio = '';
  Veredicto _veredicto = Veredicto.porDefecto;

  void _alternar(String id) {
    setState(() {
      _rellenos.contains(id) ? _rellenos.remove(id) : _rellenos.add(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final Borrador borrador = ref.watch(borradorProvider);
    final BorradorNotifier notifier = ref.read(borradorProvider.notifier);
    final List<Sabor> sabores = borrador.sabores;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Añade cada sabor con su propia nota. En una ración variada casi '
          'nunca están todas igual de buenas, y eso es justo lo que hay que '
          'contar.',
          style: AppTypography.cuerpoS.copyWith(
            color: AppColors.tintaSuave,
          ),
        ),
        const SizedBox(height: AppSpacing.l),

        // ── Lo que ya lleva el surtido ────────────────────────────────────
        if (sabores.isNotEmpty) ...<Widget>[
          for (int i = 0; i < sabores.length; i++) ...<Widget>[
            _FilaSabor(
              sabor: sabores[i],
              onVeredicto: (Veredicto v) => notifier.veredictoDe(i, v),
              onQuitar: () => notifier.quitarSabor(i),
            ),
            const SizedBox(height: AppSpacing.s),
          ],
          const SizedBox(height: AppSpacing.s),
          _ResumenSurtido(sabores: sabores),
          const SizedBox(height: AppSpacing.l),
        ],

        // ── Añadir uno nuevo ──────────────────────────────────────────────
        Pegatina(
          discontinuo: true,
          color: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                sabores.isEmpty ? 'PRIMER SABOR' : 'AÑADIR OTRO SABOR',
                style: AppTypography.antetitulo,
              ),
              const SizedBox(height: AppSpacing.m),
              PildorasRelleno(
                elegidos: _rellenos.toSet(),
                onAlternar: _alternar,
                propio: _propio,
                onPropio: (String v) => setState(() => _propio = v),
              ),
              const SizedBox(height: AppSpacing.l),
              Text('¿QUÉ TAL ESTABAN?', style: AppTypography.antetitulo),
              const SizedBox(height: AppSpacing.m),
              _PildorasVeredicto(
                elegido: _veredicto,
                onCambio: (Veredicto v) => setState(() => _veredicto = v),
              ),
              const SizedBox(height: AppSpacing.l),
              _BotonAnadir(
                activo: _rellenos.isNotEmpty,
                onTap: () {
                  notifier.anadirSabor(
                    Sabor(
                      rellenoId: _rellenos.first,
                      otros: _rellenos.sublist(1),
                      propio: _propio,
                      veredicto: _veredicto,
                    ),
                  );
                  setState(() {
                    _rellenos.clear();
                    _propio = '';
                    _veredicto = Veredicto.porDefecto;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilaSabor extends StatelessWidget {
  const _FilaSabor({
    required this.sabor,
    required this.onVeredicto,
    required this.onQuitar,
  });

  final Sabor sabor;
  final ValueChanged<Veredicto> onVeredicto;
  final VoidCallback onQuitar;

  @override
  Widget build(BuildContext context) {
    final Relleno relleno = Rellenos.de(sabor.rellenoId);

    return Pegatina(
      color: Color.lerp(relleno.color, Colors.white, 0.82)!,
      sombra: const Offset(2, 2),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 46,
            child: ElCorte(
              corte: const Corte(crujiente: 7, cremosidad: 7, sabor: 7, relleno: 7),
              rellenoId: relleno.id,
              semilla: 'sabor-${sabor.ids.join()}',
              vapor: false,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  sabor.nombre,
                  style: AppTypography.etiqueta.copyWith(fontSize: 13.5),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                GestureDetector(
                  onTap: () async {
                    final Veredicto? nuevo =
                        await _elegirVeredicto(context, sabor.veredicto);
                    if (nuevo != null) onVeredicto(nuevo);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.superficie,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.tinta, width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(sabor.veredicto.emoji,
                            style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 5),
                        Text(
                          sabor.veredicto.nombre,
                          style: AppTypography.etiqueta.copyWith(fontSize: 12),
                        ),
                        const SizedBox(width: 3),
                        const Icon(Icons.expand_more_rounded, size: 15),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onQuitar,
            icon: const Icon(Icons.close_rounded),
            color: AppColors.tinta,
            tooltip: 'Quitar del surtido',
          ),
        ],
      ),
    );
  }
}

class _ResumenSurtido extends StatelessWidget {
  const _ResumenSurtido({required this.sabores});

  final List<Sabor> sabores;

  @override
  Widget build(BuildContext context) {
    double suma = 0;
    for (final Sabor s in sabores) {
      suma += s.veredicto.valor;
    }
    final double media = suma / sabores.length;

    final Sabor mejor = sabores.reduce((Sabor a, Sabor b) =>
        b.veredicto.valor > a.veredicto.valor ? b : a);
    final Sabor peor = sabores.reduce((Sabor a, Sabor b) =>
        b.veredicto.valor < a.veredicto.valor ? b : a);

    return Pegatina(
      color: AppColors.menta,
      sombra: AppShape.sombraChica,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'EL SURTIDO, DE MOMENTO',
            style: AppTypography.antetitulo.copyWith(fontSize: 10.5),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            '${sabores.length} sabores · media ${Formato.nota(media)}',
            style: AppTypography.tituloS,
          ),
          if (sabores.length > 1) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              'Salva la ración la de ${Rellenos.de(mejor.rellenoId).nombre.toLowerCase()}'
              '${mejor.rellenoId == peor.rellenoId ? '' : '; la peor, la de ${Rellenos.de(peor.rellenoId).nombre.toLowerCase()}'}.',
              style: AppTypography.cuerpoS.copyWith(fontSize: 12.5),
            ),
          ],
        ],
      ),
    );
  }
}

class _PildorasVeredicto extends StatelessWidget {
  const _PildorasVeredicto({required this.elegido, required this.onCambio});

  final Veredicto elegido;
  final ValueChanged<Veredicto> onCambio;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final Veredicto v in Veredicto.values)
          OpcionPildora(
            texto: v.nombre,
            emoji: v.emoji,
            activa: v == elegido,
            onTap: () => onCambio(v),
          ),
      ],
    );
  }
}

class _BotonAnadir extends StatelessWidget {
  const _BotonAnadir({required this.activo, required this.onTap});

  final bool activo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Apagado y mudo, este botón parecía estropeado: se toca, no pasa
        // nada y no hay forma de saber por qué.
        if (!activo) ...<Widget>[
          Text(
            'Elige antes de qué es este sabor',
            textAlign: TextAlign.center,
            style: AppTypography.cuerpoS.copyWith(
              fontSize: 12.5,
              color: AppColors.tintaSuave,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
        ],
        Pegatina(
          color: activo ? AppColors.tomate : AppColors.superficieCalida,
          radio: AppShape.radioPildora,
          sombra: activo ? AppShape.sombraNormal : AppShape.sombraChica,
          alto: 50,
          padding: EdgeInsets.zero,
          alineacion: Alignment.center,
          onTap: activo ? onTap : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.add_rounded,
                color: activo ? Colors.white : AppColors.tintaApagada,
              ),
              const SizedBox(width: 8),
              Text(
                'Añadir al surtido',
                style: AppTypography.boton.copyWith(
                  fontSize: 16,
                  color: activo ? Colors.white : AppColors.tintaApagada,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Hoja para cambiar el veredicto de un sabor ya añadido.
Future<Veredicto?> _elegirVeredicto(BuildContext context, Veredicto actual) {
  return showModalBottomSheet<Veredicto>(
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
          Text('¿Qué tal estaban?', style: AppTypography.tituloM),
          const SizedBox(height: AppSpacing.l),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final Veredicto v in Veredicto.values)
                OpcionPildora(
                  texto: v.nombre,
                  emoji: v.emoji,
                  activa: v == actual,
                  onTap: () => Navigator.of(hoja).pop(v),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
        ],
      ),
    ),
  );
}
