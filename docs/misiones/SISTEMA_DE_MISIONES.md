# Sistema de misiones

> Cómo funcionan las misiones en el juego. Propuestas de misiones secundarias: `MISIONES_SECUNDARIAS.md`.
> Estados: ver `../mundo/MAPA_MAESTRO.md`.

## 1. Lo que ya existía (IMPLEMENTADO)

- **`Quest`** (`systems/quests/quest.gd`, datos en `data/quests/`, registro en `QuestDB`): id, título, pasos
  (`QuestStep`: id, objetivo, sala del mapa a la que hay que ir), marca al empezar, marca(s) al terminar, carteles de
  fin («NIVEL 1 COMPLETADO», «FIN DEL CAPÍTULO 1»), misión siguiente y recompensa única de Ecos.
- **`GameState`** guarda el paso de cada misión (por ranura) y avisa (`quest_started`, `quest_step_changed`,
  `quest_completed`); el autoguardado guarda al cambiar de paso cuando es seguro.
- **Cómo avanzan los pasos:** `QuestTrigger` (entrar a una zona o al cargar la sala, con diálogo), `Npc` +
  `NpcConversation` (hablar con alguien en un paso), desafíos (`ChoiceWindow`, terminales), jefes y escenas.
- **HUD y Grimorio:** el objetivo actual arriba a la derecha; en el mapa, la sala del objetivo con una marca dorada.

## 2. Categorías de actividades (IMPLEMENTADO desde esta entrega)

`Quest.category`:

| Categoría | Qué es | Ejemplo |
|---|---|---|
| **Principal** | La historia (capítulos, niveles, interludios) | «Una clase diferente», «Camino a casa» |
| **Secundaria** | Historia opcional con personajes, diálogos y consecuencias | «Sin señal en el barrio», «Un recreo diferente», «El proyecto perdido» |
| **Tarea** | Encargo breve | «El robot que no obedece» (PROPUESTA) |
| **Descubrimiento** | Lugar secreto, documento o ruta oculta | «Una fotografía antigua» (biblioteca, IMPLEMENTADO); «Las señales del pasado» (PROPUESTA) |

**Colecciones** (Fragmentos de Datos y recuerdos) no son misiones: viven en el cuarto de Kai (`Keepsake`) y en el
bestiario.

**Reglas (IMPLEMENTADO):**

- Una misión secundaria, tarea o descubrimiento **no reemplaza el objetivo principal**: el HUD sigue mostrando la
  historia y, debajo, la actividad secundaria en curso. Si no hay misión principal activa, la secundaria pasa arriba.
- Ninguna secundaria es obligatoria para terminar la historia.
- Un descubrimiento no se anuncia como objetivo: se registra al encontrarlo, aparece el aviso «Nuevo
  descubrimiento: …» y queda su página en el Grimorio (Registros).
- Las recompensas únicas no se cobran dos veces (`Economy.claim_reward`).
- Empiezan con `QuestStarter` (zona + `WorldRequirement`) o desde una conversación.
- El Grimorio las lista en la pestaña **MISIONES** (junto con la historia), con su categoría, si están en curso o completadas, su paso y su recompensa.

## 3. Consecuencias (CONFIRMADO)

Las misiones cambian algo visible cuando es posible: un comerciante recupera su tienda, una región se ilumina, un
NPC reconoce a Kai, se restaura un puente, aparece un objeto en el cuarto, una conversación nueva. Pequeñas pero
significativas. Se implementan con las marcas de la partida (la escena las lee al cargarse).

**Ejemplo implementado — «Sin señal en el barrio»:** el Bosque de Fibra vuelve a brillar, la caja del poste queda en
verde con la señal corriendo hacia las casas, el vecino agradece, se abre el acceso al bosque desde el rack del
colegio, Fibroluz pasa a «Comprensión» en el bestiario y aparece un recuerdo en el cuarto de Kai.

## 4. Matriz de cada capítulo

Cada capítulo principal documenta: año, contenido educativo, fuente curricular, región, problema narrativo,
personajes, mecánica principal, jefe o conflicto, recompensa, ruta nueva y secundarias relacionadas
(`../progresion/MATRIZ_MEP_Y_CAPITULOS.md`).

## 5. Regla educativa (CONFIRMADO)

**Kai aprende un concepto → lo encuentra representado en el mundo → comprende sus consecuencias → usa lo
aprendido para resolver un problema.** Alternar exploración, investigación, plataformas, diálogos, puzles, combate,
decisiones y simulaciones; no todo son preguntas. Los desafíos técnicos ocurren en sistemas ficticios y
controlados.
