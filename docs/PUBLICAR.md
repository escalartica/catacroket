# Antes de subir Catacroket a la tienda

Lo que hay que comprobar y en qué orden. Del 0 al 3 son bloqueantes: sin
ellos la app no se publica, o se publica rota o incumpliendo algo.

## Qué queda, paso a paso

Lo de más abajo explica el porqué de cada decisión. Esto es el manual de
instrucciones. Lo que el código necesitaba está hecho: 462 tests en verde y el
`.aab` sale firmado y con el mapa dentro.

### Antes de nada: Android tarda más que iOS

Google exige a las cuentas **personales** creadas después del 13/11/2023 una
prueba cerrada con **12 probadores distintos durante 14 días seguidos** antes
de dejarte siquiera *solicitar* el acceso a producción. No es negociable y el
reloj no corre hasta que los 12 están dentro; si alguno se sale, su tiempo no
cuenta. Las cuentas de empresa están exentas, pero piden número D-U-N-S y una
verificación que tarda lo suyo.

Apple no tiene nada parecido: se paga, se sube y se revisa en unos días.

**El orden acordado (01/10/2026):** probar en el móvil → App Store → y, una
vez eso vaya bien, Google Play. Los 12 probadores son 12 personas con cuenta
de Google que instalen la app y la dejen puesta — para una app de croquetas,
es literalmente tu grupo.

---

### 1. Probarla en tu móvil

Lo primero, porque si algo está roto todo lo demás sobra.

Enchufa el iPhone por cable, desbloquéalo, y:

```bash
herramientas/empaquetar.sh movil
```

Eso compila en **release** —lo mismo que irá a la tienda— con el mapa bien
configurado, y lo instala. No hace falta la cuenta de pago de Apple: con la
gratuita que ya tienes en Xcode vale, aunque la app caduca a los 7 días y hay
que reinstalarla.

No uses `flutter run` a secas para esta prueba: sin los `--dart-define` el
mapa cae a las teselas de OpenStreetMap y estarías probando otra cosa.

Mira **tres cosas concretas**:

- **El mapa** (pestaña Ruta). Las teselas tienen que cargar y debajo tiene que
  leerse «© OpenStreetMap · © CARTO». Si salen grises, o con una marca de agua
  «API KEY REQUIRED» encima, la clave no está llegando.
- **Compartir una mesa.** Crea una mesa, pulsa «Compartir esta mesa» y
  comprueba que **el código de seis letras aparece en pantalla** y que el botón
  de copiar copia algo. Hasta ayer salía `null`.
- **La pantalla de arranque**: al abrir tiene que verse Croqui sobre el fondo
  crema, no un cuadro blanco.

Si tienes un segundo móvil a mano, entra en la mesa con ese código.

### 2. Vaciar los datos de prueba del servidor

En la consola de Firebase → **Firestore** → pestaña **Datos**.

1. En la columna de la izquierda, pasa el ratón por **`codigos`**. Aparecen
   tres puntitos a la derecha del nombre.
2. Puntitos → **Eliminar colección**. Pide escribir el nombre para confirmar.
3. Lo mismo con **`mesas`** y con **`usuarios`**.

Hazlo **después** de la prueba del punto 1, no antes: si no, borras la mesa
que acabas de crear para probar.

Son mesas tuyas de desarrollo. Sus códigos de seis letras seguirían siendo
válidos el día del estreno, y las fichas de usuario son de cuentas de prueba.

### 3. Colgar la política de privacidad

Ya está convertida a una página web lista, en **`web/privacidad.html`**, con
los colores de la app y legible en el móvil. Falta ponerla en internet.

El repositorio (`github.com/escalartica/catacroket`) es privado, y GitHub
Pages no sirve páginas públicas desde repositorios privados en el plan
gratuito. Así que va en un repositorio aparte, público, que sólo tiene esa
página:

1. En GitHub, **New repository** → nombre `catacroket-web` → **Public** →
   marcar *Add a README* → Create.
2. En el repositorio nuevo: **Add file → Upload files**, y suelta
   `web/privacidad.html`. Commit.
3. **Settings → Pages**. En *Source* elige **Deploy from a branch**, rama
   `main`, carpeta `/ (root)`. Save.
4. Espera un minuto y la URL será:
   `https://escalartica.github.io/catacroket-web/privacidad.html`
5. Ábrela y compruébala antes de pegarla en ningún formulario.

Esa URL vale para los dos sitios donde la piden: la política de privacidad y
la «URL de borrado de cuenta» que exige Play (la página explica que se borra
desde Perfil → Borrar cuenta).

### 4. App Store, primero

1. Alta en el **Apple Developer Program** (99 $/año) en
   developer.apple.com/programs/enroll. Como particular no hace falta D-U-N-S.
   La aprobación tarda de uno a dos días.
2. Xcode → **Settings → Accounts** → añadir el Apple ID de la cuenta.
3. App Store Connect → **Mis apps → +** → nueva app con el identificador
   `com.escalartica.catacroket`.
4. Rellenar **App Privacy** con la tabla de la sección 3, y la ficha con los
   textos de `docs/ficha-de-tienda.md` y las capturas de `docs/capturas/`.
5. ```bash
   herramientas/empaquetar.sh ios
   ```
   y subir el `.ipa` con Transporter o desde Xcode → Organizer.
6. Enviar a revisión. Suele contestar en uno o dos días.

### 5. Google Play, después

1. Pagar los **25 $** en play.google.com/console y completar la verificación
   de identidad (piden documento; tarda de horas a días).
2. **Crear app**: nombre Catacroket, español, gratuita.
3. **Contenido de la app**, que son varios formularios:
   - *Política de privacidad*: la URL del punto 2.
   - *Seguridad de los datos*: la tabla de la sección 3 de este documento.
   - *Clasificación de contenido*: cuestionario. Catacroket no tiene
     violencia, ni apuestas, ni compras; sí contenido generado por usuarios
     (las catas que se comparten en una mesa) y alcohol de pasada si alguien
     lo escribe. Responde con honestidad y saldrá PEGI 3 o 12.
   - *Público objetivo*: 13+ o 16+. **No marques «dirigida a niños»**: eso
     activa un régimen mucho más estricto.
   - *Eliminación de cuenta*: la misma URL del punto 2.
4. **Subir el `.aab`** a **Prueba cerrada** (no a producción, que todavía no
   te deja).
5. Invitar a los **12 probadores** por correo electrónico de Google. Que
   acepten el enlace de participación e instalen la app.
6. Esperar **14 días** con los 12 dentro. Luego **Solicitar acceso a
   producción**, que pregunta cómo fue la prueba.

### 6. Restringir la clave de API (sólo Android, y al final)

**Ojo al orden: esto se hace DESPUÉS de subir la app a Play**, no antes.

El motivo: una clave de Android se ata al nombre del paquete más la huella
SHA-1 del certificado que firma la app. Pero Play vuelve a firmar la app con
*su* clave, así que la huella que presentan los móviles de la gente es la de
Google, y esa no la conoces hasta tener la app subida. Si la restringes antes
con tu huella, la app de los usuarios deja de funcionar.

Cuando ya esté subida:

1. Play Console → **Prueba y lanzamiento → Firma de apps**. Copia el
   **SHA-1 del certificado de firma de apps**.
2. Tu huella local, por si también compilas desde el Mac:
   ```bash
   keytool -list -v -keystore ~/catacroket-release.jks -alias catacroket
   ```
3. Google Cloud Console → **APIs y servicios → Credenciales** → la clave de
   `google-services.json`.
4. *Restricciones de aplicaciones* → **Apps para Android** → añadir el
   paquete `com.escalartica.catacroket` con **las dos huellas**.
5. *Restricciones de API* → limitar a las que la app usa de verdad: Identity
   Toolkit API (el login), Cloud Firestore API y Token Service API.

## 0. Lo único que no es gratis: la cuenta de la tienda

Todo lo demás de este documento —el mapa, el hosting, las herramientas— está
elegido para que no cueste nada nunca. La cuenta de desarrollador no se puede
elegir: la ponen las tiendas y no hay camino gratuito.

| Tienda | Precio | Forma de pago |
|---|---|---|
| App Store (iPhone) | **99 $ al año** | Suscripción. Si dejas de pagar, la app se cae de la tienda |
| Google Play (Android) | **25 $ una vez** | Pago único de por vida, todas las apps que quieras |

No hay excepciones útiles: el programa gratuito de Apple sólo firma la app
para tus propios aparatos, durante **7 días**, y hay que reinstalarla a mano
cada semana. Sirve para probar, no para que alguien se la descargue.

**Decidido el 30/09/2026: se pagan las dos.** 25 $ una vez en Play y 99 $ al
año en App Store. Queda pendiente darse de alta en el Apple Developer Program
—la aprobación puede tardar un par de días— y luego añadir la cuenta en Xcode,
en Settings → Accounts.

Mientras el alta de Apple no esté aprobada, `flutter build ipa` seguirá
fallando en el paso de exportar (`No Accounts`, `No signing certificate "iOS
Distribution" found`): el archivo se genera bien, pero firmar para distribución
exige la cuenta. Android no depende de eso y se puede dejar listo ya.

## 1. El mapa: CARTO, gratis

La política de uso de las teselas de OpenStreetMap **prohíbe distribuir una
app que las consuma**. Funciona mientras seas tú probando; con usuarios de
verdad bloquean por User-Agent y el mapa se queda gris para todos a la vez.

**CARTO da 5 millones de teselas al mes gratis para uso no comercial** (1
millón si se considera comercial), sirve raster —que es lo que la app ya
pinta— y la clave es **gratis y sin cuenta**: se pide en
<https://carto.com/basemaps/apikey/> y llega por correo en un minuto. Lo único
obligatorio es que la atribución se vea.

Un millón de teselas son unas **50.000 aperturas de mapa al mes**: para una app
de croquetas, muchísimo margen.

### Por qué CARTO y no las otras

Se miraron cinco caminos, en septiembre de 2026:

| Opción | Coste | Veredicto |
|---|---|---|
| **CARTO** | **Gratis: 5M teselas/mes no comercial, 1M comercial** | **El elegido.** Raster, clave gratis y sin cuenta |
| OpenFreeMap | Gratis, ilimitado, sin cuenta | Sirve **vectorial**. Exige reescribir las pantallas de mapa sobre MapLibre |
| Stadia Maps | 20 $/mes | De pago. El plan gratuito prohíbe uso comercial |
| MapTiler | 5.000 sesiones/mes | Diminuto y prohíbe uso comercial |
| Thunderforest | Salta de gratis a 125 $/mes | Sin escalón intermedio |

### Lo que hay que saber antes de fiarse

Dos cosas, dichas claras:

1. **Al pasar de 1M teselas, CARTO salta a 500 $/mes.** No hay escalón
   intermedio. Es un precipicio, no una cuesta. Llegar ahí significaría
   varios miles de usuarios activos, o sea un problema bueno — pero conviene
   vigilar el consumo en su panel, no enterarse por la factura.
2. **El raster no se retira.** Su documentación, consultada el 30/09/2026, lo
   dice explícitamente: raster y vectorial siguen recibiendo actualizaciones.
   Lo que sí cambió en 2026 es que la clave pasó a ser obligatoria; sin ella
   las teselas llegan con una marca de agua «API KEY REQUIRED» encima. Si algún
   día cambiaran de idea, la salida está preparada: se toca `mapa.env` y nada
   más.

### Cómo se pone

Una vez: pedir la clave en <https://carto.com/basemaps/apikey/> (gratis, sin
cuenta, llega por correo) y dejarla en `mapa.env`:

```bash
cp mapa.env.ejemplo mapa.env
# y poner la clave en CATACROKET_MAPA_CLAVE
```

A partir de ahí, **las compilaciones de tienda se hacen con el script**, no a
mano:

```bash
herramientas/empaquetar.sh android    # -> .aab para Play
herramientas/empaquetar.sh ios        # -> .ipa para App Store
```

Esto no es comodidad. Un `flutter build appbundle` a secas compila
perfectamente y deja puestas las teselas públicas de OpenStreetMap: el paquete
sale bien, se sube, y semanas después el mapa se queda gris para todos. El
script se niega a compilar si falta `mapa.env`, si la clave sigue siendo la de
la plantilla, o si la URL apunta a OpenStreetMap.

`mapa.env` está en `.gitignore`: la clave no acaba en el repositorio.

CARTO pide la clave como parámetro `key` (Stadia, MapTiler y Thunderforest la
piden como `api_key`; eso se ajusta en `CATACROKET_MAPA_PARAM`).

La atribución «© OpenStreetMap · © CARTO» es obligatoria y tiene que verse en
el mapa.

Para comprobar qué proveedor lleva una compilación, la app expone
`Mapas.sonPublicas`: en la que subas a la tienda tiene que ser `false`.

### El plan B, si algún día CARTO deja de valer

**OpenFreeMap**: gratis, ilimitado, sin cuenta, sin clave y con uso comercial
permitido. No depende de ninguna cuota. El precio es otro: sirve teselas
vectoriales, y el paquete que las pinta en `flutter_map` está parado desde
2024 y pide una versión anterior a la que usa la app. La vía buena sería
pasar las dos pantallas de mapa al paquete `maplibre`, que sí está vivo. Es
trabajo, pero es la opción que nunca puede mandarte una factura.

### Y la búsqueda de bares

**Nominatim** es lo que traduce «Bar Manoli» a unas coordenadas. Su política
pide un máximo de una consulta por segundo y no montar un producto encima.
La app ya se identifica con User-Agent propio y sólo consulta cuando el
usuario escribe, que es el uso que ellos contemplan. Si algún día crece,
Photon y Geoapify tienen planes gratuitos para esto.

## 2. La app tiene que salir vacía

Sale sola: el interruptor es `kReleaseMode`, así que cualquier compilación de
release arranca sin catas, sin mesas ajenas y sin gente inventada. Para verlo
sin compilar en release:

```bash
flutter run --dart-define=CATACROKET_VACIA=true
```

Lo cubren los tests de `test/siembra_test.dart`.

## 3. Lo que hay que declarar en las tiendas

**Esto es lo que más fácil es equivocar y lo que provoca rechazos.** La app
lleva Firebase Auth (correo y contraseña) y Cloud Firestore. Declarar «no se
recoge ningún dato» sería falso: Apple lo detecta escaneando el binario y
rechaza, y en Europa el responsable del tratamiento eres tú.

La política está en `docs/privacidad.md`. Contacto: **escalartica@gmail.com**,
que hay que poner también en las fichas de las dos tiendas.

### Antes de rellenar nada

- [x] **Región de Firestore: `eur3`** (multirregión europea). Comprobado el
      01/10/2026. Los datos se tratan dentro de la UE, así que no hay
      transferencia internacional que declarar — ni en la política ni en los
      formularios de las tiendas. Ya está escrito en `docs/privacidad.md`.
- [x] **`firestore.rules` está desplegado.** Comprobado en la consola el
      01/10/2026: el texto coincide con el del repositorio. Si alguna vez se
      tocan las reglas, hay que volver a desplegarlas —el fichero del
      repositorio no hace nada por sí solo— con
      `firebase deploy --only firestore:rules`.
- [ ] **Vaciar los datos de prueba del servidor.** La base de datos tiene las
      colecciones `codigos`, `mesas` y `usuarios` con mesas de desarrollo
      dentro. La app sale limpia (eso lo resuelve `Siembra`), pero el servidor
      no: hay códigos de mesa viejos que seguirían siendo válidos y fichas de
      usuario de pruebas. Se borran a mano desde Firestore → Datos.
- [ ] Restringir la **clave de API** de `google-services.json` en Google Cloud
      → Credenciales: limitarla a las APIs de Firebase y al identificador de la
      app. Es pública por diseño, pero sin restringir se puede usar desde fuera.
- [ ] Subir `docs/privacidad.md` a una **URL pública** (las dos tiendas piden un
      enlace, no un adjunto). Vale cualquier sitio gratuito.

### App Store — «App Privacy»

Todo se marca **«Data is linked to you»** y **«App Functionality»**, nunca
«Tracking», y todo con la casilla de **dato opcional**, porque sólo se recoge si
el usuario crea cuenta y comparte mesa.

| Categoría | Dato |
|---|---|
| Contact Info | Email Address |
| User Content | Photos or Videos |
| User Content | Other User Content (las notas de las catas) |
| Location | Precise Location |
| Identifiers | User ID |

«Used for Tracking»: **No** en todos.

### Google Play — «Seguridad de los datos»

Mismos datos, y en cada uno: recogida **sí**, compartición con terceros **no**,
**cifrado en tránsito sí**, **el usuario puede pedir que se borren sí**
(Perfil → Borrar cuenta), y **opcional sí**.

- Información personal → Dirección de correo electrónico
- Información personal → Nombre
- Fotos y vídeos → Fotos
- Ubicación → Ubicación precisa
- Actividad en la app → Otro contenido generado por el usuario

Play pide además una **URL de borrado de cuenta**: vale la misma página de la
política, siempre que explique que se borra desde Perfil → Borrar cuenta.

## 4. Android: la firma de release

`android/app/build.gradle.kts` ya lee `android/key.properties` si existe, y si
no, firma con la clave de depuración para que `flutter run --release` siga
funcionando. Play no acepta un `.aab` firmado así, o sea que hay que crear el
almacén de claves una vez:

```bash
keytool -genkey -v -keystore ~/catacroket-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias catacroket

flutter build appbundle
```

Para rellenar `android/key.properties` sin que la contraseña se quede escrita
en el historial del terminal:

```bash
python3 - <<'PY'
import getpass, pathlib
clave = getpass.getpass('Contraseña del almacén: ')
pathlib.Path('android/key.properties').write_text(
    f"storePassword={clave.replace(chr(92), chr(92)*2)}\n"
    f"keyPassword={clave.replace(chr(92), chr(92)*2)}\n"
    "keyAlias=catacroket\n"
    "storeFile=/Users/cehachehache/catacroket-release.jks\n")
print('escrito')
PY
```

`storePassword` y `keyPassword` son **la misma**: keytool crea almacenes PKCS12
desde Java 9 y ahí no hay contraseña aparte para la clave, por eso al crearlo
sólo la pidió una vez.

**El `.jks` es irreemplazable.** Si se pierde, Google Play no deja publicar
ninguna actualización más de `com.escalartica.catacroket`, nunca. Copia fuera
del ordenador y contraseñas en un gestor. Está en `.gitignore` junto con
`key.properties`: no se suben al repositorio jamás.

## 5. Comprobaciones que deben pasar

```bash
python3 herramientas/revisar.py   # lo que el analizador no ve
flutter analyze                   # ojo: sale con código ≠ 0 también con avisos
flutter test
```

## 6. Lo que ya está resuelto y no hay que volver a mirar

- `ITSAppUsesNonExemptEncryption` en el `Info.plist`: evita que App Store
  Connect pregunte por el cumplimiento de exportación en cada subida.
- Los textos de permisos de iOS cubren los dos usos reales de cámara y fotos
  (la croqueta y la foto de perfil).
- La dieta y la lista de alergias quedan fuera de la copia automática de
  Android: son datos de salud y no tienen por qué acabar en Google Drive.
- No hay secretos en el código, ni trazas que filtren datos, ni tráfico en
  claro, ni ATS relajado. La clave de `google-services.json` no es un secreto
  —va en el cliente por diseño—, pero hay que restringirla (sección 3).
- Las reglas de Firestore están escritas, revisadas y **desplegadas**: cada uno
  sólo escribe sus catas, sólo los miembros de una mesa la leen, y los códigos
  se pueden consultar de uno en uno pero no listar.
- Los códigos de mesa se generan con `Random.secure()`, sobre un alfabeto de 31
  caracteres sin letras que se confundan (ni I, ni L, ni O, ni 0, ni 1).
- Borrar la cuenta desde dentro de la app existe (Perfil → Borrar cuenta), que
  es requisito de App Store desde 2022 para toda app con cuentas.
- La pantalla de arranque ya es Croqui sobre el crema de la app, no el
  marcador de posición de Flutter.
