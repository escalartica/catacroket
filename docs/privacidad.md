# Privacidad y datos — Catacroket

Lo que la app hace con los datos, escrito para tres sitios a la vez: la
política de privacidad que hay que publicar, las etiquetas de privacidad de
App Store y el formulario de seguridad de datos de Google Play.

Fecha de revisión: septiembre de 2026. Versión auditada: 0.1.0.

## Resumen

Catacroket **no tiene cuentas, no tiene servidor y no manda tus datos a
ninguna parte**. Todo lo que apuntas —catas, notas, fotos, mesas, tu nombre y
tu foto— vive en tu móvil y en las copias de seguridad de tu propio móvil.

Hay dos excepciones, y las dos las provoca el usuario tocando algo:

1. **El mapa.** Las imágenes del mapa se descargan de OpenStreetMap. Al
   pedirlas se envía la zona que estás mirando.
2. **Buscar un bar.** Al escribir el nombre de un sitio, o al tocar «estoy
   aquí», se envía ese texto o tus coordenadas a Nominatim (OpenStreetMap)
   para traducirlo a una dirección.

Ninguna de las dos lleva tu nombre, tu identificador ni nada que te señale.

## Qué se guarda y dónde

| Dato | Dónde vive | Sale del móvil |
|---|---|---|
| Catas (sitio, nota, corte, apuntes, precio) | `SharedPreferences` | No |
| Fotos y vídeos de croquetas | Carpeta de documentos de la app | No |
| Tu nombre y tu foto de perfil | `SharedPreferences` + carpeta de la app | No |
| Mesas, miembros y códigos | `SharedPreferences` | No |
| Tu dieta y tu lista de «esto no me lo pongas» | `SharedPreferences` | No |
| Coordenadas de una cata | `SharedPreferences` | Sólo al geocodificar, ver abajo |

Nada está cifrado por la app: se apoya en el cifrado del sistema operativo,
que es lo que protege el almacenamiento de cualquier app en un móvil con
código de desbloqueo.

## Terceros

**OpenStreetMap** (Fundación OpenStreetMap, Reino Unido) recibe:

- Las coordenadas de la zona del mapa que se está mirando, al cargar cada
  imagen del mapa.
- El texto que escribes al buscar un bar.
- Tus coordenadas exactas, **sólo** si tocas «estoy aquí», para traducirlas a
  una dirección.

Se identifica a la app con un User-Agent (`com.escalartica.catacroket`), que
es lo que su política de uso exige. No se manda ningún identificador de
usuario, ni de dispositivo, ni publicitario.

**No hay** analítica, ni publicidad, ni rastreadores, ni Firebase, ni Crashlytics.

## Permisos y para qué

| Permiso | Cuándo se pide | Si lo deniegas |
|---|---|---|
| Ubicación (en uso) | Sólo al tocar «estoy aquí» al apuntar una cata | Pones el punto a mano en el mapa |
| Cámara | Al elegir «cámara» para una foto | Eliges de la galería, o te quedas sin foto |
| Fotos | Al elegir «galería» | Usas la cámara, o te quedas sin foto |
| Micrófono | Al grabar un vídeo de 15 s | Grabas sin sonido, o no grabas |

La ubicación **nunca** se pide en segundo plano ni al abrir la app.

## Copias de seguridad

**iOS**: las fotos y los datos de la app entran en la copia de iCloud del
usuario, como cualquier otra app. Es lo que permite no perder años de catas al
cambiar de móvil.

**Android**: igual, con una excepción deliberada. Tu dieta y tu lista de
alergias **quedan fuera** de la copia automática
(`res/xml/reglas_copia.xml`). Son datos de salud y no tienen por qué acabar
en Google Drive sin que nadie lo haya pedido; se vuelven a marcar en diez
segundos desde la pantalla de bienvenida.

## Menores

La app no está dirigida a menores de 13 años y no pide la edad. No recoge nada
que permita identificar a una persona.

## Borrar tus datos

Ajustes → Restablecer deja la app como recién instalada. Desinstalarla borra
todo lo demás. Como no hay servidor, no hay nada que pedirle a nadie.

## Contacto

<!-- PENDIENTE: correo de contacto. App Store y Play lo exigen y tiene que
     ser uno que se lea de verdad. -->

---

## Respuestas para los formularios

**App Store — etiquetas de privacidad**

- *Data Not Collected*. La app no recoge ningún dato asociado al usuario.
- Si el formulario pregunta por *Location*: **no se recoge**; se usa en el
  dispositivo y se envía a un tercero sólo para traducirla a una dirección,
  sin asociarla a ninguna identidad.
- *Tracking*: no. No hay IDFA ni nada parecido.

**Google Play — seguridad de datos**

- ¿Recoge o comparte datos? **No.**
- ¿Los datos están cifrados en tránsito? Sí: todo lo que sale va por HTTPS.
- ¿El usuario puede pedir que se borren sus datos? Sí, desde la propia app.
