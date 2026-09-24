import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../arte/croqui.dart';
import '../../core/data/rangos.dart';
import '../../core/models/persona.dart';
import '../../core/bitacora.dart';
import '../../core/data/enlaces.dart';
import '../../core/providers/catas_provider.dart';
import '../../core/models/dieta.dart';
import '../../core/providers/mesas_provider.dart';
import '../../core/providers/evitar_provider.dart';
import '../../core/providers/mi_dieta_provider.dart';
import 'widgets/identidad.dart';
import '../../core/providers/visto_provider.dart';
import '../../core/theme/components/pista.dart';
import '../../core/theme/components/pildoras_dieta.dart';
import '../../core/theme/components/pildoras_evitar.dart';
import '../../core/providers/perfil_provider.dart';
import '../../core/theme/components/barra_eje.dart';
import '../../core/theme/components/boton.dart';
import '../../core/theme/components/cabecera.dart';
import '../../core/theme/components/entrada.dart';
import '../../core/theme/components/pegatina.dart';
import '../../core/theme/tokens/app_colors.dart';
import '../../core/theme/tokens/app_shape.dart';
import '../../core/theme/tokens/app_spacing.dart';
import '../../core/theme/tokens/app_typography.dart';
import '../../core/services/compartir_service.dart';
import '../../core/utils/formato.dart';
import '../vitrina/widgets/tarjeta_cata.dart';

/// CROQUETÓMETRO — tu historial de paladar.
class PerfilPage extends ConsumerWidget {
  const PerfilPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Perfil perfil = ref.watch(perfilProvider);
    final Rango? siguiente = perfil.siguienteRango;

    return ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        Cabecera(
          titulo: 'Croquetómetro',
          subtitulo: 'Tu historial de paladar',
          accion: BotonRedondo(
            icono: Icons.settings_rounded,
            etiqueta: 'Ajustes',
            onTap: () => _ajustes(context, ref),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pantalla),
          child: const Pista(
            que: Visto.pistaPerfil,
            emoji: '📈',
            texto: 'Tu resumen: cuántas llevas, tu rango, las medallas y en '
                'qué eres duro puntuando. Aquí abajo también se dice cómo '
                'comes.',
          ),
        ),

        // ── Identidad ─────────────────────────────────────────────────────
        Identidad(rango: perfil.rango),
        const SizedBox(height: AppSpacing.xl),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pantalla),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // ── Progreso de rango ────────────────────────────────────────
              Pegatina(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const EtiquetaPanel(texto: 'Camino al siguiente rango'),
                    const SizedBox(height: AppSpacing.m),
                    Semantics(
                      label: 'Camino al siguiente rango',
                      value: '${(perfil.progreso * 100).round()} %',
                      child: Container(
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.superficieCalida,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: AppColors.tinta, width: AppShape.borde),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: perfil.progreso.clamp(0.02, 1.0),
                            child: Container(color: AppColors.uva),
                          ),
                        ),
                      ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(perfil.rango, style: AppTypography.etiqueta.copyWith(fontSize: 12)),
                        ),
                        Text(
                          siguiente == null
                              ? 'Techo alcanzado'
                              : (siguiente.desde - perfil.catas) == 1
                                  ? 'falta 1 para ${siguiente.nombre}'
                                  : 'faltan ${siguiente.desde - perfil.catas} para ${siguiente.nombre}',
                          textAlign: TextAlign.end,
                          style: AppTypography.etiqueta.copyWith(
                            fontSize: 12,
                            color: AppColors.uva,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.m),

              // ── Cifras ───────────────────────────────────────────────────
              Row(
                children: <Widget>[
                  Expanded(
                    child: _Cifra(
                      valor: '${perfil.catas}',
                      etiqueta: 'catas',
                      color: AppColors.chicle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: _Cifra(
                      valor: perfil.media == null ? '—' : Formato.nota(perfil.media!),
                      etiqueta: 'nota media',
                      color: AppColors.cielo,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: _Cifra(
                      valor: '${perfil.ciudades}',
                      etiqueta: perfil.ciudades == 1 ? 'ciudad' : 'ciudades',
                      color: AppColors.lima,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: _Cifra(
                      valor: '${perfil.paises}',
                      etiqueta: perfil.paises == 1 ? 'país' : 'países',
                      color: AppColors.mango,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.m),

              // ── Paladar ──────────────────────────────────────────────────
              Pegatina(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const EtiquetaPanel(texto: 'Tu paladar'),
                    const SizedBox(height: AppSpacing.m),
                    ...BarraEje.deCorte(perfil.paladar),
                    const SizedBox(height: AppSpacing.m),
                    Text(
                      perfil.catas == 0
                          ? 'Cata unas cuantas croquetas y aquí te diré en qué eres duro.'
                          : 'Puntúas alto el ${perfil.ejeFuerte} y eres duro '
                              'con el ${perfil.ejeDebil}.',
                      style: AppTypography.cuerpoS.copyWith(
                        color: AppColors.tintaSuave,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Mejor cata ───────────────────────────────────────────────
              if (perfil.mejor != null) ...<Widget>[
                const TituloSeccion(texto: 'Tu mejor cata'),
                TarjetaCata(
                  cata: perfil.mejor!,
                  autor: ref.watch(personasProvider)['tu'] ?? Persona.desconocida,
                  onTap: () => context.push('/cata/${perfil.mejor!.id}'),
                ),
              ],
              const SizedBox(height: AppSpacing.m),

              // ── Medallas ─────────────────────────────────────────────────
              Pegatina(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    EtiquetaPanel(
                      texto: 'Medallas · ${perfil.medallas.length} de ${Medallas.todas.length}',
                    ),
                    const SizedBox(height: AppSpacing.l),
                    Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      alignment: WrapAlignment.spaceBetween,
                      children: <Widget>[
                        // Entran escalonadas, como las tarjetas del feed. La
                        // rejilla de medallas es lo único de esta pantalla
                        // que se mira por gusto y no por dato, y es donde
                        // cabe el presupuesto de alegría de la app.
                        for (int i = 0; i < Medallas.todas.length; i++)
                          Entrada(
                            indice: i,
                            desde: 10,
                            child: _Medalla(
                              medalla: Medallas.todas[i],
                              conseguida:
                                  perfil.medallas.contains(Medallas.todas[i].id),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              _ComoComo(
                mias: ref.watch(miDietaProvider),
                onAlternar: ref.read(miDietaProvider.notifier).alternar,
                evitar: ref.watch(evitarProvider),
                onEvitarAnadir: ref.read(evitarProvider.notifier).anadir,
                onEvitarQuitar: ref.read(evitarProvider.notifier).quitar,
              ),

              const SizedBox(height: AppSpacing.l),
              BotonPegatina(
                texto: 'Invitar a un amigo',
                color: AppColors.menta,
                icono: Icons.chat_bubble_rounded,
                onTap: () => _invitar(context),
              ),
              const SizedBox(height: AppSpacing.xl),
              const _OtraApp(),
              const SizedBox(height: AppSpacing.xl),
              const _Firma(),
              const SizedBox(height: AppSpacing.huecoBarra),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _invitar(BuildContext context) async {
    final bool abierto =
        await CompartirService.porWhatsApp(CompartirService.invitacionApp());
    if (!abierto && context.mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('No se ha podido abrir WhatsApp.')),
        );
    }
  }

  /// Manda los fallos apuntados por donde el usuario quiera.
  ///
  /// Por la hoja del sistema y no a un correo fijo: así elige él —correo,
  /// WhatsApp, lo que use— y de paso ve exactamente qué está mandando antes
  /// de mandarlo, que en un informe de fallos no es poca cosa.
  Future<void> _contarFallo(BuildContext context, List<Fallo> fallos) async {
    final RenderBox? origen = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        text: informeDe(fallos, version: 'Catacroket'),
        subject: 'Un fallo en Catacroket',
        sharePositionOrigin: origen == null
            ? null
            : origen.localToGlobal(Offset.zero) & origen.size,
      ),
    );
  }

  void _ajustes(BuildContext context, WidgetRef ref) {
    // Sólo se ofrece contar un fallo si hay alguno apuntado. Un botón de
    // "algo ha ido mal" siempre visible en una app que funciona sólo siembra
    // la duda de si va mal.
    final List<Fallo> fallos = ref.read(bitacoraProvider);

    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Ajustes'),
        content: Text(
          'Todavía no hay cuenta ni nube: las catas viven en este móvil.\n\n'
          '«Ver las explicaciones» vuelve a enseñar los carteles de cada '
          'apartado. «Restablecer» borra tus catas y deja los datos de '
          'ejemplo.'
          '${fallos.isEmpty ? '' : '\n\nLa app ha tenido '
              '${fallos.length} ${fallos.length == 1 ? 'fallo' : 'fallos'}. '
              'Si quieres, mándalos y se arreglan.'}',
        ),
        actions: <Widget>[
          if (fallos.isNotEmpty)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _contarFallo(context, fallos);
              },
              child: const Text('Contar un fallo'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          // Las explicaciones de cada apartado se cierran y no vuelven. Sin
          // esto, cerrar una por error sería definitivo.
          TextButton(
            onPressed: () {
              ref.read(vistoProvider.notifier).olvidar();
              Navigator.of(context).pop();
            },
            child: const Text('Ver las explicaciones'),
          ),
          TextButton(
            onPressed: () {
              ref.read(catasProvider.notifier).restablecer();
              ref.read(mesasProvider.notifier).restablecer();
              Navigator.of(context).pop();
            },
            child: const Text('Restablecer'),
          ),
        ],
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

class _Medalla extends StatelessWidget {
  const _Medalla({required this.medalla, required this.conseguida});

  final Medalla medalla;
  final bool conseguida;

  @override
  Widget build(BuildContext context) {
    // Conseguida o no se dice sólo con color y opacidad, que es justo lo que
    // no llega a quien usa lector de pantalla. Y es el sentido del widget.
    return Semantics(
      label: '${medalla.nombre}, ${conseguida ? 'conseguida' : 'aún no'}',
      excludeSemantics: true,
      child: SizedBox(
        width: 62,
        child: Column(
          children: <Widget>[
            Transform.rotate(
              angle: conseguida ? -0.1 : 0,
              child: Opacity(
                opacity: conseguida ? 1 : 0.45,
                child: Container(
                  width: 54,
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: conseguida ? AppColors.sol : AppColors.superficieCalida,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.tinta, width: AppShape.borde),
                    boxShadow: conseguida
                        ? AppShape.sombra(const Offset(2, 2))
                        : AppShape.sinSombra,
                  ),
                  child: Text(medalla.emoji, style: const TextStyle(fontSize: 22)),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              medalla.nombre,
              textAlign: TextAlign.center,
              style: AppTypography.etiqueta.copyWith(fontSize: 10.5),
            ),
          ],
        ),
      ),
    );
  }
}

/// La firma del pie: la marca, discreta, donde se mira sin buscarla.
/// La otra app de los mismos.
///
/// Va al final del Perfil, no en el feed ni en una pestaña: es una
/// recomendación, no una función de Catacroket. Quien nunca baje hasta aquí
/// no se entera, y está bien que sea así.
///
/// Y explica por qué existe en vez de limitarse a enseñar un logo:
/// Catacroket es sólo de croquetas a propósito —es lo que la hace
/// reconocible— así que a quien quiera apuntar ensaladillas y tortillas hay
/// que mandarlo a otro sitio, no ensanchar ésta hasta que no sea de nada.
class _OtraApp extends StatelessWidget {
  const _OtraApp();

  Future<void> _abrir() async {
    try {
      await launchUrl(
        Uri.parse(Enlaces.palito),
        mode: LaunchMode.externalApplication,
      );
    } on Object catch (_) {
      // Si no se puede abrir la tienda no hay nada que decir: es una
      // recomendación, no una acción que el usuario estuviera esperando.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!Enlaces.hayPalito) return const SizedBox.shrink();

    return Semantics(
      button: true,
      label: 'Palito de Sabores, la otra app. Abre la App Store',
      excludeSemantics: true,
      child: Pegatina(
        onTap: _abrir,
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Row(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppShape.radioM),
              child: Image.asset(
                Enlaces.logoPalito,
                width: 54,
                height: 54,
                fit: BoxFit.cover,
                // Si el logo faltara, la fila sigue teniendo sentido sin él.
                errorBuilder: (_, _, _) => const SizedBox(width: 54, height: 54),
              ),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Palito de Sabores',
                    style: AppTypography.tituloS.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Aquí sólo hay croquetas. Si además catas ensaladillas, '
                    'tortillas o postres, ésa es la libreta.',
                    style: AppTypography.cuerpoS.copyWith(
                      fontSize: 12.5,
                      height: 1.3,
                      color: AppColors.tintaSuave,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.tinta,
            ),
          ],
        ),
      ),
    );
  }
}

class _Firma extends StatelessWidget {
  const _Firma();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.55,
      child: Column(
        children: <Widget>[
          const NombreCatacroket(alto: 17),
          const SizedBox(height: 6),
          Text(
            'Hecho con hambre en Sevilla',
            style: AppTypography.cuerpoS.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Cómo come el usuario.
///
/// No sale de las catas como el resto del Croquetómetro: esto lo dice él, y
/// es lo que convierte la app en suya. Con esto puesto, cada cata del feed
/// dice si le vale, la Barra Libre abre ya filtrada y las que no puede comer
/// dejan de robarle tiempo.
///
/// Vacío es un estado legítimo y es el de partida: quien come de todo no
/// tiene que configurar nada.
class _ComoComo extends StatelessWidget {
  const _ComoComo({
    required this.mias,
    required this.onAlternar,
    required this.evitar,
    required this.onEvitarAnadir,
    required this.onEvitarQuitar,
  });

  final Set<Dieta> mias;
  final void Function(Dieta) onAlternar;

  /// Lo escrito a mano: marisco, sésamo, boletus. Va debajo de las dietas y
  /// no mezclado con ellas porque no promete lo mismo — las dietas se
  /// deducen de la receta, esto sólo busca la palabra.
  final Set<String> evitar;
  final void Function(String) onEvitarAnadir;
  final void Function(String) onEvitarQuitar;

  @override
  Widget build(BuildContext context) {
    return Pegatina(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const EtiquetaPanel(texto: 'Cómo comes'),
          const SizedBox(height: AppSpacing.m),
          Text(
            mias.isEmpty
                ? 'Si no comes de todo, márcalo. La app te dirá en cada cata '
                    'si te vale, y la Barra Libre abrirá ya filtrada.'
                : 'Cada cata te dirá si te vale, si hay que preguntar o si '
                    'no. Se guarda sólo en este móvil.',
            style: AppTypography.cuerpoS.copyWith(height: 1.35),
          ),
          const SizedBox(height: AppSpacing.m),
          PildorasDieta(marcadas: mias, onAlternar: onAlternar),
          const SizedBox(height: AppSpacing.l),
          Text(
            'Y si hay algo que no quieres que te pongan —marisco, sésamo, '
            'boletus— apúntalo aquí.',
            style: AppTypography.cuerpoS.copyWith(height: 1.35),
          ),
          const SizedBox(height: AppSpacing.m),
          PildorasEvitar(
            lista: evitar,
            onAnadir: onEvitarAnadir,
            onQuitar: onEvitarQuitar,
          ),
          if (evitar.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.s),
            Text(
              'De esto la app sólo puede avisarte cuando alguien lo haya '
              'apuntado. Que no aparezca no quiere decir que no lleve.',
              style: AppTypography.cuerpoS.copyWith(
                height: 1.3,
                fontSize: 12.5,
                color: AppColors.tintaSuave,
              ),
            ),
          ],
          if (mias.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.m),
            const AvisoAlergias(
              texto: 'Esto no sustituye a preguntar en el bar. La app te dice '
                  'lo que apuntó quien fue antes que tú, no lo que hay hoy en '
                  'la cocina.',
            ),
          ],
        ],
      ),
    );
  }
}
