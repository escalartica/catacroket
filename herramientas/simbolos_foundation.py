"""Qué símbolos de foundation NO llegan importando sólo material.dart.

Se lee del SDK de Flutter instalado, no de la memoria de nadie. Sirve para
rehacer la lista `DE_FOUNDATION` de revisar.py cuando se actualice Flutter.

    python3 herramientas/simbolos_foundation.py [ruta/al/sdk/flutter]
"""

import pathlib
import re
import sys

CANDIDATOS = (
    'kReleaseMode', 'kDebugMode', 'kProfileMode', 'kIsWeb', 'compute',
    'listEquals', 'mapEquals', 'setEquals', 'describeIdentity',
    'objectRuntimeType', 'visibleForTesting', 'immutable', 'protected',
    'debugPrint', 'ValueNotifier', 'ChangeNotifier', 'defaultTargetPlatform',
)

PATRON = re.compile(r"export\s+'[^']*foundation\.dart'\s*(?:show\s*([^;]+))?;", re.S)


def reexportados(lib):
    """Lo que la cadena de material.dart acaba reexportando de foundation."""
    fuera = set()
    carpetas = ['*.dart', 'src/widgets/*.dart', 'src/material/*.dart',
                'src/rendering/*.dart', 'src/painting/*.dart',
                'src/services/*.dart']
    for patron in carpetas:
        for f in lib.glob(patron):
            try:
                texto = f.read_text(encoding='utf-8')
            except OSError:
                continue
            for m in PATRON.finditer(texto):
                if m.group(1):
                    fuera.update(x.strip() for x in m.group(1).split(',') if x.strip())
    return fuera


def main():
    # Por defecto, al lado del proyecto: es donde suele vivir el SDK cuando
    # se clona Flutter a mano, y evita depender de $HOME, que cambia segun
    # desde donde se lance esto.
    if len(sys.argv) > 1:
        sdk = pathlib.Path(sys.argv[1])
    else:
        sdk = pathlib.Path(__file__).resolve().parent.parent.parent / 'flutter'
    lib = sdk / 'packages/flutter/lib'
    if not lib.exists():
        print(f'No encuentro el SDK en {sdk}. Pásame la ruta como argumento.')
        return 1

    llegan = reexportados(lib)
    faltan = [c for c in CANDIDATOS if c not in llegan]

    print('Necesitan import de foundation:')
    for c in faltan:
        print(f'    {c!r},')
    print()
    print('Llegan con material.dart:',
          ', '.join(c for c in CANDIDATOS if c in llegan))
    return 0


if __name__ == '__main__':
    sys.exit(main())
