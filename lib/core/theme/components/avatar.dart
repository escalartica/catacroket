import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/persona.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_shape.dart';
import '../tokens/app_typography.dart';

/// Avatar de una persona: inicial sobre su color, con contorno.
class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.persona, this.tamano = 32});

  final Persona persona;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    // Sin esto un lector de pantalla lee la inicial suelta —"M"— sin decir
    // de quién es, y una foto no dice nada en absoluto.
    return Semantics(
      label: persona.nombre,
      image: persona.foto != null,
      excludeSemantics: true,
      child: Container(
        width: tamano,
        height: tamano,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: persona.color,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.tinta, width: AppShape.bordeFino),
        ),
        // El recorte queda por dentro del borde, que así enmarca la foto en
        // vez de quedar tapado por ella.
        child: ClipOval(
          child: _contenido,
        ),
      ),
    );
  }

  Widget get _contenido {
    final String? foto = persona.foto;
    if (foto == null || !File(foto).existsSync()) return _inicial;

    return Image.file(
      File(foto),
      width: tamano,
      height: tamano,
      fit: BoxFit.cover,
      // Si el fichero desaparece, vuelve la inicial en vez de un hueco roto.
      errorBuilder: (_, _, _) => _inicial,
    );
  }

  Widget get _inicial => Container(
        width: tamano,
        height: tamano,
        color: persona.color,
        alignment: Alignment.center,
        child: Text(
          persona.inicial,
          style: AppTypography.etiqueta.copyWith(fontSize: tamano * 0.42),
        ),
      );
}

/// Avatares superpuestos. A partir de [maximo] aparece un "+N" en vez de
/// seguir apilando, que es lo que evita que una mesa de diez desborde la fila.
class PilaAvatares extends StatelessWidget {
  const PilaAvatares({
    super.key,
    required this.personas,
    this.tamano = 32,
    this.maximo = 4,
  });

  final List<Persona> personas;
  final double tamano;
  final int maximo;

  @override
  Widget build(BuildContext context) {
    final List<Persona> visibles = personas.take(maximo).toList();
    final int restantes = personas.length - visibles.length;

    // Una sola etiqueta para toda la pila. Avatar por avatar sonaba a
    // "M", "J", "A", "más 2": cuatro nodos sueltos que no se entienden
    // juntos. Como grupo se lee de un tirón, que es lo que es.
    return Semantics(
      label: enVoz(personas, restantes),
      excludeSemantics: true,
      child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < visibles.length; i++)
          Transform.translate(
            offset: Offset(-9.0 * i, 0),
            child: Avatar(persona: visibles[i], tamano: tamano),
          ),
        if (restantes > 0)
          Transform.translate(
            offset: Offset(-9.0 * visibles.length, 0),
            child: Container(
              width: tamano,
              height: tamano,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.superficieHonda,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.tinta, width: AppShape.bordeFino),
              ),
              child: Text(
                '+$restantes',
                style: AppTypography.etiqueta.copyWith(fontSize: tamano * 0.34),
              ),
            ),
          ),
      ],
      ),
    );
  }

  /// "Marta, Javi y Ana" o "Marta, Javi, Ana y 2 más".
  @visibleForTesting
  static String enVoz(List<Persona> personas, int restantes) {
    if (personas.isEmpty) return 'Nadie';

    final List<String> nombres =
        personas.take(personas.length - restantes).map((Persona p) => p.nombre).toList();
    final String cola = restantes > 0 ? '$restantes más' : nombres.removeLast();

    if (nombres.isEmpty) return cola;
    return '${nombres.join(', ')} y $cola';
  }
}
