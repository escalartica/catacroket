import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_shape.dart';
import '../tokens/app_typography.dart';

/// Campo de texto con la forma de la app: bloque con contorno y sombra dura
/// que se "hunde" un poco al enfocarse (la sombra crece, no desaparece: aquí
/// el foco es estar dentro, no apretar).
class Campo extends StatefulWidget {
  const Campo({
    super.key,
    required this.etiqueta,
    required this.valor,
    required this.onCambio,
    this.pista = '',
    this.lineas = 1,
    this.teclado,
    this.autofoco = false,
  });

  final String etiqueta;
  final String valor;
  final ValueChanged<String> onCambio;
  final String pista;
  final int lineas;
  final TextInputType? teclado;
  final bool autofoco;

  @override
  State<Campo> createState() => _CampoState();
}

class _CampoState extends State<Campo> {
  late final TextEditingController _control =
      TextEditingController(text: widget.valor);
  final FocusNode _foco = FocusNode();
  bool _enfocado = false;

  @override
  void initState() {
    super.initState();
    _foco.addListener(() {
      if (_enfocado != _foco.hasFocus) {
        setState(() => _enfocado = _foco.hasFocus);
      }
    });
  }

  /// Sincroniza el campo cuando el valor cambia desde fuera.
  ///
  /// Pasa en dos sitios: al corregir una cata (el borrador se rellena después
  /// del primer frame) y al poner el punto en el mapa (el GPS rellena la
  /// ciudad). Sin esto, el dato está en el borrador pero el usuario ve el
  /// campo vacío y vuelve a escribirlo.
  ///
  /// La comparación con el texto actual es lo que evita que el cursor salte
  /// mientras se escribe: lo que sube el `onChanged` vuelve idéntico y aquí
  /// no se toca nada.
  @override
  void didUpdateWidget(covariant Campo viejo) {
    super.didUpdateWidget(viejo);
    if (widget.valor != _control.text) {
      _control.value = TextEditingValue(
        text: widget.valor,
        selection: TextSelection.collapsed(offset: widget.valor.length),
      );
    }
  }

  @override
  void dispose() {
    _control.dispose();
    _foco.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(widget.etiqueta.toUpperCase(), style: AppTypography.antetitulo),
        const SizedBox(height: 7),
        AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          decoration: BoxDecoration(
            color: _enfocado ? AppColors.superficieCalida : AppColors.superficie,
            borderRadius: BorderRadius.circular(AppShape.radioM),
            border: Border.all(color: AppColors.tinta, width: AppShape.borde),
            boxShadow: AppShape.sombra(
              _enfocado ? AppShape.sombraNormal : AppShape.sombraChica,
            ),
          ),
          child: TextField(
            controller: _control,
            focusNode: _foco,
            autofocus: widget.autofoco,
            maxLines: widget.lineas,
            minLines: widget.lineas,
            keyboardType: widget.teclado,
            textCapitalization: TextCapitalization.sentences,
            style: AppTypography.cuerpo,
            cursorColor: AppColors.tinta,
            onChanged: widget.onCambio,
            decoration: InputDecoration(
              hintText: widget.pista,
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
        ),
      ],
    );
  }
}

/// Opción seleccionable en forma de píldora (relleno, mesa, acompañantes).
class OpcionPildora extends StatelessWidget {
  const OpcionPildora({
    super.key,
    required this.texto,
    required this.activa,
    required this.onTap,
    this.color,
    this.emoji,
    this.colorActiva = AppColors.sol,
    this.colorInactiva = AppColors.superficie,
    this.enGrupoUnico = true,
  });

  final String texto;
  final bool activa;
  final VoidCallback onTap;
  final Color? color;
  final String? emoji;

  /// Con qué se rellena al estar activa. Por defecto el amarillo de la app;
  /// las dietas usan el suyo para que se reconozcan por el color allá donde
  /// aparezcan.
  final Color colorActiva;

  /// Y sin tocar. Blanco por defecto, pero las dietas se tiñen flojito de lo
  /// suyo: seis rectángulos blancos idénticos no dicen nada hasta que los
  /// tocas, y el color es justo lo que hace reconocible a cada dieta.
  final Color colorInactiva;

  /// Si sólo se puede elegir una del grupo.
  ///
  /// Importa para quien va con lector de pantalla: en `false` se anuncia como
  /// casilla (puedes marcar varias) y en `true` como opción única. Los
  /// rellenos y las dietas son de marcar varias, y anunciarlos como botón de
  /// radio decía justo lo contrario de lo que hacen.
  final bool enGrupoUnico;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: activa,
      inMutuallyExclusiveGroup: enGrupoUnico,
      checked: enGrupoUnico ? null : activa,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // El único control de la app que se tocaba sin decir nada. Las
        // pestañas, los deslizadores y las pegatinas ya vibraban; éstas, que
        // son las más tocadas de todas, no.
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          // 44 px de alto: es lo mínimo que pide Apple para algo que se toca,
          // y con el relleno de antes se quedaba en 39.
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: activa ? colorActiva : colorInactiva,
            borderRadius: BorderRadius.circular(AppShape.radioPildora),
            border: Border.all(color: AppColors.tinta, width: AppShape.borde),
            boxShadow: AppShape.sombra(
              activa ? AppShape.sombraNormal : const Offset(2, 2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (color != null) ...<Widget>[
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.tinta, width: 2),
                  ),
                ),
                const SizedBox(width: 8),
              ] else if (emoji != null) ...<Widget>[
                Text(emoji!, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  texto,
                  // El texto activo va sobre el color elegido, y hay colores
                  // de esta paleta que no admiten tinta encima.
                  style: AppTypography.etiqueta.copyWith(
                    fontSize: 13.5,
                    color: activa
                        ? AppColors.textoSobre(colorActiva)
                        : AppColors.tinta,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Un segundo indicador además del color. Quien no distingue el
              // verde del gris necesita algo más que un relleno para saber
              // qué tiene marcado.
              if (activa) ...<Widget>[
                const SizedBox(width: 6),
                Icon(
                  Icons.check_rounded,
                  size: 15,
                  color: AppColors.textoSobre(colorActiva),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
