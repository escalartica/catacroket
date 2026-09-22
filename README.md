# Catacroket

Cata croquetas, guárdalas en tu libreta y compite con tu gente.
Flutter + Riverpod + go_router. iOS primero, Android después.

---

## Arrancarla por primera vez

Flutter necesita las carpetas `ios/` y `android/`, que sólo puede generar el
SDK en tu Mac. Hay un script que lo hace todo:

```sh
cd ~/development/catacroket
sh preparar.sh
flutter run
```

`preparar.sh` genera las plataformas con el identificador
`com.escalartica.catacroket`, baja las dependencias y crea los iconos a partir
de `assets/icon/app_icon.png`. Se ejecuta una vez; a partir de ahí, `flutter
run` y listo.

---

## Qué hay dentro

**La v1 no lleva Firebase.** Las catas viven en el móvil
(`shared_preferences`) y la app arranca con diez catas de ejemplo para que la
primera pantalla no esté vacía. Así se puede ejecutar, enseñar y ajustar el
diseño sin depender de una cuenta ni de la red. El contrato de los
*notifiers* (`anadir`, `darMordisco`, `borrar`) es el que tendrá cuando
detrás haya Firestore, así que al migrar no habrá que tocar las pantallas.

| Pantalla | Qué hace |
|---|---|
| **La Vitrina** | Feed de catas, croqueta del día y racha semanal |
| **Ficha** | El Corte a lo grande, los cuatro ejes, la nota escrita y quién estaba |
| **Nueva cata** | Cuatro pasos: sitio, sabores, el corte y los detalles. Los mismos cuatro sirven para corregir una cata ya publicada |
| **Ruta croquetera** | Mapa de OpenStreetMap con un globo de nota por bar, filtros y «centrar donde estoy» |
| **Mesas** | Tu libreta privada y tus mesas, con código, ranking y recuerdos |
| **Barra Libre** | Croquetas veganas, sin gluten y sin lactosa, con filtro por dieta |
| **Croquetómetro** | Rango, medallas, tu paladar y tu mejor cata |

### El Corte

Está en `lib/arte/corte_painter.dart` y es la idea de producto, no un adorno.
Las cuatro notas se convierten en un dibujo distinto para cada croqueta:
el crujiente engorda la costra, la cremosidad aclara la bechamel, el relleno
añade trozos de su color y el sabor levanta el vapor. La posición de cada miga
sale de una semilla fija (el id de la cata), así que el dibujo de una croqueta
es siempre el mismo: es su retrato, no ruido.

De paso resuelve un problema real: las fotos de croquetas hechas en la barra
de un bar son feas, y un feed de fotos feas no invita a volver.

### Las mesas

Antes eran decorado: los botones de «crear» y «entrar con código» enseñaban
un aviso y ya, y las mesas ni siquiera se guardaban —una mesa creada se
perdía al cerrar la app—. Ahora se crean, se cambian, se borran y se guardan
en disco como las catas.

- **Borrar una mesa no borra sus catas**: se van a la libreta. Son dos cosas
  distintas y confundirlas sería la peor pérdida de datos posible aquí, así
  que el diálogo lo dice con el número delante.
- **La libreta no se puede borrar ni renombrar.** Es donde cae una cata
  cuando no eliges mesa; una app donde ese sitio puede desaparecer es una app
  donde se pierden catas sin querer.
- **El código son seis letras sin I, L, O, 0 ni 1.** Se dicta en voz alta en
  una barra con ruido, y una I que alguien oye como L es una mesa a la que no
  entras.

Lo que **no** hace todavía: que otra persona entre con ese código. Eso
necesita cuentas y servidor. La pantalla lo dice en vez de fingirlo.

### WhatsApp

Dos caminos, a propósito distintos:

- **La estampa** (imagen) va por la hoja del sistema, porque ninguna app
  puede saltarse eso. En esa hoja WhatsApp suele salir el primero.
- **El texto** va directo a WhatsApp, sin imagen. Es el camino del momento:
  estás comiéndotela y quieres que el grupo se entere ya. Generar la imagen,
  guardarla y pasar por la hoja del sistema son tres segundos y dos pantallas
  más de las que tienes ganas con la croqueta enfriándose.

WhatsApp se abre por `wa.me`, que es un enlace normal: si está instalado lo
coge él y si no, se abre la web. Con el esquema `whatsapp://` habría que
declararlo en el Info.plist, preguntar si está instalado y tener un plan para
cuando no lo esté; un https no necesita nada de eso.

Las invitaciones (a la app y a una mesa) salen de `CompartirService`, y el
enlace de la tienda vive en `lib/core/data/enlaces.dart`. **Está vacío a
propósito**: hasta que Catacroket esté publicada, mandar a alguien un enlace
que no lleva a ninguna parte es peor que no mandarlo, así que el texto dice
el nombre y ya. En cuanto haya ficha en la App Store se pega ahí y todas las
invitaciones lo llevan solas.

### El formulario

Cuatro pasos, y en el segundo —«¿Qué has pedido?»— se empieza por cómo te la
sirvieron: tapa, media ración o ración, y cuántas traía. Va lo primero porque
es lo primero que sabes: lo dices al pedir, antes de probarla. Elegir formato
propone sus unidades habituales (una tapa suelen ser dos, una ración seis)
para que en el caso normal no haya que tocar nada.

No es un dato decorativo: con las unidades, el precio por croqueta deja de
ser una cuenta de cabeza. Antes la ficha decía «Ración de 6» a fuego,
hubieras pedido lo que hubieras pedido. Era mentira seis de cada siete veces.

Cambiar de formato vuelve a proponer sus unidades —tapa 2, media ración 5,
ración 10— mientras nadie haya tocado el contador. En cuanto lo tocas, manda
tu número y deja de moverse.

**Ningún botón apagado se queda mudo.** Un botón que no responde y no dice
por qué parece estropeado: se toca, no pasa nada y el usuario se queda
mirando. Encima del botón sale qué falta —«elige al menos un relleno»— y en
el buscador, si no encuentra nada, el mensaje apunta a «A mi manera», que por
eso no se filtra nunca: es la salida, y una salida escondida es un callejón.
Además, lo que hubieras escrito en el buscador se aprovecha: marcas «A mi
manera» y ya está escrito.

**Una croqueta puede llevar varios ingredientes.** Jamón y boletus es una
cosa que existe, y antes había que elegir uno de los dos y mentir sobre el
otro —lo cual, además, le mentía a la deducción de dietas, que sólo miraba el
principal—. Ahora se marcan los que sean; el primero manda, porque alguien
tiene que decidir el color y el dibujo.

**Y lo que no está en el catálogo se escribe.** «A mi manera» abre un campo:
la croqueta de carrillada de un bar concreto no va a estar nunca en una lista
de veintiuno. Eso sí, lo escrito a mano la app no sabe qué lleva, así que a
efectos de dietas cuenta como un relleno sin describir y no promete nada.

**Con quién, a mano.** Antes eran cinco personas del catálogo de
demostración, que es como pedirle al usuario que mienta sobre con quién come.
Ahora se escriben los nombres; el color del avatar sale del nombre, así que
tu hermana es siempre del mismo color sin guardar nada de nadie.

### El mapa, y una trampa de flutter_map

El encuadre inicial va en `MapOptions.initialCameraFit`, **no** en un
`fitCamera` dentro de `onMapReady`. Parece el sitio natural y no lo es:
`onMapReady` salta en un post-frame de `initState`, antes de que el mapa se
haya medido, y encuadrar contra un tamaño cero deja una cámara degenerada.

El síntoma engañaba: los globos con las notas salían bien —se recolocan en
cada frame a partir de la cámara— pero el mapa estaba en blanco. La capa de
teselas sólo recalcula cuando la cámara cambia, así que se quedaba vacía
hasta que el usuario hacía zoom a mano, y entonces aparecía de golpe.

Parecía un problema de red o de bloqueo del servidor, y no lo era. Lo que lo
delató fue «hasta que no hago zoom no se arregla».

`initialCameraFit` existe justo para esto y flutter_map lo aplica cuando ya
tiene un tamaño de verdad. `fitCamera` sigue valiendo cuando el mapa ya está
en pantalla: al cambiar de filtro, por ejemplo.

### La ubicación

Hasta ahora ninguna cata nueva llegaba al mapa: el formulario no preguntaba
dónde estaba el bar y `lat`/`lon` se quedaban en nulo. Sólo salían las catas
de demostración, que traen las coordenadas a mano. Eso es lo que arregla
`lib/core/services/ubicacion_service.dart`, con tres caminos para el mismo
dato porque son tres momentos distintos:

- **Estoy aquí** — GPS (`geolocator`). Es lo que haces con la croqueta
  delante. De paso rellena ciudad y país, y sólo si están vacíos: lo que
  escribió el usuario manda siempre sobre lo que deduzca OpenStreetMap.
- **Buscar el bar** — texto libre contra Nominatim.
- **En el mapa** — el mapa se mueve y la chincheta se queda clavada en el
  centro de la pantalla. Es al revés de arrastrar el marcador, y es mejor: el
  dedo nunca tapa lo que intentas señalar.

**Sobre Nominatim.** Es el geocodificador público de OpenStreetMap: sin clave
ni tarjeta, igual que las teselas. A cambio pide identificarse con un
User-Agent de verdad y no pasar de una consulta por segundo, y por eso el
buscador espera a que pulses buscar en vez de consultar letra a letra. Si
algún día esto lo usa mucha gente hay que pagar un geocodificador de verdad;
hasta entonces, esto es lo honesto y es suficiente. La atribución «©
OpenStreetMap» vive en `AtribucionOsm` y no copiada en cada pantalla,
precisamente para que no se olvide en la siguiente que se añada.

### Corregir, borrar y compartir

`/editar/:id` abre el formulario de siempre con el borrador ya relleno
(`BorradorNotifier.desdeCata`). No hay un segundo formulario para editar: dos
formularios acaban pidiendo cosas distintas, y el que se queda viejo es
siempre el que menos se usa.

Tres detalles que parecen pequeños y no lo son:

- **Corregir no reordena el feed.** `actualizar()` deja la cata donde estaba
  y no toca la fecha: arreglar una falta de hace un mes no es una cata nueva.
- **Quitar una foto al editar no borra el fichero hasta guardar.** Mientras no
  guardes, la cata publicada sigue siendo la de antes y tiene que poder
  enseñar su foto. Los ficheros que sobran se limpian al guardar; los de una
  cata borrada, al borrarla.
- **Borrar es lo único que pregunta**, porque es lo único que no se puede
  deshacer, y el diálogo dice qué se pierde en vez de «¿estás seguro?».

Compartir (`lib/features/compartir/`) pinta una estampa de 360×450 y la
captura a ×3 → 1080×1350, que es lo que pide Instagram y lo que ni él ni
WhatsApp recortan. Lleva El Corte y no una foto: el dibujo es de esa croqueta
y de ninguna otra, y no depende de que saliera bien la foto en la barra. Antes
de compartir se enseña la vista previa, porque eso sale de la app del usuario
con su nombre encima.

### La Barra Libre y las dietas

Ésta es la parte que más ha cambiado, y cambió porque la primera versión
estaba mal planteada.

**El agujero.** Se marcaban etiquetas a mano: abrías una cata de jamón,
tocabas «vegana» y la app se lo tragaba. Guardaba etiquetas, no hechos. Y el
catálogo de rellenos tenía once entradas de las que nueve llevaban carne o
pescado: para alguien vegano, abrir el formulario y no encontrar nada que
pedir no es un detalle, es la app diciéndole que no es para él.

**Lo que hay ahora.** No se marcan etiquetas: se contestan tres preguntas
concretas sobre cómo está hecha —la bechamel, el rebozado y la freidora— y
las dietas se deducen (`Dieta.deducir`). Son además preguntas que el camarero
sabe responder: «¿esto es vegano?» se contesta mal muchas veces, «¿la
bechamel es de leche?» no.

Lo que la deducción sabe y una etiqueta a mano no:

- **Una croqueta de boletus no es vegana** si la bechamel es de leche, que es
  lo que pasa en casi todos los bares. Hacen falta las tres cosas: relleno
  vegano, bechamel vegetal y rebozado sin huevo.
- **El seitán es gluten de trigo.** Una croqueta vegana de seitán es de las
  peores cosas que se le pueden poner delante a un celíaco, y es el ejemplo
  perfecto de por qué «vegano» y «sin gluten» no son lo mismo. Está en los
  datos de ejemplo a propósito.
- **«Sin lactosa» no es «sin leche».** El alérgeno es la proteína, no el
  azúcar: la leche sin lactosa sirve para un intolerante y no para un
  alérgico.
- **La freidora tiene pregunta propia.** Una croqueta de harina de arroz
  frita en el mismo aceite que las de trigo no es segura para un celíaco, y
  eso la receta sola no lo ve. Cuando pasa, la ficha lo dice con todas las
  letras en vez de enseñar una pastilla verde.
- **Lo dudoso no cuenta como ausente.** Si no se preguntó de qué es la bebida
  vegetal, puede ser de almendra o de soja, y la app no dice ni que sí ni que
  no: lo pone en «sin confirmar». Confundir «no lo lleva» con «no lo sé» es
  exactamente el error que manda a alguien al hospital.

**Los catorce alérgenos** son los del Anexo II del Reglamento (UE) 1169/2011,
los mismos que cualquier bar de España está obligado a poder decirte. Se usa
la lista oficial entera y no una versión recortada «de croquetas»: es la que
el camarero tiene detrás de la barra, así que preguntar y apuntar hablan el
mismo idioma, y una lista inventada siempre deja fuera el alérgeno de
alguien.

**El catálogo de rellenos** pasó de 11 a 33, y veinte son vegetales. No por
hacer bulto: son los que de verdad se ven en las cartas —champiñones,
calabacín, zanahoria y curry, brócoli, maíz, guisantes, cebolla caramelizada,
patata y puerro, lentejas y verduras, acelgas y pasas, falafel, seitán,
boletus, trufa, calabaza, boniato, berenjena, puerro, coliflor al curry,
pimiento con hummus—. Cada uno lleva su perfil y sus alérgenos.

Lo vegetariano de la lista es sólo lo que necesita lácteo o huevo en el
propio relleno: los quesos. Todo lo vegano vale también para un
vegetariano, y el selector se lo enseña junto; repetir las setas en los dos
grupos sería una lista más larga diciendo lo mismo.

**El selector enseña sólo lo tuyo.** Si has dicho que eres vegano, las de
jamón y las de gamba no aparecen. No es ahorro de scroll: una lista que
empieza por cosas que no puedes comer es la app diciéndote que no está hecha
para ti. Con dos contrapesos, porque filtrar está bien y decidir por el
usuario no: un enlace discreto enseña todas —a veces apuntas la croqueta que
se comió otro— y lo que ya has marcado no desaparece nunca, ni al filtrar ni
al buscar. Con treinta y tres rellenos hay además buscador, que sólo aparece
cuando de verdad hace falta.

**Mi dieta** (`mi_dieta_provider.dart`) es lo que convierte esto en tuyo: lo
dices una vez y cada cata del feed te contesta lo que ibas a preguntar —te
vale, pregunta, o no—, y la Barra Libre abre ya filtrada. Son tres estados y
no dos: «sin datos» es la respuesta honesta para una cata a la que nadie le
preguntó la receta, y juntarla con «no te vale» escondería las que sí te
valdrían si alguien preguntara.

Vacío es un estado legítimo y es el de partida: quien come de todo no tiene
que configurar nada.

### El estilo

Todo es una pegatina: bloque de color plano, contorno de tinta y sombra
maciza desplazada. Al pulsar, el elemento se desplaza exactamente lo que mide
su sombra y la sombra desaparece, así que acaba justo donde estaba su sombra.
Eso vive en `Pegatina` (`lib/core/theme/components/pegatina.dart`) y es lo que
hay que reutilizar para cualquier superficie nueva.

Los tokens están en `lib/core/theme/tokens/`. Ningún color, radio ni sombra
debería escribirse a mano en una pantalla.

---

## Antes de compilar

```bash
python3 herramientas/revisar.py && flutter analyze && flutter test
```

Un par de segundos y sin compilar nada. No sustituye a `flutter analyze`
—que es quien manda—, pero pilla lo que más veces ha roto la compilación
aquí: un símbolo usado sin importar, un import roto, un asset que falta,
llaves descuadradas y nombres con tilde. Eso último es fácil de colar
escribiendo en español: los comentarios y las cadenas van con tildes, pero
Dart sólo admite ASCII en los identificadores, y `final String qué` no
compila.

Lo que no puede ver: si un constructor de un paquete admite `const` o no.
Para eso está `flutter analyze`.

### Los tests

`test/dieta_test.dart` comprueba `Dieta.deducir`, que es lógica pura y de
seguridad: si se equivoca, alguien se come algo que no puede. Es el sitio de
la app donde un fallo hace daño de verdad.

`test/cata_test.dart` cubre lo demás que es lógica y no pintura: cómo se
llama una croqueta de varios ingredientes, qué dice la ficha de lo que
pediste y qué pasa cuando no se apuntó —que es cuando la app tiene que
callarse en vez de suponer.

Los casos están escritos como frases y no como asertos sueltos —«el seitán es
vegano y es trigo», «un relleno vegano con bechamel de leche NO es vegana»—
porque son las reglas del dominio y conviene poder leerlas.

Escribirlos destapó dos fallos que no se veían leyendo el código, los dos de
la misma familia: **afirmar una ausencia sin haber preguntado**.

1. Con la bechamel sin identificar, una cata en la que sólo se había
   contestado «freidora compartida» presumía de «sin frutos secos». Una
   bechamel desconocida puede esconder leche, el gluten de su harina —que la
   bechamel también lleva harina, no sólo el rebozado— y soja o almendra si
   resulta que era vegetal.
2. Un relleno «a mi manera» bloqueaba lo vegano y lo vegetariano, pero seguía
   diciendo «sin frutos secos» y «sin lactosa» de algo cuyo contenido no
   conoce nadie.

## Estructura

```
lib/
  app/          armazón (barra de pestañas) y rutas
  arte/         El Corte, Croqui y el confeti
  core/
    data/       catálogos (rellenos, rangos, medallas) y datos de ejemplo
    models/     Cata, Corte, Mesa, Persona, Recuerdo
    providers/  estado con Riverpod
    theme/      tokens y componentes
    utils/      formateo y semilla determinista
  features/     una carpeta por pantalla
```

---

## Lo que viene después

1. **Firebase** — auth con Apple y Google, Firestore para catas y mesas,
   Storage para las fotos. Mismas versiones que Palito, que ya están probadas.
2. **Foto real** — `image_picker` más los permisos de cámara y fotos en el
   `Info.plist`. Se dejó fuera de la v1 a propósito para que la app pudiera
   ejecutarse sin configurar nada.
3. **Ubicación** — `geolocator` para centrar el mapa donde estás y rellenar el
   barrio solo.
4. **Mesas de verdad** — entrar con código, salir, y expulsar a alguien.

---

## Notas

- Bares, personas y puntuaciones de ejemplo son inventados. No hay nombres
  reales porque las notas tampoco lo son.
- El mapa usa las teselas públicas de OpenStreetMap. Para producción con
  volumen conviene un proveedor propio (Stadia, MapTiler o similar): es
  cambiar una URL en `lib/features/ruta/ruta_page.dart`.
- Los iconos y el logo están en `assets/`, y el kit de marca completo
  (variantes de color, SVG editables) está en la carpeta `catacroket-marca`
  que te pasé en el chat.
