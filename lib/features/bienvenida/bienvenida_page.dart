import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/visto_provider.dart';

import '../../core/theme/tokens/app_colors.dart';
import '../../core/theme/tokens/app_spacing.dart';
import '../../core/theme/tokens/app_typography.dart';

/// La bienvenida: la chapa del logo, dos segundos, y adentro.
///
/// Existe por una razón concreta y no por adorno: la app abre en un feed de
/// tarjetas, y sin este paso la marca no se ve NUNCA dentro del producto.
/// Dos segundos al arrancar es donde cabe sin estorbar.
class BienvenidaPage extends ConsumerStatefulWidget {
  const BienvenidaPage({super.key});

  @override
  ConsumerState<BienvenidaPage> createState() => _BienvenidaPageState();
}

class _BienvenidaPageState extends ConsumerState<BienvenidaPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _control = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  bool _yendo = false;

  @override
  void initState() {
    super.initState();
    _control.forward();

    // Con "reducir movimiento" puesto, la chapa no rebota y la espera baja a
    // medio segundo: quien apaga las animaciones no está pidiendo una versión
    // más lenta de la misma animación.
    final bool quieto = WidgetsBinding
        .instance.platformDispatcher.accessibilityFeatures.disableAnimations;

    Future<void>.delayed(
      Duration(milliseconds: quieto ? 500 : 1500),
      _entrar,
    );
  }

  /// Adentro. Sirve para el temporizador y para el toque, y por eso lleva el
  /// pestillo: si tocas justo cuando salta el reloj, se navegaría dos veces y
  /// la pantalla parpadearía.
  ///
  /// La primera vez se pasa por "Cómo comes" y a partir de ahí, directo a La
  /// Vitrina.
  Future<void> _entrar() async {
    if (_yendo || !mounted) return;
    _yendo = true;

    // Saber si ya se contestó exige haber leído el disco. Normalmente está
    // listo mucho antes que el segundo y medio del logo; si no, se espera un
    // poco más antes que enseñar la pregunta a quien ya la contestó.
    for (int intento = 0; intento < 20; intento++) {
      if (ref.read(vistoProvider.notifier).cargado) break;
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    if (!mounted) return;

    final bool preguntar = !ref
        .read(vistoProvider)
        .contains(Visto.comoComes.id);
    context.go(preguntar ? '/como-comes' : '/');
  }

  @override
  void dispose() {
    _control.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CurvedAnimation entrada = CurvedAnimation(
      parent: _control,
      curve: Curves.elasticOut,
    );
    final CurvedAnimation texto = CurvedAnimation(
      parent: _control,
      curve: const Interval(0.45, 1, curve: Curves.easeOut),
    );

    return Scaffold(
      backgroundColor: AppColors.tomate,
      // Toda la pantalla salta la espera. Segundo y medio no es mucho, pero
      // se paga en cada arranque y quien ya ha visto el logo tiene derecho a
      // saltárselo.
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _entrar(),
        child: Semantics(
          label: 'Catacroket. Toca para entrar.',
          button: true,
          child: Stack(
        children: <Widget>[
          Positioned.fill(child: CustomPaint(painter: const _Lunares())),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ScaleTransition(
                  scale: entrada,
                  child: RotationTransition(
                    turns: Tween<double>(begin: -0.06, end: 0)
                        .animate(entrada),
                    child: SvgPicture.asset(
                      'assets/brand/logo.svg',
                      width: 260,
                      semanticsLabel: 'Catacroket',
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                FadeTransition(
                  opacity: texto,
                  child: Text(
                    'Cata, puntúa, presume.',
                    style: AppTypography.tituloS.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
          ),
        ),
      ),
    );
  }
}

class _Lunares extends CustomPainter {
  const _Lunares();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint pincel = Paint()..color = Colors.white.withValues(alpha: 0.16);
    const double paso = 26;
    for (double y = 0; y < size.height + paso; y += paso) {
      final double desvio = ((y / paso).round() % 2) * paso / 2;
      for (double x = desvio; x < size.width + paso; x += paso) {
        canvas.drawCircle(Offset(x, y), 3.4, pincel);
      }
    }
  }

  @override
  bool shouldRepaint(_Lunares viejo) => false;
}
