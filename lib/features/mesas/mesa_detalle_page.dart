import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../arte/corte_painter.dart';
import '../../arte/croqui.dart';
import '../../core/data/rellenos.dart';
import '../../core/models/cata.dart';
import '../../core/models/mesa.dart';
import '../../core/models/persona.dart';
import '../../core/providers/catas_provider.dart';
import '../../core/providers/mesas_provider.dart';
import '../../core/theme/components/avatar.dart';
import '../../core/theme/components/boton.dart';
import '../../core/theme/components/cabecera.dart';
import '../../core/theme/components/nota.dart';
import '../../core/theme/components/pegatina.dart';
import '../../core/theme/tokens/app_colors.dart';
import '../../core/theme/tokens/app_shape.dart';
import '../../core/theme/tokens/app_spacing.dart';
import '../../core/theme/tokens/app_typography.dart';
import '../../core/services/compartir_service.dart';
import '../../core/utils/formato.dart';
import 'mesas_providers.dart';
import 'widgets/hoja_mesa.dart';
import '../vitrina/widgets/tarjeta_cata.dart';

/// Una mesa por dentro: quién manda, qué habéis vivido y todas sus catas.
class MesaDetallePage extends ConsumerWidget {
  const MesaDetallePage({super.key, required this.mesaId});

  final String mesaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Mesa? mesa = ref.watch(mesaProvider(mesaId));
    if (mesa == null) {
      return Column(
        children: <Widget>[
          Cabecera(titulo: 'Esta mesa ya no está', volver: () => context.pop()),
          const Spacer(),
          const Croqui(ancho: 140, conProps: false),
          const SizedBox(height: AppSpacing.l),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pantalla),
            child: Text(
              'Puede que la disolvierais o que el código ya no valga.\nPregunta a quien te invitó.',
              textAlign: TextAlign.center,
              style: AppTypography.cuerpo,
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          BotonPegatina.fantasma(
            texto: 'Ver mis mesas',
            icono: Icons.people_alt_rounded,
            onTap: () => context.go('/mesas'),
          ),
          const Spacer(),
        ],
      );
    }

    final List<Cata> catas = ref.watch(catasDeMesaProvider(mesaId));
    final Map<String, Persona> personas = ref.watch(personasProvider);
    final List<Recuerdo> recuerdos = ref.watch(recuerdosProvider(mesaId));
    final double? media = mediaDe(catas);

    // El ranking se monta en mesas_providers.dart: es trabajo de verdad y
    // aquí se recalculaba entero en cada pasada.
    final List<Puesto> ranking = ref.watch(rankingMesaProvider(mesaId));

    return ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pantalla,
            AppSpacing.s,
            AppSpacing.pantalla,
            0,
          ),
          child: Row(
            children: <Widget>[
              BotonRedondo(
                icono: Icons.arrow_back_ios_new_rounded,
                etiqueta: 'Volver',
                onTap: () => context.pop(),
              ),
              const Spacer(),
              if (!mesa.esLibreta)
                BotonRedondo(
                  icono: Icons.more_horiz_rounded,
                  etiqueta: 'Ajustes de la mesa',
                  onTap: () => _ajustes(context, ref, mesa),
                ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pantalla,
            AppSpacing.l,
            AppSpacing.pantalla,
            0,
          ),
          child: Column(
            children: <Widget>[
              Text(
                mesa.esPrivada ? 'MESA PRIVADA' : 'MESA COMPARTIDA · ${mesa.codigo}',
                style: AppTypography.antetitulo.copyWith(
                  color: AppColors.tintaSuave,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                mesa.nombre,
                textAlign: TextAlign.center,
                style: AppTypography.tituloXL,
              ),
              const SizedBox(height: 6),
              Text(
                mesa.descripcion,
                textAlign: TextAlign.center,
                style: AppTypography.cuerpoS.copyWith(
                  color: AppColors.tintaSuave,
                ),
              ),
              const SizedBox(height: AppSpacing.l),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _Cifra(
                      valor: '${catas.length}',
                      etiqueta: 'catas',
                      color: AppColors.chicle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: _Cifra(
                      valor: media == null ? '—' : Formato.nota(media),
                      etiqueta: 'nota media',
                      color: AppColors.cielo,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: _Cifra(
                      valor: '${mesa.miembros.length}',
                      etiqueta: mesa.miembros.length == 1 ? 'tú sola' : 'en la mesa',
                      color: AppColors.lima,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pantalla),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (mesa.miembros.length > 1) ...<Widget>[
                const SizedBox(height: AppSpacing.l),
                Pegatina(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const EtiquetaPanel(texto: 'Quién manda en la mesa'),
                      const SizedBox(height: AppSpacing.m),
                      for (int i = 0; i < ranking.length; i++)
                        _FilaRanking(puesto: i + 1, datos: ranking[i]),
                    ],
                  ),
                ),
              ],

              // El código, en su propio panel y no colgando del ranking: una
              // mesa recién creada todavía no tiene ranking que enseñar, y es
              // justo cuando más falta hace pasar el código.
              if (!mesa.esLibreta) ...<Widget>[
                const SizedBox(height: AppSpacing.l),
                Pegatina(
                  color: AppColors.menta,
                  lunares: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const EtiquetaPanel(texto: 'El código de la mesa'),
                      const SizedBox(height: AppSpacing.m),
                      Text(
                        mesa.codigo ?? '',
                        style: AppTypography.tituloXL.copyWith(
                          letterSpacing: 5,
                          color: AppColors.tinta,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Seis letras, sin íes ni oes: se dictan en una barra '
                        'con ruido sin que nadie se confunda.',
                        style: AppTypography.cuerpoS.copyWith(
                          fontSize: 12.5,
                          height: 1.3,
                          color: AppColors.tinta,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.l),
                      BotonPegatina(
                        texto: 'Mandarlo por WhatsApp',
                        pequeno: true,
                        icono: Icons.chat_bubble_rounded,
                        onTap: () => _invitarAMesa(context, mesa),
                      ),
                      const SizedBox(height: AppSpacing.s),
                      BotonPegatina.fantasma(
                        texto: 'Copiar el código',
                        pequeno: true,
                        icono: Icons.copy_rounded,
                        onTap: () => _copiarCodigo(context, mesa),
                      ),
                    ],
                  ),
                ),
              ],

              if (recuerdos.isNotEmpty) ...<Widget>[
                TituloSeccion(
                  texto: 'Recuerdos',
                  pastilla: Text('${recuerdos.length}', style: AppTypography.cifraM),
                ),
                for (final Recuerdo r in recuerdos)
                  _TarjetaRecuerdo(recuerdo: r),
              ],

              const TituloSeccion(texto: 'Todas las catas'),
              if (catas.isEmpty)
                Column(
                  children: <Widget>[
                    const Croqui(ancho: 150),
                    const SizedBox(height: AppSpacing.m),
                    Text(
                      'La libreta está en blanco.\nLo que catas aquí no lo ve nadie más.',
                      textAlign: TextAlign.center,
                      style: AppTypography.cuerpo,
                    ),
                  ],
                )
              else
                for (final Cata c in catas) ...<Widget>[
                  TarjetaCata(
                    cata: c,
                    autor: personas[c.autorId] ?? Persona.desconocida,
                    onTap: () => context.push('/cata/${c.id}'),
                  ),
                  const SizedBox(height: AppSpacing.m),
                ],
              const SizedBox(height: AppSpacing.huecoBarra),
            ],
          ),
        ),
      ],
    );
  }

  /// Copia el código al portapapeles. Sigue teniendo sentido aunque ya se
  /// pueda mandar por WhatsApp: a veces se pega en un grupo de Telegram, o en
  /// las notas, o se dicta en la barra mirando la pantalla.
  static void _copiarCodigo(BuildContext context, Mesa mesa) {
    HapticFeedback.mediumImpact();
    Clipboard.setData(ClipboardData(text: mesa.codigo ?? ''));
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text('Código ${mesa.codigo} copiado.')),
      );
  }

  static Future<void> _invitarAMesa(BuildContext context, Mesa mesa) async {
    final bool abierto = await CompartirService.porWhatsApp(
      CompartirService.invitacionMesa(mesa),
    );
    if (!abierto && context.mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('No se ha podido abrir WhatsApp.')),
        );
    }
  }

  /// Ajustes de la mesa: cambiarla, mandar el código o borrarla.
  static Future<void> _ajustes(
    BuildContext context,
    WidgetRef ref,
    Mesa mesa,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext hoja) => Container(
        margin: const EdgeInsets.all(AppSpacing.s),
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
            Text(mesa.nombre, style: AppTypography.tituloM),
            const SizedBox(height: AppSpacing.l),
            BotonPegatina(
              texto: 'Cambiar nombre y color',
              icono: Icons.edit_rounded,
              pequeno: true,
              onTap: () async {
                Navigator.of(hoja).pop();
                await hojaMesa(context, mesa: mesa);
              },
            ),
            const SizedBox(height: AppSpacing.s),
            BotonPegatina.fantasma(
              texto: 'Mandar el código por WhatsApp',
              icono: Icons.chat_bubble_rounded,
              pequeno: true,
              onTap: () {
                Navigator.of(hoja).pop();
                _invitarAMesa(context, mesa);
              },
            ),
            const SizedBox(height: AppSpacing.s),
            BotonPegatina(
              texto: 'Borrar la mesa',
              color: AppColors.tomate,
              icono: Icons.delete_outline_rounded,
              pequeno: true,
              onTap: () async {
                Navigator.of(hoja).pop();
                await _confirmarBorrado(context, ref, mesa);
              },
            ),
            const SizedBox(height: AppSpacing.s),
            BotonPegatina.fantasma(
              texto: 'Cerrar',
              pequeno: true,
              onTap: () => Navigator.of(hoja).pop(),
            ),
          ],
        ),
      ),
    );
  }

  /// Borrar la mesa no borra sus catas: se van a la libreta.
  ///
  /// Es la diferencia entre ordenar y perder, y el diálogo lo dice con el
  /// número delante para que nadie tenga que suponerlo.
  static Future<void> _confirmarBorrado(
    BuildContext context,
    WidgetRef ref,
    Mesa mesa,
  ) async {
    final int cuantas = ref
        .read(catasDeMesaProvider(mesa.id))
        .length;

    final bool seguro = await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogo) => AlertDialog(
            backgroundColor: AppColors.superficie,
            title: Text('¿Borrar «${mesa.nombre}»?'),
            content: Text(
              cuantas == 0
                  ? 'No tiene ninguna cata dentro, así que no se pierde nada.'
                  : 'Sus ${Formato.plural(cuantas, 'cata', 'catas')} no se '
                      'borran: pasan a tu libreta. Lo que desaparece es la '
                      'mesa y su código.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogo).pop(false),
                child: const Text('Quedármela'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogo).pop(true),
                child: const Text('Borrar'),
              ),
            ],
          ),
        ) ??
        false;

    if (!seguro) return;
    await ref.read(mesasProvider.notifier).borrar(mesa.id);
    await HapticFeedback.heavyImpact();
    if (context.mounted) context.go('/mesas');
  }
}

class _FilaRanking extends StatelessWidget {
  const _FilaRanking({required this.puesto, required this.datos});

  final int puesto;
  final Puesto datos;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: puesto == 1
            ? null
            : Border(
                top: BorderSide(
                  color: AppColors.tinta.withValues(alpha: 0.22),
                  width: 2,
                ),
              ),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 24,
            child: Text(
              '$puesto',
              textAlign: TextAlign.center,
              style: AppTypography.cifraS.copyWith(
                color: puesto == 1
                    ? AppColors.tinta
                    : AppColors.tintaSuave,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          Avatar(persona: datos.persona),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(datos.persona.nombre, style: AppTypography.etiqueta.copyWith(fontSize: 14)),
                Text(
                  Formato.plural(datos.catas, 'cata', 'catas'),
                  style: AppTypography.cuerpoS.copyWith(
                    fontSize: 12,
                    color: AppColors.tintaSuave,
                  ),
                ),
              ],
            ),
          ),
          if (datos.media != null)
            Nota(valor: datos.media!)
          else
            Text('—', style: AppTypography.cifraS),
        ],
      ),
    );
  }
}

class _TarjetaRecuerdo extends StatelessWidget {
  const _TarjetaRecuerdo({required this.recuerdo});

  final Recuerdo recuerdo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.m),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Column(
              children: <Widget>[
                Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: AppColors.tomate,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.tinta, width: 2.5),
                  ),
                ),
                Expanded(
                  child: Container(width: 4, color: AppColors.tinta),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${Formato.relativo(recuerdo.cuando).toUpperCase()} · ${recuerdo.lugar.toUpperCase()}',
                    style: AppTypography.antetitulo.copyWith(
                      fontSize: 10.5,
                      color: AppColors.tintaSuave,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(recuerdo.titulo, style: AppTypography.tituloS),
                  const SizedBox(height: 4),
                  Text(
                    recuerdo.texto,
                    style: AppTypography.cuerpoS.copyWith(
                      color: AppColors.tintaSuave,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  Row(
                    children: <Widget>[
                      for (final String id in recuerdo.catas)
                        _MiniCorte(cataId: id),
                      Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        margin: const EdgeInsets.only(left: 4),
                        decoration: BoxDecoration(
                          color: AppColors.sol,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.tinta, width: 2),
                        ),
                        child: Text(
                          '${recuerdo.quien.length}',
                          style: AppTypography.etiqueta.copyWith(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniCorte extends ConsumerWidget {
  const _MiniCorte({required this.cataId});

  final String cataId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Cata? cata = ref.watch(cataProvider(cataId));
    if (cata == null) return const SizedBox.shrink();

    // El dibujo no dice nada a un lector de pantalla: sin esto es un botón
    // sin nombre, indistinguible de no estar ahí.
    return Semantics(
      button: true,
      label: '${cata.sitio}, nota ${Formato.nota(cata.puntuacion)}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => context.push('/cata/${cata.id}'),
        child: Container(
          width: 50,
          height: 50,
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.all(3),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Rellenos.de(cata.rellenoId).color,
            borderRadius: BorderRadius.circular(AppShape.radioS),
            border: Border.all(color: AppColors.tinta, width: 2),
          ),
          child: ElCorte(
            corte: cata.corte,
            rellenoId: cata.rellenoId,
            semilla: cata.id,
            vapor: false,
          ),
        ),
      ),
    );
  }
}

class _Cifra extends StatelessWidget {
  const _Cifra({required this.valor, required this.etiqueta, required this.color});

  final String valor;
  final String etiqueta;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Pegatina(
      color: color,
      radio: AppShape.radioM,
      sombra: AppShape.sombraChica,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(valor, style: AppTypography.cifraM.copyWith(fontSize: 28)),
          const SizedBox(height: 2),
          Text(
            etiqueta,
            textAlign: TextAlign.center,
            style: AppTypography.etiqueta.copyWith(fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}
