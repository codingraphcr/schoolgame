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

## Pruebas automáticas

Scripts en `tests/` que se ejecutan sin abrir el editor:

```
godot --headless --path . --script res://tests/<prueba>.gd
```

Cada prueba imprime `OK`/`FAIL` por comprobación y termina con código 0 si todo pasó.
