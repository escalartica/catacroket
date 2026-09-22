import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../arte/croqui.dart';
import '../core/theme/components/boton.dart';
import '../core/theme/components/pegatina.dart';
import '../core/theme/tokens/app_colors.dart';
import '../core/theme/tokens/app_spacing.dart';
import '../core/theme/tokens/app_typography.dart';
import '../features/vitrina/vitrina_page.dart';
import '../features/bienvenida/bienvenida_page.dart';
import '../features/como_comes/como_comes_page.dart';
import '../features/detalle/detalle_page.dart';
import '../features/libre/barra_libre_page.dart';
import '../features/mesas/mesa_detalle_page.dart';
import '../features/mesas/mesas_page.dart';
import '../features/nueva_cata/nueva_cata_page.dart';
import '../features/perfil/perfil_page.dart';
import '../features/publicada/publicada_page.dart';
import '../features/ruta/ruta_page.dart';
import 'concha.dart';

/// Rutas de la app.
///
/// Todo lo que se navega con la barra puesta cuelga de la [ShellRoute]. Las
/// dos pantallas que la ocultan —el formulario y la celebración— van fuera:
/// mientras escribes una cata no hay nada más que hacer, y esconder la barra
/// es lo que lo deja claro sin decirlo.
final GoRouter router = GoRouter(
  initialLocation: '/bienvenida',
  // Una ruta que no existe no debe sacar la pantalla de error de go_router,
  // que es un volcado de pila sobre fondo blanco. Aquí se cae con la cara de
  // la app y un camino de vuelta.
  errorBuilder: (BuildContext context, GoRouterState state) =>
      const _SinBarra(child: _RutaPerdida()),
  routes: <RouteBase>[
    GoRoute(
      path: '/bienvenida',
      builder: (BuildContext context, GoRouterState state) =>
          const BienvenidaPage(),
    ),
    // Fuera de la [ShellRoute]: se pregunta antes de que exista la app, y
    // enseñar las pestañas aquí invitaría a saltársela tocando cualquiera.
    GoRoute(
      path: '/como-comes',
      builder: (BuildContext context, GoRouterState state) =>
          const _SinBarra(child: ComoComesPage()),
    ),
    ShellRoute(
      builder: (BuildContext context, GoRouterState state, Widget child) {
        return Concha(ruta: state.uri.path, child: child);
      },
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (BuildContext context, GoRouterState state) =>
              const VitrinaPage(),
        ),
        GoRoute(
          path: '/ruta',
          // `?cata=<id>` abre el mapa ya centrado en esa cata y con su globo
          // abierto. Sin esto, "ver en la ruta" te dejaba delante de todos
          // los globos a la vez y tenías que buscar el tuyo.
          builder: (BuildContext context, GoRouterState state) =>
              RutaPage(cataInicial: state.uri.queryParameters['cata']),
        ),
        GoRoute(
          path: '/libre',
          builder: (BuildContext context, GoRouterState state) =>
              const BarraLibrePage(),
        ),
        GoRoute(
          path: '/mesas',
          builder: (BuildContext context, GoRouterState state) =>
              const MesasPage(),
        ),
        GoRoute(
          path: '/perfil',
          builder: (BuildContext context, GoRouterState state) =>
              const PerfilPage(),
        ),
        GoRoute(
          path: '/cata/:id',
          builder: (BuildContext context, GoRouterState state) =>
              DetallePage(cataId: state.pathParameters['id'] ?? ''),
        ),
        GoRoute(
          path: '/mesa/:id',
          builder: (BuildContext context, GoRouterState state) =>
              MesaDetallePage(mesaId: state.pathParameters['id'] ?? ''),
        ),
      ],
    ),
    GoRoute(
      path: '/nueva',
      pageBuilder: (BuildContext context, GoRouterState state) =>
          _desdeAbajo(state, const _SinBarra(child: NuevaCataPage())),
    ),
    GoRoute(
      path: '/editar/:id',
      pageBuilder: (BuildContext context, GoRouterState state) => _desdeAbajo(
        state,
        _SinBarra(
          child: NuevaCataPage(cataId: state.pathParameters['id']),
        ),
      ),
    ),
    GoRoute(
      path: '/publicada/:id',
      pageBuilder: (BuildContext context, GoRouterState state) => _apareciendo(
        state,
        _SinBarra(
          child: PublicadaPage(cataId: state.pathParameters['id'] ?? ''),
        ),
      ),
    ),
  ],
);

/// Entra deslizándose desde abajo: es una hoja que tapa la app, no un sitio
/// nuevo al que se viaja. Escribir una cata es una tarea, no un destino.
CustomTransitionPage<void> _desdeAbajo(GoRouterState state, Widget hijo) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: hijo,
    transitionDuration: const Duration(milliseconds: 340),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    transitionsBuilder: (
      BuildContext context,
      Animation<double> animacion,
      Animation<double> secundaria,
      Widget hijo,
    ) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: animacion, curve: Curves.easeOutCubic),
        ),
        child: hijo,
      );
    },
  );
}

/// La celebración no se desliza: aparece. Deslizarse insinuaría que vienes de
/// algún sitio, y aquí lo que ha pasado es que algo ha nacido.
CustomTransitionPage<void> _apareciendo(GoRouterState state, Widget hijo) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: hijo,
    transitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (
      BuildContext context,
      Animation<double> animacion,
      Animation<double> secundaria,
      Widget hijo,
    ) =>
        FadeTransition(opacity: animacion, child: hijo),
  );
}

/// Lo que se ve cuando se navega a algo que no existe.
///
/// No dice "error 404" ni enseña la ruta que ha fallado: a quien está catando
/// croquetas no le sirve de nada. Dice que se ha perdido y le da la vuelta.
class _RutaPerdida extends StatelessWidget {
  const _RutaPerdida();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pantalla,
          vertical: AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Croqui(ancho: 150),
            const SizedBox(height: AppSpacing.l),
            Text(
              'Esta croqueta no está en la vitrina.\nSe habrá caído por el camino.',
              textAlign: TextAlign.center,
              style: AppTypography.cuerpo,
            ),
            const SizedBox(height: AppSpacing.l),
            BotonPegatina(
              texto: 'Volver a la vitrina',
              icono: Icons.arrow_back,
              onTap: () => context.go('/'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pantalla a pantalla completa, con el fondo de la app pero sin pestañas.
class _SinBarra extends StatelessWidget {
  const _SinBarra({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondo,
      body: FondoLunares(child: SafeArea(child: child)),
    );
  }
}
