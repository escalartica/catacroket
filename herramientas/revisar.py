#!/usr/bin/env python3
"""Comprobaciones rápidas sobre lib/, sin compilar.

No sustituye a `flutter analyze`, que es quien manda. Sirve para pasarlo
antes de compilar y pillar lo que más veces ha roto la compilación aquí: un
símbolo usado sin importar, un import roto, un asset que no existe, llaves
descuadradas y nombres con tilde (Dart sólo admite ASCII en los
identificadores, aunque las cadenas y los comentarios vayan en español).

Uso:  python3 herramientas/revisar.py
"""
import re
import sys
import pathlib

RAIZ = pathlib.Path(__file__).resolve().parent.parent

# Se mira TODO el proyecto y no sólo `lib/`.
#
# `flutter analyze` analiza cualquier .dart del proyecto, incluido uno
# olvidado en una carpeta suelta, y eso ya ha costado una compilación: un
# fichero viejo en `_to_delete/` con imports rotos tumbaba el análisis entero
# mientras este comprobador decía que todo estaba bien.
CARPETAS_FUERA = {'build', '.dart_tool', 'ios', 'android', 'macos', 'windows',
                  'linux', 'web', '.git', 'herramientas'}

# El nombre del paquete, para resolver los `package:<nombre>/...` de los tests.
PAQUETE = 'catacroket'

CODIGO, BLOQUE, INTERP, CADENA = 'codigo', 'bloque', 'interp', 'cadena'


def solo_codigo(texto):
    """Quita cadenas y comentarios, dejando el código en su sitio.

    Hace falta recorrer el texto y no una expresión regular porque Dart
    permite cadenas dentro de la interpolación de otra cadena:
    `'${Formato.plural(n, 'país', 'países')}'`. Un `re.sub` corta en la
    primera comilla interior y deja trozos sueltos que parecen código.
    """
    fuera = []
    pila = [[CODIGO, None, None]]
    i, n = 0, len(texto)

    while i < n:
        marco = pila[-1]
        c = texto[i]

        if marco[0] != CADENA:
            if texto.startswith('//', i):
                j = texto.find('\n', i)
                i = n if j < 0 else j
                continue
            if texto.startswith('/*', i):
                j = texto.find('*/', i + 2)
                i = n if j < 0 else j + 2
                continue
            if c in '\'"':
                cruda = i > 0 and texto[i - 1] in 'rR'
                fin = c * 3 if texto.startswith(c * 3, i) else c
                pila.append([CADENA, fin, cruda])
                fuera.append(' ')
                i += len(fin)
                continue
            if c == '{':
                pila.append([BLOQUE, None, None])
            elif c == '}' and marco[0] == INTERP:
                # La llave de cierre de un `${...}` no se emite, porque su
                # pareja de apertura tampoco: si no, el recuento de llaves
                # sale descuadrado en cada cadena interpolada.
                pila.pop()
                fuera.append(' ')
                i += 1
                continue
            elif c == '}' and marco[0] == BLOQUE:
                pila.pop()
            fuera.append(c)
            i += 1
            continue

        # dentro de una cadena
        fin, cruda = marco[1], marco[2]
        if not cruda and c == '\\':
            i += 2
            continue
        if texto.startswith(fin, i):
            pila.pop()
            i += len(fin)
            continue
        if not cruda and texto.startswith('${', i):
            pila.append([INTERP, None, None])
            fuera.append(' ')
            i += 2
            continue
        if not cruda and c == '$':
            j = i + 1
            while j < n and (texto[j].isalnum() or texto[j] == '_'):
                j += 1
            fuera.append(texto[i + 1:j])  # `$nombre` también es un identificador
            i = j
            continue
        fuera.append('\n' if c == '\n' else ' ')
        i += 1

    return ''.join(fuera)


# ── Símbolos de Flutter que NO vienen con material.dart ──────────────────────
#
# El fallo que motiva esto: se usó `kReleaseMode` importando sólo
# `material.dart`. El import existía, así que este comprobador lo daba por
# bueno — y reventó al compilar para el móvil.
#
# La causa: `widgets.dart` reexporta foundation con `show Brightness,
# UniqueKey` y nada más. Lo demás de foundation hay que pedirlo a mano.
DE_FOUNDATION = (
    'kReleaseMode', 'kDebugMode', 'kProfileMode', 'kIsWeb',
    'debugPrint', 'compute', 'listEquals', 'mapEquals', 'setEquals',
    'visibleForTesting', 'describeIdentity', 'objectRuntimeType',
)

# Imports que sí traen esos símbolos.
TRAEN_FOUNDATION = (
    'package:flutter/foundation.dart',
    'package:meta/meta.dart',
)


def ficheros():
    salida = []
    for f in RAIZ.rglob('*.dart'):
        if CARPETAS_FUERA & set(f.relative_to(RAIZ).parts):
            continue
        salida.append(f)
    return sorted(salida)


def revisar():
    fallos = []
    declara = {}

    for f in ficheros():
        t = f.read_text()
        for pat in (
            r'^(?:abstract |sealed |final |base )?(?:class|enum|mixin|extension|typedef)\s+(\w+)',
            r'^(?:Future<[^>]*>|void|String|bool|double|int|Widget)\s+(\w+)\s*\(',
            r'^final (\w+Provider)\s*=',
        ):
            for m in re.finditer(pat, t, re.M):
                declara.setdefault(m.group(1), set()).add(f)

    for f in ficheros():
        bruto = f.read_text()
        codigo = solo_codigo(bruto)
        rel = f.relative_to(RAIZ)

        for a, b in (('{', '}'), ('(', ')'), ('[', ']')):
            if codigo.count(a) != codigo.count(b):
                fallos.append(f'{rel}: descuadre {a}{b} ({codigo.count(a)}/{codigo.count(b)})')

        for num, linea in enumerate(codigo.split('\n'), 1):
            raro = next((c for c in linea if ord(c) > 127), None)
            if raro:
                fallos.append(f'{rel}:{num}: «{raro}» en un identificador; Dart sólo admite ASCII')

        resueltos = set()
        for imp in re.findall(r"import '([^']+)'", bruto):
            if imp.startswith('dart:'):
                continue

            # Los tests importan el propio proyecto por su nombre de paquete
            # (`package:<nombre>/...`), no por ruta relativa. Sin traducirlo,
            # todos sus símbolos parecían sin importar.
            if imp.startswith(f'package:{PAQUETE}/'):
                destino = RAIZ / 'lib' / imp.split('/', 1)[1]
            elif imp.startswith('package:'):
                continue
            else:
                destino = f.parent / imp

            resueltos.add(destino.resolve())
            if not destino.exists():
                fallos.append(f'{rel}: import roto -> {imp}')

        for simbolo, fuentes in declara.items():
            if simbolo.startswith('_'):
                continue
            if not re.search(r'\b' + simbolo + r'(\(|\.|<|\s+\w+\s*[=;,)])', codigo):
                continue
            if f in fuentes or any(x.resolve() in resueltos for x in fuentes):
                continue
            fallos.append(f'{rel}: usa {simbolo} sin importarlo')

        if not any(t in bruto for t in TRAEN_FOUNDATION):
            for simbolo in DE_FOUNDATION:
                if re.search(r'\b' + simbolo + r'\b', codigo):
                    fallos.append(
                        f'{rel}: usa {simbolo}, que NO viene con material.dart; '
                        f"falta import 'package:flutter/foundation.dart'"
                    )

        for m in re.finditer(r"'(assets/[^']+)'", bruto):
            if not (RAIZ / m.group(1)).exists():
                fallos.append(f'{rel}: falta el asset {m.group(1)}')

    return sorted(set(fallos))


if __name__ == '__main__':
    problemas = revisar()
    if problemas:
        print('\n'.join(problemas))
        print(f'\n{len(problemas)} cosas que mirar.')
        sys.exit(1)
    print('Sin problemas.')
