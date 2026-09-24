# Capturas para la ficha de tienda

Los textos de la ficha están en [`../ficha-de-tienda.md`](../ficha-de-tienda.md).
Aquí va cómo se hacen las imágenes, que tiene más trampa de la que parece.

## Por qué no vale compilar en release

Lo lógico sería fotografiar una compilación de release, que es la que se baja
la gente. **El simulador de iOS no admite release ni profile**: lo dice él
mismo, «Release mode is not supported by Catacroket Store 6.9». Y las capturas
se hacen en el simulador porque es donde está el tamaño exacto de cada modelo.

Pero en depuración hay cosas que en la tienda no existen —el botón de
diagnóstico del mapa— y fotografiarlas sería enseñar otra app. Para eso está el
modo capturas: sirve datos de ejemplo y esconde la ferretería de depuración,
sin tocar nada de la interfaz que se está fotografiando.

```bash
flutter run --dart-define=CATACROKET_CAPTURAS=true -d "Catacroket Store 6.9"
```

## Antes de disparar

**La barra de estado**, que Apple quiere limpia y a las 9:41:

```bash
xcrun simctl status_bar booted override --time "9:41" --batteryState charged --batteryLevel 100 --cellularMode active --cellularBars 4 --wifiMode active --wifiBars 3
```

Para dejarla como estaba: `xcrun simctl status_bar booted clear`.

**Los carteles de ayuda.** Cada apartado abre con uno («Aquí aparece cada
croqueta que catáis…»). Explican bien la app, pero en una captura ocupan el
sitio del producto. Se cierran con la equis y vuelven desde
Perfil → Ajustes → «Ver las explicaciones».

**La dieta del perfil.** Si hay alguna marcada, la Barra Libre dice «Ninguna de
las 6 te vale aún», que no es lo que se quiere enseñar. Déjala sin marcar.

## Disparar

```bash
xcrun simctl io booted screenshot docs/capturas/1-vitrina.png
```

Sale a 1320 × 2868, que es justo lo que pide la App Store para 6.9". No las
redimensiones: si hacen falta otros tamaños, se repite con otro simulador.

## Qué enseñar

La primera es la que decide: el 90% de la gente no pasa de la tercera.

1. **La Vitrina** — el feed, con la croqueta del día y la racha.
2. **La Ruta** — el mapa con los globos agrupados. Es lo más difícil de
   explicar con palabras y lo más fácil de entender de un vistazo.
3. **La ficha de una cata** — el corte dibujado, que es lo que no tiene nadie.
4. **El corte, paso 3** — las cuatro notas y la prueba del tiro al plato.
5. **Una mesa** — el ranking, que es el argumento para bajársela en grupo.
6. **La estampa de compartir** — lo que acaba en el grupo de WhatsApp.

## Lo que hay aquí ahora

`1-vitrina.png`, hecha a mano durante la revisión. Las demás están sin hacer:
se quedaron a medias porque el disco del portátil se llenó dos veces seguidas
mientras se compilaba.
