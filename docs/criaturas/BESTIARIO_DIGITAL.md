# Bestiario digital

> **Calidad antes que cantidad.** Por bioma: una criatura común característica, una secundaria solo si aporta una
> mecánica distinta y un guardián o jefe solo si la historia lo justifica. Las criaturas tienen una función en su
> ecosistema: no existen solo para ser vencidas. Estados: ver `../mundo/MAPA_MAESTRO.md`.

## 1. Sistema (IMPLEMENTADO)

- **`DigitalCreature`** (`characters/creatures/digital_creature.gd`): base modular con estados **Reposo**,
  **Patrulla**, **Investigación**, **Huida**, **Defensa** e **Interacción** (guiar a Kai por unos puntos). No todas
  usan todos. Disposición: amistosa, neutral, territorial u hostil (las del MVP no hacen daño). Sin IA compleja ni
  mascotas permanentes.
- **Registro con la Visión Digital** (sin tener que vencerla), en tres etapas (`Bestiary`, `CreatureEntry`):
  1. **Avistamiento:** verla con la Visión activa.
  2. **Observación:** seguir mirándola unos segundos.
  3. **Comprensión:** entender su función (con una misión o interacción).
- **Grimorio · Bestiario:** nombre, bioma, apariencia, comportamiento, función, concepto informático y comentario de
  Kai; cada etapa muestra más. Solo aparecen las criaturas que existen en el juego (sin páginas vacías).
- **Persistencia:** marcas `bestiario_<id>_<etapa>` en la ranura.

## 2. Criaturas

| Criatura | Bioma | Función en el ecosistema | Concepto | Estado |
|---|---|---|---|---|
| **Fibroluz** | Bosque de Fibra | Transporta señales entre nodos; si un enlace se corta, espera junto al corte | Transmisión: camino completo origen → destino | **IMPLEMENTADO** |
| Recolector | Distrito Caché | Recupera datos olvidados | Caché, datos huérfanos | PROPUESTO |
| Termita | Núcleo Térmico | Absorbe calor residual | Rendimiento, gestión de recursos | PROPUESTO |
| Memoriana | Archivo Criogénico | Conserva o proyecta recuerdos | Almacenamiento, integridad | PROPUESTO |
| Depurador | Canales Corruptos | Limpia datos dañados | Detección y recuperación | PROPUESTO |
| Arconte (guardián) | Santuario Raíz | Guarda accesos antiguos | Autorización, privilegios | PROPUESTO |
| Desfase | El Velo Nulo | Se desplaza mediante anomalías | Integridad de reglas | PROPUESTO |

Los nombres son provisionales. Ya existen además, fuera del bestiario de biomas: **Chip y Glitch** (red de
entrenamiento), **Bucle** (simulador) y los enemigos de los sistemas del colegio.

### Fibroluz (IMPLEMENTADO)

- **Apariencia:** una gotita de luz cian con dos antenas de fibra; carga un paquete de luz amarilla (sin señal, se
  apaga un poco). Dibujo provisional por código.
- **Comportamiento:** patrulla entre nodos; si Kai se queda quieto cerca, se acerca con curiosidad (Investigación);
  con un ataque, un dash o una carrera, huye y vuelve después; en la misión guía a Kai hasta el corte
  (Interacción). No hace daño y no se le puede hacer daño.
- **Comentarios de Kai:** «Una lucecita con patas... ¿me está mirando?» → «No pelea: lleva algo de un lado a otro.
  Como un paquete de datos.» → «Sin un camino completo, la señal no llega. Por eso se quedaba esperando junto al
  corte.»

## 3. Jefes y conflictos (CONFIRMADO)

Clasificación: **Anomalías** (procesos o entidades que funcionan mal), **Guardianes** (protegen rutas, recursos o
secretos) y **Antagonistas** (objetivos y motivaciones propias). No todos los jefes son malvados y no todos los
incidentes son de Axiom: también errores, sistemas antiguos, decisiones humanas, procesos mal configurados,
conflictos entre criaturas y corrupción de datos. Cada jefe tiene motivación, relación con su región y con la
historia, mecánicas reconocibles, patrones legibles y consecuencias. No hace falta un jefe por bioma.

| Encuentro | Tipo | Estado |
|---|---|---|
| Chip y Glitch | Anomalía (traviesos, no malvados) | IMPLEMENTADO (Cap. 1) |
| Bucle | Anomalía (un proceso sin condición de salida; no es malvado) | IMPLEMENTADO (Cap. 2); versión «hardcore» con los siete impactos clave: pendiente |
| Arconte | Guardián | PROPUESTO |
| Axiom | Antagonista | FUTURO |
