import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/cata.dart';
import '../../core/models/mesa.dart';
import '../../core/models/persona.dart';
import '../../core/providers/catas_provider.dart';
import '../../core/providers/mesas_provider.dart';
import '../../core/providers/visto_provider.dart';
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
import 'widgets/hoja_mesa.dart';

/// MESAS — tu libreta y tu gente.
class MesasPage extends ConsumerWidget {
  const MesasPage({super.key});

  Future<void> _crear(BuildContext context) async {
    final Mesa? nueva = await hojaMesa(context);
    if (nueva != null && context.mounted) context.push('/mesa/${nueva.id}');
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

    return ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        Cabecera(
          titulo: 'Mesas',
          subtitulo: 'Tu libreta y tu gente',
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
              for (final Mesa m in mesas) ...<Widget>[
                _TarjetaMesa(
                  mesa: m,
                  catas: ref.watch(catasDeMesaProvider(m.id)),
                  personas: personas,
                  onTap: () => context.push('/mesa/${m.id}'),
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
                      'Cada mesa nace con su código de seis letras. Por ahora '
                      'las mesas son tuyas y guardan tus catas ordenadas; '
                      'que tu gente entre con el código llega en la próxima '
                      'versión, la que lleva cuentas.',
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

    return Pegatina(
      onTap: onTap,
      color: Color(mesa.colorHex),
      lunares: true,
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
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
                  style: AppTypography.tituloM,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.tinta,
                  borderRadius: BorderRadius.circular(AppShape.radioS),
                ),
                child: Text(
                  mesa.codigo ?? 'PRIVADA',
                  style: AppTypography.antetitulo.copyWith(
                    fontSize: 10.5,
                    color: AppColors.crema,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            mesa.descripcion,
            style: AppTypography.cuerpoS.copyWith(fontSize: 13),
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
                    _Dato(valor: '${catas.length}', etiqueta: 'catas'),
                    _Dato(
                      valor: media == null ? '—' : Formato.nota(media),
                      etiqueta: 'media',
                    ),
                    _Dato(
                      valor: '${mesa.miembros.length}',
                      etiqueta: mesa.miembros.length == 1 ? 'tú' : 'personas',
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
  const _Dato({required this.valor, required this.etiqueta});

  final String valor;
  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(valor, style: AppTypography.cifraM),
        Text(
          etiqueta,
          style: AppTypography.etiqueta.copyWith(
            fontSize: 11.5,
            color: AppColors.tinta,
          ),
        ),
      ],
    );
  }
}
