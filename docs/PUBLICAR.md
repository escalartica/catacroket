# Publicar Catacroket

Primero App Store, se prueba unos días en un iPhone de verdad, y después
Google Play. Esto es lo que ya está hecho en el repositorio y lo que hay que
rellenar a mano.

## Ya está hecho y comprobado

- **Manifiesto de privacidad** (`ios/Runner/PrivacyInfo.xcprivacy`): sin
  rastreo, sin dominios de rastreo y sin datos recogidos. Está dado de alta en
  el proyecto de Xcode, que es lo que hace que entre dentro de la app —
  crear el fichero y no darlo de alta es el error clásico.
- **Cifrado**: `ITSAppUsesNonExemptEncryption` a `false` en el `Info.plist`.
  Sin esto, cada envío pregunta por el cifrado y se queda esperando.
- **Textos de uso**: los cinco puestos (cámara, ubicación, micrófono y las dos
  de fotos). Si falta uno, la app **se cierra de golpe** al usar esa función y
  Apple la rechaza.
- **Icono de tienda**: 1024 × 1024, RGB **sin canal alfa**. Apple rechaza los
  iconos con transparencia.
- **Capturas**: seis, a 1320 × 2868 (6.9"), en `docs/capturas/`.
- **Versión**: 1.0.0+1.
- **Política de privacidad**: redactada en `docs/privacidad.md`. **Hay que
  subirla a una dirección pública** — Apple pide una URL, no un fichero.

## Lo que sólo puedes hacer tú

1. **Cuenta de Apple Developer** (99 $/año) y el certificado de distribución.
2. **Firmar**. En Xcode, target Runner → Signing & Capabilities → tu equipo.
3. **Alojar la política de privacidad** y quedarte con la URL. Vale GitHub
   Pages, una Gist pública o cualquier página tuya.
4. **Subir el archivo**: `flutter build ipa` y luego Xcode → Organizer →
   Distribute App. O directamente Product → Archive desde Xcode.

## Respuestas para el formulario de privacidad de App Store Connect

Apple pregunta esto una por una. Para esta app la respuesta es corta:

| Pregunta | Respuesta |
|---|---|
| ¿Recoges datos de esta app? | **No** |
| ¿Rastreas usuarios? | **No** |
| Identificadores de publicidad | Ninguno |

Es verdad y es comprobable: no hay servidor, ni analítica, ni cuenta.

Dos matices que hay que tener claros por si preguntan, y que están escritos en
la política:

- El mapa pide sus imágenes a OpenStreetMap.
- Para rellenar sola la ciudad, la app manda las coordenadas a Nominatim (el
  buscador de direcciones de OpenStreetMap) y recibe el nombre del sitio.

Ninguna de las dos es «recogida de datos» por tu parte: no guardas nada, no
tienes dónde guardarlo y no recibes copia. Pero **sí hay que declararlas en la
política**, y están.

**Clasificación por edad**: 4+. No hay contenido restringido. Si el
cuestionario pregunta por alcohol, la app no lo trata: son croquetas.

## Metadatos: borrador para pegar

**Nombre** (30): `Catacroket`

**Subtítulo** (30): `Cata croquetas con tu gente`

**Palabras clave** (100, separadas por comas y sin espacios):

    croquetas,cata,tapas,bares,mapa,ranking,amigos,comida,restaurantes,bechamel

**Texto promocional** (170):

    Apunta la croqueta que te acabas de comer antes de que se te olvide. El
    corte, la nota y dónde estaba. Con tu gente y en un mapa.

**Descripción**:

    Te comes una croqueta buenísima en un bar y a los dos meses no te acuerdas
    ni de cómo se llamaba el sitio.

    Catacroket es la libreta para eso.

    LA CATA
    Apuntas el bar, el relleno y le pones nota a lo que importa: lo crujiente,
    lo cremoso, el sabor y el relleno. La app dibuja el corte con tus notas —
    ninguna otra te enseña por dentro la croqueta que te comiste.

    EL MAPA
    Cada bar donde has catado se queda marcado. Meses después ves de un
    vistazo dónde estaba aquella que no se te olvida.

    LAS MESAS
    Una mesa es tu grupo: los que catáis juntos. Las catas se juntan, hay
    ranking y sale quién puntúa más duro.

    COMPARTIR
    Cada cata sale como una estampa para mandar al grupo. Con la nota, el
    corte y el bar.

    SIN CUENTA Y SIN SERVIDOR
    No hay registro ni correo. Lo que apuntas se queda en tu móvil.

## Dónde suelen rechazarla, y cómo va ésta

- **Manifiesto de privacidad ausente** → puesto y dado de alta.
- **Icono con transparencia** → comprobado, no la tiene.
- **Falta un texto de uso y la app se cierra** → los cinco están.
- **Capturas que no son la app** (marcos, rótulos) → las seis son la app tal
  cual.
- **Sin URL de política de privacidad** → *pendiente: hay que alojarla*.
- **Funcionalidad escasa** ("minimal functionality") → aquí no aplica: hay
  formulario, mapa, grupos, ranking y compartir.

## Después, Google Play

Cuando toque. Lo de Android ya está comprobado: la app compila, corre y el
mapa carga. Y hay dos cosas anotadas:

- El permiso de internet faltaba en la versión de tienda y **ya está
  arreglado** (verificado con `aapt2` sobre el APK empaquetado).
- La firma sigue siendo la de depuración: hay un `TODO` en
  `android/app/build.gradle.kts`. Play no acepta eso, hay que generar una
  clave propia.
