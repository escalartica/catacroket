# Política de privacidad de Catacroket

Última actualización: 30 de septiembre de 2026

## Lo corto

Catacroket funciona entera sin cuenta y sin conexión: apuntas tus croquetas y
se quedan en tu móvil.

Hay una sola cosa que hace que algo salga de ahí, y es que tú la pidas:
**compartir una mesa con otras personas**. Para eso hace falta una cuenta con
tu correo, y las catas de esa mesa se guardan en un servidor para que los
móviles de los demás puedan verlas. Si nunca compartes una mesa, no se crea
ninguna cuenta y no se sube nada.

No hay anuncios, no hay analítica y no hay rastreo, compartas o no.

## Lo que se queda en el móvil

Tus catas —el bar, la ciudad, las notas, la puntuación, lo que escribiste, las
fotos y el punto del mapa— se guardan en el almacenamiento privado de la
aplicación, en tu móvil.

También se quedan ahí, y **no salen nunca** aunque compartas:

- Tu dieta y tus alergias, y la lista de «lo que no quiero encontrarme».
- Tu nombre y tu foto de perfil, mientras no entres en una mesa compartida.
- Las mesas que no has compartido con nadie.

Si borras la aplicación, todo eso se borra con ella.

## Si creas una cuenta

La cuenta se crea con **correo y contraseña** y sólo sirve para compartir
mesas. La gestiona Firebase Authentication, de Google. Nosotros vemos tu
correo; la contraseña no la vemos ni nosotros ni nadie, se guarda cifrada en
sus servidores.

En cuanto hay cuenta se guarda también, en la base de datos (Cloud Firestore,
de Google), **el nombre que hayas puesto en tu perfil**, para que en las mesas
compartidas tus catas salgan con tu nombre y no con un código.

## Si compartes una mesa

Entonces, y sólo entonces, las catas de esa mesa se copian al servidor para
que las vean los demás miembros. De cada cata viaja:

- El bar, la ciudad y el país.
- **Las coordenadas exactas del sitio**, si las pusiste.
- La fecha, el precio, la puntuación, la receta y lo que escribieras.
- **Las fotos**, reducidas de tamaño.
- Quién la apuntó.

Quién puede verlo: **sólo las personas que están en esa mesa**. El servidor
tiene reglas que lo comprueban en cada lectura; alguien de fuera no puede
leerlas aunque lo intente. Un código de mesa es una invitación: quien lo tenga
puede entrar, así que dáselo sólo a quien quieras dentro.

Y algo que conviene decir claro: como el proyecto de servidor es nuestro,
técnicamente **sí podríamos ver esos datos** desde el panel de Google. No lo
hacemos y no hay nada montado para hacerlo, pero sería mentira decir que no
tenemos forma. Lo que nunca sale del móvil (el bloque de arriba) no podemos
verlo de ninguna manera.

Las catas de tus mesas privadas no se suben. Si sales de una mesa o la borras,
tus catas siguen en tu móvil.

## Borrar la cuenta

Desde **Perfil → Borrar cuenta**, dentro de la aplicación, sin escribir a
nadie. Desaparecen la cuenta y el acceso a las mesas compartidas.

Tus catas del móvil **no se tocan**: son tuyas y siguen ahí. Si además quieres
que se borre lo que ya subiste a una mesa, bórralo desde la mesa antes de
borrar la cuenta, o escríbenos al correo de abajo y lo hacemos nosotros.

## La ubicación

Se pide sólo cuando pulsas para poner el punto de una cata en el mapa.

Para rellenar solos la ciudad y el país, esas coordenadas se le mandan a
**Nominatim**, el buscador de direcciones de OpenStreetMap, que responde con el
nombre del sitio. En ese momento un punto aproximado de dónde estás sale del
móvil hacia sus servidores, junto a tu dirección IP. No pasa por nosotros y no
guardamos copia. Su política está en
<https://osmfoundation.org/wiki/Privacy_Policy>.

Puedes no dar la ubicación: el punto se pone a mano y entonces no se consulta
nada.

## Las fotos

La cámara y el carrete se usan sólo cuando tú eliges una foto para una cata o
para tu perfil. La copia se guarda en el almacenamiento privado de la
aplicación. Sólo sale del móvil si esa cata está en una mesa compartida, y
entonces va reducida de tamaño.

## El mapa

Los mapas los dibuja **CARTO**, sobre datos de **OpenStreetMap**. El móvil les
pide las imágenes del trozo de mapa que estás mirando, y esa petición —como
cualquier petición a una web— lleva tu dirección IP y la zona que se ve.

Ocurre entre tu móvil y sus servidores; nosotros no intervenimos ni recibimos
copia. Sus políticas están en <https://carto.com/privacy/> y
<https://wiki.osmfoundation.org/wiki/Privacy_Policy>.

## Compartir una cata como imagen

Cuando compartes una cata, la aplicación prepara una imagen y se la pasa al
selector del sistema o a WhatsApp. A partir de ahí manda la aplicación que
elijas y su política, no la nuestra.

## Rastreo y publicidad

No hay. Ni anuncios, ni identificadores de publicidad, ni rastreo entre
aplicaciones, ni perfilado, ni analítica de uso. Nada de lo que hagas en
Catacroket se cruza con ningún otro sitio ni se vende a nadie.

## Menores

La aplicación no está dirigida a menores de 14 años y no les pide datos. Para
crear una cuenta hay que tener 14 años o más, que es la edad a partir de la
cual en España se puede consentir por uno mismo el tratamiento de datos.

## Tus derechos

Si nunca has creado una cuenta, no tenemos ningún dato tuyo y no hay nada que
pedirnos: todo está en tu móvil.

Si la has creado, tienes derecho a acceder a tus datos, corregirlos,
suprimirlos, limitar su tratamiento, oponerte y pedir que te los entreguemos en
un fichero. La supresión puedes hacerla tú desde la propia aplicación; para lo
demás, escribe al correo de abajo y se responde en un mes como máximo. Si crees
que no lo hacemos bien, puedes reclamar ante la Agencia Española de Protección
de Datos (<https://www.aepd.es>).

Los datos se guardan mientras tengas la cuenta, y se tratan para lo único que
existen: que una mesa compartida funcione.

## Dónde están los datos

En servidores de **Google (Firebase)**, que actúa como encargado del
tratamiento.

Los datos **se guardan dentro de la Unión Europea**: la base de datos está en
la región europea de Google. No se transfieren fuera del Espacio Económico
Europeo.

## Cambios

Si algo de esto cambia, se dice aquí y se avisa dentro de la aplicación antes
de que pase.

## Contacto

escalartica@gmail.com

Para cualquier duda sobre esta política o sobre tus datos. Es el correo que hay
que poner también en la ficha de App Store y en la de Play: las dos tiendas lo
exigen y comprueban que responda.
