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
#   herramientas/empaquetar.sh movil            -> instala en el móvil enchufado
#   herramientas/empaquetar.sh movil ID         -> en ESE móvil (`flutter devices`)
#   herramientas/empaquetar.sh movil-limpio ID  -> lo BORRA del móvil y lo instala
#   herramientas/empaquetar.sh android          -> build/app/outputs/bundle/release
#   herramientas/empaquetar.sh ios              -> build/ios/ipa
#
# «movil-limpio» existe porque `flutter run` instala ENCIMA: sustituye la app y
# deja intacta su carpeta de datos. Probar «cómo se ve recién instalada» con
# «movil» a secas no prueba eso: salen las mesas, las preferencias y las catas
# de antes, y uno se cree que la app arranca con datos de nadie sabe dónde.
# Con «movil-limpio» se borra primero, que es lo mismo que hace el usuario
# manteniendo pulsado el icono, y entonces sí arranca como recién bajada de la
# tienda.
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
  movil|movil-limpio|android|ios) ;;
  *)
    echo "Uso: herramientas/empaquetar.sh movil [ID] | movil-limpio ID | android | ios" >&2
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

# Lo que va a la tienda va VACÍO. Sin catas, sin mesas inventadas, sin gente
# que el usuario no conoce: quien se la baje empieza por su primera croqueta.
#
# Eso lo decide `Siembra.conEjemplos`, que mira `kReleaseMode`, así que
# compilar en release basta... salvo por una puerta: `CATACROKET_CAPTURAS`
# siembra los datos de ejemplo AUNQUE sea release, porque una ficha de tienda
# con la app vacía no enseña nada. Está bien que exista, y está muy mal que se
# cuele en el paquete que sube a la tienda.
#
# Si esa variable anda puesta en el entorno —de haber hecho capturas hace un
# rato, por ejemplo— aquí se para. Es el único camino por el que los datos de
# prueba podrían llegar a un desconocido.
if [[ "$destino" == "android" || "$destino" == "ios" ]]; then
  if [[ -n "${CATACROKET_CAPTURAS:-}" ]]; then
    echo "CATACROKET_CAPTURAS está puesta y esto va a la tienda." >&2
    echo "Con ella, la app se publicaría CON datos de ejemplo dentro." >&2
    echo "Quítala del entorno (unset CATACROKET_CAPTURAS) y repite." >&2
    exit 1
  fi
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

# El identificador con el que el sistema conoce la app. Es el mismo en iOS
# (PRODUCT_BUNDLE_IDENTIFIER) y en Android (applicationId).
app_id="com.escalartica.catacroket"

# Borra la app del aparato, con su carpeta de datos y su entrada del llavero.
#
# Si no se puede borrar, esto PARA. Es a propósito: una desinstalación que
# falla en silencio deja creer que lo que sale luego es el arranque limpio
# cuando son los datos de antes, y esa confusión cuesta más que el fallo.
desinstalar() {
  local aparato="$1" salida estado

  if [[ -z "$aparato" ]]; then
    echo "«movil-limpio» necesita el ID del aparato: no se desinstala a ciegas." >&2
    echo "Sale de \`flutter devices\`." >&2
    exit 2
  fi

  echo "Borrando $app_id de $aparato..."

  for intento in ios android; do
    case "$intento" in
      ios)
        command -v xcrun >/dev/null 2>&1 || continue
        set +e
        salida="$(xcrun devicectl device uninstall app --device "$aparato" "$app_id" 2>&1)"
        estado=$?
        ;;
      android)
        command -v adb >/dev/null 2>&1 || continue
        set +e
        salida="$(adb -s "$aparato" uninstall "$app_id" 2>&1)"
        estado=$?
        ;;
    esac
    set -e

    if [[ $estado -eq 0 ]] && ! grep -qi "Failure" <<<"$salida"; then
      echo "Borrada. Arranca como recién bajada de la tienda."
      return
    fi

    # No estar instalada es justo lo que buscábamos.
    if grep -qiE "not installed|not found|DELETE_FAILED_INTERNAL_ERROR|Unknown package" <<<"$salida"; then
      echo "No estaba instalada. Igual de limpio."
      return
    fi
  done

  echo >&2
  echo "No se ha podido borrar la app del aparato." >&2
  echo "${salida:-(sin salida: ni xcrun ni adb disponibles)}" >&2
  echo >&2
  echo "Esto NO sigue: instalar encima dejaría los datos de la instalación" >&2
  echo "anterior y la prueba del arranque limpio no valdría. Bórrala a mano en" >&2
  echo "el móvil (mantener pulsado el icono → Eliminar app) y repite." >&2
  exit 1
}

case "$destino" in
  movil|movil-limpio)
    if [[ "$destino" == "movil-limpio" ]]; then
      desinstalar "${2:-}"
    fi

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
