import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/borrador_provider.dart';
import '../../../core/theme/components/campo.dart';
import '../../../core/theme/components/selector_pais.dart';
import '../../../core/theme/tokens/app_spacing.dart';
import '../widgets/selector_medios.dart';
import '../widgets/selector_ubicacion.dart';

/// Paso 1: dónde estás y qué aspecto tenía.
///
/// El orden importa: primero la foto, porque es lo que se hace con la
/// croqueta delante y antes de que se enfríe; los campos de texto se rellenan
/// igual de bien después.
class PasoSitio extends ConsumerWidget {
  const PasoSitio({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Borrador borrador = ref.watch(borradorProvider);
    final BorradorNotifier notifier = ref.read(borradorProvider.notifier);

    // El orden importa. La foto iba primero, y era lo único opcional de un
    // paso que se llama "¿Dónde estás?": lo primero que veías no era dónde
    // estabas, y lo único que el botón de abajo te exige —el nombre del
    // sitio— quedaba por debajo. Ahora se pregunta lo que da título al paso,
    // y la foto va al final, que es donde va lo que puedes saltarte.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Campo(
          etiqueta: 'Sitio',
          valor: borrador.sitio,
          pista: 'Bar Manoli',
          onCambio: notifier.sitio,
        ),
        const SizedBox(height: AppSpacing.l),
        Campo(
          etiqueta: 'Ciudad',
          valor: borrador.ciudad,
          pista: 'Sevilla',
          onCambio: notifier.ciudad,
        ),
        const SizedBox(height: AppSpacing.l),
        BotonPais(codigo: borrador.pais, onCambio: notifier.pais),
        const SizedBox(height: AppSpacing.xl),
        const SelectorUbicacion(),
        const SizedBox(height: AppSpacing.xl),
        const SelectorMedios(),
      ],
    );
  }
}
