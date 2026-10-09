# Plan del MVP — Nullveil: Beyond the Firewall

Resumen del análisis del **Documento maestro de desarrollo** (octubre 2026) y de las decisiones del equipo.
Detalle técnico de cada sistema en `arquitectura.md`; combate e historia en `combate.md`.

## Visión

Metroidvania-lite 2D educativo (Godot 4, Windows y Android). Kai, un estudiante común de un colegio técnico,
descubre la **Visión Digital** y ve las amenazas informáticas como criaturas. Para avanzar tiene que *aplicar*
ciberseguridad: terminales con comandos reales, decisiones y combate. Estructura completa: 3 grados × 4 capítulos ×
2 niveles = **24 niveles**, más prólogo y contenido opcional. Meta inmediata: **muestra vertical jugable en 4 semanas**.

## Decisiones del equipo

| Tema | Decisión |
|---|---|
| Prólogo | Se mantiene el nuestro: Visión involuntaria → PC del profesor (SPAM, terminal, «Contraseña débil» con mini espada, 2 elecciones) → cuarto viejo con Nullblade.exe. La «Contraseña débil» dirá «Tú no deberías poder vernos». **«EL DESPERTAR»** pasa al final (al obtener Nullblade) |
| Primera tarea | La **terminal simulada** (antes que el combate) ✅ |
| Primera terminal | En la PC del profesor: encontrar la configuración de la cuenta (un solo objetivo) ✅ |
| Aegis | Se obtiene en el **capítulo 2, nivel 3** (fundamentos de programación). Historia por definir (idea: un proyecto viejo llamado AEGIS que Kai completa programando) |
| Puntos de control | **Computadora segura**: con E guarda la partida, marca dónde reaparecer y llena las máscaras. Reemplazará al punto de restauración actual cuando exista el guardado |
| Terminal | Estilo **Linux** (bash) |
| La entidad «???» | Primera manifestación de **El Núcleo**, sin revelarlo |

## Pendiente de decidir

- Fecha de entrega del MVP (para fijar el cronograma).
- Qué es la «protección defensiva manual» de Aegis Pulse (el escudo se reemplazó por el dash-parry) y con qué tecla.
- Botón de **correr** (hoy Kai tiene una sola velocidad).
- Estudiantes con diálogo en el pasillo (más arte para Ariel).
- Cómo encaja el sistema de decisiones de Ariel (incidentes, presupuesto, confianza): propuesta, como formato de los
  desafíos educativos de fin de nivel y de los jefes.
- Antes de Steam: cambiar los nombres parodia (MineKraft, Robucks…) por nombres 100 % inventados.

## Currículo (MEP)

Referencia: *Tabla de especificaciones para la Prueba Nacional Escrita Estandarizada Comprensiva de Especialidades
Técnicas 2025 — Ciberseguridad* (código 5210). No se inventan contenidos oficiales: cada nivel cita los indicadores
de logro que trabaja. Faltan los **programas de estudio completos** (décimo, undécimo y duodécimo, 2020).

**Revisar:** en la tabla, los fundamentos de redes (modelos OSI y TCP/IP, IPv4/IPv6, Ethernet, direcciones MAC)
parecen ser de **décimo**, pero el documento maestro los ubica en undécimo (capítulos 6 y 7). Confirmarlo con el
programa antes de diseñar esos capítulos (el PDF pierde las columnas al leerlo).

## Arquitectura

Se conserva lo que existe y se agrega solo lo necesario:

| Documento maestro | En el proyecto | Estado |
|---|---|---|
| PlayerController, HealthComponent | `Player`, `HealthComponent`, `PlayerDamage` | ✅ |
| DigitalVisionManager | autoload `DigitalVision` | ✅ |
| DialogueManager, QuestManager | `DialogueBox` + `Dialogue`; misiones en `GameState` + `QuestDB` | ✅ |
| TerminalManager, CommandInterpreter | `TerminalStation`, `TerminalWindow`, `CommandInterpreter`, `VirtualFileSystem`, `TerminalChallenge` | ✅ |
| PlayerCombat, NullbladeController/Data | `PlayerCombat` + recurso `NullbladeStage` (las 4 etapas son datos) | MVP |
| Enemigos | `EnemyBase` (vida, golpe, debilidad, ficha del Grimorio) | MVP |
| SaveManager | autoload `SaveManager`: `GameState.to_dict()` → `user://partida.json` con versión | MVP |
| GrimoireManager, WorldMapManager | Grimorio de Ariel (`ui/menus/grimorio/`, entradas `GrimorioEntry` en `data/grimorio/`, mapa de salas visitadas). Las páginas de comandos se desbloquean al usarlos en la terminal | ✅ base · falta abrirlo con Tab dentro del juego y el minimapa |
| Controles táctiles | `TouchControls` | MVP |
| EnergyComponent, Aegis, Dominio Nulo, Salto de Nexo | — | Después |

**Identificadores estables** para todo lo que se guarda: `g10_c01_n01` (niveles), `zona0_pasillo` (salas),
`pc_profesor_cuenta` (terminales), comandos por su nombre, `nodo_colegio` (nodos).

### Niveles reutilizables

`GradeData → ChapterData → LevelData`. Un **nivel** = 1 misión + 2 a 5 salas + al menos 1 desafío educativo.
`LevelData` guarda: objetivo de aprendizaje, concepto central, indicadores del MEP, desafíos (terminal, decisión, jefe),
aplicación, retroalimentación, recompensa, salas y requisitos. El progreso queda en `GameState.levels[id]`.

### Grimorio y mapa

Tab abre el libro: Mapa · Misiones · Comandos · Glosario · Amenazas · Historia. Muestra pistas, no soluciones.
Cada sala tiene un `RoomData` (zona, rectángulo en la cuadrícula, salidas); el mapa dibuja solo lo visitado.
El mismo dibujador sirve para el mapa general (zonas), el de zona (salas) y el minimapa.

### Futuro: Nullblade, Aegis, Dominio Nulo y nodos

- **Nullblade**: un `PlayerCombat` que lee la etapa actual (`GameState.nullblade_stage`); evolucionar = cambiar de recurso.
- **Aegis**: hijo del jugador que lo sigue con suavizado. K dispara al enemigo válido más cercano (teledirigido, no
  dispara sin objetivos). Bridge solo en puntos de apoyo (F). Sync con coste de energía.
- **Dominio Nulo**: la ralentización (80 %) afecta solo a los enemigos (multiplicador propio, no `Engine.time_scale`);
  el bonus de daño se aplica una vez al crear cada golpe.
- **Salto de Nexo**: nodos `DESCONOCIDO → DESCUBIERTO` (al verlo) `→ ACTIVADO` (con E). Solo se viaja entre nodos
  activados, con la habilidad, fuera de combate o persecución y sin bloqueos de historia.

## Alcance del MVP

**Entra:** prólogo completo (H4c, H4d, H5), 1 enemigo común, terminal simulada con su primer desafío ✅, Grimorio
básico (✅ base de Ariel; falta Tab en el juego, misiones y minimapa), guardado y carga, computadora segura,
controles táctiles, exportación Windows y Android, documentación.

**No entra:** Aegis, Dominio Nulo, Salto de Nexo, Nullblade después de .exe, jefes, los 24 niveles, Steam.

## Cronograma (se ajusta con la fecha de entrega)

| Bloque | Tareas |
|---|---|
| 1 · Terminal y prólogo | ✅ Terminal simulada · H4c combate y `EnemyBase` · H4d elecciones · H5 Nullblade.exe y «EL DESPERTAR» |
| 2 · Guardado | `SaveManager`, computadora segura, `LevelData` |
| 3 · Grimorio y mapa | ✅ Grimorio base (Ariel) · Tab dentro del juego, pestaña de misiones, minimapa |
| 4 · Entrega | Controles táctiles, exportaciones, sonido, pulido, pruebas en celular, documentación |
