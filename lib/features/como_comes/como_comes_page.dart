import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../arte/croqui.dart';
import '../../core/models/dieta.dart';
import '../../core/providers/evitar_provider.dart';
import '../../core/providers/mi_dieta_provider.dart';
import '../../core/providers/visto_provider.dart';
import '../../core/theme/components/boton.dart';
import '../../core/theme/components/cabecera.dart';
import '../../core/theme/components/entrada.dart';
import '../../core/theme/components/pegatina.dart';
import '../../core/theme/components/pildoras_dieta.dart';
import '../../core/theme/components/pildoras_evitar.dart';
import '../../core/theme/tokens/app_colors.dart';
import '../../core/theme/tokens/app_shape.dart';
import '../../core/theme/tokens/app_spacing.dart';
import '../../core/theme/tokens/app_typography.dart';

/// Cómo comes, preguntado al entrar por primera vez.
///
/// Antes esto vivía al final del Croquetómetro, debajo de las medallas. Un
/// celíaco tenía que catar, bajar hasta el fondo de la cuarta pestaña y
/// encontrarlo para que la app empezara a servirle. Preguntarlo de entrada
/// no es un paso mas: es lo que decide si la app le sirve o no.
///
/// Se pregunta una sola vez y se sale de un toque, porque para quien come de
/// todo no hay nada que contestar. Todo se cambia luego en Perfil.
class ComoComesPage extends ConsumerWidget {
  const ComoComesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Set<Dieta> mias = ref.watch(miDietaProvider);
    final Set<String> evitar = ref.watch(evitarProvider);
    final int marcado = mias.length + evitar.length;

    Future<void> seguir() async {
      await ref.read(vistoProvider.notifier).marcar(Visto.comoComes);
      if (context.mounted) context.go('/');
    }

    // El fondo y el area segura los pone _SinBarra, en el router. Cuando
    // esta pantalla se lo montaba por su cuenta y se olvidaba una pieza,
    // salia el negro del Scaffold con el texto de tinta encima: ilegible.
    return Column(
      children: <Widget>[
        const Cabecera(
          titulo: 'Cómo comes',
          subtitulo: 'Sólo se pregunta esta vez',
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pantalla,
              0,
              AppSpacing.pantalla,
              AppSpacing.xl,
            ),
            children: <Widget>[
              Entrada(indice: 0, child: _Presentacion(marcado: marcado)),
              const SizedBox(height: AppSpacing.l),
              Entrada(
                indice: 1,
                child: _Panel(
                  etiqueta: 'Lo que no puedes comer',
                  explicacion:
                      'Cada cata te dirá si te vale, si hay que '
                      'preguntar o si no.',
                  child: PildorasDieta(
                    marcadas: mias,
                    onAlternar:
                        ref.read(miDietaProvider.notifier).alternar,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.l),
              Entrada(
                indice: 2,
                child: _Panel(
                  etiqueta: 'Lo que no quieres que te pongan',
                  explicacion:
                      'Una alergia que no esté arriba, o algo que '
                      'simplemente no te gusta: marisco, sésamo, '
                      'boletus, cebolla.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      PildorasEvitar(
                        lista: evitar,
                        onAnadir:
                            ref.read(evitarProvider.notifier).anadir,
                        onQuitar:
                            ref.read(evitarProvider.notifier).quitar,
                      ),
                      if (evitar.isNotEmpty) ...<Widget>[
                        const SizedBox(height: AppSpacing.m),
                        Text(
                          'De esto sólo se puede avisar cuando alguien '
                          'lo haya apuntado. Que no aparezca no quiere '
                          'decir que no lleve.',
                          style: AppTypography.cuerpoS.copyWith(
                            fontSize: 12.5,
                            height: 1.3,
                            color: AppColors.tintaSuave,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.l),
              Entrada(
                indice: 3,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('🤝', style: TextStyle(fontSize: 15)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'La app cuenta lo que apuntó quien fue antes '
                        'que ti, no lo que hay hoy en la cocina. Si hay '
                        'alergia de por medio, en el bar pregunta igual.',
                        style: AppTypography.cuerpoS.copyWith(
                          fontSize: 12.5,
                          height: 1.35,
                          color: AppColors.tintaSuave,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _Pie(marcado: marcado, onSeguir: seguir),
      ],
    );
  }
}

/// Croqui y la frase que dice por qué se pregunta esto.
///
/// La mascota va dentro de su chapa y no suelta en mitad de la pantalla: en
/// una app hecha de pegatinas, un dibujo flotando es el único elemento sin
/// borde ni sombra y se nota.
class _Presentacion extends StatelessWidget {
  const _Presentacion({required this.marcado});

  final int marcado;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Transform.rotate(
          angle: -0.06,
          child: Container(
            width: 92,
            height: 92,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.sol,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.tinta, width: AppShape.borde),
              boxShadow: AppShape.sombra(AppShape.sombraChica),
            ),
            child: const Croqui(ancho: 62, conProps: false),
          ),
        ),
        const SizedBox(width: AppSpacing.m),
        Expanded(
          child: Text(
            marcado == 0
                ? 'Si comes de todo no tienes nada que hacer aquí: dale al '
                    'botón de abajo y adentro.'
                : 'Con esto la app deja de ser un catálogo y pasa a saber para '
                    'quién trabaja.',
            style: AppTypography.cuerpo.copyWith(height: 1.4),
          ),
        ),
      ],
    );
  }
}

/// Un bloque de la pantalla: etiqueta en versales, una frase y el control.
///
/// Los dos bloques son distintos de verdad y no sólo dos listas seguidas: uno
/// lo deduce la app de la receta y el otro es texto tuyo. Separarlos en dos
/// pegatinas es lo que hace que no se confundan.
class _Panel extends StatelessWidget {
  const _Panel({
    required this.etiqueta,
    required this.explicacion,
    required this.child,
  });

  final String etiqueta;
  final String explicacion;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Pegatina(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          EtiquetaPanel(texto: etiqueta),
          const SizedBox(height: AppSpacing.m),
          Text(
            explicacion,
            style: AppTypography.cuerpoS.copyWith(height: 1.35),
          ),
          const SizedBox(height: AppSpacing.l),
          child,
        ],
      ),
    );
  }
}

/// El pie fijo: cuenta lo marcado y deja salir.
///
/// Fijo y no al final de la lista porque la salida no puede depender de que
/// llegues al fondo haciendo scroll. El degradado de arriba deja claro que
/// hay más contenido por debajo en vez de cortarlo a hachazo.
class _Pie extends StatelessWidget {
  const _Pie({required this.marcado, required this.onSeguir});

  final int marcado;
  final Future<void> Function() onSeguir;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            AppColors.fondo.withValues(alpha: 0),
            AppColors.fondo,
            AppColors.fondo,
          ],
          stops: const <double>[0, 0.35, 1],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pantalla,
        AppSpacing.l,
        AppSpacing.pantalla,
        AppSpacing.m,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          BotonPegatina(
            texto: marcado == 0 ? 'Como de todo' : 'Listo, son $marcado',
            icono: marcado == 0
                ? Icons.check_rounded
                : Icons.arrow_forward_rounded,
            color: marcado == 0 ? AppColors.sol : AppColors.menta,
            ancho: double.infinity,
            onTap: onSeguir,
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            'Se cambia cuando quieras en Perfil',
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
