import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/rellenos.dart';
import '../../models/dieta.dart';
import '../../providers/mi_dieta_provider.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_shape.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'campo.dart';

/// El selector de relleno.
///
/// Tres decisiones para que treinta y tres rellenos no sean un muro:
///
/// 1. **Enseña sólo lo tuyo.** Si has dicho que eres vegano, las de jamón y
///    las de gamba no aparecen. No es sólo ahorro de scroll: una lista que
///    empieza por cosas que no puedes comer es la app diciéndote que no está
///    hecha para ti.
/// 2. **Pero se puede salir.** Un enlace discreto enseña todas. A veces
///    apuntas la croqueta que se comió otro, o el bar te sorprende. Filtrar
///    está bien; decidir por el usuario, no.
/// 3. **Buscador cuando hace falta.** Sólo aparece si quedan muchas a la
///    vista; con seis pastillas un buscador es ruido.
class PildorasRelleno extends ConsumerStatefulWidget {
  const PildorasRelleno({
    super.key,
    required this.elegidos,
    required this.onAlternar,
    required this.propio,
    required this.onPropio,
  });

  /// Los ingredientes elegidos. El primero manda: es el que da color.
  final Set<String> elegidos;
  final void Function(String) onAlternar;

  /// Lo que el usuario haya escrito a mano.
  final String propio;
  final void Function(String) onPropio;

  @override
  ConsumerState<PildorasRelleno> createState() => _PildorasRellenoState();
}

class _PildorasRellenoState extends ConsumerState<PildorasRelleno> {
  final TextEditingController _buscador = TextEditingController();
  bool _verTodos = false;
  String _busqueda = '';

  @override
  void dispose() {
    _buscador.dispose();
    super.dispose();
  }

  void _limpiarBusqueda() {
    _buscador.clear();
    setState(() => _busqueda = '');
  }

  /// A partir de aquí, buscar sale más a cuenta que mirar.
  static const int _umbralBuscador = 14;

  @override
  Widget build(BuildContext context) {
    final Set<Dieta> mias = ref.watch(miDietaProvider);
    final PerfilRelleno? limite = _limiteDe(mias);
    final bool filtrando = limite != null && !_verTodos;

    // Dos cosas no desaparecen nunca:
    //
    // - Lo ya elegido, ni al filtrar ni al buscar: ver esfumarse algo que
    //   acabas de marcar da la sensación de haberlo perdido.
    // - "A mi manera", que es la salida para lo que no está en la lista. Se
    //   escondía al buscar, y entonces el mensaje decía "elige «A mi manera»"
    //   señalando a una pastilla que no estaba en pantalla. Callejón sin
    //   salida, y de los que hacen cerrar la app.
    final List<Relleno> visibles = Rellenos.todos.where((Relleno r) {
      if (widget.elegidos.contains(r.id)) return true;
      if (r.perfil == PerfilRelleno.sinSaber) return true;
      if (filtrando && !_cuadra(r, limite)) return false;
      return _coincide(r, _busqueda);
    }).toList();

    final bool buscando = _busqueda.trim().isNotEmpty;
    final bool sinResultados = buscando &&
        !visibles.any((Relleno r) => r.perfil != PerfilRelleno.sinSaber &&
            _coincide(r, _busqueda));

    final bool hayBuscador =
        (filtrando ? Rellenos.para(limite).length : Rellenos.todos.length) >=
            _umbralBuscador;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (filtrando)
          _AvisoFiltro(
            limite: limite,
            onVerTodos: () => setState(() => _verTodos = true),
          ),
        if (hayBuscador) ...<Widget>[
          const SizedBox(height: AppSpacing.s),
          _Buscador(
            control: _buscador,
            onCambio: (String v) => setState(() => _busqueda = v),
            onLimpiar: _busqueda.isEmpty ? null : _limpiarBusqueda,
          ),
          const SizedBox(height: AppSpacing.m),
        ],

        if (sinResultados) ...<Widget>[
          Text(
            'Nada con «${_busqueda.trim()}». Si no está en la lista, marca '
            '«A mi manera» aquí abajo y se escribe tal cual.',
            style: AppTypography.cuerpoS.copyWith(
              fontSize: 12.5,
              height: 1.3,
              color: AppColors.tintaSuave,
            ),
          ),
          const SizedBox(height: AppSpacing.m),
        ],

        for (final PerfilRelleno perfil in _orden(mias))
          if (visibles.any((Relleno r) => r.perfil == perfil)) ...<Widget>[
            _Grupo(perfil: perfil),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final Relleno r in visibles)
                  if (r.perfil == perfil)
                    OpcionPildora(
                      texto: r.nombre,
                      color: r.color,
                      activa: widget.elegidos.contains(r.id),
                      // Una croqueta puede ser de jamón y de calabaza a la
                      // vez, así que esto no es un botón de radio.
                      enGrupoUnico: false,
                      onTap: () => _tocar(r),
                    ),
              ],
            ),

            // "A mi manera" abre un campo: el catálogo nunca va a tener la
            // croqueta de carrillada de un bar concreto, y obligar a elegir
            // "otras" y callarse es peor que dejar escribirlo.
            if (perfil == PerfilRelleno.sinSaber &&
                widget.elegidos.contains('otro'))
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.m),
                child: Campo(
                  etiqueta: '¿De qué era?',
                  valor: widget.propio,
                  pista: 'Carrillada, pulpo a la gallega…',
                  onCambio: widget.onPropio,
                ),
              ),

            const SizedBox(height: AppSpacing.m),
          ],

      ],
    );
  }

  /// Al marcar "A mi manera" después de buscar algo, lo buscado se escribe
  /// solo: has tecleado "carrillada", no tiene sentido pedirte que lo
  /// vuelvas a teclear dos centímetros más abajo.
  void _tocar(Relleno r) {
    final bool marcando = !widget.elegidos.contains(r.id);
    widget.onAlternar(r.id);
    if (marcando &&
        r.perfil == PerfilRelleno.sinSaber &&
        widget.propio.trim().isEmpty &&
        _busqueda.trim().isNotEmpty) {
      widget.onPropio(_busqueda.trim());
      _limpiarBusqueda();
    }
  }

  /// Hasta dónde llega lo que puede comer. Nulo si come de todo.
  static PerfilRelleno? _limiteDe(Set<Dieta> mias) {
    if (mias.contains(Dieta.vegana)) return PerfilRelleno.vegano;
    if (mias.contains(Dieta.vegetariana)) return PerfilRelleno.vegetariano;
    return null;
  }

  /// "A mi manera" entra siempre: es el hueco para lo que no está, y eso no
  /// depende de cómo comas.
  static bool _cuadra(Relleno r, PerfilRelleno limite) =>
      r.perfil == PerfilRelleno.sinSaber ||
      (limite == PerfilRelleno.vegano
          ? r.perfil.esVegano
          : r.perfil.esVegetariano);

  static bool _coincide(Relleno r, String busqueda) {
    final String q = busqueda.trim().toLowerCase();
    if (q.isEmpty) return true;
    return _sinTildes(r.nombre.toLowerCase()).contains(_sinTildes(q));
  }

  static String _sinTildes(String texto) {
    const String con = 'áàäâéèëêíìïîóòöôúùüûñç';
    const String sin = 'aaaaeeeeiiiioooouuuunc';
    final StringBuffer salida = StringBuffer();
    for (final int unidad in texto.runes) {
      final String c = String.fromCharCode(unidad);
      final int i = con.indexOf(c);
      salida.write(i >= 0 ? sin[i] : c);
    }
    return salida.toString();
  }

  /// Primero lo que puedes comer, después lo demás.
  static List<PerfilRelleno> _orden(Set<Dieta> mias) {
    if (mias.contains(Dieta.vegana)) {
      return <PerfilRelleno>[
        PerfilRelleno.vegano,
        PerfilRelleno.sinSaber,
        PerfilRelleno.vegetariano,
        PerfilRelleno.carne,
        PerfilRelleno.pescado,
        PerfilRelleno.marisco,
      ];
    }
    if (mias.contains(Dieta.vegetariana)) {
      return <PerfilRelleno>[
        PerfilRelleno.vegano,
        PerfilRelleno.vegetariano,
        PerfilRelleno.sinSaber,
        PerfilRelleno.carne,
        PerfilRelleno.pescado,
        PerfilRelleno.marisco,
      ];
    }
    return <PerfilRelleno>[
      PerfilRelleno.carne,
      PerfilRelleno.pescado,
      PerfilRelleno.marisco,
      PerfilRelleno.vegetariano,
      PerfilRelleno.vegano,
      PerfilRelleno.sinSaber,
    ];
  }
}

class _AvisoFiltro extends StatelessWidget {
  const _AvisoFiltro({required this.limite, required this.onVerTodos});

  final PerfilRelleno limite;
  final VoidCallback onVerTodos;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.superficieCalida,
        borderRadius: BorderRadius.circular(AppShape.radioM),
        border: Border.all(color: AppColors.tinta, width: AppShape.bordeFino),
      ),
      child: Row(
        children: <Widget>[
          Text(limite.emoji, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              limite == PerfilRelleno.vegano
                  ? 'Viendo sólo las veganas'
                  : 'Viendo sólo las que puedes comer',
              style: AppTypography.cuerpoS.copyWith(fontSize: 12.5),
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            button: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onVerTodos,
              child: Container(
                height: 44,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Ver todas',
                  style: AppTypography.etiqueta.copyWith(
                    fontSize: 12.5,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Buscador extends StatelessWidget {
  const _Buscador({
    required this.control,
    required this.onCambio,
    required this.onLimpiar,
  });

  final TextEditingController control;
  final ValueChanged<String> onCambio;

  /// Nulo cuando no hay nada que borrar.
  final VoidCallback? onLimpiar;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(AppShape.radioPildora),
        border: Border.all(color: AppColors.tinta, width: AppShape.borde),
      ),
      padding: const EdgeInsets.only(left: 14),
      child: Row(
        children: <Widget>[
          const Icon(Icons.search_rounded, size: 20, color: AppColors.tinta),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: control,
              onChanged: onCambio,
              style: AppTypography.cuerpo.copyWith(fontSize: 15),
              cursorColor: AppColors.tinta,
              decoration: InputDecoration(
                hintText: 'Buscar relleno',
                hintStyle: AppTypography.cuerpo.copyWith(
                  fontSize: 15,
                  color: AppColors.tintaSuave,
                  fontWeight: FontWeight.w600,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
          if (onLimpiar != null)
            Semantics(
              button: true,
              label: 'Borrar la búsqueda',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onLimpiar,
                child: const SizedBox(
                  width: 46,
                  height: 46,
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.tinta,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Grupo extends StatelessWidget {
  const _Grupo({required this.perfil});

  final PerfilRelleno perfil;

  @override
  Widget build(BuildContext context) {
    final String titulo = switch (perfil) {
      PerfilRelleno.vegano => 'VEGANAS',
      PerfilRelleno.vegetariano => 'VEGETARIANAS',
      PerfilRelleno.pescado => 'PESCADO',
      PerfilRelleno.marisco => 'MARISCO',
      PerfilRelleno.carne => 'CARNE',
      PerfilRelleno.sinSaber => 'OTRAS',
    };

    return Row(
      children: <Widget>[
        Text(perfil.emoji, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 6),
        Text(
          titulo,
          style: AppTypography.antetitulo.copyWith(
            fontSize: 10.5,
            color: AppColors.tintaSuave,
          ),
        ),
      ],
    );
  }
}
