#!/usr/bin/env bash
#
# Empaqueta Catacroket para la tienda, con el mapa bien configurado.
#
# Existe por una razón concreta: `flutter build appbundle` a secas compila y
# funciona, pero deja puestas las teselas públicas de OpenStreetMap, cuya
# política PROHÍBE distribuir una app que las consuma. El .aab sale bien, se
# sube, y semanas después el mapa se queda gris para todos a la vez.
#
# Este script no deja que eso pase: sin `mapa.env` no compila.
#
#   herramientas/empaquetar.sh movil      -> instala en el móvil enchufado
#   herramientas/empaquetar.sh movil ID   -> en ESE móvil (`flutter devices`)
#   herramientas/empaquetar.sh android    -> build/app/outputs/bundle/release
#   herramientas/empaquetar.sh ios        -> build/ios/ipa
#
# «movil» es para probar antes de publicar: compila en release con el mapa
# bien puesto y lo instala en el aparato que tengas conectado. No hace falta
# cuenta de desarrollador de pago, basta con la gratuita de Xcode.
#
# Con VARIOS aparatos a la vez —tu iPhone, el de otra persona, el simulador—
# conviene decir cuál, porque el simulador NO puede correr en release y si lo
# elige por su cuenta el build muere con «Release mode is not supported».
# `flutter devices` da los identificadores.
#
set -euo pipefail

cd "$(dirname "$0")/.."

destino="${1:-}"
case "$destino" in
  movil|android|ios) ;;
  *)
    echo "Uso: herramientas/empaquetar.sh movil [ID] | android | ios" >&2
    echo "     El ID sale de \`flutter devices\`. Hace falta cuando hay varios" >&2
    echo "     aparatos: el simulador no puede correr en release." >&2
    exit 2
    ;;
esac

if [[ ! -f mapa.env ]]; then
  cat >&2 <<'AVISO'
Falta mapa.env.

Copia la plantilla y pon dentro la clave de CARTO:

    cp mapa.env.ejemplo mapa.env

La clave se pide gratis en https://carto.com/basemaps/apikey/ — no hace falta
cuenta, llega por correo en un minuto. Sin ella el mapa sale con la marca de
agua «API KEY REQUIRED» encima.
AVISO
  exit 1
fi

set -a
# shellcheck disable=SC1091
source mapa.env
set +a

falta=""
[[ -z "${CATACROKET_TESELAS:-}" ]] && falta="$falta CATACROKET_TESELAS"
[[ -z "${CATACROKET_MAPA_CREDITO:-}" ]] && falta="$falta CATACROKET_MAPA_CREDITO"
if [[ -n "$falta" ]]; then
  echo "mapa.env está incompleto, falta:$falta" >&2
  exit 1
fi

case "${CATACROKET_MAPA_CLAVE:-}" in
  ""|tu-clave|LA-CLAVE-DE-CARTO)
    echo "mapa.env no tiene una clave de CARTO de verdad en CATACROKET_MAPA_CLAVE." >&2
    echo "Se pide gratis en https://carto.com/basemaps/apikey/" >&2
    exit 1
    ;;
esac

if [[ "$CATACROKET_TESELAS" == *"tile.openstreetmap.org"* ]]; then
  echo "CATACROKET_TESELAS apunta a las teselas públicas de OpenStreetMap." >&2
  echo "Su política prohíbe distribuir una app que las use. No se compila." >&2
  exit 1
fi

defines=(
  --dart-define="CATACROKET_TESELAS=$CATACROKET_TESELAS"
  --dart-define="CATACROKET_MAPA_CLAVE=$CATACROKET_MAPA_CLAVE"
  --dart-define="CATACROKET_MAPA_CREDITO=$CATACROKET_MAPA_CREDITO"
  --dart-define="CATACROKET_MAPA_PARAM=${CATACROKET_MAPA_PARAM:-key}"
)

echo "Mapa:   $CATACROKET_TESELAS"
echo "Crédito: $CATACROKET_MAPA_CREDITO"
echo "Clave:  [${#CATACROKET_MAPA_CLAVE} caracteres]"
echo

case "$destino" in
  movil)
    # `run` y no `build`: instala y arranca en el aparato de una vez. En
    # release, porque lo que se prueba es lo que va a la tienda.
    if [[ -n "${2:-}" ]]; then
      exec flutter run --release -d "$2" "${defines[@]}"
    fi
    exec flutter run --release "${defines[@]}"
    ;;
  android)
    exec flutter build appbundle "${defines[@]}"
    ;;
  ios)
    exec flutter build ipa "${defines[@]}"
    ;;
esac
