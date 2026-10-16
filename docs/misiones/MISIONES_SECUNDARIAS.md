# Misiones secundarias, tareas y descubrimientos

> Propuestas originales del equipo para desarrollo progresivo. Inspiración solo en principios generales (historias
> de NPC, conflictos locales, investigación, consecuencias visibles, recompensas significativas): no se copian
> misiones, personajes ni diálogos de otros juegos. No todas son educativas; cuando tiene sentido, se relacionan
> con el MEP. Estados: ver `../mundo/MAPA_MAESTRO.md`.

## Implementadas

### El bosque que dejó de brillar — Secundaria · Capítulo 3 · IMPLEMENTADO

- **Fusiona** la versión breve del MVP («Sin señal en el barrio», decisión del equipo del 16 de octubre de 2026).
- **Cuándo y dónde:** empieza en el Bosque de Fibra, en las raíces, después de que Kai cae por la conexión del equipo 7
  (Nivel 5). Se puede dejar para después: sigue disponible hasta terminarla.
- **Historia:** el bosque está apagado. Un Fibroluz (el que se rió de la caída de Kai) no puede llevar su señal; Kai
  lo sigue hasta el claro, donde los empalmes apuntan para cualquier lado, y los gira hasta que la señal tiene un camino
  completo. El bosque vuelve a brillar, **vuelve la señal del barrio** (el vecino agradece) y la **caja de fibra del
  poste queda como atajo** al bosque. Si Kai la hace después de rescatar a Aegis, Aegis comenta (una vez).
- **Pasos:** ayudar al Fibroluz → reconectar los empalmes.
- **Concepto:** conectividad y transmisión: la información solo llega si hay un camino continuo del origen al
  destino; un solo enlace roto corta la comunicación (capa física; décimo, redes).
- **Recompensas:** 40 Ecos (una vez), Fibroluz en «Comprensión», el recuerdo «Nota del vecino» en el cuarto de Kai,
  el atajo de la caja de fibra, el bosque iluminado para siempre.
- **Archivos:** `data/quests/senal_del_barrio.tres` (el id se conserva por las partidas guardadas),
  `data/dialogues/mundo/`, `world/zones/bosque_fibra/`, `tests/test_mundo.gd`.

### El robot que no obedece — Tarea · Capítulo 2 · IMPLEMENTADO

- **Dónde:** el taller de robótica (anexo del laboratorio), desde el Capítulo 2. La Compañera de la actividad de
  robótica tiene un robot que ejecuta las instrucciones en orden incorrecto.
- **Qué hace Kai:** ordena la secuencia en la estación del fondo del taller (`RoboticsChallenge`, tipo SECUENCIA,
  simulado) y vuelve a contarle.
- **Concepto:** secuencias y control de flujo (el orden de las instrucciones importa).
- **Por qué existe:** el Capítulo 3 pide terminar las secundarias y tareas de los capítulos 1 y 2; el Capítulo 2 no
  tenía ninguna.
- **Archivos:** `data/quests/robot_desobediente.tres`, `data/robotics/robot_companera.tres`,
  `data/dialogues/colegio/robot_*.tres`, `systems/robotics/sequence_sim.gd`.

## «Una fotografía antigua» (Descubrimiento, Capítulo 1) — IMPLEMENTADO

- **Dónde:** la biblioteca del colegio, en la pared entre diplomas (`world/school/old_photo.gd`).
- **Qué es:** la foto de la inauguración del Laboratorio 2 (el cuarto viejo del prólogo). En la orilla, el profesor
  Alvarado joven; la etiqueta dice «Programa de Sistemas Inteligentes» y el nombre del convenio está arrancado.
  **Pista sutil:** no explica el pasado del profesor, no nombra el Proyecto Génesis ni dice nada del origen de Kai.
- **Registro:** al mirarla por primera vez se completa el descubrimiento `foto_antigua`, queda la marca
  `foto_antigua_vista` y se abre la página «Una fotografía antigua» en el Grimorio (Registros). Sin Ecos.
- **Archivos:** `data/quests/foto_antigua.tres`, `data/grimorio/registro_foto_antigua.tres`, la escena de la
  biblioteca y `tests/test_foto_antigua.gd`.

## «Un recreo diferente» (Secundaria, Capítulo 1) — IMPLEMENTADO

- **Cuándo y dónde:** mientras el profesor prepara el acceso al cuarto técnico, el Compañero (uno de los tres amigos
  sin nombre) espera a Kai en la soda. Opcional; si Kai no va, no pasa nada.
- **Qué pasa:** charla breve (la mitad de una empanada, lo de la Sala 3) y **una elección pequeña** (`DialogueChoice`,
  sin respuestas correctas): contarle la verdad, decir que fue un virus o cambiar de tema a la actividad de robótica.
  Cada opción muestra otra cara del amigo; todas terminan con una observación sobre la vida en el colegio técnico.
- **Sin consecuencias irreversibles:** queda la marca `recreo_eleccion_<n>` para que el amigo lo recuerde más
  adelante (p. ej. en la actividad de robótica). Sin Ecos.
- **Archivos:** `world/school/recess_chat.gd`, `ui/components/dialogue_choice.gd`, `data/quests/un_recreo_diferente.tres`,
  `data/dialogues/colegio/recreo_*.tres`, `tests/test_recreo.gd`.

## «El proyecto perdido» (Secundaria, Capítulo 1) — IMPLEMENTADO

- **Cuándo y dónde:** desde que el profesor prepara el acceso, en el taller (el anexo del laboratorio, detrás de la
  puerta de vidrio). Empieza al entrar; el HUD la
  muestra como ACTIVIDAD debajo de la historia.
- **Quién:** una estudiante (NPC nuevo 2 de 2, sin nombre) perdió su proyecto de la feria: un robot seguidor de línea.
- **Qué hace Kai:** usa la computadora «Equipo 4», una terminal **simulada** (solo `help`, `pwd`, `ls`, `cd`, `cat`;
  ningún comando real del sistema). El archivo no se borró: Chip y Glitch lo movieron. `proyectos/notas.txt` dice
  cómo se llama, `temporal/registro_de_cambios.txt` dice a dónde fue y está en `respaldo/viejos/seguidor.py` (con un
  «si / si no» que adelanta el Capítulo 2).
- **Recompensas:** Ecos de terminal (una vez), la misión completada y lo que dice la estudiante después (hace dos
  copias en lugares distintos: respaldos).
- **Conceptos:** navegación de carpetas, rutas, leer antes de actuar, registros de cambios, copias de respaldo.
- **Archivos:** `data/terminals/proyecto_perdido.tres`, `data/quests/proyecto_perdido.tres`,
  `data/dialogues/colegio/proyecto_*.tres`, la escena del taller (`ProyectoPerdido`), `tests/test_proyecto_perdido.gd`.

## Candidatas (FUTURO, no son compromisos de implementación)

| Nombre | Tipo | Ubicación | Historia | Conceptos | Recompensas |
|---|---|---|---|---|---|
| El último mensaje | Secundaria | Barrio de los Almendros | Un vecino intenta recuperar un mensaje antiguo de un dispositivo; Kai investiga y ayuda a restaurar una copia válida | Respaldos e integridad de datos | Ecos, una fotografía (recuerdo), diálogo opcional |
| El comerciante sin identidad | Secundaria | Distrito Caché | Un comerciante pierde el acceso legítimo a su almacén; Kai investiga los permisos y ayuda a restaurarlo | Autenticación y control de acceso | Productos nuevos y un atajo digital |
| Las señales del pasado | Descubrimiento | Altos de Cartago | Registros de una instalación antigua de comunicaciones | Lore (sin revelar el Proyecto Génesis) | Lore, Fragmento de Datos, pista |
| Una memoria que no quiere desaparecer | Secundaria | Archivo Criogénico | Una criatura conserva un recuerdo incompleto; Kai ayuda a reconstruirlo | Integridad y recuperación | Recuerdo y fragmento narrativo |
| El pequeño depurador | Secundaria | Canales Corruptos | Una criatura intenta limpiar una zona contaminada; Kai restaura la contención | Detección, contención, recuperación | Sector restaurado y diálogo futuro |
| El guardián sin órdenes | Secundaria | Santuario Raíz | Un guardián protege una puerta con instrucciones antiguas; Kai comprende el conflicto y busca una solución | Autorización y reglas de acceso | Ruta nueva e información narrativa |

**Nota:** «El bosque que dejó de brillar» y «El robot que no obedece» pasaron de candidatas a implementadas (arriba).

## Reglas para las nuevas

- Pocas, memorables, con consecuencias visibles; no llenar el mapa de marcadores.
- Nunca obligatorias para la historia principal.
- No crear personajes nuevos sin aprobación (los amigos siguen sin nombre por ahora).
- Las que entregan un recuerdo usan `Keepsake` (cuarto de Kai): se registra, se guarda, se ve en la estantería, se
  inspecciona y su texto puede cambiar con los años.
