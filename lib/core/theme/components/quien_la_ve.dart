import 'package:flutter/material.dart';

import '../../models/mesa.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_motion.dart';
import '../tokens/app_shape.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import '../../utils/texto.dart';
import 'boton.dart';
import 'campo.dart';

/// Elegir quién ve una cata: nadie, una mesa o varias.
///
/// Esto vivía como un «GUARDAR EN» en letra pequeña, en el cuarto paso, entre
/// el precio y la nota. Era la decisión más importante de toda la pantalla
/// —si tu gente ve la croqueta o no la ve— vestida de campo secundario, y lo
/// que pasaba era lo esperable: la gente apuntaba la cata, se iba a su
/// libreta y su mesa no se enteraba nunca. Ahora es un bloque con su pregunta
/// delante y una frase debajo que dice en castellano lo que va a pasar.
///
/// «Sólo yo» es una opción más y no la ausencia de opciones: no marcar nada
/// no se lee como una decisión, y el silencio es justo lo que hacía que nadie
/// se diera cuenta de que había algo que decidir.
class QuienLaVe extends StatelessWidget {
  const QuienLaVe({
    super.key,
    required this.mesas,
    required this.elegidas,
    required this.onAlternar,
    required this.onSoloYo,
    this.onCrearMesa,
    this.titulo = '¿Quién la ve?',
  });

  /// Todas las mesas del móvil. La libreta se descarta aquí dentro: ya no es
  /// un destino, es tu diario, y ahí está todo lo que catas, lo compartas o
  /// no.
  final List<Mesa> mesas;

  final List<String> elegidas;
  final void Function(String mesaId) onAlternar;
  final VoidCallback onSoloYo;

  /// Qué hacer si todavía no hay ninguna mesa. Nulo: no se ofrece.
  final VoidCallback? onCrearMesa;

  final String titulo;

  List<Mesa> get _compartibles =>
      mesas.where((Mesa m) => !m.esLibreta).toList();

  List<Mesa> get _marcadas =>
      _compartibles.where((Mesa m) => elegidas.contains(m.id)).toList();

  /// Las marcadas que todavía no se han activado.
  ///
  /// Una mesa nace sin activar: existe en tu móvil y su código no funciona
  /// hasta que le das a «Activar el código» en su ficha. Marcar una cata
  /// para una mesa así no la comparte con nadie, y la app lo daba por
  /// compartido en cuatro pantallas distintas sin comprobarlo ni una vez.
  List<Mesa> get _dormidas =>
      _marcadas.where((Mesa m) => !m.enLaNube).toList();

  /// La frase de abajo, en castellano y con los nombres de verdad.
  String get _enVoz {
    final List<String> despiertas = <String>[
      for (final Mesa m in _marcadas)
        if (m.enLaNube) m.nombre,
    ];
    final List<String> dormidas =
        _dormidas.map((Mesa m) => m.nombre).toList();

    if (despiertas.isEmpty && dormidas.isEmpty) {
      return 'Sólo tú la verás. No sale de este móvil.';
    }

    final StringBuffer dice = StringBuffer();
    if (despiertas.isNotEmpty) {
      dice.write('La verá la gente de ${Texto.enumerar(despiertas)}.');
    }
    if (dormidas.isNotEmpty) {
      if (dice.isNotEmpty) dice.write(' ');
      dice.write(
        dormidas.length == 1
            ? '«${dormidas.first}» todavía no está activada: hasta que '
                'actives su código no la verá nadie.'
            : '${Texto.enumerar(dormidas)} todavía no están activadas: hasta '
                'que actives sus códigos no las verá nadie.',
      );
    }
    return dice.toString();
  }

  @override
  Widget build(BuildContext context) {
    final List<Mesa> compartibles = _compartibles;
    final bool soloYo = _marcadas.isEmpty;
    final bool hayDormidas = _dormidas.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(titulo, style: AppTypography.tituloM),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            OpcionPildora(
              texto: 'Sólo yo',
              emoji: '🔒',
              activa: soloYo,
              // De marcar varias, no de radio: puedes poner una cata en dos
              // mesas a la vez, y anunciarlo como opción única le diría a
              // quien usa lector de pantalla justo lo contrario.
              enGrupoUnico: false,
              onTap: onSoloYo,
            ),
            for (final Mesa m in compartibles)
              OpcionPildora(
                // El «sin activar» va en la propia píldora: es lo que decide
                // si la croqueta sale del móvil o no, y enterarse después de
                // publicarla no sirve de nada.
                texto: m.enLaNube ? m.nombre : '${m.nombre} · sin activar',
                activa: elegidas.contains(m.id),
                enGrupoUnico: false,
                colorActiva: Color(m.colorHex),
                onTap: () => onAlternar(m.id),
              ),
          ],
        ),
        const SizedBox(height: 10),

        // La frase cambia con un fundido, no de golpe: es lo único que
        // confirma que la pulsación ha hecho algo, y saltando no se nota.
        AnimatedSwitcher(
          duration: AppMotion.rapida,
          child: Container(
            key: ValueKey<String>(_enVoz),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: hayDormidas
                  ? AppColors.sol.withValues(alpha: 0.5)
                  : soloYo
                      ? AppColors.superficieCalida
                      : AppColors.menta.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(AppShape.radioM),
            ),
            child: Row(
              children: <Widget>[
                Text(
                  hayDormidas
                      ? '⚠️'
                      : soloYo
                          ? '🔒'
                          : '👀',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _enVoz,
                    style: AppTypography.cuerpoS.copyWith(height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ),

        if (compartibles.isEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.s),
          Text(
            'Todavía no tienes ninguna mesa: una mesa es tu grupo, la gente '
            'con la que catas. Créala y podrás enseñarles tus croquetas.',
            style: AppTypography.cuerpoS.copyWith(
              fontSize: 12.5,
              color: AppColors.tintaSuave,
              height: 1.35,
            ),
          ),
          if (onCrearMesa != null) ...<Widget>[
            const SizedBox(height: AppSpacing.s),
            // Con su botón. Antes decía «créala en Mesas» y ya está, y desde
            // el formulario de una cata nueva la barra de pestañas está
            // escondida: para ir a Mesas había que abandonar la croqueta a
            // medias. Un vacío que manda a un sitio al que no se puede ir.
            BotonPegatina.fantasma(
              texto: 'Crear mi primera mesa',
              icono: Icons.add_rounded,
              pequeno: true,
              onTap: onCrearMesa,
            ),
          ],
        ],
      ],
    );
  }
}
