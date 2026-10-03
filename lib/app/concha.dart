import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/components/pegatina.dart';
import '../core/theme/tokens/app_colors.dart';
import '../core/theme/tokens/app_motion.dart';
import '../core/theme/tokens/app_shape.dart';
import '../core/theme/tokens/app_typography.dart';

/// El armazón de la app: fondo de lunares, contenido y barra de pestañas.
///
/// Cuatro destinos y el botón de añadir en el centro, elevado. No hay menús
/// ocultos ni un quinto sitio donde buscar cosas: si algo no está en una de
/// estas cuatro pantallas, es que no debería existir todavía.
class Concha extends StatelessWidget {
  const Concha({super.key, required this.child, required this.ruta});

  final Widget child;
  final String ruta;

  static const List<_Destino> _destinos = <_Destino>[
    _Destino(ruta: '/', icono: Icons.storefront_rounded, texto: 'La Vitrina'),
    _Destino(ruta: '/ruta', icono: Icons.map_rounded, texto: 'Ruta'),
    _Destino(ruta: '/mesas', icono: Icons.people_alt_rounded, texto: 'Mesas'),
    _Destino(ruta: '/perfil', icono: Icons.person_rounded, texto: 'Perfil'),
  ];

  /// Qué pestaña se ilumina. Las subpantallas (una cata, una mesa) heredan la
  /// pestaña de la que cuelgan, así que la barra nunca se queda "apagada".
  int get _indice {
    if (ruta.startsWith('/ruta')) return 1;
    if (ruta.startsWith('/mesas') || ruta.startsWith('/mesa/')) return 2;
    if (ruta.startsWith('/perfil')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondo,
      body: FondoLunares(
        // Las pestañas se cruzaban de golpe, de un fotograma al siguiente, y
        // eso borra la sensación de que son cuatro sitios distintos de una
        // misma app: parecían cuatro pantallas sin relación. Entra deslizando
        // un poco desde abajo y apareciendo; corto, porque cambiar de pestaña
        // se hace muchas veces al día y una transición larga acaba cansando.
        //
        // La llave es la ruta: sin ella AnimatedSwitcher no ve que haya
        // cambiado nada, porque el widget es del mismo tipo.
        child: SafeArea(
          bottom: false,
          child: AnimatedSwitcher(
            duration: AppMotion.rapida,
            switchInCurve: AppMotion.entrada,
            switchOutCurve: Curves.easeIn,
            // El saliente no se queda ocupando sitio debajo del entrante:
            // con el por defecto, los dos se dibujan a la vez centrados y el
            // contenido daba un tirón vertical.
            layoutBuilder: (Widget? actual, List<Widget> antiguos) => Stack(
              alignment: Alignment.topCenter,
              children: <Widget>[
                ...antiguos,
                ?actual,
              ],
            ),
            transitionBuilder: (Widget hijo, Animation<double> animacion) =>
                FadeTransition(
              opacity: animacion,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.012),
                  end: Offset.zero,
                ).animate(animacion),
                child: hijo,
              ),
            ),
            child: KeyedSubtree(key: ValueKey<int>(_indice), child: child),
          ),
        ),
      ),
      bottomNavigationBar: _BarraPestanas(indice: _indice, destinos: _destinos),
      extendBody: true,
    );
  }
}

class _Destino {
  const _Destino({required this.ruta, required this.icono, required this.texto});

  final String ruta;
  final IconData icono;
  final String texto;
}

class _BarraPestanas extends StatelessWidget {
  const _BarraPestanas({required this.indice, required this.destinos});

  final int indice;
  final List<_Destino> destinos;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 8,
        bottom: 8 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.superficie,
        border: Border(
          top: BorderSide(color: AppColors.tinta, width: AppShape.borde),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _Pestana(destino: destinos[0], activa: indice == 0),
          _Pestana(destino: destinos[1], activa: indice == 1),
          const _BotonAnadir(),
          _Pestana(destino: destinos[2], activa: indice == 2),
          _Pestana(destino: destinos[3], activa: indice == 3),
        ],
      ),
    );
  }
}

class _Pestana extends StatelessWidget {
  const _Pestana({required this.destino, required this.activa});

  final _Destino destino;
  final bool activa;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      // Con lector de pantalla el relleno amarillo de la pestaña activa no
      // existe: sin `selected` no hay manera de saber en qué apartado estás.
      child: Semantics(
        button: true,
        selected: activa,
        inMutuallyExclusiveGroup: true,
        label: destino.texto,
        excludeSemantics: true,
        // La acción va aquí arriba y no sólo en el hijo: `excludeSemantics`
        // descarta la semántica de dentro, la acción de pulsar incluida, así
        // que el nodo quedaba con nombre de botón y sin forma de activarse.
        // Con TalkBack la app se podía leer entera y no se podía usar: ni
        // cambiar de pestaña ni abrir una cata.
        onTap: () => context.go(destino.ruta),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            context.go(destino.ruta);
          },
          child: AnimatedContainer(
            duration: AppMotion.rapida,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(
              color: activa ? AppColors.sol : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: activa ? AppColors.tinta : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(destino.icono, size: 23, color: AppColors.tinta),
                const SizedBox(height: 2),
                Text(
                  destino.texto,
                  style: AppTypography.etiqueta.copyWith(fontSize: 10.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// El botón de añadir una cata. Rojo, elevado y más grande que todo lo demás:
/// es la única acción que crea contenido en la app.
class _BotonAnadir extends StatelessWidget {
  const _BotonAnadir();

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Transform.translate(
        offset: const Offset(0, -16),
        // heightFactor 1: sin él, el Align intentaría ocupar todo el alto
        // disponible de la fila y estiraría la barra de pestañas.
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: 1,
          // La etiqueta va DENTRO de la pegatina, no envolviéndola: la
          // pegatina declara `container: true`, que abre un límite
          // semántico, así que una etiqueta puesta por fuera no aterriza en
          // el nodo que se pulsa. Es la única acción que crea contenido en
          // toda la app, y era la que se quedaba sin nombre.
          child: Pegatina(
            etiqueta: 'Apuntar una croqueta',
            color: AppColors.tomate,
            radio: AppShape.radioPildora,
            ancho: 60,
            alto: 60,
            padding: EdgeInsets.zero,
            alineacion: Alignment.center,
            onTap: () {
              HapticFeedback.mediumImpact();
              context.push('/nueva');
            },
            child: Icon(
              Icons.add_rounded,
              size: 32,
              // Blanco sobre tomate son 3,05:1, por debajo del 3:1 que pide
              // la norma para un icono… por cinco centésimas. Que lo decida
              // el token y no la suerte.
              color: AppColors.textoSobre(AppColors.tomate),
            ),
          ),
        ),
      ),
    );
  }
}
