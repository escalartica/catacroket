import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/mesa.dart';
import '../../../core/providers/mesas_provider.dart';
import '../../../core/theme/components/boton.dart';
import '../../../core/theme/components/campo.dart';
import '../../../core/theme/tokens/app_colors.dart';
import '../../../core/theme/tokens/app_shape.dart';
import '../../../core/theme/tokens/app_spacing.dart';
import '../../../core/theme/tokens/app_typography.dart';

/// Crea una mesa o cambia una que ya existe.
///
/// Devuelve la mesa resultante, o nulo si se cerró sin guardar. Es la misma
/// hoja para los dos casos por lo mismo que el formulario de catas: dos
/// pantallas que piden lo mismo acaban pidiendo cosas distintas.
Future<Mesa?> hojaMesa(BuildContext context, {Mesa? mesa}) {
  return showModalBottomSheet<Mesa>(
    context: context,
    // Por el Navigator raíz: si no, la hoja se abre dentro de la concha y la
    // barra de pestañas se dibuja encima, tapando los botones de abajo. En la
    // de crear una mesa dejaba "Crear la mesa" y "Cancelar" inalcanzables.
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) => _HojaMesa(mesa: mesa),
  );
}

/// Los colores que puede tener una mesa.
///
/// Son los de la app y no un selector libre: el color de la mesa tiñe
/// tarjetas enteras, y dejar elegir un gris o un amarillo flúor es dejar
/// elegir una pantalla ilegible.
/// Los colores que puede llevar una mesa, con su nombre.
///
/// El nombre no es decorativo: sin él el selector es una fila de círculos
/// mudos para quien no los ve o no los distingue.
const List<(Color, String)> _paleta = <(Color, String)>[
  (AppColors.sol, 'Amarillo'),
  (AppColors.tomate, 'Rojo'),
  (AppColors.menta, 'Verde menta'),
  (AppColors.uva, 'Morado'),
  (AppColors.cielo, 'Azul'),
  (AppColors.chicle, 'Rosa'),
  (AppColors.lima, 'Verde lima'),
  (AppColors.mango, 'Naranja'),
];

class _HojaMesa extends ConsumerStatefulWidget {
  const _HojaMesa({this.mesa});

  final Mesa? mesa;

  @override
  ConsumerState<_HojaMesa> createState() => _HojaMesaState();
}

class _HojaMesaState extends ConsumerState<_HojaMesa> {
  late String _nombre = widget.mesa?.nombre ?? '';
  late String _descripcion = widget.mesa?.descripcion ?? '';
  late int _color = widget.mesa?.colorHex ?? AppColors.tomate.toARGB32();
  bool _guardando = false;

  bool get _esNueva => widget.mesa == null;

  Future<void> _guardar() async {
    if (_guardando || _nombre.trim().isEmpty) return;
    setState(() => _guardando = true);

    final MesasNotifier mesas = ref.read(mesasProvider.notifier);
    Mesa resultado;

    if (_esNueva) {
      resultado = await mesas.crear(
        nombre: _nombre,
        descripcion: _descripcion,
        colorHex: _color,
      );
    } else {
      await mesas.editar(
        widget.mesa!.id,
        nombre: _nombre,
        descripcion: _descripcion,
        colorHex: _color,
      );
      resultado = ref.read(mesaProvider(widget.mesa!.id)) ?? widget.mesa!;
    }

    if (!mounted) return;
    Navigator.of(context).pop(resultado);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.s),
        padding: const EdgeInsets.all(AppSpacing.l),
        decoration: BoxDecoration(
          color: AppColors.fondo,
          borderRadius: BorderRadius.circular(AppShape.radioXL),
          border: Border.all(color: AppColors.tinta, width: AppShape.borde),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                _esNueva ? 'Una mesa nueva' : 'Cambiar la mesa',
                style: AppTypography.tituloM,
              ),
              const SizedBox(height: AppSpacing.l),
              Campo(
                etiqueta: 'Nombre',
                valor: _nombre,
                pista: 'Los Croquetólogos',
                autofoco: _esNueva,
                onCambio: (String v) => setState(() => _nombre = v),
              ),
              const SizedBox(height: AppSpacing.l),
              Campo(
                etiqueta: 'De qué va',
                valor: _descripcion,
                pista: 'Los domingos, sin método y sin remordimiento.',
                lineas: 2,
                onCambio: (String v) => setState(() => _descripcion = v),
              ),
              const SizedBox(height: AppSpacing.l),
              Text('COLOR', style: AppTypography.antetitulo),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  for (final (Color c, String nombre) in _paleta)
                    _Tinte(
                      nombre: nombre,
                      color: c,
                      elegido: _color == c.toARGB32(),
                      onTap: () => setState(() => _color = c.toARGB32()),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              BotonPegatina(
                texto: _guardando
                    ? 'Guardando…'
                    : _esNueva
                        ? 'Crear la mesa'
                        : 'Guardar',
                color: AppColors.tomate,
                onTap: _nombre.trim().isEmpty || _guardando ? null : _guardar,
              ),
              const SizedBox(height: AppSpacing.s),
              BotonPegatina.fantasma(
                texto: 'Cancelar',
                pequeno: true,
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tinte extends StatelessWidget {
  const _Tinte({
    required this.color,
    required this.nombre,
    required this.elegido,
    required this.onTap,
  });

  final Color color;

  /// Cómo se llama este color en voz alta.
  final String nombre;

  final bool elegido;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: elegido,
      inMutuallyExclusiveGroup: true,
      label: nombre,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.tinta,
              width: elegido ? 4 : AppShape.bordeFino,
            ),
            boxShadow: elegido ? AppShape.sombra(const Offset(2, 2)) : null,
          ),
          child: elegido
              ? const Icon(Icons.check_rounded, size: 20, color: AppColors.tinta)
              : null,
        ),
      ),
    );
  }
}
