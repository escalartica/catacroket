# Ficha de tienda

Textos y guion de capturas para App Store y Google Play. Todos los campos
están contados y caben. Las reglas que gobiernan cada límite van anotadas
donde importan, porque no son las mismas en las dos tiendas.

> **Antes de publicar**: pega el enlace de la ficha en
> `lib/core/data/enlaces.dart` (`Enlaces.tienda`). Todos los textos de
> invitación de la app lo recogen solos. Mientras esté vacío, las
> invitaciones dicen el nombre y ya, que es mejor que mandar un enlace roto.

---

## El gancho

Lo que hace distinta a esta app no es que apuntes croquetas. Es **El Corte**:
las cuatro notas que le pones se convierten en un dibujo de su sección, y la
posición de cada miga sale del identificador de la cata, así que el dibujo de
una croqueta es siempre el mismo. Es su retrato, no ruido.

De paso resuelve un problema real que tienen todas las apps de comida: las
fotos hechas en la barra de un bar son feas, y un feed de fotos feas no
invita a volver.

Ese es el argumento de venta. Todo lo demás lo tienen los competidores.

---

## App Store

### Título — 27 / 30

```
Catacroket: catar croquetas
```

No sólo la marca. Una app que nadie conoce todavía necesita que el título
lleve la palabra que la gente busca, y esa palabra es «croquetas».

### Subtítulo — 27 / 30

```
Tu libreta de bares y tapas
```

Apple indexa cada palabra **una sola vez** en el conjunto de título +
subtítulo + claves. Este subtítulo no repite ninguna del título y añade dos
términos que sí se buscan: *bares* y *tapas*.

### Palabras clave — 93 / 100 bytes

```
cata,reseñas,restaurantes,comida,mapa,ruta,amigos,notas,tapeo,gluten,vegana,bechamel,picoteo
```

Comas sin espacios: el espacio cuenta como byte y no separa nada. Se mide en
**bytes, no en caracteres**, y cada tilde o eñe ocupa dos. Ninguna palabra se
repite del título ni del subtítulo.

### Texto promocional — 145 / 170

Se puede cambiar sin publicar versión nueva. No afecta a la búsqueda: es para
convencer, no para posicionar.

```
Ya no hace falta la foto: las cuatro notas dibujan el corte de cada croqueta.
Un retrato distinto para cada una, y siempre el mismo para la suya.
```

### Descripción

**No se indexa en App Store.** Sirve para convertir a quien ya ha llegado, así
que va escrita para leerse, no para colar palabras.

```
Te comes una croqueta buenísima, dices «esta hay que recordarla» y a la
semana siguiente no sabes ni en qué bar fue.

Catacroket es la libreta para eso.

CADA CROQUETA, SU RETRATO
Le pones nota a cuatro cosas —crujiente, cremosidad, sabor y relleno— y la
app dibuja su corte. El crujiente engorda la costra, la cremosidad aclara la
bechamel, el relleno añade trozos de su color y el sabor levanta el vapor.
Cada croqueta sale distinta, y la tuya sale siempre igual: es su retrato.

Sin fotos. Las que se hacen en la barra de un bar salen mal, y una libreta de
fotos mal hechas no apetece abrirla.

TU RUTA EN EL MAPA
Cada bar donde has catado queda como un globo con su nota. Meses después ves
de un vistazo dónde estaba aquella que no se te olvida.

TU GENTE, TU MESA
Crea una mesa, pasa el código a tus amigos y las catas de todos van juntas.
Hay ranking, porque catar más cuenta tanto como puntuar mejor.

BARRA LIBRE
Si no comes de todo, márcalo una vez. Cada cata te dirá si te vale, si hay
que preguntar o si no. Veganas, vegetarianas, sin gluten, sin lactosa, sin
huevo y sin frutos secos.

CROQUETÓMETRO
De Aprendiz de panko a Leyenda dorada. Medallas, racha semanal y tu paladar
en un vistazo.

SIN CUENTA Y SIN NUBE
Las catas viven en tu móvil. No hay registro, no hay contraseña y no se
manda nada a ningún servidor.

Gratis, en español y hecha por quien también se pide siempre las de jamón.
```

---

## Google Play

### Título — 29 / 30

```
Catacroket: cata de croquetas
```

Prohibido por política desde 2021: emojis, MAYÚSCULAS completas, «mejor»,
«nº 1», «gratis» y las llamadas a la acción. Este título no lleva nada de eso.

### Descripción corta — 74 / 80

```
Apunta cada croqueta que catas, ponle nota y compárala con la de tu gente.
```

### Descripción larga

**Aquí sí se indexa**, al contrario que en Apple. La densidad objetivo es del
2-3 % y natural: Google entiende el lenguaje y penaliza el amontonamiento de
palabras clave.

Medido sobre este texto: 2.251 caracteres de 4.000, 421 palabras. Cada
término va entre el 0,2 % y el 1,2 %, y agrupados como los agrupa un
buscador, `croqueta/croquetas` sale al 1,4 % y `cata/catas/catar` al 1,9 %.
Dentro de objetivo. Sumar las dos familias da 4,5 %, pero eso es juntar dos
cosas distintas —la comida y el acto de catarla— y no es así como se mide.

```
Te comes una croqueta buenísima, dices «esta hay que recordarla» y a la
semana siguiente no sabes ni en qué bar fue. Catacroket es la libreta para
eso: apuntas la croqueta, le pones nota y queda guardada con su sitio, su
fecha y con quién estabas.

CADA CROQUETA TIENE SU RETRATO

Puntúas cuatro cosas —crujiente, cremosidad, sabor y relleno— y la app dibuja
el corte de esa croqueta. El crujiente engorda la costra, la cremosidad
aclara la bechamel, el relleno añade trozos de su color y el sabor levanta el
vapor. Cada cata sale distinta y la tuya sale siempre igual, porque el dibujo
nace de su propio identificador.

Por eso no hay fotos. Las fotos de croquetas hechas en la barra de un bar
salen mal, y una libreta de fotos mal hechas no apetece abrirla.

LA RUTA CROQUETERA

Todos los bares donde has catado, en un mapa, cada uno con su nota. Filtras
por las tuyas o por las que valen para tu dieta, y meses después ves de un
vistazo dónde estaba aquella croqueta que no se te olvida. El mapa es de
OpenStreetMap y no hace falta cuenta de nada.

TUS MESAS

Una mesa es tu grupo: creas una, pasas el código de seis letras y las catas
de todos van juntas. Hay ranking, y manda quien más cata, no quien mejor
puntúa: esto es una mesa de amigos, no un jurado.

Borrar una mesa nunca borra sus catas. Se vuelven a tu libreta, que es la
única que no se puede borrar.

BARRA LIBRE, SI NO COMES DE TODO

Márcalo una vez en tu perfil y cada cata te dirá si te vale, si hay que
preguntar o si no. Veganas, vegetarianas, sin gluten, sin lactosa, sin huevo
y sin frutos secos. Y si hay algo que simplemente no quieres que te pongan
—marisco, sésamo, boletus— también se apunta.

EL CROQUETÓMETRO

Tu historial de paladar: cuántas llevas, tu nota media, en cuántas ciudades y
países has catado, tus medallas y tu rango. Se empieza de Aprendiz de panko y
se llega a Leyenda dorada. Hay racha semanal, y se apaga si dejas de catar.

PARA COMPARTIR

Cada cata se convierte en una estampa que se manda al grupo tal cual. Es la
forma bonita de decir «mirad lo que me acabo de comer».

SIN CUENTA, SIN NUBE, SIN ANUNCIOS

Las catas viven en tu móvil. No hay registro, no hay contraseña, no hay
publicidad y no se manda nada a ningún servidor.

Gratis y en español.
```

---

## Guion de capturas

**El 90 % de la gente no pasa de la tercera.** Así que las tres primeras
tienen que contar la historia entera solas. Apple indexa el texto de las
capturas desde junio de 2025, así que los rótulos son texto de verdad, no
decoración.

Apple admite hasta 10; Google, **8 como máximo** (no 10).

| # | Pantalla | Rótulo | Por qué va aquí |
|---|---|---|---|
| 1 | Ficha con El Corte grande | **Cada croqueta, su retrato** | El gancho. Es lo único que no tiene nadie más |
| 2 | Formulario, paso del corte | **Cuatro notas y se dibuja sola** | Explica de dónde sale el dibujo |
| 3 | Ruta croquetera con globos | **Todos tus bares, en un mapa** | La segunda razón para volver |
| 4 | La Vitrina con la racha | **Tu libreta y la de tu gente** | Presenta el grupo |
| 5 | Mesas con ranking | **Manda quien más cata** | La regla que hace gracia y engancha |
| 6 | Barra Libre filtrada | **Si no comes de todo, te avisa** | Público concreto y desatendido |
| 7 | Croquetómetro | **De Aprendiz de panko a Leyenda dorada** | La progresión |
| 8 | Estampa para compartir | **Mándala al grupo** | Cierra con la acción social |

### Vídeo

En App Store se reproduce solo y sin sonido, y sube la conversión entre un 20
y un 40 %: **merece la pena**. En Google Play hay que darle al play y sólo lo
hace el 6 %, así que ahí es secundario.

15 segundos: pones las cuatro notas → el corte se dibuja → aparece en el mapa
→ se manda al grupo. Sin locución.

### Gráfico destacado (sólo Google) — 1024 × 500 exactos

Obligatorio para que Google pueda destacar la app. Sin él, queda fuera de esas
posiciones. Croqui sobre el fondo de lunares, el logotipo y «Cata croquetas,
guárdalas en tu libreta».

---

## Categorías

| Tienda | Principal | Secundaria |
|---|---|---|
| App Store | Comida y bebida | Estilo de vida |
| Google Play | Comida y bebida | — |

«Comida y bebida» tiene bastante menos competencia que «Redes sociales», y es
donde alguien busca esto de verdad.

---

## Lo que no se puede saber sin herramientas de pago

Volumen de búsqueda real de cada palabra clave, la dificultad de posicionarse
para «croquetas» y en qué puesto queda la app. Para eso hacen falta AppTweak,
Sensor Tower o similares. Lo de aquí arriba está construido con las reglas de
cada tienda y con lo que la app hace de verdad, pero las palabras clave habrá
que ajustarlas con datos cuando los haya.
