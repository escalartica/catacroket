import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../arte/corte_painter.dart';
import '../../arte/croqui.dart';
import '../../core/data/rellenos.dart';
import '../../core/models/cata.dart';
import '../../core/models/corte.dart';
import '../../core/models/alergeno.dart';
import '../../core/models/dieta.dart';
import '../../core/models/receta.dart';
import '../../core/models/mesa.dart';
import '../../core/models/persona.dart';
import '../../core/models/sabor.dart';
import '../../core/providers/catas_provider.dart';
import '../../core/providers/cuenta_provider.dart';
import '../../core/providers/mesas_provider.dart';
import 'widgets/hoja_quien_la_ve.dart';
import '../../core/providers/mi_dieta_provider.dart';
import '../../core/theme/components/avatar.dart';
import '../../core/theme/components/barra_eje.dart';
import '../../core/theme/components/boton.dart';
import '../../core/theme/components/cabecera.dart';
import '../../core/theme/components/chip.dart';
import '../../core/theme/components/nota.dart';
import '../../core/theme/components/pegatina.dart';
import '../../core/theme/components/mapa_mini.dart';
import '../../core/theme/components/pildoras_dieta.dart';
import '../../core/theme/components/vuelo.dart';
import '../../core/theme/tokens/app_colors.dart';
import '../../core/theme/tokens/app_shape.dart';
import '../../core/theme/tokens/app_spacing.dart';
import '../../core/theme/tokens/app_typography.dart';
import '../../core/utils/formato.dart';
import '../../core/utils/texto.dart';
import '../compartir/compartir_cata.dart';
import 'widgets/carrusel_medios.dart';

/// Ficha de una cata.
class DetallePage extends ConsumerWidget {
  const DetallePage({super.key, required this.cataId});

  final String cataId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Cata? cata = ref.watch(cataProvider(cataId));

    if (cata == null) {
      return Column(
        children: <Widget>[
          Cabecera(titulo: 'Esta cata ya no está', volver: () => context.pop()),
          const Spacer(),
          const Croqui(ancho: 140, conProps: false),
          const SizedBox(height: AppSpacing.l),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pantalla),
            child: Text(
              'La borraste o nunca llegó a guardarse.\nNo pasa nada: se cata otra.',
              textAlign: TextAlign.center,
              style: AppTypography.cuerpo,
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          BotonPegatina.fantasma(
            texto: 'Volver a La Vitrina',
            icono: Icons.storefront_rounded,
            onTap: () => context.go('/'),
          ),
          const Spacer(),
        ],
      );
    }

    final Relleno relleno = Rellenos.de(cata.rellenoId);
    // Por cuenta primero y por identificador local después, igual que en la
    // ficha de la mesa. Mirando sólo `autorId`, la cata de otra persona
    // llevaba TU cara y TU nombre, porque `autorId` vale 'tu' en todos los
    // móviles y el mapa de personas lo traduce a quien lo está mirando.
    final Map<String, Persona> personas = ref.watch(personasProvider);
    final Persona autor = personas[cata.autorUid] ??
        personas[cata.autorId] ??
        Persona.desconocida;
    final List<Mesa> susMesas = <Mesa>[
      for (final Mesa m in ref.watch(mesasProvider))
        if (cata.estaEn(m.id)) m,
    ];
    // Por uid. Con `autorId == 'tu'` salían los botones de editar y borrar
    // encima de las catas de tu gente, que es lo peor que puede hacer una
    // pantalla de detalle: ofrecer una acción que no te corresponde.
    final bool esMia = cata.esMia(ref.watch(miUidProvider));
    final Encaje encaje = cata.encajeCon(ref.watch(miDietaProvider));

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
              BotonRedondo(
                icono: Icons.ios_share_rounded,
                etiqueta: 'Compartir',
                onTap: () =>
                    compartirCata(context, cata: cata, autor: autor),
              ),
            ],
          ),
        ),

        // ── Fotos y vídeo, si los hay ─────────────────────────────────────
        if (cata.tieneMedios) ...<Widget>[
          const SizedBox(height: AppSpacing.l),
          CarruselMedios(medios: cata.medios),
        ],

        // ── El corte, a lo grande ─────────────────────────────────────────
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
                // Por `lugar` y no montando la cadena aquí: él sabe que sin
                // ciudad hay que decir el país. Hecho a mano, una cata sin
                // ciudad dejaba un espacio suelto y la bandera huérfana.
                '${cata.lugar.toUpperCase()} · ${cata.sitio.toUpperCase()}',
                textAlign: TextAlign.center,
                style: AppTypography.antetitulo.copyWith(
                  color: AppColors.tintaSuave,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                cata.esSurtido
                    ? 'Surtido de ${cata.sabores.length}'
                    : '${relleno.emoji}  ${relleno.nombre}',
                textAlign: TextAlign.center,
                style: AppTypography.tituloL,
              ),
              const SizedBox(height: AppSpacing.m),

              // Sin foto, el dibujo es la imagen de la cata y va a lo grande.
              if (!cata.tieneMedios) ...<Widget>[
                Vuelo(
                  id: cata.id,
                  child: ElCorte(
                    corte: cata.corte,
                    rellenoId: cata.rellenoId,
                    semilla: cata.id,
                    animado: true,
                    ancho: 250,
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
              ],

              // Con foto, el dibujo se mete en la fila de la nota. Suelto y
              // centrado entre dos huecos parecía un despiste, y encima decía
              // dos veces lo mismo que la foto de arriba. Aquí acompaña a la
              // nota, que es lo que se viene a mirar.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (cata.tieneMedios) ...<Widget>[
                    Vuelo(
                      id: cata.id,
                      child: ElCorte(
                        corte: cata.corte,
                        rellenoId: cata.rellenoId,
                        semilla: cata.id,
                        animado: true,
                        vapor: false,
                        ancho: 72,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Nota(valor: cata.puntuacion, grande: true, conSufijo: true),
                  const SizedBox(width: 14),
                  // Flexible: con el texto grande de accesibilidad estas dos
                  // líneas crecen y la fila se salía 76 píxeles. Así se parten
                  // en vez de salirse, y a tamaño normal no cambia nada.
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          'La nota',
                          style: AppTypography.tituloS.copyWith(fontSize: 16),
                        ),
                        Text(
                          'Gana por ${cata.corte.ejeFuerte}',
                          style: AppTypography.cuerpoS.copyWith(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Quién la ve ───────────────────────────────────────────────────
        //
        // Arriba y con su propio bloque, no como una fila más de la lista de
        // datos que hay al final de la pantalla. Es la única cosa de esta
        // ficha que cambia algo para otra persona, y estando abajo del todo
        // no la encontraba nadie: la cata se quedaba sin enseñar y la mesa
        // sin enterarse.
        if (esMia)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pantalla,
              AppSpacing.l,
              AppSpacing.pantalla,
              0,
            ),
            child: _QuienLaVePanel(cata: cata, suyas: susMesas),
          ),

        Padding(
          padding: const EdgeInsets.all(AppSpacing.pantalla),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Pegatina(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const EtiquetaPanel(texto: 'El corte'),
                    const SizedBox(height: AppSpacing.m),
                    ...BarraEje.deCorte(cata.corte),
                    // La prueba del tiro va aquí y no en su propio panel: es
                    // un apunte sobre el rebozado, no un dato aparte.
                    if (cata.tiro != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.m),
                      Semantics(
                        label: 'Al tirarla al plato: ${cata.tiro!.nombre}. '
                            '${cata.tiro!.queSignifica}',
                        excludeSemantics: true,
                        child: Row(
                          children: <Widget>[
                            ChipCata(
                              texto: cata.tiro!.nombre,
                              emoji: cata.tiro!.emoji,
                              color: cata.tiro!.color,
                              compacto: true,
                            ),
                            const SizedBox(width: AppSpacing.s),
                            Expanded(
                              child: Text(
                                'al tirarla al plato',
                                style: AppTypography.etiqueta.copyWith(
                                  fontSize: 11,
                                  color: AppColors.tintaSuave,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.m),

              if (cata.esSurtido) ...<Widget>[
                Pegatina(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const EtiquetaPanel(texto: 'La bandeja'),
                      const SizedBox(height: AppSpacing.m),

                      // Quién ganó y quién perdió, antes de la lista.
                      //
                      // El modelo ya lo calculaba y no se enseñaba en ninguna
                      // pantalla. Es la frase que se dice al salir del bar
                      // —«ganó la de calamar, la de jamón era de cartón»— y
                      // es justo lo que quiere contar quien pide una ración
                      // variada.
                      _Veredicto(cata: cata),

                      for (final Sabor sabor in cata.sabores)
                        _FilaBandeja(sabor: sabor),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
              ],

              if (cata.receta != null || cata.tieneDietas) ...<Widget>[
                Pegatina(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const EtiquetaPanel(texto: 'Apta para'),
                      const SizedBox(height: AppSpacing.m),

                      // Lo tuyo primero. Si has dicho cómo comes, la respuesta
                      // que traías es "¿puedo comerme esto?", y esa va arriba,
                      // no escondida entre las etiquetas de la croqueta.
                      if (encaje.seEnsena) ...<Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: encaje.color,
                            borderRadius:
                                BorderRadius.circular(AppShape.radioM),
                            border: Border.all(
                              color: AppColors.tinta,
                              width: AppShape.bordeFino,
                            ),
                          ),
                          child: Row(
                            children: <Widget>[
                              Text(
                                encaje.emoji,
                                style: const TextStyle(fontSize: 18),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  switch (encaje) {
                                    Encaje.vale =>
                                      'Te vale, según lo que apuntaron.',
                                    Encaje.ojo =>
                                      'Casi. Hay algo que hay que preguntar '
                                          'antes de pedirla.',
                                    Encaje.no =>
                                      'Esta no es para ti.',
                                    Encaje.sinSaber => '',
                                  },
                                  style: AppTypography.cuerpoS.copyWith(
                                    color: AppColors.textoSobre(encaje.color),
                                    height: 1.25,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.m),
                      ],
                      if (cata.dietas.isEmpty)
                        Text(
                          // No es lo mismo "no vale" que "no se preguntó", y
                          // decir lo primero cuando pasa lo segundo es
                          // esconder una croqueta que quizá sí valía.
                          cata.alergenosDudosos.isEmpty
                              ? 'Para ninguna de las dietas de la app: la '
                                  'bechamel, el rebozado o el relleno lo '
                                  'impiden.'
                              : 'No se preguntó lo suficiente para poder '
                                  'decirlo. Si vuelves, pregunta en la barra '
                                  'y corrige la cata.',
                          style: AppTypography.cuerpo,
                        )
                      else
                        for (final Dieta d in cata.dietas)
                          _FilaDieta(dieta: d),

                      // El aviso de la freidora va aquí y no en letra
                      // pequeña: es la trampa que más veces se lleva por
                      // delante a un celíaco en un bar.
                      if (cata.riesgoDeFreidora) ...<Widget>[
                        const SizedBox(height: AppSpacing.s),
                        AvisoAlergias(
                          texto: cata.receta!.freidora == Freidora.compartida
                              ? 'La receta es sin gluten, pero se fríe en la '
                                  'misma freidora que el resto. Para un '
                                  'celíaco eso NO es seguro.'
                              : 'La receta es sin gluten, pero nadie preguntó '
                                  'por la freidora. Si eres celíaco, '
                                  'pregúntalo tú antes de pedirla.',
                        ),
                      ],

                      if (cata.receta != null) ...<Widget>[
                        const SizedBox(height: AppSpacing.l),
                        _ComoEstaHecha(receta: cata.receta!),
                      ],

                      if (cata.alergenos.isNotEmpty) ...<Widget>[
                        const SizedBox(height: AppSpacing.l),
                        Text('LLEVA', style: AppTypography.antetitulo),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: <Widget>[
                            for (final Alergeno a
                                in Alergeno.ordenar(cata.alergenos))
                              ChipCata(
                                texto: a.nombre,
                                emoji: a.emoji,
                                color: AppColors.superficieHonda,
                                compacto: true,
                              ),
                          ],
                        ),
                      ],

                      if (cata.alergenosDudosos.isNotEmpty) ...<Widget>[
                        const SizedBox(height: AppSpacing.m),
                        Text('SIN CONFIRMAR', style: AppTypography.antetitulo),
                        const SizedBox(height: 4),
                        Text(
                          'Nadie lo preguntó, así que no se puede descartar: '
                          '${Alergeno.ordenar(cata.alergenosDudosos).map((Alergeno a) => a.nombre.toLowerCase()).join(', ')}.',
                          style: AppTypography.cuerpoS.copyWith(
                            fontSize: 12.5,
                            height: 1.3,
                            color: AppColors.tintaSuave,
                          ),
                        ),
                      ],

                      const SizedBox(height: AppSpacing.m),
                      const AvisoAlergias(),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
              ],

              Pegatina(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    EtiquetaPanel(
                      texto: esMia ? 'Tu nota' : 'La nota de ${autor.nombre}',
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Text(
                      cata.nota.isEmpty
                          ? 'Sin nota. A veces no hace falta.'
                          : '“${cata.nota}”',
                      style: AppTypography.cuerpo,
                    ),
                    const SizedBox(height: AppSpacing.l),
                    Row(
                      children: <Widget>[
                        PilaAvatares(
                          personas: <Persona>[autor, ...cata.gente],
                        ),
                        const SizedBox(width: AppSpacing.m),
                        Expanded(
                          child: Text(
                            cata.acompanantes.isEmpty
                                ? 'En solitario · ${Formato.relativo(cata.fecha)}'
                                // Los nombres, no el número: "con Marta y
                                // Jose" dice algo; "estabais 3", nada.
                                : 'Con ${cata.acompanantes.join(', ')} · ${Formato.relativo(cata.fecha)}',
                            style: AppTypography.cuerpoS.copyWith(
                              fontSize: 12.5,
                              color: AppColors.tintaSuave,
                            ),
                          ),
                        ),
                        _BotonMordisco(cata: cata),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.m),

              Pegatina(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.l,
                  vertical: AppSpacing.s,
                ),
                child: Column(
                  children: <Widget>[
                    _Fila(
                      icono: '📍',
                      titulo: cata.sitio,
                      // Sin ciudad, "${cata.ciudad}, España" daría una coma
                      // suelta al principio.
                      subtitulo: cata.ciudad.isEmpty
                          ? cata.paisInfo.nombre
                          : '${cata.ciudad}, ${cata.paisInfo.nombre}',
                      valor: 'Ver',
                      onTap: () => context.push('/ruta?cata=${cata.id}'),
                    ),
                    if (cata.sabemosLaRacion)
                      _Fila(
                        icono: '🥘',
                        titulo: 'Lo que pediste',
                        subtitulo: cata.precioTotal == null
                            ? 'Sin precio apuntado'
                            : '${Formato.precio(cata.precioTotal!)} el plato',
                        valor: cata.racion,
                      ),
                    if (cata.precio != null)
                      _Fila(
                        icono: '💶',
                        titulo: 'Precio por croqueta',
                        // Antes ponía "Ración de 6" a fuego, hubieras pedido
                        // lo que hubieras pedido. Ahora sale de lo que había
                        // en el plato, y si no se apuntó, no se inventa.
                        subtitulo: cata.precioTotal == null
                            ? 'No se apuntó cuántas traía'
                            : '${cata.racion}: ${Formato.precio(cata.precioTotal!)}',
                        valor: Formato.precio(cata.precio!),
                      ),
                    // Quién la ve, y cómo cambiarlo desde aquí mismo.
                    //
                    // Antes decía «Guardada en» y nombraba una sola mesa,
                    // porque una cata vivía en un sitio y sólo uno. Y no se
                    // podía cambiar sin abrir la corrección entera y pasar
                    // por los cuatro pasos, que es justo lo que nadie hace:
                    // la croqueta se apunta en el bar y lo de enseñarla se
                    // decide después.
                    // Para las tuyas esto ya está arriba, en su panel.
                    if (!esMia && susMesas.isNotEmpty)
                      _Fila(
                        icono: '🍽️',
                        titulo: 'La catasteis en',
                        subtitulo: susMesas.first.descripcion,
                        valor: susMesas.first.nombre,
                        onTap: () => context.push('/mesa/${susMesas.first.id}'),
                      ),
                  ],
                ),
              ),
              // El mapa del sitio, si lo tiene. Un "Sevilla, España" no te
              // lleva a ningún bar; una manzana concreta, sí.
              if (cata.tieneUbicacion) ...<Widget>[
                const SizedBox(height: AppSpacing.m),
                // FlutterMap no aporta nada al árbol de accesibilidad, así
                // que sin etiqueta esto se anunciaba como "botón" a secas.
                Semantics(
                  button: true,
                  label: 'Ver ${cata.sitio} en la ruta croquetera',
                  excludeSemantics: true,
                  onTap: () => context.push('/ruta?cata=${cata.id}'),
                  child: Pegatina(
                    padding: const EdgeInsets.all(AppSpacing.s),
                    onTap: () => context.push('/ruta?cata=${cata.id}'),
                    child: MapaMini(lat: cata.lat!, lon: cata.lon!, alto: 138),
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.l),
              BotonPegatina(
                texto: 'Ver en la ruta croquetera',
                color: AppColors.menta,
                icono: Icons.map_rounded,
                // `push` y con el id: el mapa abre centrado en este bar y con
                // la flecha para volver aquí. Con `go` te quedabas en el mapa
                // sin salida y sin saber cuál de los globos era el tuyo.
                onTap: () => context.push('/ruta?cata=${cata.id}'),
              ),

              // Corregir y borrar sólo en las tuyas. La cata de otro se lee,
              // se comparte y se le da un mordisco; no se toca.
              if (esMia) ...<Widget>[
                const SizedBox(height: AppSpacing.m),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: BotonPegatina.fantasma(
                        texto: 'Corregir esta cata',
                        icono: Icons.edit_rounded,
                        onTap: () => context.push('/editar/${cata.id}'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    BotonRedondo(
                      icono: Icons.delete_outline_rounded,
                      etiqueta: 'Borrar la cata',
                      onTap: () => _confirmarBorrado(context, ref, cata),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.huecoBarra),
            ],
          ),
        ),
      ],
    );
  }

  /// Borrar es la única acción de la app que no se puede deshacer, así que es
  /// la única que pregunta. El diálogo dice qué se pierde —la nota, las fotos
  /// y el vídeo— en vez de un "¿estás seguro?" que no informa de nada.
  static Future<void> _confirmarBorrado(
    BuildContext context,
    WidgetRef ref,
    Cata cata,
  ) async {
    final bool seguro = await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogo) => AlertDialog(
            backgroundColor: AppColors.superficie,
            title: const Text('¿Borrar esta cata?'),
            content: Text(
              'Se va «${cata.sitio}» con su nota'
              '${cata.tieneMedios ? ', sus fotos y su vídeo' : ''}. '
              'Esto no se puede deshacer.',
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
    await ref.read(catasProvider.notifier).borrar(cata.id);
    await HapticFeedback.heavyImpact();
    if (context.mounted) context.go('/');
  }
}

class _BotonMordisco extends ConsumerWidget {
  const _BotonMordisco({required this.cata});

  final Cata cata;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      button: true,
      label: 'Dar un mordisco. Lleva ${cata.mordiscos}',
      onTap: () {
        HapticFeedback.mediumImpact();
        ref.read(catasProvider.notifier).darMordisco(cata.id);
      },
      child: ExcludeSemantics(
        child: Pegatina(
          color: AppColors.chicle,
          radio: AppShape.radioPildora,
          sombra: const Offset(2, 2),
          // 44 de alto: antes medía 30 y era de lo más pulsado de la ficha.
          alto: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alineacion: Alignment.center,
          onTap: () {
            HapticFeedback.mediumImpact();
            ref.read(catasProvider.notifier).darMordisco(cata.id);
          },
          // El color lo decide textoSobre, que es la regla de oro de la
          // paleta. A ojo salía 4,59:1 —pasa AA por nueve centésimas— y en
          // cuanto cambiara `chicle` se rompía sin que nadie se enterara.
          child: Text(
            '🤌 ${cata.mordiscos}',
            style: AppTypography.etiqueta.copyWith(
              color: AppColors.textoSobre(AppColors.chicle),
            ),
          ),
        ),
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.valor,
    this.onTap,
  });

  final String icono;
  final String titulo;
  final String subtitulo;
  final String valor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Pegatina y no InkWell. El tema apaga las ondas de Material a propósito
    // —la respuesta al dedo la da el hundimiento de la pegatina—, así que
    // este InkWell, el único de toda la app, se quedaba sin las dos cosas:
    // tocar «📍 Bar Manolo → Ver» no producía absolutamente nada hasta que
    // aparecía la pantalla siguiente.
    return Pegatina(
      onTap: onTap,
      color: Colors.transparent,
      conBorde: false,
      sombra: Offset.zero,
      radio: AppShape.radioM,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: EdgeInsets.zero,
        child: Row(
          children: <Widget>[
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.superficieCalida,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: AppColors.tinta, width: AppShape.bordeFino),
              ),
              child: Text(icono, style: const TextStyle(fontSize: 17)),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(titulo, style: AppTypography.etiqueta.copyWith(fontSize: 13.5)),
                  Text(
                    subtitulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.cuerpoS.copyWith(
                      fontSize: 12,
                      color: AppColors.tintaSuave,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            Text(
              valor,
              style: AppTypography.etiqueta.copyWith(
                color: AppColors.tintaSuave,
              ),
            ),
            // La flechita sólo cuando se puede ir a algún sitio: sin ella,
            // «Lo que pediste» y «Precio por croqueta», que no navegan, se
            // pintaban exactamente igual que las filas que sí lo hacen.
            if (onTap != null) ...<Widget>[
              const SizedBox(width: 2),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.tintaSuave,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Un sabor dentro de la bandeja de un surtido: su corte, su nombre y lo que
/// se dijo de él. Ordenados como se añadieron, no por nota: el orden en que
/// se cataron es parte de la historia.
class _FilaBandeja extends StatelessWidget {
  const _FilaBandeja({required this.sabor});

  final Sabor sabor;

  @override
  Widget build(BuildContext context) {
    final Relleno relleno = Rellenos.de(sabor.rellenoId);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: Row(
        children: <Widget>[
          Container(
            width: 54,
            height: 54,
            padding: const EdgeInsets.all(4),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: relleno.color,
              borderRadius: BorderRadius.circular(AppShape.radioM),
              border: Border.all(color: AppColors.tinta, width: AppShape.bordeFino),
            ),
            child: ElCorte(
              corte: Corte(
                crujiente: 7,
                cremosidad: 7,
                sabor: sabor.veredicto.valor.round(),
                relleno: 7,
              ),
              rellenoId: relleno.id,
              semilla: 'bandeja-${relleno.id}',
              vapor: false,
            ),
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  relleno.nombre,
                  style: AppTypography.etiqueta.copyWith(fontSize: 14),
                ),
                if (sabor.apunte.isNotEmpty)
                  Text(
                    sabor.apunte,
                    style: AppTypography.cuerpoS.copyWith(
                      fontSize: 12,
                      color: AppColors.tintaSuave,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          // Todos del mismo ancho: con el suyo natural, «Meh» quedaba mucho
          // más corto que «Muy buenas» y la columna de veredictos salía en
          // zigzag, con cada emoji empezando en un sitio distinto. El mínimo
          // no es un ancho fijo: si el texto de accesibilidad crece, el chip
          // crece con él en vez de recortarse.
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 138),
            child: ChipCata(
              texto: sabor.veredicto.nombre,
              emoji: sabor.veredicto.emoji,
              color: _colorDe(sabor.veredicto),
            ),
          ),
        ],
      ),
    );
  }

  /// El veredicto se lee antes por el color que por la palabra.
  static Color _colorDe(Veredicto v) {
    if (v.valor >= 9) return AppColors.menta;
    if (v.valor >= 6.5) return AppColors.sol;
    if (v.valor >= 4.5) return AppColors.mango;
    return AppColors.tomate;
  }
}

/// Una dieta en el detalle: la pastilla y por qué lo es.
///
/// Lleva la explicación y no sólo la etiqueta porque "sin gluten" y "sin
/// gluten pero frito en el mismo aceite" no son lo mismo, y quien lee esta
/// pantalla se está jugando la tarde.
class _FilaDieta extends StatelessWidget {
  const _FilaDieta({required this.dieta});

  final Dieta dieta;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: dieta.color,
              borderRadius: BorderRadius.circular(AppShape.radioS),
              border: Border.all(
                color: AppColors.tinta,
                width: AppShape.bordeFino,
              ),
            ),
            child: Text(dieta.emoji, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(dieta.nombre, style: AppTypography.tituloS.copyWith(fontSize: 16)),
                const SizedBox(height: 1),
                Text(
                  dieta.explicacion,
                  style: AppTypography.cuerpoS.copyWith(
                    fontSize: 12.5,
                    height: 1.3,
                    color: AppColors.tintaSuave,
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

/// Las tres respuestas que hacen apta —o no— a una croqueta.
///
/// Se enseñan aunque el resultado sea "no vale para nadie": saber que la
/// bechamel es de leche también es información, y evita que el siguiente
/// vuelva a preguntar.
class _ComoEstaHecha extends StatelessWidget {
  const _ComoEstaHecha({required this.receta});

  final Receta receta;

  @override
  Widget build(BuildContext context) {
    final String bechamel = receta.esVegetal &&
            receta.bebida != BebidaVegetal.sinSaber
        ? 'Vegetal, de ${receta.bebida.nombre.toLowerCase()}'
        : receta.bechamel.nombre;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('CÓMO ESTÁ HECHA', style: AppTypography.antetitulo),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            ChipCata(
              texto: bechamel,
              emoji: receta.bechamel.emoji,
              color: AppColors.superficieCalida,
              compacto: true,
            ),
            ChipCata(
              texto: receta.rebozadoConGluten
                  ? 'Rebozado de trigo'
                  : 'Rebozado sin gluten',
              // El mismo emoji que en el formulario: aquí es una etiqueta de
              // lectura y no se puede marcar, pero que la misma cosa se
              // dibuje igual en los dos sitios es la mitad de lo que hace
              // que una app se entienda sin explicarla.
              emoji: receta.rebozadoConGluten ? '🌾' : '🚫',
              color: AppColors.superficieCalida,
              compacto: true,
            ),
            ChipCata(
              texto: receta.rebozadoConHuevo ? 'Con huevo' : 'Sin huevo',
              emoji: receta.rebozadoConHuevo ? '🥚' : '🚫',
              color: AppColors.superficieCalida,
              compacto: true,
            ),
            ChipCata(
              texto: receta.freidora.nombre,
              emoji: receta.freidora.emoji,
              color: receta.freidora == Freidora.aparte
                  ? AppColors.lima
                  : AppColors.superficieCalida,
              compacto: true,
            ),
          ],
        ),
      ],
    );
  }
}

/// La mejor y la peor de una bandeja.
///
/// No se enseña si todas empataron: «ganó la de jamón y perdió la de jamón»
/// no dice nada. Con empate se dice el empate, que sí dice algo.
class _Veredicto extends StatelessWidget {
  const _Veredicto({required this.cata});

  final Cata cata;

  @override
  Widget build(BuildContext context) {
    final Sabor? mejor = cata.mejorSabor;
    final Sabor? peor = cata.peorSabor;
    if (mejor == null || peor == null) return const SizedBox.shrink();

    final bool empate = mejor.veredicto == peor.veredicto;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (empate)
            _Linea(
              emoji: '🤝',
              texto: 'Todas igual de ${mejor.veredicto.nombre.toLowerCase()}.',
            )
          else ...<Widget>[
            _Linea(
              emoji: '🏆',
              texto: 'Ganó la de ${mejor.nombre.toLowerCase()}',
              cola: mejor.veredicto.nombre.toLowerCase(),
            ),
            const SizedBox(height: 4),
            _Linea(
              emoji: '🥀',
              texto: 'La peor, la de ${peor.nombre.toLowerCase()}',
              cola: peor.veredicto.nombre.toLowerCase(),
            ),
          ],
        ],
      ),
    );
  }
}

class _Linea extends StatelessWidget {
  const _Linea({required this.emoji, required this.texto, this.cola});

  final String emoji;
  final String texto;
  final String? cola;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(emoji, style: const TextStyle(fontSize: 15)),
        const SizedBox(width: 8),
        // Flexible porque los nombres los escribe el usuario y no tienen
        // límite: «carrillada ibérica con pimentón de la Vera» existe.
        Flexible(
          child: Text(
            cola == null ? texto : '$texto: $cola',
            style: AppTypography.cuerpoS.copyWith(height: 1.3),
          ),
        ),
      ],
    );
  }
}

/// Quién ve esta cata, y el botón para cambiarlo.
///
/// Va con color y a lo ancho a propósito. La forma anterior —una fila de
/// texto entre «Precio por croqueta» y el mapa— era correcta y no la veía
/// nadie: compartir una croqueta con tu gente es la mitad de lo que hace esta
/// app, y estaba escondida como un dato de ficha técnica.
class _QuienLaVePanel extends ConsumerWidget {
  const _QuienLaVePanel({required this.cata, required this.suyas});

  final Cata cata;
  final List<Mesa> suyas;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool soloYo = suyas.isEmpty;
    // Una mesa sin activar no la ve nadie: existe sólo en este móvil hasta
    // que se le da a «Activar el código». Decir «la ve tu gente» de una de
    // ésas es mentir en la pantalla donde el usuario lo comprueba.
    final List<String> despiertas = <String>[
      for (final Mesa m in suyas)
        if (m.enLaNube) m.nombre,
    ];
    final List<String> dormidas = <String>[
      for (final Mesa m in suyas)
        if (!m.enLaNube) m.nombre,
    ];
    final bool avisa = dormidas.isNotEmpty;

    final String titulo = soloYo
        ? 'Sólo la ves tú'
        : despiertas.isEmpty
            ? 'Todavía no la ve nadie'
            : 'La ve tu gente';
    final String debajo = soloYo
        ? 'Tócalo para enseñársela a una mesa'
        : despiertas.isEmpty
            ? '${Texto.enumerar(dormidas)} sin activar'
            : avisa
                ? '${despiertas.join(' · ')} · '
                    '${Texto.enumerar(dormidas)} sin activar'
                : despiertas.join(' · ');

    return Pegatina(
      color: avisa
          ? AppColors.sol
          : soloYo
              ? AppColors.superficieCalida
              : AppColors.menta,
      onTap: () => hojaQuienLaVe(context, ref, cata),
      etiqueta: '$titulo. $debajo. Toca para cambiarlo',
      child: Row(
        children: <Widget>[
          Text(
            avisa
                ? '⚠️'
                : soloYo
                    ? '🔒'
                    : '👀',
            style: const TextStyle(fontSize: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  titulo,
                  style: AppTypography.tituloS.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 2),
                Text(
                  debajo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.cuerpoS.copyWith(
                    fontSize: 13,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          const Icon(Icons.chevron_right_rounded, color: AppColors.tinta),
        ],
      ),
    );
  }
}
