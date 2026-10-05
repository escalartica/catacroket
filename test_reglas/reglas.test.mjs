import { after, before, beforeEach, describe, it } from 'node:test';
import { readFileSync } from 'node:fs';
import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, getDocs, setDoc, updateDoc, deleteDoc, collection } from 'firebase/firestore';

// Quién es quién en todas las pruebas.
const DUENA = 'uid-duena';     // creó la mesa
const AMIGO = 'uid-amigo';     // está dentro
const FUERA = 'uid-fuera';     // tiene cuenta, no está en la mesa
const COMPLICE = 'uid-complice';

const MESA = 'mesa-1';
const CODIGO = 'NGZYV8';

let entorno;

before(async () => {
  entorno = await initializeTestEnvironment({
    projectId: 'catacroket-reglas',
    firestore: {
      rules: readFileSync('firestore.rules', 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
  });
});

after(async () => entorno?.cleanup());

// Estado de partida, puesto SIN reglas: una mesa de la dueña, con un amigo
// dentro, y una cata de cada uno.
beforeEach(async () => {
  await entorno.clearFirestore();
  await entorno.withSecurityRulesDisabled(async (c) => {
    const db = c.firestore();
    await setDoc(doc(db, 'mesas', MESA), {
      nombre: 'Mamarracha',
      creadoPor: DUENA,
      codigo: CODIGO,
      miembros: [DUENA, AMIGO],
    });
    await setDoc(doc(db, 'mesas', MESA, 'catas', 'cata-duena'), {
      sitio: 'Rufino', autorUid: DUENA,
    });
    await setDoc(doc(db, 'mesas', MESA, 'catas', 'cata-amigo'), {
      sitio: 'La paka', autorUid: AMIGO,
    });
    await setDoc(doc(db, 'codigos', CODIGO), { mesaId: MESA, creadoPor: DUENA });
    await setDoc(doc(db, 'usuarios', DUENA), { nombre: 'Ce' });
  });
});

const como = (uid) => entorno.authenticatedContext(uid).firestore();
const sinCuenta = () => entorno.unauthenticatedContext().firestore();

describe('Un extraño', () => {
  it('no lee una mesa en la que no está', async () => {
    await assertFails(getDoc(doc(como(FUERA), 'mesas', MESA)));
  });

  it('no lee las catas de esa mesa', async () => {
    await assertFails(
      getDoc(doc(como(FUERA), 'mesas', MESA, 'catas', 'cata-duena')),
    );
  });

  it('sin cuenta no lee nada', async () => {
    await assertFails(getDoc(doc(sinCuenta(), 'mesas', MESA)));
  });

  it('no se puede bajar la lista de todos los usuarios', async () => {
    // `get` sí y `list` no: sin esto, cualquiera con una cuenta se lleva el
    // nombre de todo el mundo.
    await assertFails(getDocs(collection(como(FUERA), 'usuarios')));
  });

  it('no se puede bajar la lista de todos los códigos', async () => {
    await assertFails(getDocs(collection(como(FUERA), 'codigos')));
  });

  it('no se cuela en la mesa sin el código', async () => {
    // EL AGUJERO GRAVE. Antes bastaba con conocer el identificador de la
    // mesa, y el identificador lo conoce para siempre cualquiera que haya
    // estado dentro alguna vez.
    await assertFails(
      updateDoc(doc(como(FUERA), 'mesas', MESA), {
        miembros: [DUENA, AMIGO, FUERA],
      }),
    );
  });

  it('con el código sí entra', async () => {
    await assertSucceeds(
      updateDoc(doc(como(FUERA), 'mesas', MESA), {
        miembros: [DUENA, AMIGO, FUERA],
        codigoUsado: CODIGO,
      }),
    );
  });

  it('con un código equivocado no entra', async () => {
    await assertFails(
      updateDoc(doc(como(FUERA), 'mesas', MESA), {
        miembros: [DUENA, AMIGO, FUERA],
        codigoUsado: 'XXXXXX',
      }),
    );
  });

  it('no mete a nadie más que a sí mismo', async () => {
    await assertFails(
      updateDoc(doc(como(FUERA), 'mesas', MESA), {
        miembros: [DUENA, AMIGO, FUERA, COMPLICE],
        codigoUsado: CODIGO,
      }),
    );
  });
});

describe('Un miembro de la mesa', () => {
  it('lee las catas de los demás: de eso va compartir', async () => {
    await assertSucceeds(
      getDoc(doc(como(AMIGO), 'mesas', MESA, 'catas', 'cata-duena')),
    );
  });

  it('NO puede echar a los demás', async () => {
    // EL OTRO AGUJERO GRAVE. La rama de «me salgo yo» sólo miraba que quien
    // escribe no quedara dentro de la lista nueva, sin compararla con la
    // vieja: escribir `miembros: ['mi-amigo']` vaciaba la mesa y metía a
    // quien quisiera. El cómplice pasaba a leerlo todo.
    await assertFails(
      updateDoc(doc(como(AMIGO), 'mesas', MESA), { miembros: [COMPLICE] }),
    );
  });

  it('NO puede dejar la mesa sin nadie', async () => {
    await assertFails(
      updateDoc(doc(como(AMIGO), 'mesas', MESA), { miembros: [] }),
    );
  });

  it('NO puede meter a un amigo suyo', async () => {
    await assertFails(
      updateDoc(doc(como(AMIGO), 'mesas', MESA), {
        miembros: [DUENA, AMIGO, COMPLICE],
      }),
    );
  });

  it('sí puede salirse él solo', async () => {
    await assertSucceeds(
      updateDoc(doc(como(AMIGO), 'mesas', MESA), { miembros: [DUENA] }),
    );
  });

  it('puede cambiar el nombre de la mesa', async () => {
    await assertSucceeds(
      updateDoc(doc(como(AMIGO), 'mesas', MESA), { nombre: 'Otro nombre' }),
    );
  });

  it('NO puede apropiarse de la mesa', async () => {
    await assertFails(
      updateDoc(doc(como(AMIGO), 'mesas', MESA), { creadoPor: AMIGO }),
    );
  });

  it('NO puede borrar la mesa de otro', async () => {
    await assertFails(deleteDoc(doc(como(AMIGO), 'mesas', MESA)));
  });

  it('NO puede tocar la cata de otro', async () => {
    await assertFails(
      updateDoc(doc(como(AMIGO), 'mesas', MESA, 'catas', 'cata-duena'), {
        sitio: 'Lo cambio yo',
      }),
    );
  });

  it('NO puede borrar la cata de otro', async () => {
    await assertFails(
      deleteDoc(doc(como(AMIGO), 'mesas', MESA, 'catas', 'cata-duena')),
    );
  });

  it('sí puede borrar la suya', async () => {
    await assertSucceeds(
      deleteDoc(doc(como(AMIGO), 'mesas', MESA, 'catas', 'cata-amigo')),
    );
  });

  it('NO puede subir una cata firmada por otro', async () => {
    await assertFails(
      setDoc(doc(como(AMIGO), 'mesas', MESA, 'catas', 'nueva'), {
        sitio: 'Bar', autorUid: DUENA,
      }),
    );
  });

  it('sí sube una cata suya', async () => {
    await assertSucceeds(
      setDoc(doc(como(AMIGO), 'mesas', MESA, 'catas', 'nueva'), {
        sitio: 'Bar', autorUid: AMIGO,
      }),
    );
  });
});

describe('La dueña de la mesa', () => {
  it('puede echar a alguien', async () => {
    await assertSucceeds(
      updateDoc(doc(como(DUENA), 'mesas', MESA), { miembros: [DUENA] }),
    );
  });

  it('puede borrar su mesa', async () => {
    await assertSucceeds(deleteDoc(doc(como(DUENA), 'mesas', MESA)));
  });

  it('rotar el código deja fuera a quien tenía el viejo', async () => {
    // Esto es lo que convierte «echar a alguien» en algo que sirve de algo.
    await assertSucceeds(
      updateDoc(doc(como(DUENA), 'mesas', MESA), { codigo: 'NUEVO1' }),
    );
    await assertFails(
      updateDoc(doc(como(FUERA), 'mesas', MESA), {
        miembros: [DUENA, AMIGO, FUERA],
        codigoUsado: CODIGO,
      }),
    );
  });
});

describe('Tu ficha', () => {
  it('la escribes sólo tú', async () => {
    await assertFails(
      setDoc(doc(como(FUERA), 'usuarios', DUENA), { nombre: 'Te la cambio' }),
    );
    await assertSucceeds(
      setDoc(doc(como(DUENA), 'usuarios', DUENA), { nombre: 'Ce' }),
    );
  });
});
