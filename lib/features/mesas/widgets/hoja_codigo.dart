import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/mesa.dart';
import '../../../core/providers/cuenta_provider.dart';
import '../../../core/providers/mesas_provider.dart';
import '../../../core/services/nube_service.dart';
import '../../../core/theme/components/boton.dart';
import '../../../core/theme/components/campo.dart';
import '../../../core/theme/tokens/app_colors.dart';
import '../../../core/theme/tokens/app_shape.dart';
import '../../../core/theme/tokens/app_spacing.dart';
import '../../../core/theme/tokens/app_typography.dart';
import '../../cuenta/hoja_cuenta.dart';

/// Entrar en la mesa de otro con su código de seis letras.
Future<Mesa?> hojaCodigo(BuildContext context) {
  return showModalBottomSheet<Mesa>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) => const _HojaCodigo(),
  );
}

class _HojaCodigo extends ConsumerStatefulWidget {
  const _HojaCodigo();

  @override
  ConsumerState<_HojaCodigo> createState() => _HojaCodigoState();
}

class _HojaCodigoState extends ConsumerState<_HojaCodigo> {
  String _codigo = '';
  bool _trabajando = false;
  String? _fallo;

  Future<void> _entrar() async {
    // Sin cuenta no hay a quién dejar entrar: el servidor necesita saber a
    // quién añade a la mesa. Se ofrece entrar ahí mismo en vez de mandar a
    // buscarlo al perfil.
    if (!ref.read(haySesionProvider)) {
      final bool entro = await hojaCuenta(context);
      if (!entro) return;
    }

    setState(() {
      _trabajando = true;
      _fallo = null;
    });

    try {
      final Mesa mesa =
          await ref.read(mesasProvider.notifier).entrarCon(_codigo);
      if (mounted) Navigator.of(context).pop(mesa);
    } on FalloNube catch (e) {
      if (mounted) setState(() => _fallo = e.mensaje);
    } finally {
      if (mounted) setState(() => _trabajando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.crema,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppShape.radioL),
          ),
          border: Border(
            top: BorderSide(color: AppColors.tinta, width: AppShape.borde),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pantalla,
          AppSpacing.m,
          AppSpacing.pantalla,
          AppSpacing.xl,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.tinta,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.l),
              Text(
                'Entrar en una mesa',
                style: AppTypography.tituloL,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Pide el código de seis letras a quien la creó. Lo tiene en '
                'la ficha de su mesa.',
                style: AppTypography.cuerpoS.copyWith(
                  color: AppColors.tintaSuave,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.l),
              Campo(
                etiqueta: 'El código',
                valor: _codigo,
                pista: 'Seis letras',
                autofoco: true,
                onCambio: (String v) => setState(() => _codigo = v),
                // Mayúsculas y sin espacios: el código se dicta en voz alta
                // en un bar y nadie lo teclea igual que está escrito.
                formateadores: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
                  LengthLimitingTextInputFormatter(6),
                  _AMayusculas(),
                ],
              ),
              if (_fallo != null) ...<Widget>[
                const SizedBox(height: AppSpacing.m),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.tomate.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(AppShape.radioM),
                    border: Border.all(
                      color: AppColors.tinta,
                      width: AppShape.bordeFino,
                    ),
                  ),
                  child: Text(
                    _fallo!,
                    style: AppTypography.cuerpoS.copyWith(
                      color: AppColors.textoSobre(AppColors.tomate),
                      height: 1.3,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.l),
              BotonPegatina(
                texto: _trabajando ? 'Entrando…' : 'Entrar',
                onTap: _codigo.length == 6 && !_trabajando ? _entrar : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// El código siempre en mayúsculas, se teclee como se teclee.
class _AMayusculas extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue antes,
    TextEditingValue ahora,
  ) =>
      TextEditingValue(
        text: ahora.text.toUpperCase(),
        selection: ahora.selection,
      );
}
