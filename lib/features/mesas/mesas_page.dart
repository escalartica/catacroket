import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/cata.dart';
import '../../core/models/mesa.dart';
import '../../core/models/persona.dart';
import '../../core/providers/catas_provider.dart';
import '../../core/providers/mesas_provider.dart';
import '../../core/providers/nube_provider.dart';
import '../../core/providers/visto_provider.dart';
import '../../core/theme/components/entrada.dart';
import '../../core/theme/components/pista.dart';
import '../../core/theme/components/avatar.dart';
import '../../core/theme/components/boton.dart';
import '../../core/theme/components/cabecera.dart';
import '../../core/theme/components/pegatina.dart';
import '../../core/theme/tokens/app_colors.dart';
import '../../core/theme/tokens/app_shape.dart';
import '../../core/theme/tokens/app_spacing.dart';
import '../../core/theme/tokens/app_typography.dart';
import '../../core/services/compartir_service.dart';
import '../../core/utils/formato.dart';
import 'widgets/hoja_codigo.dart';
import 'widgets/hoja_mesa.dart';

/// MESAS — tu diario y tu gente.
class MesasPage extends ConsumerWidget {
  const MesasPage({super.key});

  Future<void> _crear(BuildContext context) async {
    final Mesa? nueva = await hojaMesa(context);
    if (nueva != null && context.mounted) context.push('/mesa/${nueva.id}');
  }

  Future<void> _entrarConCodigo(BuildContext context) async {
    final Mesa? mesa = await hojaCodigo(context);
    if (mesa != null && context.mounted) context.push('/mesa/${mesa.id}');
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Mesa> mesas = ref.watch(mesasProvider);
    final Map<String, Persona> personas = ref.watch(personasProvider);

    // Enciende la escucha de quién entra en tus mesas. No pinta nada: se
    // mira aquí porque por la lista de mesas se pasa siempre, y así la ficha
    // de una mesa ya está al día cuando la abres.
    ref.watch(miembrosAlDiaProvider);

    // Y recupera las mesas que el servidor sabe que son tuyas: las que se
    // perdían al reinstalar o al cambiar de móvil.
    ref.watch(recuperarMesasProvider);

    // Y publica tu nombre, para que tu gente no te vea como «Alguien».
    ref.watch(publicarMiNombreProvider);

    return ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        Cabecera(
          titulo: 'Mesas',
          subtitulo: 'Tu diario y tu gente',
          accion: BotonRedondo(
            icono: Icons.add_rounded,
            etiqueta: 'Crear una mesa',
            onTap: () => _crear(context),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pantalla),
          child: Column(
            children: <Widget>[
              const Pista(
                que: Visto.pistaMesas,
                emoji: '👥',
                texto: 'Una mesa es tu grupo: los que catáis juntos. Compartís '
                    'las catas, hay ranking y se entra con un código. Crea una '
                    'con el + de arriba.',
              ),
              for (int i = 0; i < mesas.length; i++) ...<Widget>[
                Entrada(
                  key: ValueKey<String>(mesas[i].id),
                  indice: i,
                  child: _TarjetaMesa(
                    mesa: mesas[i],
                    catas: ref.watch(catasDeMesaProvider(mesas[i].id)),
                    personas: personas,
                    onTap: () => context.push('/mesa/${mesas[i].id}'),
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
              ],
              const SizedBox(height: AppSpacing.s),
              Pegatina(
                discontinuo: true,
                color: Colors.transparent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const EtiquetaPanel(texto: 'Añadir gente'),
                    const SizedBox(height: AppSpacing.m),
                    Text(
                      'Cada mesa nace con su código de seis letras. Para que '
                      'funcione hay que activarlo desde la ficha de la mesa: '
                      'desde ese momento, quien lo teclee entra y veis las '
                      'catas de todos.',
                      style: AppTypography.cuerpoS,
                    ),
                    const SizedBox(height: AppSpacing.l),
                    BotonPegatina(
                      texto: 'Crear una mesa nueva',
                      pequeno: true,
                      icono: Icons.add_rounded,
                      onTap: () => _crear(context),
                    ),
                    const SizedBox(height: AppSpacing.s),
                    BotonPegatina(
                      texto: 'Entrar con un código',
                      pequeno: true,
                      icono: Icons.login_rounded,
                      color: AppColors.menta,
                      onTap: () => _entrarConCodigo(context),
                    ),
                    const SizedBox(height: AppSpacing.s),
                    BotonPegatina.fantasma(
                      texto: 'Invitar a un amigo',
                      pequeno: true,
                      icono: Icons.chat_bubble_rounded,
                      onTap: () => _invitar(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.huecoBarra),
            ],
          ),
        ),
      ],
    );
  }
}

class _TarjetaMesa extends StatelessWidget {
  const _TarjetaMesa({
    required this.mesa,
    required this.catas,
    required this.personas,
    required this.onTap,
  });

  final Mesa mesa;
  final List<Cata> catas;
  final Map<String, Persona> personas;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final double? media = mediaDe(catas);

    // El color de la mesa lo elige el usuario, así que el texto no puede ir
    // en tinta fija: sobre la uva, una tinta oscura se queda en 2,2:1 y el
    // nombre de la mesa no se lee. Lo decide [AppColors.textoSobre].
    final Color fondo = Color(mesa.colorHex);
    final Color texto = AppColors.textoSobre(fondo);

    return Pegatina(
      onTap: onTap,
      color: fondo,
      lunares: true,
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              // La foto de la mesa, si la tiene. Si no, la tarjeta se queda
              // con su color y sus lunares, que ya la distinguen.
              if (mesa.tieneFoto) ...<Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppShape.radioS),
                  child: Image.file(
                    File(mesa.foto!),
                    width: 42,
                    height: 42,
                    fit: BoxFit.cover,
                    // Si el fichero ya no está, no se deja un hueco roto:
                    // simplemente no hay foto.
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
              ],
              // A una línea: un nombre de mesa lo escribe el usuario y no
              // tiene límite, y sin esto «Los que quedamos los jueves para
              // probar croquetas por Triana» estiraba la tarjeta a tres
              // líneas y dejaba la lista hecha un acordeón.
              //
              // En la ficha de la mesa sí se lee entero, que es donde toca:
              // allí el nombre es el título de la pantalla y no una fila de
              // una lista.
              Expanded(
                child: Text(
                  mesa.nombre,
                  style: AppTypography.tituloM.copyWith(color: texto),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: texto,
                  borderRadius: BorderRadius.circular(AppShape.radioS),
                ),
                child: Text(
                  // Sólo si está activada. Enseñar el código de una mesa que
                  // vive sólo en este móvil invitaba a dictarlo en un bar, y
                  // al otro lado salía «ese código no existe» —peor aún,
                  // activar la mesa puede devolver un código distinto si el
                  // que llevaba ya estaba cogido—.
                  !mesa.enLaNube
                      ? (mesa.esPrivada ? 'PRIVADA' : 'SIN ACTIVAR')
                      : (mesa.codigo ?? 'PRIVADA'),
                  style: AppTypography.antetitulo.copyWith(
                    fontSize: 10.5,
                    color: AppColors.textoSobre(texto),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            mesa.descripcion,
            style: AppTypography.cuerpoS.copyWith(fontSize: 13, color: texto),
          ),
          const SizedBox(height: AppSpacing.m),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              // Wrap y no tres huecos fijos: con el texto grande de los
              // ajustes de accesibilidad las tres cifras no caben en una línea
              // y la fila se salía 23 píxeles. Así bajan a la siguiente en vez
              // de salirse, y a tamaño normal se ven exactamente igual.
              Expanded(
                child: Wrap(
                  spacing: AppSpacing.l,
                  runSpacing: AppSpacing.s,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  children: <Widget>[
                    _Dato(
                      valor: '${catas.length}',
                      etiqueta: catas.length == 1 ? 'cata' : 'catas',
                      color: texto,
                    ),
                    _Dato(
                      valor: media == null ? '—' : Formato.nota(media),
                      etiqueta: 'media',
                      color: texto,
                    ),
                    _Dato(
                      valor: '${mesa.miembros.length}',
                      etiqueta: mesa.miembros.length == 1 ? 'sólo tú' : 'en la mesa',
                      color: texto,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              PilaAvatares(
                personas: mesa.miembros
                    .map((String id) => personas[id] ?? Persona.desconocida)
                    .toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({
    required this.valor,
    required this.etiqueta,
    required this.color,
  });

  final String valor;
  final String etiqueta;

  /// El del texto de la tarjeta, que depende del color de la mesa.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(valor, style: AppTypography.cifraM.copyWith(color: color)),
        Text(
          etiqueta,
          style: AppTypography.etiqueta.copyWith(
            fontSize: 11.5,
            color: color,
          ),
        ),
      ],
    );
  }
}
