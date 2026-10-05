# Pruebas de las reglas

Las reglas de Firestore son lo único que impide que alguien lea las catas de
una mesa que no es suya. En el plan gratuito no hay Cloud Functions, así que
detrás de ellas no hay nada: lo que no prohíba `firestore.rules`, pasa.

Durante mucho tiempo no hubo ni una prueba, y la auditoría del 5/10/2026
encontró **dos agujeros graves** justo en la parte que no se puede sostener
leyéndola: las cuatro ramas del `allow update` de las mesas.

- Cualquier miembro podía escribir la lista de miembros entera y echar a todo
  el mundo, al creador incluido.
- Para entrar en una mesa no hacía falta el código: bastaba con conocer el
  identificador de la mesa, así que echar a alguien no servía de nada.

Los dos se arreglaron. Estas pruebas son la diferencia entre creer que están
arreglados y saberlo.

## Correrlas

Una vez:

    cd test_reglas && npm install && cd ..

Y cada vez que se toquen las reglas:

    firebase emulators:exec --only firestore "node --test test_reglas"

Hace falta Java 11 o más nuevo, que es lo que pide el emulador.

## Qué se prueba

No el camino feliz —de eso ya se encarga la app— sino el del que ataca:
el extraño que quiere leer, el miembro que quiere mandar, el expulsado que
quiere volver y el que quiere tocar lo que escribió otro.
