import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../arte/croqui.dart';
import '../../core/models/cata.dart';
import '../../core/models/dieta.dart';
import '../../core/models/persona.dart';
import '../../core/providers/catas_provider.dart';
import '../../core/providers/mi_dieta_provider.dart';
import '../../core/providers/visto_provider.dart';
import '../../core/theme/components/boton.dart';
import '../../core/theme/components/cabecera.dart';
import '../../core/theme/components/campo.dart';
import '../../core/theme/components/chip.dart';
import '../../core/theme/components/entrada.dart';
import '../../core/theme/components/pegatina.dart';
import '../../core/theme/components/pildoras_dieta.dart';
import '../../core/theme/tokens/app_colors.dart';
import '../../core/theme/tokens/app_shape.dart';
import '../../core/theme/tokens/app_spacing.dart';
import '../../core/theme/tokens/app_typography.dart';
import '../vitrina/widgets/tarjeta_cata.dart';

/// BARRA LIBRE — las croquetas que valen para quien no puede con todo.
///
/// Es una pantalla aparte y no un filtro más del feed a propósito. Quien no
/// come gluten no quiere ver veinte croquetas que no puede probar y buscar la
/// suya entre ellas: quiere entrar en un sitio donde todo lo que hay le vale.
///
/// Aquí sólo entran las catas cuya receta contestó alguien. Una croqueta de
/// la que nadie dijo cómo estaba hecha no aparece: que nadie lo mirara no es
/// lo mismo que que valga.
class BarraLibrePage extends ConsumerStatefulWidget {
  const BarraLibrePage({super.key});

  @override
  ConsumerState<BarraLibrePage> createState() => _BarraLibrePageState();
}

class _BarraLibrePageState extends ConsumerState<BarraLibrePage> {
  @override
  void initState() {
    super.initState();
    // Abrir esta pantalla filtrada por lo tuyo es todo el sentido de haber
    // dicho cómo comes. Sólo la primera vez y sólo si no hay filtro puesto:
    // si vuelves después de tocar las pastillas, manda lo que tocaste.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final Set<Dieta> mias = ref.read(miDietaProvider);
      if (mias.isEmpty) return;
      if (ref.read(filtroDietaProvider).isNotEmpty) return;
      ref.read(filtroDietaProvider.notifier).state = mias;
    });
  }

  /// Guarda el filtro de la pantalla como la dieta del perfil.
  ///
  /// Con eso, el resto de la app deja de contestar por una respuesta que
  /// nunca le dieron: las tarjetas dirán si te vale, la ficha también, y esta
  /// pantalla abrirá ya filtrada la próxima vez.
  Future<void> _guardarComoMia(Set<Dieta> filtro) async {
    await ref.read(miDietaProvider.notifier).poner(filtro);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          content: Text('Guardado. El resto de la app ya lo tiene en cuenta.'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final Set<Dieta> filtro = ref.watch(filtroDietaProvider);
    final Set<Dieta> mia = ref.watch(miDietaProvider);
    final List<Cata> catas = ref.watch(catasLibresProvider);
    final Map<Dieta, int> recuento = ref.watch(recuentoDietasProvider);
    final Map<String, Persona> personas = ref.watch(personasProvider);

    void alternar(Dieta d) {
      final Set<Dieta> nuevo = <Dieta>{...filtro};
      nuevo.contains(d) ? nuevo.remove(d) : nuevo.add(d);
      ref.read(filtroDietaProvider.notifier).state = nuevo;
    }

    return CustomScrollView(
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Cabecera(
            titulo: 'Barra Libre',
            // Antes ponía «Sin gluten, sin lactosa, sin drama»: una gracia
            // que no dice qué es esta pantalla. Quien entra la primera vez
            // tiene que salir sabiendo para qué sirve.
            subtitulo: 'Qué croquetas puedes comer tú',
            // `pop` y no `go('/')`: a esta pantalla se llega empujándola
            // desde La Vitrina, así que volver es deshacer ese paso.
            volver: () => context.pop(),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pantalla),
          sliver: SliverList(
            delegate: SliverChildListDelegate(<Widget>[
              const _Explicacion(),

              TituloSeccion(
                texto: 'Filtra por lo tuyo',
                // Una `OpcionPildora` y no un chip: el chip medía 27 px de
                // alto y esto es un botón, no una etiqueta.
                pastilla: filtro.isEmpty
                    ? null
                    : OpcionPildora(
                        texto: 'Quitar filtros',
                        emoji: '✕',
                        activa: false,
                        onTap: () => ref
                            .read(filtroDietaProvider.notifier)
                            .state = const <Dieta>{},
                      ),
              ),
              PildorasDieta(
                marcadas: filtro,
                onAlternar: alternar,
                recuento: recuento,
              ),

              // El puente entre el filtro de aquí y la dieta del perfil.
              //
              // Son las mismas seis pastillas en dos sitios y hasta ahora no
              // había manera de pasar de uno al otro: quien marcaba «sin
              // gluten» cada vez que entraba seguía viendo «⛔ No te vale» en
              // las tarjetas del resto de la app, porque allí contesta la
              // dieta del perfil y nadie se la había dicho.
              // De dónde salen las pastillas que están puestas sin que
              // nadie las tocara. Entrabas y veías cinco encendidas: parecía
              // que la app decidía por su cuenta.
              if (mia.isNotEmpty && setEquals(filtro, mia))
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.m),
                  child: Text(
                    'Puesto con lo que marcaste en «Cómo comes», en tu perfil.',
                    style: AppTypography.cuerpoS.copyWith(
                      fontSize: 12.5,
                      color: AppColors.tintaSuave,
                      height: 1.35,
                    ),
                  ),
                ),

              if (filtro.isNotEmpty && !setEquals(filtro, mia))
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.m),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: OpcionPildora(
                      texto: mia.isEmpty
                          ? 'Yo como así siempre'
                          : 'Cambiar mi dieta por esto',
                      emoji: '📌',
                      activa: false,
                      colorInactiva: AppColors.superficieCalida,
                      onTap: () => _guardarComoMia(filtro),
                    ),
                  ),
                ),

              TituloSeccion(
                // «Todas las aptas» no decía aptas para quién, que es la
                // única pregunta que importa en esta pantalla. Son las que
                // tienen receta contestada: unas te valdrán y otras no.
                texto: filtro.isEmpty ? 'Con receta apuntada' : 'Te valen',
                pastilla: ChipCata(
                  texto: catas.length == 1 ? '1 cata' : '${catas.length} catas',
                  color: AppColors.lima,
                ),
              ),
            ]),
          ),
        ),
        if (catas.isEmpty)
          SliverToBoxAdapter(child: _Vacia(filtro: filtro))
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pantalla),
            sliver: SliverList.separated(
              itemCount: catas.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.m),
              itemBuilder: (BuildContext context, int i) {
                final Cata cata = catas[i];
                return Entrada(
                  key: ValueKey<String>(cata.id),
                  indice: i,
                  child: TarjetaCata(
                    cata: cata,
                    // Por cuenta primero: `autorId` vale 'tu' en todos los
                    // móviles, así que la cata de tu gente salía aquí con tu
                    // cara y tu nombre. Y ésta es la pantalla donde alguien
                    // decide qué se come fiándose de quién lo apuntó: el peor
                    // sitio para equivocarse de persona.
                    autor: personas[cata.autorUid] ??
                        personas[cata.autorId] ??
                        Persona.desconocida,
                    // Sin veredicto: aquí manda el filtro de arriba, no la
                    // dieta del perfil. Con el veredicto puesto, debajo de
                    // «Te valen» salían tarjetas con «⛔ No te vale».
                    segun: const <Dieta>{},
                    onTap: () => context.push('/cata/${cata.id}'),
                  ),
                );
              },
            ),
          ),
        const SliverToBoxAdapter(
          child: SizedBox(height: AppSpacing.huecoBarra),
        ),
      ],
    );
  }
}

/// El panel que explica de qué va esto.
///
/// Se pliega, y la primera vez se abre solo. Ocupaba la pantalla entera cada
/// vez que entrabas: es el texto que hace falta leer una vez y estorba las
/// otras cincuenta, porque empuja la lista —que es a lo que vienes— por
/// debajo del borde.
///
/// El aviso de las alergias no se pliega con lo demás. Es lo único de aquí
/// que puede hacer daño si no se lee, así que se queda a la vista siempre.
class _Explicacion extends ConsumerStatefulWidget {
  const _Explicacion();

  @override
  ConsumerState<_Explicacion> createState() => _ExplicacionState();
}

class _ExplicacionState extends ConsumerState<_Explicacion> {
  /// Nulo mientras no se haya tocado: lo decide si es la primera visita.
  bool? _abierto;

  /// Ya se ha pedido apuntar que esto se leyó, para no pedirlo en cada
  /// repintado.
  bool _apuntado = false;

  @override
  Widget build(BuildContext context) {
    final bool quieto = MediaQuery.disableAnimationsOf(context);

    // La primera visita entra con el panel abierto; de la segunda en adelante
    // abre por la lista, que es a lo que se viene.
    //
    // Esto NO se puede mirar una sola vez en `initState`: lo que ya se ha
    // leído se guarda en el disco y el disco tarda más que el primer
    // fotograma, así que allí siempre dice «ya visto» y el panel no se abría
    // nunca. Se mira en cada repintado y el que manda es el primero que llega
    // con el disco ya leído.
    final bool primera = ref.watch(tocaEnsenarProvider(Visto.pistaLibre));
    if (primera && !_apuntado) {
      _apuntado = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // Se fija abierto ANTES de apuntarlo: apuntarlo pone `primera` en
        // falso, y sin esto el panel se cerraría de golpe al instante de
        // abrirse.
        setState(() => _abierto = true);
        ref.read(vistoProvider.notifier).marcar(Visto.pistaLibre);
      });
    }
    final bool abierto = _abierto ?? primera;

    return Pegatina(
      color: AppColors.menta,
      lunares: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Semantics(
            button: true,
            expanded: abierto,
            label: abierto
                ? 'Qué es esto. Plegar la explicación'
                : 'Qué es esto. Desplegar la explicación',
            excludeSemantics: true,
            onTap: () => setState(() => _abierto = !abierto),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _abierto = !abierto),
              // 44 px de alto: la cabecera sola mide 26 y lo que se toca en
              // esta app nunca baja de lo que pide Apple.
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Row(
                  children: <Widget>[
                    const EtiquetaPanel(texto: 'Qué es esto'),
                    const Spacer(),
                    AnimatedRotation(
                      turns: abierto ? 0.5 : 0,
                      duration: Duration(milliseconds: quieto ? 0 : 200),
                      curve: Curves.easeOutCubic,
                      child: const Icon(
                        Icons.expand_more_rounded,
                        color: AppColors.tinta,
                        size: 26,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: Duration(milliseconds: quieto ? 0 : 200),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: abierto
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const SizedBox(height: AppSpacing.m),
                      Text(
                        'Marca abajo lo tuyo —sin gluten, vegana, lo que '
                        'sea— y te quedas sólo con las croquetas que puedes '
                        'comer.',
                        style: AppTypography.cuerpo.copyWith(
                          color: AppColors.tinta,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s),
                      // De dónde salen. Es la pregunta que nadie respondía:
                      // la pantalla enseñaba una lista corta o vacía y no
                      // había forma de saber por qué, ni cómo meter más.
                      Text(
                        'Aquí sólo entra una croqueta cuando alguien contesta '
                        'de qué estaba hecha al apuntarla. Si falta la tuya, '
                        'apúntala y rellena «La receta».',
                        style: AppTypography.cuerpoS.copyWith(
                          color: AppColors.tinta,
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
          const SizedBox(height: AppSpacing.m),
          const AvisoAlergias(),
        ],
      ),
    );
  }
}

/// Cuando no hay nada que enseñar.
///
/// Tres situaciones que no se parecen en nada y antes se contestaban con dos
/// frases: que nadie haya apuntado una receta todavía, que lo que hay lleve
/// algo que tú no quieres, y que estés pidiendo cinco cosas a la vez. La
/// última es la que dejaba la pantalla muerta: el filtro se llena solo con lo
/// que marcaste en «Cómo comes», así que entras, ves cinco pastillas
/// encendidas que tú no has tocado y cero croquetas, sin saber cuál sobra.
class _Vacia extends ConsumerWidget {
  const _Vacia({required this.filtro});

  final Set<Dieta> filtro;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int conReceta = ref.watch(totalLibresProvider);

    if (filtro.isEmpty) {
      return _Hueco(
        // Con filtro vacío y nada debajo, o no hay recetas apuntadas o lo que
        // hay lo tapa tu lista de «esto no me lo pongas». No es lo mismo y
        // decir lo primero cuando pasa lo segundo manda a apuntar una cata
        // que ya está apuntada.
        texto: conReceta == 0
            ? 'Aquí no hay nada todavía porque nadie ha dicho de qué estaban '
                'hechas sus croquetas.'
            : conReceta == 1
                ? 'La única croqueta con receta lleva algo de lo que dijiste '
                    'que no querías.'
                : 'Las $conReceta croquetas con receta llevan algo de lo que '
                    'dijiste que no querías.',
        letraChica: conReceta == 0
            ? 'Al apuntar una cata, rellena «La receta» —la bechamel, el '
                'rebozado— y aparecerá aquí sola.'
            : 'Eso se cambia en el Perfil, en «Cómo comes».',
        boton: conReceta == 0
            ? BotonPegatina(
                texto: 'Apuntar una croqueta',
                icono: Icons.add_rounded,
                color: AppColors.tomate,
                ancho: 260,
                onTap: () => context.push('/nueva'),
              )
            : null,
      );
    }

    // Con filtro puesto: qué pedías, y cuál de las cosas que pides sobra.
    final List<(Dieta, int)> culpables = ref.watch(culpablesDelVacioProvider);
    final (Dieta, int)? sobra = culpables.isEmpty ? null : culpables.first;

    return _Hueco(
      texto: conReceta == 0
          ? 'Todavía no hay ninguna croqueta con la receta apuntada, así que '
              'no hay nada que filtrar.'
          : conReceta == 1
              ? 'La única croqueta con receta no cumple todo lo que pides.'
              : 'Ninguna de las $conReceta con receta cumple todo lo que '
                  'pides.',
      letraChica: sobra == null
          ? (conReceta == 0
              ? 'Apunta una y rellena «La receta»: la bechamel, el rebozado.'
              : 'Si encuentras una que cumpla, apúntala y la estrenas tú.')
          : 'Pides ${filtro.length} cosas a la vez. Sin «${sobra.$1.nombre.toLowerCase()}» '
              'te ${sobra.$2 == 1 ? 'saldría 1' : 'saldrían ${sobra.$2}'}.',
      boton: sobra != null
          // El botón quita SÓLO la que estorba, no el filtro entero: lo demás
          // que pediste sigue siendo verdad.
          ? BotonPegatina(
              texto: 'Quitar «${sobra.$1.nombre.toLowerCase()}»',
              icono: Icons.close_rounded,
              color: AppColors.sol,
              ancho: 280,
              onTap: () => ref.read(filtroDietaProvider.notifier).state =
                  <Dieta>{...filtro}..remove(sobra.$1),
            )
          : (conReceta == 0
              ? BotonPegatina(
                  texto: 'Apuntar una croqueta',
                  icono: Icons.add_rounded,
                  color: AppColors.tomate,
                  ancho: 260,
                  onTap: () => context.push('/nueva'),
                )
              : BotonPegatina(
                  texto: 'Quitar filtros',
                  icono: Icons.close_rounded,
                  color: AppColors.sol,
                  ancho: 260,
                  onTap: () => ref.read(filtroDietaProvider.notifier).state =
                      const <Dieta>{},
                )),
    );
  }
}

/// El molde de los tres huecos: croqueta, frase, letra chica y una salida.
class _Hueco extends StatelessWidget {
  const _Hueco({required this.texto, this.letraChica, this.boton});

  final String texto;
  final String? letraChica;
  final Widget? boton;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pantalla,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        children: <Widget>[
          const Croqui(ancho: 150, conProps: false),
          const SizedBox(height: AppSpacing.l),
          Text(texto, textAlign: TextAlign.center, style: AppTypography.cuerpo),
          if (letraChica != null) ...<Widget>[
            const SizedBox(height: AppSpacing.m),
            Text(
              letraChica!,
              textAlign: TextAlign.center,
              style: AppTypography.cuerpoS.copyWith(
                fontSize: 12.5,
                color: AppColors.tintaSuave,
                height: 1.35,
              ),
            ),
          ],
          if (boton != null) ...<Widget>[
            const SizedBox(height: AppSpacing.l),
            boton!,
          ],
        ],
      ),
    );
  }
}

/// La entrada a la Barra Libre desde el feed.
///
/// Va en La Vitrina y no en una quinta pestaña: la barra de abajo tiene cuatro
/// destinos y el botón de añadir, y meter un quinto icono para una sección
/// que no todo el mundo usa a diario empeoraría los cuatro que sí.
class EntradaBarraLibre extends ConsumerWidget {
  const EntradaBarraLibre({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int total = ref.watch(totalLibresProvider);
    final int? paraMi = ref.watch(totalParaMiProvider);

    // Tres frases para tres situaciones distintas. La de antes ("N croquetas
    // aptas") decía "aptas" sin decir para quién, que en esta sección es
    // justo lo que no se puede hacer: quien la usa se fía para decidir qué
    // se come.
    final String pie;
    if (total == 0) {
      pie = 'Qué croquetas puedes comer tú';
    } else if (paraMi == null) {
      pie = 'Cuáles puedes comer tú · $total con receta';
    } else if (paraMi == 0) {
      // «Ninguna de las 1 te vale aún» no es castellano. Y la frase tiene
      // que decir primero para qué sirve esto, no sólo el recuento.
      pie = 'De $total con receta, ninguna te vale';
    } else {
      pie = '$paraMi te valen, de $total con receta';
    }

    // El menta pasa del bloque entero a la pastilla del icono: como
    // rectángulo verde a ancho completo era el cuarto de la misma pantalla y
    // le quitaba protagonismo a la croqueta del día.
    // Sin lunares: son blancos al 28% y aquí el fondo ya es blanco. No se
    // ven, ensucian y cuestan un repintado. Se quedaron puestos de cuando
    // este bloque era verde entero.
    return Pegatina(
      color: AppColors.superficie,
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      onTap: () => context.push('/libre'),
      child: Row(
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              // Antes era crema sobre el menta del bloque. Ahora que el
              // bloque es blanco, la crema desaparecería: el verde se muda
              // aquí, que es donde queda como acento y no como grito.
              color: AppColors.menta,
              borderRadius: BorderRadius.circular(AppShape.radioM),
              border: Border.all(
                color: AppColors.tinta,
                width: AppShape.bordeFino,
              ),
            ),
            // Un icono de tinta y no el brote verde: verde sobre verde no
            // se distinguía, que es lo primero que se ve de esta sección.
            child: const Icon(
              Icons.eco_rounded,
              size: 24,
              color: AppColors.tinta,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Barra Libre',
                  style: AppTypography.tituloS.copyWith(
                    color: AppColors.tinta,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  pie,
                  style: AppTypography.cuerpoS.copyWith(
                    fontSize: 12.5,
                    color: AppColors.tinta,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: AppColors.tinta,
          ),
        ],
      ),
    );
  }
}
