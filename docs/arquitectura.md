# Arquitectura técnica

Documento vivo: se actualiza cada vez que se agrega o cambia un sistema.

## Principios

- **Carpetas por funcionalidad:** cada escena vive junto a su script (`player.tscn` + `player.gd`).
- **Composición:** comportamientos reutilizables como nodos-componente (salud, hitbox, visibilidad digital…).
- **Señales** para comunicar sistemas sin acoplarlos.
- **Datos separados del código** (`data/`), para que el contenido educativo se edite sin programar.
- Sin plugins ni dependencias externas. Versión del motor: **Godot 4.7.2** para todo el equipo.

## Estructura de carpetas

```
res://
├── autoload/      # Singletons globales (SceneManager…)
├── characters/    # Jugador, NPC y enemigos
├── components/    # Componentes reutilizables (hitbox, hurtbox, salud…)
├── world/         # Salas, tilesets, cámara y objetos del mundo
├── systems/       # Diálogos, misiones, Visión Digital, defensas
├── minigames/     # Retos educativos
├── ui/            # Menús, HUD, tema visual y componentes de interfaz
├── data/          # Contenido: diálogos, misiones, glosario, traducciones
├── assets/        # Arte, audio, fuentes y shaders
├── tests/         # Pruebas automáticas (scripts de línea de comandos)
└── docs/          # Documentación (Godot la ignora por el archivo .gdignore)
```

Las carpetas se crean cuando se necesitan, no antes.

## Autoloads

| Nombre | Archivo | Responsabilidad |
|---|---|---|
| `SceneManager` | `autoload/scene_manager.gd` | Cambiar de pantalla con fundido. Contiene las rutas de las pantallas principales. |
| `GameState` | `autoload/game_state.gd` | Presupuesto, seguridad y confianza; estado de incidentes, pistas, marcas y decisiones. **Progreso del jugador** (créditos, habilidades, evoluciones). Preparado para guardar partida (`to_dict` / `from_dict`). |

## Resolución y pixel art

- Resolución base **1280×720** horizontal, estiramiento `canvas_items` + aspecto `expand`.
- La interfaz se dibuja a 1280×720 (nítida). El mundo usa **cámara con zoom ×2**: se ven 640×360 píxeles de arte.
- **Tiles de 16 px.** El jugador mide ~12×22 px.
- El nodo raíz de cada sala usa filtro de textura **Nearest** (pixel art nítido); la interfaz conserva el filtro lineal.

## Capas de colisión (2D)

| # | Nombre | Uso |
|---|---|---|
| 1 | mundo | Suelo, paredes, plataformas |
| 2 | jugador | Cuerpo del jugador |
| 3 | enemigos | Cuerpos de enemigos |
| 4 | ataques_jugador | Hitbox de los ataques del jugador |
| 5 | ataques_enemigos | Hitbox de enemigos y proyectiles |
| 6 | interactuables | NPC, terminales, objetos |
| 7 | mundo_digital | Geometría que solo existe con la Visión Digital |

## Controles

| Acción | Teclado | Mando |
|---|---|---|
| `move_left` / `move_right` | A / D, ← / → | Stick izquierdo, cruceta |
| `move_up` / `move_down` | W / S, ↑ / ↓ | Stick izquierdo, cruceta |
| `jump` | Espacio | A |
| `attack` (Nullblade) | J | X |
| `aegis_fire` | K | Y |
| `dash` | Shift | RB |
| `vision` (Visión Digital) | Q | LB |
| `interact` | E | B |
| `ultimate` (Dominio Nulo) | R | RT |
| `heal` (mantener) | L | LT |
| `aegis_platform` | F | Clic del stick derecho |
| `pause` | Esc | Start |

Las teclas usan **código físico**: funcionan igual en teclados en español o inglés.
Los controles táctiles se agregarán en la tarea C12.

## Jugador (`characters/player/`)

`CharacterBody2D` con el origen a la altura de los pies.
Estados: `IDLE`, `RUN`, `JUMP`, `FALL`, `DASH`, `WALL_SLIDE` (señal `state_changed`, útil para animaciones).
Señales: `jumped`, `double_jumped`, `wall_jumped`, `dashed`, `landed`.

**Habilidades** (en el Inspector, grupo "Habilidades"):

| Habilidad | Por defecto | Notas |
|---|---|---|
| `dash_level` | 0 | 0 sin dash · 1 Dash · 2 Dash Fantasma (invulnerable) · 3 Esquiva Perfecta. Nivel 2 en la sala de pruebas |
| `can_double_jump` | desactivada | Se desbloquea con la historia. Activada en la sala de pruebas |
| `can_wall_jump` | desactivada | Deslizar por paredes y saltar desde ellas. Activada en la sala de pruebas |

**Valores principales:**

| Parámetro | Valor | Efecto |
|---|---|---|
| `max_speed` | 140 px/s | Velocidad máxima horizontal |
| `jump_height` | 72 px (4,5 tiles) | Altura máxima del salto: alcanza plataformas de 4 tiles |
| `time_to_apex` | 0,4 s | Tiempo hasta el punto más alto (define la gravedad) |
| `fall_gravity_multiplier` | 2,0 | Caída más rápida y firme que la subida |
| `max_fall_speed` | 500 px/s | Velocidad máxima de caída |
| `jump_cut_multiplier` | 0,45 | Salto corto al soltar el botón |
| `coyote_time` / `jump_buffer_time` | 0,1 s / 0,12 s | Márgenes de tolerancia para saltar |
| `double_jump_height` | 56 px | Altura del doble salto (con salto + doble se alcanzan 7 tiles) |
| `wall_slide_speed` | 60 px/s | Caída máxima al deslizarse por una pared |
| `wall_jump_height` / `wall_jump_push` | 56 px / 160 px/s | Salto de pared: altura e impulso horizontal |
| `dash_speed` / `dash_duration` | 340 px/s / 0,15 s | Dash de ~51 px (3 tiles) |
| `dash_cooldown` | 0,35 s | Tiempo entre dashes |

**Prioridad al pulsar salto:** salto desde el suelo (con coyote time) → salto de pared → doble salto.
Si ninguno es posible, la pulsación se guarda (jump buffer) para el aterrizaje.

`is_invulnerable()` combina la invulnerabilidad tras un golpe/reaparición y el dash desde el nivel 2.
`controls_locked` bloquea los controles (reaparición). `apply_knockback()` aplica el empuje de un golpe.
El dibujo (`Visual/Body`) se deforma al saltar/aterrizar y el dash deja una estela de siluetas.

**Apariencia de Kai (huesos pixelados, `characters/player/kai/`):** `KaiVisual` es el dibujo final del jugador.
Instancia `kai_esqueleto.tscn` (`Skeleton2D` + `Bone2D` con una pieza de `assets/art/characters/kai/kai_piezas.png`
por hueso y un `AnimationPlayer`), lo dibuja con `PixelatedRig` (`components/visual/`) a resolución de pixel art,
elige la animación según `Player.state` y mueve el mechón y la mochila por código. Para usarlo en el jugador basta con
agregarlo como hijo de `Visual/Body` (asignándole `player`) y ocultar los polígonos provisionales; hoy lo usa la muestra E.
Las medidas de las piezas están en `kai_piezas.gd`; `generar_esqueleto_kai.gd` regenera la escena (borra retoques manuales).

## Combate (`components/combat/`)

| Componente | Nodo | Responsabilidad |
|---|---|---|
| `HitData` | RefCounted | Datos de un golpe: daño, tipo de amenaza, empuje, origen, si es peligro |
| `HitboxComponent` | Area2D | Causa daño. `once_per_activation` para que un tajo golpee una vez. Capa 4 (jugador) o 5 (enemigos/peligros) |
| `HurtboxComponent` | Area2D | Recibe daño revisando superposiciones cada cuadro (el contacto prolongado vuelve a dañar). `immune` = escudo educativo |
| `HealthComponent` | Node | Vida: máscaras del jugador o puntos de vida de enemigos. Señales `health_changed`, `damaged`, `died` |

**Jugador:** `characters/player/player_damage.gd` (`PlayerDamage`, nodo `Damage`) aplica las reglas de Hollow Knight:
quita máscaras, congela la acción (`HitStop`), empuja, da 1 s de invulnerabilidad con parpadeo, devuelve al último
suelo seguro ante peligros y emite `died` al perder todas las máscaras. La sala (`Room`) decide dónde reaparece.

**Peligros:** `world/hazards/spikes.gd` (`Spikes`): pinchos con ancho configurable, visibles en el editor.

**HUD:** `ui/hud/combat_hud.tscn` muestra las máscaras (`MaskIcon`) y los créditos (`CreditsDisplay`, con +X / −X al cambiar).

**Autoloads en scripts compartidos:** `Room` y `PlayerDamage` obtienen `SceneManager` por ruta (`/root/SceneManager`)
para que compilen también en las pruebas de línea de comandos.

## Salas (`world/`)

- `world/rooms/room.gd` (`Room`): calcula los límites de la cámara a partir del `TileMapLayer` y coloca al jugador en el `SpawnPoint`.
  Caer fuera cuenta como peligro; al morir se reaparece en `checkpoint` (o `SpawnPoint`). Sacude la cámara al recibir daño.
- `world/camera/` (`GameCamera`): zoom ×2, suavizado, mirada hacia adelante, adelanto hacia abajo en caídas rápidas y margen vertical.
- `world/effects/ring_burst.gd` (`RingBurst`): anillo que se expande; efecto reutilizable (doble salto, impactos).
- `world/tilesets/graybox_tileset.tres`: tiles de prueba (bloque sólido y plataforma de un sentido).
- `world/test/combat_test_room.tscn`: sala de pruebas del prototipo (alturas, huecos, plataformas, techo bajo, caída, hueco con dash, chimenea para salto de pared y pilar de doble salto). Se edita normalmente en el editor.
- `ui/debug/` : panel de depuración (F3) con estado, velocidad y temporizadores del jugador.

## Progreso del jugador (`GameState`)

Todo lo que el jugador ha adquirido vive en `GameState` y se guarda con `to_dict()` (clave `"player"`).
El jugador **solo puede usar lo adquirido**: cada `Room` aplica el progreso al jugador al cargar
(`Player.apply_progress()`) y de nuevo cuando cambia (señal `progress_changed`).

| Campo | Inicial | Rango / significado |
|---|---|---|
| `credits` | 0 | Créditos del jugador para mejoras (separados del `budget` del colegio). Al morir se pierde el 10 % |
| `max_masks` | 4 | Máscaras máximas |
| `dash_level` | 0 | 0–3 (sin dash, Dash, Dash Fantasma, Esquiva Perfecta) |
| `can_double_jump` / `can_wall_jump` | no | Se desbloquean con la historia |
| `vision_unlocked` | no | Visión Digital |
| `nullblade_stage` | 0 | 0 no obtenida · 1 .exe · 2 .zero · 3 .void · 4 .max |
| `aegis_stage` | 0 | 0 no obtenido · 1 Pulse · 2 Bridge · 3 Sync |
| `domain_stage` | 0 | 0 bloqueado · 1–3 Dominio Nulo I–III |

Se modifica solo con funciones que limitan los valores y emiten señales: `add_credits()`, `spend_credits()`
(devuelve `false` si no alcanza), `apply_death_penalty()`, `set_dash_level()`, `set_nullblade_stage()`,
`set_aegis_stage()`, `set_domain_stage()`, `set_max_masks()`, `unlock_double_jump()`, `unlock_wall_jump()`, `unlock_vision()`.
Señales: `progress_changed` y `credits_changed(credits, delta)`. Nombres para la interfaz: `DASH_NAMES`, `NULLBLADE_NAMES`, `AEGIS_NAMES`, `DOMAIN_NAMES`.

**Sesión de desarrollo:** `begin_dev_session()` guarda la partida real y desbloquea todo (500 créditos, Dash Fantasma,
doble salto, pared, visión, Nullblade.exe, Aegis Pulse, Dominio Nulo I); `end_dev_session()` restaura la partida.
La sala de pruebas la abre al entrar y la cierra al salir. Teclas en la sala: **1** dash · **2** Nullblade · **3** Aegis ·
**4** Dominio · **5** doble salto · **6** pared · **7** +100 créditos · **8** llenar máscaras · **9** máscaras máximas.

## Incidentes y decisiones (`systems/incidents/`)

Sistema de recursos de la institución. Cada incidente enseña un concepto real de ciberseguridad:
el jugador investiga, encuentra pistas y decide qué medida aplicar con un presupuesto limitado.

| Indicador | Inicial | Significado |
|---|---|---|
| `budget` | 10 000 | Dinero disponible para implementar medidas |
| `security` | 35 / 100 | Nivel general de protección de la institución |
| `trust` | 60 / 100 | Percepción de estudiantes, docentes y administrativos |

**Recursos de datos** (se editan en el Inspector, sin programar):

| Clase | Contenido |
|---|---|
| `Incident` | Título, `threat_type` (mismos tipos que `docs/combate.md`), pistas, pistas necesarias y medidas posibles |
| `Clue` | Evidencia que se descubre al investigar |
| `SecurityControl` | Costo, efecto en seguridad y confianza, `outcome` (eliminada / contenida / reducida / empeorada), consecuencia, reacción, lección y marcas para consecuencias futuras |

**Flujo** (estados de `Incident.State`):

```
INACTIVE ──start_incident()──▶ INVESTIGATING ──find_clue() × clues_to_decide──▶ READY ──apply_control()──▶ RESOLVED
```

- `GameState.check_control()` devuelve por qué no se puede aplicar una medida ("" si se puede): útil para deshabilitar botones.
- Señales: `stats_changed`, `incident_state_changed`, `clue_found`, `control_applied`. La interfaz y el mundo reaccionan a ellas sin conocerse.
- Las marcas (`has_flag()`) permiten consecuencias posteriores: p. ej. `phishing_dominio_rotado` si solo se bloqueó el dominio.
- Incidente de ejemplo: `data/incidents/phishing_laboratorio.tres` (3 pistas, 5 medidas). Ninguna medida elimina por sí sola el phishing, a propósito: así se enseña la defensa en capas.

## Pruebas automáticas

Scripts en `tests/` que se ejecutan sin abrir el editor:

```
godot --headless --path . --script res://tests/<prueba>.gd
```

Cada prueba imprime `OK`/`FAIL` por comprobación y termina con código 0 si todo pasó.

| Prueba | Comprueba |
|---|---|
| `test_menu_navigation.gd` | Menú → Configuración → Menú → Jugar |
| `test_player_movement.gd` | Correr y frenar, salto completo y corto, coyote time, jump buffer, hueco de 6, plataforma de un sentido, reaparición y límites de cámara |
| `test_player_abilities.gd` | Dash (suelo, aire, reutilización, invulnerabilidad), doble salto, deslizamiento y salto de pared, bloqueo de habilidades no desbloqueadas |
| `test_player_health.gd` | Máscaras, pinchos, suelo seguro, invulnerabilidad, empuje, contacto prolongado, escudo educativo, caída, muerte y niveles del dash |
| `test_progress.gd` | Progreso inicial, créditos, penalización al morir, límites, guardar/cargar (también partidas antiguas), sesión de desarrollo y restauración |
| `test_decision_system.gd` | Datos del incidente de phishing, flujo de investigación, cobro y efectos de las medidas, rechazos (sin evidencia, sin presupuesto, ya resuelto) y guardar/cargar |
