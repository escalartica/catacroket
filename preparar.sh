#!/bin/sh
# ---------------------------------------------------------------------------
# Catacroket — preparación inicial
#
# Flutter necesita las carpetas ios/ y android/, que sólo puede generar el
# propio SDK en tu Mac. Este script las crea en un proyecto temporal, las
# trae aquí y lo borra. Se ejecuta UNA vez.
#
#   cd ~/development/catacroket && sh preparar.sh
# ---------------------------------------------------------------------------
set -e
DIR=$(cd "$(dirname "$0")" && pwd)
TMP="$DIR/../.catacroket_base"

if [ -d "$DIR/ios" ] && [ -d "$DIR/android" ]; then
  echo "Las plataformas ya existen. Sólo actualizo dependencias."
else
  echo "==> Generando plataformas iOS y Android..."
  rm -rf "$TMP"
  flutter create --org com.escalartica --project-name catacroket \
    --platforms=ios,android "$TMP" > /dev/null
  cp -R "$TMP/ios" "$DIR/ios"
  cp -R "$TMP/android" "$DIR/android"
  rm -rf "$TMP"
  echo "    Listo."
fi

echo "==> Descargando dependencias..."
cd "$DIR"
flutter pub get

echo "==> Generando iconos de la app..."
dart run flutter_launcher_icons || echo "    (los iconos se pueden generar luego)"

echo ""
echo "Todo listo. Arranca con:"
echo "   cd ~/development/catacroket && flutter run"
