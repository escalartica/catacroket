import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/persona.dart';
import '../../../core/providers/borrador_provider.dart';
import '../../../core/theme/components/avatar.dart';
import '../../../core/theme/components/campo.dart';
import '../../../core/theme/tokens/app_colors.dart';
import '../../../core/theme/tokens/app_shape.dart';
import '../../../core/theme/tokens/app_spacing.dart';
import '../../../core/theme/tokens/app_typography.dart';

/// Con quién te las estás comiendo.
///
/// Nombres escritos a mano. Antes eran cinco personas del catálogo de
/// demostración, que es como pedirle al usuario que mienta sobre con quién
/// come: la gente con la que sales a croquetas no está en una lista de la
/// app. Cuando entren las cuentas, esto pasará a sugerir los nombres de tu
/// mesa mientras escribes, pero seguirá admitiendo escribir uno cualquiera.
class SelectorGente extends ConsumerStatefulWidget {
  const SelectorGente({super.key});

  @override
  ConsumerState<SelectorGente> createState() => _SelectorGenteState();
}

class _SelectorGenteState extends ConsumerState<SelectorGente> {
  final TextEditingController _control = TextEditingController();
  final FocusNode _foco = FocusNode();

  @override
  void dispose() {
    _control.dispose();
    _foco.dispose();
    super.dispose();
  }

  void _anadir() {
    final String nombre = _control.text.trim();
    if (nombre.isEmpty) return;
    HapticFeedback.selectionClick();
    ref.read(borradorProvider.notifier).anadirAcompanante(nombre);
    _control.clear();
    // El foco se queda: normalmente no vas a cenar con una sola persona.
    _foco.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> gente = ref.watch(borradorProvider).acompanantes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('¿CON QUIÉN?', style: AppTypography.antetitulo),
        const SizedBox(height: 4),
        Text(
          'Opcional. Escribe un nombre y dale al más.',
          style: AppTypography.cuerpoS.copyWith(
            fontSize: 12.5,
            color: AppColors.tintaSuave,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: _CampoNombre(
                control: _control,
                foco: _foco,
                onEnviar: _anadir,
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            Semantics(
              button: true,
              label: 'Añadir a esta persona',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _anadir,
                child: Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.sol,
                    borderRadius: BorderRadius.circular(AppShape.radioM),
                    border: Border.all(
                      color: AppColors.tinta,
                      width: AppShape.borde,
                    ),
                    boxShadow: AppShape.sombra(AppShape.sombraChica),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: AppColors.tinta,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (gente.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.m),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final String nombre in gente)
                _Ficha(
                  nombre: nombre,
                  onQuitar: () => ref
                      .read(borradorProvider.notifier)
                      .quitarAcompanante(nombre),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// El campo, con el mismo aspecto que [Campo] pero con su propio controlador:
/// aquí hace falta vaciarlo al añadir y devolverle el foco.
class _CampoNombre extends StatelessWidget {
  const _CampoNombre({
    required this.control,
    required this.foco,
    required this.onEnviar,
  });

  final TextEditingController control;
  final FocusNode foco;
  final VoidCallback onEnviar;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(AppShape.radioM),
        border: Border.all(color: AppColors.tinta, width: AppShape.borde),
        boxShadow: AppShape.sombra(AppShape.sombraChica),
      ),
      child: TextField(
        controller: control,
        focusNode: foco,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => onEnviar(),
        style: AppTypography.cuerpo,
        cursorColor: AppColors.tinta,
        decoration: InputDecoration(
          hintText: 'Marta',
          hintStyle: AppTypography.cuerpo.copyWith(
            color: AppColors.tintaSuave,
            fontWeight: FontWeight.w600,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

class _Ficha extends StatelessWidget {
  const _Ficha({required this.nombre, required this.onQuitar});

  final String nombre;
  final VoidCallback onQuitar;

  @override
  Widget build(BuildContext context) {
    final Persona p = Persona.deNombre(nombre);

    return Semantics(
      button: true,
      label: 'Quitar a $nombre',
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onQuitar,
          child: Container(
            height: 44,
            padding: const EdgeInsets.fromLTRB(6, 0, 12, 0),
            decoration: BoxDecoration(
              color: AppColors.superficie,
              borderRadius: BorderRadius.circular(AppShape.radioPildora),
              border: Border.all(
                color: AppColors.tinta,
                width: AppShape.bordeFino,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Avatar(persona: p, tamano: 32),
                const SizedBox(width: 8),
                Text(
                  nombre,
                  style: AppTypography.etiqueta.copyWith(fontSize: 13.5),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: AppColors.tintaSuave,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
