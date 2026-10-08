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
| `attack` | J | X |
| `dash` | K, Shift | RB |
| `ability` | L, Q | Y |
| `vision` | F | LB |
| `interact` | E | B |
| `pause` | Esc | Start |

Las teclas usan **código físico**: funcionan igual en teclados en español o inglés.
Los controles táctiles se agregarán en la tarea T10.

## Jugador (`characters/player/`)

`CharacterBody2D` con el origen a la altura de los pies. Estados: `IDLE`, `RUN`, `JUMP`, `FALL`
(señal `state_changed`, útil para animaciones). Señales `jumped` y `landed`.

| Parámetro | Valor inicial | Efecto |
|---|---|---|
| `max_speed` | 140 px/s | Velocidad máxima horizontal |
| `jump_height` | 72 px (4,5 tiles) | Altura máxima del salto: alcanza plataformas de 4 tiles |
| `time_to_apex` | 0,4 s | Tiempo hasta el punto más alto (define la gravedad) |
| `fall_gravity_multiplier` | 1,5 | Caída más rápida que la subida |
| `jump_cut_multiplier` | 0,45 | Salto corto al soltar el botón |
| `coyote_time` | 0,1 s | Margen para saltar después de salir de un borde |
| `jump_buffer_time` | 0,12 s | Margen para pulsar salto antes de aterrizar |

Todos se ajustan en el Inspector. El dibujo (`Visual/Body`) se deforma al saltar y aterrizar sin afectar a la colisión.

## Salas (`world/`)

- `world/rooms/room.gd` (`Room`): calcula los límites de la cámara a partir del `TileMapLayer`,
  coloca al jugador en el `SpawnPoint` y lo devuelve ahí si cae fuera de la sala.
- `world/camera/` (`GameCamera`): zoom ×2, suavizado, mirada hacia adelante y margen vertical.
- `world/tilesets/graybox_tileset.tres`: tiles de prueba (bloque sólido y plataforma de un sentido).
- `world/test/combat_test_room.tscn`: sala de pruebas del prototipo. Se edita normalmente en el editor.
- `ui/debug/` : panel de depuración (F3) con estado, velocidad y temporizadores del jugador.

## Pruebas automáticas

Scripts en `tests/` que se ejecutan sin abrir el editor:

```
godot --headless --path . --script res://tests/<prueba>.gd
```

Cada prueba imprime `OK`/`FAIL` por comprobación y termina con código 0 si todo pasó.

| Prueba | Comprueba |
|---|---|
| `test_menu_navigation.gd` | Menú → Configuración → Menú → Jugar |
| `test_player_movement.gd` | Correr y frenar, salto completo y corto, coyote time, jump buffer, plataforma de un sentido, reaparición y límites de cámara |
