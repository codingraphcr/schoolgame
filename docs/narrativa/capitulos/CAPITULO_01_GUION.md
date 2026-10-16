# Capítulo 1 — Guion (etapa 1)

**Estado:** propuesta de guion para revisar con el equipo. Sigue la especificación (`CAPITULO_01.md`) y las
propuestas de su sección 18 (la entrada al PC del prólogo fue involuntaria; la clase usa compañeros sin nombre;
el nivel 1 no repite el tutorial). Los diálogos ya están en `data/dialogues/capitulo1/` y las preguntas en
`data/challenges/` (ver la tabla del final). Lo que dice la especificación palabra por palabra (la arena y el cierre)
no se cambió.

**Personajes:** Kai · Prof. Alvarado · Chip · Glitch · compañeros de clase sin nombre (los NPC de fondo de Ariel) ·
«???» no aparece en este capítulo (el antagonista solo observa: Biblia VI, «décimo: observa, prueba y deja señales»).

---

## Nivel 1 — Una clase diferente

### Escena 1.1 · La clase (Sala 3)

Primera clase después del prólogo, en el **aula de Kai: la Sala 3**, junto al pasillo principal (cambio pedido por el
equipo después de probar el juego: la clase tiene que verse como una clase). El Prof. Alvarado está frente a la
pizarra y los compañeros, en sus pupitres. Da **«Uso ético de la información»**: en una revisión autorizada solo se
mira lo que el encargado permite. Para practicar, cada uno va a revisar el **registro de eventos** del sistema de
entrenamiento. Las computadoras de práctica empiezan a fallar una por una (pitidos, pantallas que parpadean).

### Escena 1.2 · Investigar el registro y la cinemática (Sala 3)

Kai abre el registro en la computadora de su puesto (comandos ya conocidos: `ls`, `cat`; lo nuevo es **leer un
registro**). Hay entradas raras: inicios de sesión a las 3:12 a. m., un usuario «chip_y_glitch» que no existe y
archivos de práctica modificados cientos de veces en un minuto.

- **Desafío «Comportamiento anómalo»** (`cap1_registro_anomalo`): ¿cuál de esas entradas es la señal más clara de que
  algo anda mal? Enseña a reconocer comportamientos anómalos.
- Se abre la página del Grimorio **«Registro de eventos»**.
- **Cinemática corta:** «Si el registro no me dice quién... tal vez pueda verlo». Kai mira con la Visión Digital (la
  elige él: ya sabe usarla) y la cámara va a los monitores: **Chip y Glitch** saltan entre las computadoras. Glitch
  nota que Kai los mira; Chip no se lo cree... hasta que Kai los saluda. Escapan por la puerta, las computadoras
  vuelven a la normalidad y Kai sale detrás («¡Ya vuelvo, profe!»).
- *Diferencia con el prólogo:* allá la criatura amenazaba («Tú no deberías poder vernos»). Acá los hermanos son
  traviesos y se asustan; Chip dice que **eso no estaba en el plan** (pista de la Biblia: «las amenazas reaccionan
  de manera particular a su presencia»).

### Escena 1.3 · La persecución por el colegio (Pasillo → Escaleras → Pasillo del segundo piso)

Chip y Glitch salen de la Sala 3. Kai los sigue por el Pasillo y suben por las escaleras (desde el Capítulo 1 ya
se pueden usar): es la presentación de la mecánica (sin daño ni temporizador).

Arriba, en el **pasillo del segundo piso** (largo, entre las escaleras y la biblioteca), la persecución se pone
seria. Glitch: «¡Todavía nos sigue!»; Chip: «Plan B: ¡obstáculos!».

- **Chip tira estanterías.** Primero tiemblan (aviso «!»), después caen hacia Kai y quedan en el piso como un
  obstáculo que hay que saltar. Si caen encima de Kai, le quitan medio cristal.
- **Glitch tira cajas.** Ruedan por el piso hacia Kai; hay que saltarlas (medio cristal si tocan).
- **Dos veces «¡casi!».** Los hermanos se quedan quietos hasta que Kai está a punto de tocarlos («¡Te tengo!»),
  y se escapan a toda velocidad («¡Ups, casi!», «¡Por un pelo!»).
- **Los estudiantes reaccionan** al pasar: «¡No se corre en los pasillos!», «¿Quién tiró eso?».

Al final del pasillo, Chip: «¡Glitch, a la biblioteca!», y Kai grita «¡Esperen!» mientras desaparecen por la puerta.

### Escena 1.4 · La biblioteca

Glitch se metió en la computadora del catálogo: en la pantalla pública quedó abierto **el archivo privado de un
estudiante** (notas y datos personales).

- **Desafío «Un archivo que no es tuyo»** (`cap1_archivo_privado`): ¿qué hace Kai? Correcto: no abrirlo ni copiarlo,
  cerrar la sesión y avisar al encargado. Enseña confidencialidad y protección de datos.
- Chip lo regaña («¡Así no era el plan!») y los dos huyen hacia la **zona técnica**.

### Escena 1.5 · El cuarto técnico (fin del nivel 1)

Los hermanos se cuelan por debajo de la puerta del **cuarto técnico** del colegio (los servidores). La puerta está
cerrada con llave. Kai no la fuerza: **le pide permiso al profesor** (acceso autorizado). El profesor acepta, pero
necesita unos minutos para preparar el acceso (pedir la llave en la Dirección y desconectar el sistema de
entrenamiento de la red del colegio).

### Escena 1.6 · Tras las huellas del error (expansión, v1.9)

Mientras tanto, Kai puede explorar el colegio (patio, soda, biblioteca, amigos, actividades opcionales). El objetivo
principal sigue claro: **buscar rastros de la falla con la Visión Digital** y volver con el profesor.

- Hay tres rastros (`ErrorTrace`): «CHIP ESTUVO AQUÍ» en la pared del patio, el «JIJIJI» que se repite en la radio de
  la soda (Glitch) y una flecha hacia el cuarto técnico en la pizarra del pasillo. Solo se ven con la Visión y solo
  en este momento. **Bastan dos**: no hay temporizador ni hay que encontrarlos todos.
- Si Kai vuelve antes, el profesor le pide «un par de rastros».
- Con dos, Kai vuelve a la Sala 3. El profesor nombra lo que hizo: **buscar indicadores** (las señales de que un
  sistema fue alterado; se anotan antes de tocar nada). Ya tiene la llave: lo acompaña hasta la puerta y le pide
  revisar **solo** el respaldo del sistema de entrenamiento.

Pasos: `pedir_permiso` → `buscar_huellas` → `volver_profesor`. Marcas: `huella_patio`, `huella_soda`,
`huella_pasillo`, `nivel_1_completado`.

---

## Nivel 2 — Travesuras en el sistema

### Escena 2.1 · Los servidores

En el cuarto técnico, el servidor del sistema de entrenamiento está en rojo. Chip y Glitch se ríen desde adentro del
monitor y **desaparecen dentro de la computadora**. Kai intenta seguirlos, pero no sabe cómo.

### Escena 2.2 · Inmersión Digital

El jugador activa la Visión Digital (Q): en el monitor aparece una conexión brillante. Kai se acerca.

> **KAI [pensativo]:** «La otra vez la computadora me jaló».
> **KAI:** «Esta vez... voy yo».

*Pendiente:* esta línea recuerda la entrada a la computadora del prólogo. El equipo decidió mover esa entrada a otro
lugar (por definir): cuando se sepa dónde, se ajusta o se cambia la línea.

Kai atraviesa el monitor (transición de `DigitalDive`). Título: **INMERSIÓN DIGITAL**. Se desbloquea para siempre y
se abre su página del Grimorio. Kai todavía no la domina: le cuesta materializarse adentro.

### Escena 2.3 · La persecución digital

La red de entrenamiento del colegio: plataformas flotantes, vacíos, estructuras de datos, la **barrera de
corrupción** detrás y el **temporizador** (4:00). Tres tramos, cada uno termina en una zona segura con su pregunta:

| Checkpoint | Desafío | Pregunta |
|---|---|---|
| 1 | `cap1_checkpoint_1` | ¿Qué debe hacerse al encontrar archivos privados durante una revisión autorizada? |
| 2 | `cap1_checkpoint_2` | ¿Qué se recomienda antes de restaurar información importante? |
| 3 | `cap1_checkpoint_3` | ¿Qué ayuda a proteger la confidencialidad? |

Los hermanos se burlan a la distancia mientras Kai avanza.

### Escena 2.4 · La arena

La barrera se detiene, el temporizador desaparece y se registra el checkpoint. Diálogo de la especificación (sin
cambios). Empieza el combate: **sin límite de tiempo**.

### Escena 2.5 · El escudo de Chip

A mitad de la pelea, Chip se protege con un escudo de datos. El combate entra en una **fase segura** (los dos
retroceden; la arena se calma) y aparece una terminal.

- En la terminal, `cat escudo.cfg` muestra una configuración insegura: **todos los usuarios tienen permiso de
  escritura**.
- **Desafío «Permisos de más»** (`cap1_escudo_chip`): ¿qué cambio desactiva el escudo? Correcto: **dar solo los
  permisos necesarios** (mínimo privilegio). Trabaja el control de acceso sin repetir la pregunta del checkpoint 3.

### Escena 2.6 · El cierre

Diálogo de la especificación (sin cambios). Después, Kai les explica por qué importa:

> **KAI:** «Detrás de cada computadora hay personas. Si borran un trabajo, alguien pierde horas. Si muestran un
> archivo privado, alguien queda expuesto».
> **GLITCH [pensativo]:** «...¿Como cuando Chip me borró mi colección de ruidos?».
> **CHIP [sorprendido]:** «¡Eso fue un accidente!».
> **GLITCH:** «Igual me dolió».
> **CHIP [pensativo]:** «...Ok. Ya entendimos».

Chip deja caer un **Fragmento de Datos**: «Tomá. Lo encontramos acá adentro. No sabemos qué es». Kai lo toma y el
Grimorio muestra su lectura (pantalla propia, no un diálogo):

```
ORIGEN: DESCONOCIDO
ESTADO: INCOMPLETO
OBSERVADOR: RECONOCIDO
PROTOCOLO: [DATOS CORRUPTOS]
```

> **KAI [pensativo]:** «¿Observador...?».

Chip y Glitch se van (neutralizados, no derrotados para siempre). Kai sale de la computadora.

### Escena 2.7 · El profesor (cuarto técnico)

> **PROF. ALVARADO:** «¿Y? ¿Qué le pasaba al sistema de entrenamiento?».
> **KAI:** «Alguien estaba jugando con él. Ya no va a molestar... creo».
> **PROF. ALVARADO [sorprendido]:** «¿Alguien? ¿Quién?».
> **KAI [sonriente]:** «Digamos que... aprendieron la lección».
> **PROF. ALVARADO [sonriente]:** «Buen trabajo, Kai. Andá a descansar».

Kai se va. **Escena aparte** (opción A, decisión del equipo del 14 de octubre de 2026: Kai no la ve ni sabe nada
de ella, como dice la Biblia): fundido a negro y el cartel «Mientras tanto, en el cuarto técnico...». El profesor,
solo frente al monitor: en la pantalla se abre el archivo **`GENESIS_ARCHIVE`** y la cámara se acerca despacio.
**Sin explicación:** el profesor se queda mirándolo en silencio («...»). «FIN DEL CAPÍTULO 1» sobre esa imagen y,
después, Kai aparece en la **entrada del colegio** (no vuelve al cuarto).

**FIN DEL CAPÍTULO 1.** Marcas: `nivel_2_completado`, `capitulo_1_completado`.

*Cuidado con la Biblia:* el profesor no explica nada ni dice qué es el archivo (reglas 3, 11 y 12). Kai no lo ve.

### Después del capítulo · Camino a casa

Misión `camino_a_casa`, entre el Capítulo 1 y el 2 (sin combate ni examen; detalle completo en
`docs/escenarios/HOGAR_DE_KAI.md`). En la entrada, los amigos comentan el día («Mae, ¿viste cómo se pusieron las
compus de la Sala 3?»). Objetivo: **«Regresá a casa.»** Kai cruza su barrio de tarde (opcional: el vecino, la
pulpería, la parada, Canelo) y llega a su casa: la primera charla con mamá y papá («Recordá esto, Kai: cuanto más
grande sea tu capacidad de cambiar las cosas, mayor será tu responsabilidad de hacer lo correcto»). Después de la
cena, Kai explora su cuarto y se acuesta. Mientras duerme, los papás hablan a solas («¿Creés que ya empezó?» / «No lo
sé.»), sin explicar nada. Esa noche, la **Resonancia Digital**; Kai despierta confundido y empieza el **Capítulo 2**.

*Cuidado con la Biblia (v1.6):* los papás conocen parte del origen de Kai, pero no lo dicen; Kai no descubre nada.

---

## Datos de esta etapa

| Archivo | Qué es |
|---|---|
| `data/characters/chip.tres`, `glitch.tres` | Personajes de los diálogos (sin retrato hasta que Ariel los dibuje) |
| `data/quests/una_clase_diferente.tres`, `travesuras_en_el_sistema.tres` | Las dos misiones con sus pasos y títulos (registradas en `QuestDB`; todavía no empiezan solas) |
| `data/dialogues/capitulo1/*.tres` | Los diálogos de cada escena |
| `data/challenges/cap1_*.tres` | Los dos desafíos del nivel 1, los tres checkpoints y el escudo de Chip |

«El cuarto viejo» (fin del prólogo) lleva a «Una clase diferente», y esta a «Travesuras en el sistema».
