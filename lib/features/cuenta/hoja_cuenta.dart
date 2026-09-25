import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/cuenta_service.dart';
import '../../core/theme/components/boton.dart';
import '../../core/theme/components/campo.dart';
import '../../core/theme/tokens/app_colors.dart';
import '../../core/theme/tokens/app_shape.dart';
import '../../core/theme/tokens/app_spacing.dart';
import '../../core/theme/tokens/app_typography.dart';

/// Entrar o registrarse.
///
/// Se abre sólo cuando hace falta de verdad: al compartir una mesa. No hay
/// pantalla de registro al arrancar la app, y es a propósito. Apuntar tus
/// catas no necesita cuenta, y una pantalla de registro nada más abrir es lo
/// que hace que la gente desinstale antes de ver nada.
Future<bool> hojaCuenta(BuildContext context) async {
  final bool? entro = await showModalBottomSheet<bool>(
    context: context,
    // Por el Navigator raíz, como el resto de hojas: si no, la barra de
    // pestañas se dibuja encima y tapa los botones de abajo.
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) => const _HojaCuenta(),
  );
  return entro ?? false;
}

class _HojaCuenta extends ConsumerStatefulWidget {
  const _HojaCuenta();

  @override
  ConsumerState<_HojaCuenta> createState() => _HojaCuentaState();
}

class _HojaCuentaState extends ConsumerState<_HojaCuenta> {
  String _correo = '';
  String _clave = '';
  bool _registrando = false;
  bool _trabajando = false;
  String? _fallo;
  String? _aviso;

  bool get _puede =>
      _correo.trim().contains('@') && _clave.length >= 6 && !_trabajando;

  Future<void> _adelante() async {
    setState(() {
      _trabajando = true;
      _fallo = null;
      _aviso = null;
    });

    try {
      if (_registrando) {
        await CuentaService.registrarse(correo: _correo, clave: _clave);
      } else {
        await CuentaService.entrar(correo: _correo, clave: _clave);
      }
      if (mounted) Navigator.of(context).pop(true);
    } on FalloCuenta catch (e) {
      if (mounted) setState(() => _fallo = e.mensaje);
    } finally {
      if (mounted) setState(() => _trabajando = false);
    }
  }

  Future<void> _olvidada() async {
    if (!_correo.trim().contains('@')) {
      setState(() => _fallo = 'Escribe tu correo y te mandamos el enlace.');
      return;
    }
    try {
      await CuentaService.recordarClave(_correo);
      if (mounted) {
        setState(() {
          _fallo = null;
          _aviso = 'Te hemos mandado un correo para poner otra contraseña.';
        });
      }
    } on FalloCuenta catch (e) {
      if (mounted) setState(() => _fallo = e.mensaje);
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
                _registrando ? 'Crear una cuenta' : 'Entrar',
                style: AppTypography.tituloL,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Sólo hace falta para compartir mesas con tu gente. Tus catas '
                'siguen guardándose en el móvil, con cuenta o sin ella.',
                style: AppTypography.cuerpoS.copyWith(
                  color: AppColors.tintaSuave,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.l),

              Campo(
                etiqueta: 'Correo',
                valor: _correo,
                pista: 'tu@correo.com',
                teclado: TextInputType.emailAddress,
                onCambio: (String v) => setState(() => _correo = v),
              ),
              const SizedBox(height: AppSpacing.m),
              Campo(
                etiqueta: 'Contraseña',
                valor: _clave,
                pista: 'Seis caracteres como mínimo',
                oculto: true,
                onCambio: (String v) => setState(() => _clave = v),
              ),

              if (_fallo != null) ...<Widget>[
                const SizedBox(height: AppSpacing.m),
                _Aviso(texto: _fallo!, color: AppColors.tomate),
              ],
              if (_aviso != null) ...<Widget>[
                const SizedBox(height: AppSpacing.m),
                _Aviso(texto: _aviso!, color: AppColors.menta),
              ],

              const SizedBox(height: AppSpacing.l),
              BotonPegatina(
                texto: _trabajando
                    ? 'Un momento…'
                    : (_registrando ? 'Crear la cuenta' : 'Entrar'),
                onTap: _puede ? _adelante : null,
              ),
              const SizedBox(height: AppSpacing.s),
              BotonPegatina.fantasma(
                texto: _registrando
                    ? 'Ya tengo cuenta'
                    : 'No tengo cuenta todavía',
                onTap: _trabajando
                    ? null
                    : () => setState(() {
                          _registrando = !_registrando;
                          _fallo = null;
                          _aviso = null;
                        }),
              ),

              if (!_registrando) ...<Widget>[
                const SizedBox(height: AppSpacing.s),
                TextButton(
                  onPressed: _trabajando ? null : _olvidada,
                  child: Text(
                    'No me acuerdo de la contraseña',
                    style: AppTypography.cuerpoS.copyWith(
                      color: AppColors.tintaSuave,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.texto, required this.color});

  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppShape.radioM),
        border: Border.all(
          color: AppColors.tinta,
          width: AppShape.bordeFino,
        ),
      ),
      child: Text(
        texto,
        style: AppTypography.cuerpoS.copyWith(
          color: AppColors.textoSobre(color),
          height: 1.3,
        ),
      ),
    );
  }
}
