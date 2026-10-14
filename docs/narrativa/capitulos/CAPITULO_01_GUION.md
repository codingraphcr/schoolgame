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

### Escena 1.3 · Primera persecución corta (Pasillo → Escaleras)

Chip y Glitch salen de la Sala 3. Kai los sigue por el Pasillo y suben por las escaleras (desde el Capítulo 1 ya
se pueden usar). Persecución corta: los hermanos van delante y esperan cuando Kai se queda atrás. Sin daño ni
temporizador: es la presentación de la mecánica.

### Escena 1.4 · La biblioteca

Glitch se metió en la computadora del catálogo: en la pantalla pública quedó abierto **el archivo privado de un
estudiante** (notas y datos personales).

- **Desafío «Un archivo que no es tuyo»** (`cap1_archivo_privado`): ¿qué hace Kai? Correcto: no abrirlo ni copiarlo,
  cerrar la sesión y avisar al encargado. Enseña confidencialidad y protección de datos.
- Chip lo regaña («¡Así no era el plan!») y los dos huyen hacia la **zona técnica**.

### Escena 1.5 · El cuarto técnico (fin del nivel 1)

Los hermanos se cuelan por debajo de la puerta del **cuarto técnico** del colegio (los servidores). La puerta está
cerrada con llave. Kai no la fuerza: **le pide permiso al profesor** (acceso autorizado). El profesor lo acompaña
hasta la puerta, la abre y le pide revisar **solo** el respaldo del sistema de entrenamiento.

Marca: `nivel_1_completado`.

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

Kai se va. El profesor se queda solo frente al monitor. **Sin diálogo:** en la pantalla aparece el archivo
**`GENESIS_ARCHIVE`**. El profesor se queda mirándolo. Corte a negro.

**FIN DEL CAPÍTULO 1.** Marcas: `nivel_2_completado`, `capitulo_1_completado`.

*Cuidado con la Biblia:* el profesor no explica nada ni dice qué es el archivo (reglas 3, 11 y 12). Kai no lo ve.

---

## Datos de esta etapa

| Archivo | Qué es |
|---|---|
| `data/characters/chip.tres`, `glitch.tres` | Personajes de los diálogos (sin retrato hasta que Ariel los dibuje) |
| `data/quests/una_clase_diferente.tres`, `travesuras_en_el_sistema.tres` | Las dos misiones con sus pasos y títulos (registradas en `QuestDB`; todavía no empiezan solas) |
| `data/dialogues/capitulo1/*.tres` | Los diálogos de cada escena |
| `data/challenges/cap1_*.tres` | Los dos desafíos del nivel 1, los tres checkpoints y el escudo de Chip |

«El cuarto viejo» (fin del prólogo) lleva a «Una clase diferente», y esta a «Travesuras en el sistema».
