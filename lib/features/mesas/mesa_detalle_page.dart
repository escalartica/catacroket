import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../arte/corte_painter.dart';
import '../../arte/croqui.dart';
import '../../core/data/rellenos.dart';
import '../../core/errores.dart';
import '../../core/models/cata.dart';
import '../../core/models/mesa.dart';
import '../../core/models/recuento.dart';
import '../cuenta/hoja_cuenta.dart';
import '../../core/services/nube_service.dart';
import '../../core/providers/cuenta_provider.dart';
import '../../core/models/persona.dart';
import '../../core/providers/catas_provider.dart';
import '../../core/providers/mesas_provider.dart';
import '../../core/providers/nube_provider.dart';
import '../../core/providers/yo_provider.dart';
import '../../core/theme/components/avatar.dart';
import '../../core/theme/components/entrada.dart';
import '../../core/theme/components/cifra.dart';
import '../../core/providers/borrador_provider.dart';
import '../../core/theme/components/boton.dart';
import '../../core/theme/components/cabecera.dart';
import '../../core/theme/components/nota.dart';
import '../../core/theme/components/pegatina.dart';
import '../../core/theme/tokens/app_colors.dart';
import '../../core/theme/tokens/app_motion.dart';
import '../../core/theme/tokens/app_shape.dart';
import '../../core/theme/tokens/app_spacing.dart';
import '../../core/theme/tokens/app_typography.dart';
import '../../core/services/compartir_service.dart';
import '../../core/utils/formato.dart';
import 'mesas_providers.dart';
import 'widgets/hoja_mesa.dart';
import '../vitrina/widgets/tarjeta_cata.dart';
import 'widgets/hoja_nombre.dart';

/// Una mesa por dentro: quién manda, qué habéis vivido y todas sus catas.
class MesaDetallePage extends ConsumerWidget {
  const MesaDetallePage({super.key, required this.mesaId});

  final String mesaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // También aquí: a la ficha se puede llegar recién entrada con el código,
    // sin haber pasado por la lista.
    ref.watch(miembrosAlDiaProvider);

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
                // Por `enLaNube` y no por `esPrivada`. `esPrivada` sólo mira
                // si hay código, y toda mesa nace con uno puesto en el móvil,
                // así que una mesa recién creada se titulaba «MESA COMPARTIDA
                // · ABCDEF» mientras el panel de abajo, en esta misma
                // pantalla, decía que ese código todavía no funcionaba.
                mesa.esPrivada
                    ? 'MESA PRIVADA'
                    : mesa.enLaNube
                        ? 'MESA COMPARTIDA · ${mesa.codigo}'
                        : 'MESA SIN ACTIVAR',
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
              // En una fila que se parte en dos con la letra grande: ver
              // `FilaDeCifras`.
              FilaDeCifras(
                cifras: <Cifra>[
                  Cifra(
                    valor: '${catas.length}',
                    numero: catas.length.toDouble(),
                    etiqueta: catas.length == 1 ? 'cata' : 'catas',
                    color: AppColors.chicle,
                  ),
                  Cifra(
                    valor: '—',
                    numero: media,
                    decimales: 1,
                    etiqueta: 'nota media',
                    color: AppColors.cielo,
                  ),
                  Cifra(
                    valor: '${mesa.miembros.length}',
                    numero: mesa.miembros.length.toDouble(),
                    // «tú sola» daba por hecho el sexo de quien lo lee, y
                    // la lista de mesas resolvía lo mismo con otras
                    // palabras. Una sola forma, y sin género.
                    etiqueta:
                        mesa.miembros.length == 1 ? 'sólo tú' : 'en la mesa',
                    color: AppColors.lima,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Apuntar una croqueta DESDE la mesa en la que estás.
        //
        // El botón rojo de la barra abre la cata nueva sin destino, así que
        // estando dentro de una mesa había que acordarse de volver a
        // elegirla en el último paso. Nadie lo hacía: la croqueta se
        // apuntaba, se quedaba en el diario y la mesa seguía a cero. Desde
        // aquí la mesa viene ya puesta.
        //
        // A lo ancho y debajo de las cifras, no metido en la cabecera: ahí
        // arriba, entre los dos botones redondos, no cabía y el texto salía
        // partido en dos líneas.
        if (!mesa.esLibreta)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pantalla,
              AppSpacing.l,
              AppSpacing.pantalla,
              0,
            ),
            child: BotonPegatina(
              texto: 'Apuntar una croqueta aquí',
              icono: Icons.add_rounded,
              color: AppColors.tomate,
              onTap: () {
                ref.read(borradorProvider.notifier).empezarEnMesa(mesa.id);
                context.push('/nueva');
              },
            ),
          ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pantalla),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const TituloSeccion(texto: 'Todas las catas'),
              if (catas.isEmpty)
                Column(
                  children: <Widget>[
                    const Croqui(ancho: 150),
                    const SizedBox(height: AppSpacing.m),
                    Text(
                      // Tres mesas vacías distintas, tres frases distintas.
                      // La de siempre («no lo ve nadie más») prometía
                      // intimidad en una mesa con gente dentro, que es
                      // justo lo contrario de lo que pasa.
                      mesa.esLibreta
                          ? 'Tu diario está en blanco.\nApunta tu primera croqueta con el botón rojo.'
                          : mesa.esPrivada
                          ? 'La libreta está en blanco.\nLo que catas aquí no lo ve nadie más.'
                          : mesa.miembros.length > 1
                              ? 'Aún no hay ninguna croqueta.\nLa primera que apuntes la ve toda la mesa.'
                              : 'La mesa está puesta y vacía.\nApunta una croqueta o pasa el código.',
                      textAlign: TextAlign.center,
                      style: AppTypography.cuerpo,
                    ),
                  ],
                )
              else
                for (int i = 0; i < catas.length; i++) ...<Widget>[
                  Entrada(
                    key: ValueKey<String>(catas[i].id),
                    indice: i,
                    child: TarjetaCata(
                      cata: catas[i],
                      // Por cuenta primero: una cata que llegó de otro
                      // móvil sólo se puede atribuir así. El identificador
                      // local vale para las de antes de que hubiera cuentas.
                      autor: personas[catas[i].autorUid] ??
                          personas[catas[i].autorId] ??
                          Persona.desconocida,
                      onTap: () => context.push('/cata/${catas[i].id}'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),
                ],

              if (mesa.miembros.length > 1) ...<Widget>[
                const SizedBox(height: AppSpacing.l),
                Pegatina(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const EtiquetaPanel(texto: 'Quién manda en la mesa'),
                      const SizedBox(height: AppSpacing.m),
                      // Con fundido al reordenarse. Cuando llega la cata de
                      // alguien de la mesa, los puestos cambian solos; sin
                      // esto el cambio ocurre entre dos fotogramas y, si no
                      // estabas mirando ese rincón, parece que siempre
                      // estuvieron así. El ranking es la mitad de la gracia
                      // de compartir mesa: que se vea moverse es el premio.
                      AnimatedSwitcher(
                        duration: AppMotion.normal,
                        switchInCurve: AppMotion.entrada,
                        child: Column(
                          key: ValueKey<String>(
                            ranking
                                .map((Puesto p) =>
                                    '${p.persona.id}:${p.catas}')
                                .join('|'),
                          ),
                          children: <Widget>[
                            for (int i = 0; i < ranking.length; i++)
                              _FilaRanking(puesto: i + 1, datos: ranking[i]),
                          ],
                        ),
                      ),

                      // Cómo te ven los demás, y cómo cambiarlo, aquí
                      // mismo. Sale siempre: sin nombre para avisar de que
                      // apareces como «Alguien», y con nombre para poder
                      // cambiarlo sin ir a buscarlo al perfil, que es donde
                      // nadie lo busca estando en la mesa.
                      const SizedBox(height: AppSpacing.m),
                      _ComoTeVen(mesa: mesa),
                    ],
                  ),
                ),
              ],
              // Cuántas de cada clase lleváis.
              //
              // Cuenta croquetas y no catas: un surtido de seis es una cata
              // pero son seis croquetas, y de seis clases distintas.
              // Desde tres: con una cata el reparto es una barra al 100 %
              // que no cuenta nada, y con dos tampoco hay reparto que ver.
              if (catas.length >= 3) ...<Widget>[
                const SizedBox(height: AppSpacing.l),
                _RecuentoPorClase(catas: catas),
              ],

              if (recuerdos.isNotEmpty) ...<Widget>[
                TituloSeccion(
                  texto: 'Recuerdos',
                  pastilla: Text('${recuerdos.length}', style: AppTypography.cifraM),
                ),
                for (final Recuerdo r in recuerdos)
                  _TarjetaRecuerdo(recuerdo: r),
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

                      // Dos estados, y nunca los dos a la vez. Antes los
                      // botones de invitar salían siempre, grises mientras la
                      // mesa no estuviera subida, y un botón gris sin
                      // explicación sólo genera la pregunta «¿por qué no
                      // puedo?». Ahora, o se activa o se reparte.
                      if (!mesa.enLaNube) ...<Widget>[
                        Text(
                          'Este código todavía no funciona: la mesa está sólo '
                          'en tu móvil. Actívalo y ya podrás repartirlo.',
                          style: AppTypography.cuerpoS.copyWith(
                            fontSize: 12.5,
                            height: 1.3,
                            color: AppColors.tinta,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s),
                        _BotonCompartir(mesa: mesa),
                      ] else ...<Widget>[
                        BotonPegatina(
                          texto: 'Invitar por WhatsApp',
                          pequeno: true,
                          icono: Icons.chat_bubble_rounded,
                          onTap: () => _invitarAMesa(context, mesa),
                        ),
                        const SizedBox(height: AppSpacing.s),
                        BotonPegatina.fantasma(
                          texto: 'Copiar la invitación',
                          pequeno: true,
                          icono: Icons.copy_rounded,
                          onTap: () => _copiarCodigo(context, mesa),
                        ),
                        const SizedBox(height: AppSpacing.s),
                        BotonPegatina.fantasma(
                          texto: 'Copiar sólo el código',
                          pequeno: true,
                          icono: Icons.tag_rounded,
                          onTap: () => _copiarSoloCodigo(context, mesa),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.huecoBarra),
            ],
          ),
        ),
      ],
    );
  }

  /// Copia la invitación entera: el código y qué hacer con él.
  ///
  /// Es lo que se pega en un grupo de Telegram o en un correo. Seis letras
  /// sueltas no le dicen nada a quien las recibe.
  static void _copiarCodigo(BuildContext context, Mesa mesa) {
    HapticFeedback.mediumImpact();
    Clipboard.setData(
      ClipboardData(text: CompartirService.invitacionMesa(mesa)),
    );
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(content: Text('Invitación copiada, con el código.')),
      );
  }

  /// Sólo las seis letras, para quien ya sabe de qué va y únicamente
  /// necesita el código.
  static void _copiarSoloCodigo(BuildContext context, Mesa mesa) {
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
      // Por el Navigator raíz: dentro de la concha, la barra de pestañas se
      // dibuja encima de la hoja y le tapa los botones de abajo.
      useRootNavigator: true,
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

    if (!seguro || !context.mounted) return;

    // El mensajero se coge antes de navegar: en cuanto se va de esta pantalla,
    // su contexto ya no sirve para pedirlo.
    final ScaffoldMessengerState mensajero = ScaffoldMessenger.of(context);

    final int movidas;
    try {
      movidas = await ref.read(mesasProvider.notifier).borrar(mesa.id);
    } on FalloNube catch (e) {
      // Borrar una mesa compartida exige avisar al servidor. Si no se puede,
      // la mesa se queda: dejarla desaparecer del móvil sabiendo que volverá
      // sola mañana es lo que había antes y es peor que no borrarla.
      mensajero
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text('${e.mensaje} No se ha borrado.')));
      return;
    } catch (error, pila) {
      Errores.registrar(error, pila, origen: 'mesa.borrar');
      mensajero
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('No se ha podido borrar la mesa.')),
        );
      return;
    }

    await HapticFeedback.heavyImpact();
    if (!context.mounted) return;
    context.go('/mesas');

    // El diálogo prometió que las catas no se pierden; esto lo confirma una
    // vez hecho, que es cuando de verdad tranquiliza. Antes se navegaba en
    // silencio: la mesa desaparecía de la lista y había que fiarse de que lo
    // que catasteis estaba en alguna parte.
    mensajero
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            movidas == 0
                ? '«${mesa.nombre}» borrada.'
                : '«${mesa.nombre}» borrada. '
                    '${Formato.plural(movidas, 'cata', 'catas')} '
                    '${movidas == 1 ? 'sigue' : 'siguen'} en tu diario.',
          ),
        ),
      );
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
      onTap: () => context.push('/cata/${cata.id}'),
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


/// Cuántas croquetas de cada clase lleva la mesa.
///
/// Sólo las seis primeras: una mesa con veinte años de catas tendría cuarenta
/// filas y nadie las lee. Lo que interesa es qué mandáis pidiendo.
class _RecuentoPorClase extends StatelessWidget {
  const _RecuentoPorClase({required this.catas});

  final List<Cata> catas;

  @override
  Widget build(BuildContext context) {
    final List<Recuento> todas = Recuento.de(catas);
    if (todas.isEmpty) return const SizedBox.shrink();

    final List<Recuento> arriba = todas.take(6).toList();
    final int resto = todas.length - arriba.length;
    final int mayor = arriba.first.cuantas;

    return Pegatina(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const EtiquetaPanel(texto: 'Las croquetas que más pedís'),
          const SizedBox(height: AppSpacing.m),
          for (final Recuento r in arriba) ...<Widget>[
            Row(
              children: <Widget>[
                Text(r.emoji, style: const TextStyle(fontSize: 15)),
                const SizedBox(width: 8),
                // Flexible: los nombres de relleno pueden ser largos y el
                // usuario escribe los suyos.
                Flexible(
                  child: Text(
                    r.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.cuerpoS,
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                // La barra es proporcional a la más pedida, no al total: con
                // veinte clases distintas todas las barras saldrían mínimas y
                // no se compararía nada.
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: r.cuantas / mayor,
                      minHeight: 6,
                      backgroundColor: AppColors.superficieCalida,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.uva,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                Text(
                  '${r.cuantas}',
                  style: AppTypography.tituloS.copyWith(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s),
          ],
          if (resto > 0)
            Text(
              resto == 1 ? 'y una clase más' : 'y $resto clases más',
              style: AppTypography.cuerpoS.copyWith(
                fontSize: 12.5,
                color: AppColors.tintaSuave,
              ),
            ),
        ],
      ),
    );
  }
}

/// Sube la mesa para que su gente pueda verla.
///
/// Pide cuenta si no la hay, porque el servidor necesita saber a quién está
/// metiendo en la mesa. Se ofrece entrar ahí mismo en vez de mandar a nadie
/// a buscarlo al perfil.
class _BotonCompartir extends ConsumerStatefulWidget {
  const _BotonCompartir({required this.mesa});

  final Mesa mesa;

  @override
  ConsumerState<_BotonCompartir> createState() => _BotonCompartirState();
}

class _BotonCompartirState extends ConsumerState<_BotonCompartir> {
  bool _subiendo = false;

  Future<void> _compartir() async {
    if (!ref.read(haySesionProvider)) {
      final bool entro = await hojaCuenta(context);
      if (!entro) return;
    }

    // Se coge la barra ANTES de cualquier await que pueda seguir: tras la
    // hoja de cuenta el contexto puede haber dejado de ser válido.
    if (!mounted) return;
    final ScaffoldMessengerState barra = ScaffoldMessenger.of(context);
    setState(() => _subiendo = true);

    try {
      await ref.read(mesasProvider.notifier).compartir(widget.mesa.id);

      // Quien abre la mesa también necesita nombre: si no, su gente le ve
      // como «Alguien» en su propia mesa.
      if (mounted) {
        await hojaNombre(
          context,
          ref,
          motivo: 'Tu mesa ya está activa. Ponte un nombre para que quien '
              'entre sepa quién la ha abierto.',
        );
      }

      barra
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Código activado. Ya puedes invitar a tu gente.',
            ),
          ),
        );
    } on FalloNube catch (e) {
      barra
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(e.mensaje)));
    } finally {
      if (mounted) setState(() => _subiendo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BotonPegatina(
      texto: _subiendo ? 'Activando…' : 'Activar el código',
      pequeno: true,
      icono: Icons.cloud_upload_rounded,
      onTap: _subiendo ? null : _compartir,
    );
  }
}

/// Cómo te ve tu gente en esta mesa, y cómo cambiarlo.
///
/// Sin nombre avisa de que sales como «Alguien»; con nombre lo enseña y deja
/// cambiarlo. Las dos cosas en el mismo sitio porque la pregunta («¿cómo me
/// ven?») y el arreglo («cámbialo») son la misma.
class _ComoTeVen extends ConsumerWidget {
  const _ComoTeVen({required this.mesa});

  final Mesa mesa;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Yo yo = ref.watch(yoProvider);
    final bool tiene = yo.tieneNombrePropio;

    // Pegatina y no un Container con GestureDetector: lleva chevrón, o sea
    // que promete llevar a algún sitio, y no se hundía al tocarlo, no vibraba
    // y no se anunciaba como botón. El tema apaga las ondas de Material a
    // propósito, así que tocarlo no producía absolutamente nada hasta que
    // aparecía la hoja. Y es el único sitio donde cambiar cómo te ve tu gente
    // está a mano estando en la mesa.
    return Pegatina(
      onTap: () => hojaNombre(
        context,
        ref,
        forzar: true,
        motivo: tiene
            ? 'Así es como te ve tu gente de «${mesa.nombre}».'
            : 'Ahora mismo tu gente de «${mesa.nombre}» te ve como '
                '«Alguien». Ponte un nombre y lo verán al momento.',
      ),
      etiqueta: tiene
          ? 'Tu gente te ve como ${yo.nombre}. Tócalo para cambiarlo'
          : 'Tu gente te ve como Alguien. Tócalo para ponerte un nombre',
      color: tiene ? AppColors.superficie : AppColors.superficieCalida,
      radio: AppShape.radioM,
      sombra: Offset.zero,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: 10,
      ),
      child: Row(
          children: <Widget>[
            Text(tiene ? '🙂' : '👋', style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                tiene
                    ? 'Tu gente te ve como «${yo.nombre}». Tócalo para cambiarlo.'
                    : 'Tu gente te ve como «Alguien». Ponte un nombre.',
                style: AppTypography.cuerpoS.copyWith(
                  fontSize: 13,
                  height: 1.25,
                  color: AppColors.tinta,
                ),
              ),
            ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.tinta),
        ],
      ),
    );
  }
}
