import 'package:flutter/material.dart';

import '../../data/paises.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_shape.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'campo.dart';
import 'pegatina.dart';

/// Botón que abre la lista de países.
class BotonPais extends StatelessWidget {
  const BotonPais({super.key, required this.codigo, required this.onCambio});

  final String codigo;
  final ValueChanged<String> onCambio;

  @override
  Widget build(BuildContext context) {
    final Pais pais = Paises.de(codigo);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('PAÍS', style: AppTypography.antetitulo),
        const SizedBox(height: 7),
        Pegatina(
          radio: AppShape.radioM,
          sombra: AppShape.sombraChica,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          onTap: () async {
            final String? elegido = await mostrarSelectorPais(context, codigo);
            if (elegido != null) onCambio(elegido);
          },
          child: Row(
            children: <Widget>[
              Text(pais.bandera, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(child: Text(pais.nombre, style: AppTypography.cuerpo)),
              const Icon(Icons.expand_more_rounded, color: AppColors.tinta),
            ],
          ),
        ),
      ],
    );
  }
}

/// Hoja con buscador. Devuelve el código elegido o nulo si se cierra.
Future<String?> mostrarSelectorPais(BuildContext context, String actual) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) => _HojaPaises(actual: actual),
  );
}

class _HojaPaises extends StatefulWidget {
  const _HojaPaises({required this.actual});

  final String actual;

  @override
  State<_HojaPaises> createState() => _HojaPaisesState();
}

class _HojaPaisesState extends State<_HojaPaises> {
  String _busqueda = '';

  @override
  Widget build(BuildContext context) {
    final List<Pais> resultados = Paises.buscar(_busqueda);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        height: MediaQuery.sizeOf(context).height * 0.78,
        decoration: const BoxDecoration(
          color: AppColors.fondo,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppShape.radioXL),
          ),
          border: Border(
            top: BorderSide(color: AppColors.tinta, width: AppShape.borde),
            left: BorderSide(color: AppColors.tinta, width: AppShape.borde),
            right: BorderSide(color: AppColors.tinta, width: AppShape.borde),
          ),
        ),
        child: Column(
          children: <Widget>[
            Container(
              width: 56,
              height: 7,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.tinta,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pantalla,
                0,
                AppSpacing.pantalla,
                AppSpacing.m,
              ),
              child: Campo(
                etiqueta: '¿Dónde te la comiste?',
                valor: '',
                pista: 'Busca un país…',
                onCambio: (String v) => setState(() => _busqueda = v),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pantalla,
                  0,
                  AppSpacing.pantalla,
                  AppSpacing.xxl,
                ),
                itemCount: resultados.length,
                itemBuilder: (BuildContext context, int i) {
                  final Pais pais = resultados[i];
                  final bool elegido = pais.codigo == widget.actual;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.s),
                    child: Pegatina(
                      color: elegido ? AppColors.sol : AppColors.superficie,
                      radio: AppShape.radioM,
                      sombra: elegido
                          ? AppShape.sombraNormal
                          : const Offset(2, 2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      onTap: () => Navigator.of(context).pop(pais.codigo),
                      child: Row(
                        children: <Widget>[
                          Text(pais.bandera, style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(pais.nombre, style: AppTypography.cuerpo),
                          ),
                          if (elegido)
                            const Icon(Icons.check_rounded, color: AppColors.tinta),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
