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
├── assets/        # Arte (art/pixel: estilo oficial), audio, fuentes y shaders
├── tools/         # Herramientas de desarrollo (generador de sprites)
├── tests/         # Pruebas automáticas (scripts de línea de comandos) y su sala gris (fixtures/)
└── docs/          # Documentación (Godot la ignora por el archivo .gdignore)
```

Las carpetas se crean cuando se necesitan, no antes.

## Autoloads

| Nombre | Archivo | Responsabilidad |
|---|---|---|
| `SceneManager` | `autoload/scene_manager.gd` | Cambiar de pantalla con fundido. Contiene las rutas de las pantallas principales. |
| `DigitalVision` | `autoload/digital_vision.gd` | Estado de la Visión Digital (lista, activa, recargando), duración, recarga y `blend` para los efectos. Ver "Visión Digital". |
| `GameState` | `autoload/game_state.gd` | Presupuesto, seguridad y confianza; estado de incidentes, pistas, marcas y decisiones. **Progreso del jugador** (créditos, habilidades, evoluciones). Preparado para guardar partida (`to_dict` / `from_dict`). |

## Estilo visual oficial: muestra E de Ariel (huesos pixelados + Visión Digital)

Detalle completo en [`docs/arte/guia_de_arte.md`](arte/guia_de_arte.md).

- **Escenarios** en pixel art (640×360, tiles de 16 px).
- **Personajes** animados por huesos (`Skeleton2D`) pero dibujados a resolución de pixel art (`PixelatedRig`):
  se dibujan una vez por piezas y las animaciones no requieren más dibujos.
- **Mundo digital** (Visión Digital) en vectorial, dibujado con `VectorCanvas` (`world/effects/vector_canvas.gd`).
  En la muestra dura 10 s y se recarga en 16 s.
- `assets/art/pixel/`: sprites, tiles y paleta (`paleta.png`). Los genera `tools/art/generar_sprites.gd`
  con `PixelPainter` (`tools/art/pixel_painter.gd`). **Ojo:** volver a ejecutar el generador sobrescribe los PNG;
  si se retocan a mano (Pixelorama, Aseprite, LibreSprite), ya no conviene regenerarlos.
- `assets/shaders/glitch_cercania.gdshader`: efecto de glitch (transición de la Visión Digital).
- `prototypes/estilos/`: las 6 muestras originales (A–F) se conservan como referencia y usan los recursos de arriba.

**Kai, el personaje:** diseño de Ariel (hoja de concepto en `docs/arte/referencias/kai_hoja_concepto.webp`).
`player.tscn` usa `KaiVisual` en `Visual/Body/Kai` con la apariencia **CONCEPTO**: los sprites de esa hoja,
de 96 px de alto en cuadros de 96×128 (más anchos si hay efectos), mostrados a **mitad de escala** (48 px en el
mundo, como una puerta). Con la cámara ×2, cada píxel del dibujo cae en un píxel de pantalla. La cámara, la
colisión (10×22) y las mecánicas no cambian. Ver "Apariencia de Kai" más abajo. Las siluetas del dash son instantáneas congeladas del cuadro actual
(`PixelatedRig.snapshot()`), y el shader `pixel_crisp` respeta el `modulate` del nodo (parpadeo al recibir daño,
tinte de las siluetas).

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
| `heal` (mantener: curarse) | L | LT |
| `aegis_platform` | F | Clic del stick derecho |
| `grimorio` (abrir el Grimorio) | G | — |
| `pause` | Esc | Start |

Las teclas usan **código físico**: funcionan igual en teclados en español o inglés. Todas se pueden cambiar en
Opciones → Configurar controles. `grimorio` todavía no está en `project.godot`: `GameSettings` la registra al cargar.
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
elige la animación según `Player.state` y mueve con resortes el pelo, los mechones, el faldón y la mochila
(`KaiVisual.SPRINGS`). Toma como `player` al dueño de la escena si no se le asigna uno. `attack()` reproduce el ataque
con el Nullblade (pendiente de conectar al ataque real). Las estelas del dash usan `PixelatedRig.snapshot()`.
Las muestras de estilo usan este Kai si `_build_player_visual()` devuelve null (D y E).
**Apariencias (`KaiVisual.apariencia`):**

| Apariencia | Qué usa | Cómo se genera |
|---|---|---|
| `CONCEPTO` (por defecto) | `AnimatedSprite2D` con `assets/art/characters/kai/hd/` (`kai_hd.json`: archivo, tamaño de cuadro, pies, cuadros, fps y bucle por animación; escala 0,5) | `tools/art/extraer_personajes_concepto.gd` recorta las poses de la hoja de concepto, quita el fondo, usa la misma escala para todas y alinea los pies y la cabeza |
| `HUESOS` | `kai_esqueleto.tscn` con `PixelatedRig` y resortes | `generar_esqueleto_kai.gd` |
| `CUADROS` | Tiras de `assets/art/characters/kai/cuadros/` (72×72) | `exportar_cuadros_kai.gd` (necesita pantalla) desde el esqueleto, para retocar a mano |

Con cuadros, `attack()` encadena `ataque_1` → `ataque_2` si se ataca dos veces seguidas, `PlayerDamage.hurt` muestra
`dano` y `died` muestra `muerte`; al correr hay un rebote suave. `current_animation()` devuelve la animación visible
(la usan las pruebas). La hoja tiene un cuadro por pose: para más fluidez, cada animación necesita más cuadros.
Las medidas de las piezas están en `kai_piezas.gd`; `generar_esqueleto_kai.gd` regenera la escena (borra retoques manuales).

## Combate (`components/combat/`)

| Componente | Nodo | Responsabilidad |
|---|---|---|
| `HitData` | RefCounted | Datos de un golpe: daño, tipo de amenaza, empuje, origen, si es peligro |
| `HitboxComponent` | Area2D | Causa daño. `once_per_activation` para que un tajo golpee una vez. Capa 4 (jugador) o 5 (enemigos/peligros) |
| `HurtboxComponent` | Area2D | Recibe daño revisando superposiciones cada cuadro (el contacto prolongado vuelve a dañar). `immune` = escudo educativo |
| `HealthComponent` | Node | Vida: máscaras del jugador o puntos de vida de enemigos. Señales `health_changed`, `damaged`, `died` |

**Jugador:** `characters/player/player_damage.gd` (`PlayerDamage`, nodo `Damage`) aplica las reglas de Hollow Knight:
quita integridad (**un golpe enemigo vale la mitad de su daño**: uno normal quita medio cristal, `enemy_damage_scale`; los pinchos también medio cristal; los anuncios trampa y las caídas, uno entero), congela la acción (`HitStop`), empuja, da 1 s de invulnerabilidad con parpadeo, devuelve al último
suelo seguro ante peligros y emite `died` al perder todas las máscaras. La sala (`Room`) decide dónde reaparece.

**Curación:** `characters/player/player_heal.gd` (`PlayerHeal`, nodo `Heal`): manteniendo **L**, Kai canaliza su energía. Cada curación gasta **media barrita** (`Player.energy`, máximo `GameState.max_energy_cells`) y devuelve **1,5 cristales**. La primera tarda **1,141 s** (incluye **0,30 s** de inicio); manteniendo L y con energía, cada una más tarda **0,9 s**. Soltar antes cancela sin gastar; un golpe la corta; para volver a curarse hay que soltar y presionar L. En el suelo Kai se arrodilla y en el aire queda flotando (animaciones `curar_suelo*` / `curar_aire*` de `assets/art/characters/kai/hd/kai_hd_curacion.json`, extraídas de `docs/arte/referencias/kai_curacion_concepto.webp` con `tools/art/extraer_personajes_concepto.gd -- kai_curacion`). La energía se conserva entre salas (`GameState.current_energy`), se llena al reaparecer y `Player.add_energy()` queda para recompensas futuras.
**Peligros:** `world/hazards/spikes.gd` (`Spikes`): pinchos con ancho configurable, visibles en el editor. Quitan medio cristal.

**HUD:** `ui/hud/combat_hud.tscn` muestra los **cristales de integridad** (`MaskIcon`, el Núcleo de integridad del concepto de Ariel en `docs/arte/referencias/vidas_concepto.webp`: completo, a la mitad o vacío, con un glitch al perder integridad), las **barritas de energía** con su marco (`EnergyBar`: una por cada `GameState.max_energy_cells`, empiezan 2 y suben con la historia con `set_max_energy_cells()`; para habilidades futuras: `CombatHUD.set_energy(actual, máximo)` o una señal `energy_changed` en el jugador) y los créditos (`CreditsDisplay`, con +X / −X al cambiar).

**Autoloads en scripts compartidos:** `Room` y `PlayerDamage` obtienen `SceneManager` por ruta (`/root/SceneManager`)
para que compilen también en las pruebas de línea de comandos.

## Salas (`world/`)

- `world/zones/zone0/pasillo_laboratorio.tscn`: **primera sala real** (Zona 0, Pasillo + Laboratorio), creada a partir
  de la muestra de Ariel y editable en Godot: tiles (`Background`, `Cables`, tileset `world/tilesets/colegio_tileset.tres`),
  colisiones como rectángulos (`Collisions`: suelo, paredes y bandejas de cables de un sentido), objetos (`Corridor`, `Lab`,
  `CableTrays`), luces (`Lights`, textura compartida `assets/art/light_soft.tres`) y paquetes de datos (`Packets`).
  Una partida nueva (`GameState.reset()`) empieza en la Entrada: Kai es un alumno común, sin habilidades.
- `world/effects/`: comportamientos reutilizables del escenario: `flicker.gd` (parpadeo de carteles), `bob.gd`
  (flotar en píxeles enteros), `pulse_light.gd` (luz que late) y `packet_stream.gd` (paquetes por el cable que se
  "infectan" al pasar por la zona del phishing).
- **Transiciones entre salas** (como en Hollow Knight): `RoomExit` (Area2D en un borde, con `target_scene` y
  `target_entry`) hace un fundido y lleva a la `RoomEntry` (Marker2D con `id` y `facing`) de la otra sala.
  `SceneManager.go_to_room(escena, entrada)` recuerda la entrada; la sala la usa al cargarse. Las máscaras actuales
  se conservan entre salas (`GameState.current_masks`): cambiar de sala no cura.
- `world/zones/zone0/entrada.tscn`: **Entrada del colegio** (escena 1 del prólogo; arte provisional con los tiles de
  Ariel): puerta principal con cartel BIENVENIDOS, ayudas de controles y casilleros que hay que saltar. **"Jugar"
  empieza aquí.** Salida derecha → Pasillo (`desde_entrada`); salida izquierda del Pasillo → Entrada (`desde_pasillo`).
- `world/rooms/room.gd` (`Room`): calcula los límites de la cámara a partir del `TileMapLayer` y coloca al jugador en el `SpawnPoint`.
  Esc vuelve al menú (temporal, hasta que exista la pausa). Caer fuera cuenta como peligro; al morir se reaparece en `checkpoint` (un Node2D: banco o `RestorePoint`; si no hay, `SpawnPoint`). Sacude la cámara al recibir daño.
- `world/camera/` (`GameCamera`): zoom ×2, suavizado, mirada hacia adelante, adelanto hacia abajo en caídas rápidas y margen vertical.
- `world/effects/ring_burst.gd` (`RingBurst`): anillo que se expande; efecto reutilizable (doble salto, impactos).
- `world/tilesets/graybox_tileset.tres`: tiles de prueba (bloque sólido y plataforma de un sentido).
- `tests/fixtures/combat_test_room.tscn`: sala gris **solo para pruebas automáticas** (alturas, huecos, plataformas, techo bajo, caída, pinchos, hueco con dash, chimenea y pilar de doble salto). No es accesible desde el juego.
- `ui/debug/` : panel de depuración (F3) con estado, velocidad y temporizadores del jugador.

## Visión Digital (`autoload/digital_vision.gd`, `world/vision/`)

Diseño de Ariel: **dura 10 s** y **se recarga en 16 s** desde que se apaga; parpadea los últimos 2 s y se puede
apagar antes con **Q**. Solo funciona si `GameState.vision_unlocked`: se desbloquea al terminar la misión de la
contraseña del profesor. En el prólogo aparece sola, como un glitch (`glitch()`).

| Pieza | Responsabilidad |
|---|---|
| `DigitalVision` (autoload) | Estado (`READY` / `ACTIVE` / `RECHARGING`), `toggle()`, `activate(force)`, `deactivate()`, `reset()`, `blend` (0 físico → 1 digital, con transición). Señales `activated`, `deactivated`, `denied(reason, segundos)` |
| `DigitalWorld` (uno por sala) | Oscurece el ambiente, muestra la capa digital (`digital_layer`) y los nodos del grupo `digital_only` (oculta `physical_only`), activa la **capa de colisión 7 (mundo_digital)** en el jugador, ilumina a Kai y hace el glitch de pantalla |
| `DataFragment` | Objeto oculto que solo se recoge con la visión activa: da créditos y deja una marca en `GameState` |
| `Room` | Q llama a `DigitalVision.toggle()` |
| HUD | `VisionMeter` (LISTA / ACTIVA / RECARGANDO, arriba a la derecha) y `Toast` (mensajes: `get_tree().call_group(&"toast", &"show_message", texto)`) |

**Para que algo exista solo en el mundo digital:** ponerlo en la capa de colisión 7 (puentes, plataformas) o en el
grupo `digital_only` (dibujos). No hace falta duplicar la sala.

**Zona 0:** `DigitalLayer/Network` (`red_zona0.gd`, dibujo vectorial de Ariel: red, servidores, puente de datos y el
pez del phishing), `DataBridge` (capa 7), `DataFragment` (+25 créditos, marca `zona0_fragmento_recogido`) y
`LabComputer` (`lab_computer.gd`, un `Interactable`): en el prólogo el **monitor de pared** (`LabMonitor`, pixel art por
código) se enciende solo con interferencia, muestra el **ojo de la entidad «???»** mientras habla en magenta con escritura
irregular («Por fin alguien está mirando», «Te estoy observando»), parpadea y se apaga un momento. Después
las luces parpadean y la Visión Digital se activa **sola** unos segundos (`DigitalVision.glitch()`:
involuntaria, sin indicador, Q no la controla y no deja recarga). En la misión del profesor, la pantalla **absorbe a Kai**
(ver "Entrar a una computadora").

`GameState.set_flag()` deja marcas de eventos y objetos recogidos (se guardan con la partida).

## Interacción, diálogos y NPC

| Pieza | Responsabilidad |
|---|---|
| `Interactable` (`components/interaction/`) | Area2D con una CollisionShape2D: al acercarse Kai muestra el aviso (`prompt_text`, p. ej. "E: hablar") y con **E** emite `interacted(player)`. `busy` lo desactiva mientras dura un diálogo o evento |
| `Dialogue` (`systems/dialogue/`) | Recurso con el texto del diálogo, **una línea por intervención: `Nombre: texto`** u opcionalmente **`Nombre [expresión]: texto`**. Las líneas sin nombre son narración; las vacías y las que empiezan con `#` se ignoran. Se edita en el Inspector |
| `DialogueCharacter` (`systems/dialogue/`, uno por personaje en `data/characters/`) | Nombre, otros nombres (`aliases`, p. ej. "Profesor"), título, retrato, expresiones, lado de la pantalla y color de acento |
| `DialogueBox` (`ui/dialogue/`) | Caja de diálogo **estilo Hades**, dentro del HUD de cada sala: muestra el **retrato grande** del que habla (Kai a la izquierda, los demás a la derecha; el otro se oscurece y retrocede), una **placa oscura** con nombre y título y un emblema hexagonal (`DialogueNamePlate`), y una **caja clara inclinada** con marco doble del color del personaje (`DialogueFrameArt`, dibujada por código) que aparece con un pequeño salto cuando cambia quien habla, más un triángulo para continuar. Sin retrato (narración) la caja va centrada. Carga sola los personajes de `data/characters/`. Texto letra por letra; **E / Espacio** completa la línea o pasa a la siguiente. `await DialogueBox.find(self).play(dialogo)` |
| `Npc` (`characters/npcs/npc.gd`, plantilla `npc.tscn`) | Personaje con `dialogue` (primera vez) y `repeat_dialogue` (las siguientes), animaciones `idle` / `talk`, mira hacia Kai y deja la marca `talked_flag` en `GameState`. Opcional: `idle_extra_animation`, que hace de vez en cuando mientras espera |

**El Prof. Alvarado** (`characters/npcs/profesor/`) está en el pasillo, con los sprites de la hoja de concepto de Ariel
(`idle`, `walk`, `talk` y `notas`), la misma estructura que Kai: `tools/art/extraer_personajes_concepto.gd` →
`assets/art/characters/profesor/hd/` → `tools/art/generar_sprite_frames.gd` → `profesor_frames.tres` (Sprite con
escala 0,5 y offset (0, -55)). Retrato en `data/characters/profesor.tres`.
Diálogos en `data/dialogues/prologo/`: `profesor_pedido.tres` (pide revisar la computadora del laboratorio; marca
`prologo_profesor_pidio_ayuda`) y `profesor_recordatorio.tres`.

## Entrar a una computadora (alma digital)

1. `DigitalDive.dive(jugador, punto_de_pantalla, cámara)` (`world/effects/digital_dive.gd`): la pantalla brilla, la cámara
   se acerca, píxeles de Kai vuelan hacia la pantalla, Kai se estira, gira y se encoge dentro, y un destello blanco cubre todo.
2. `LoadingScreen.show_loading(nodo, título, líneas, segundos)` (`ui/transitions/`): lluvia de código, líneas de estado y barra
   de progreso. Vive sobre la raíz, así que sigue visible mientras cambia la sala.
3. `SceneManager.go_to_room()` a la sala de la computadora. Su `RoomEntry` tiene `arrival_effect = "materialize"`: la sala
   cierra la pantalla de carga y Kai se arma desde píxeles (`DigitalDive.materialize()`).
4. Las salas digitales usan `Room.player_tint` (Kai celeste: su alma digital) y `Room.room_size` (no tienen tiles).

`world/zones/pc_profesor/escritorio.tscn`: **nivel de SPAM** dentro de la computadora del profesor (3360 px, solo caminar
y saltar). La salida izquierda vuelve al laboratorio (entrada `desde_pc`, también con materialización).

Recorrido, de izquierda a derecha:

| Zona | x | Obstáculos |
|---|---|---|
| A | 260–940 | Lluvia de correos A, trampa suelta y escalera MineKraft → Terrarya → GTA 6 (se cierra) sobre trampas |
| B | 940–1300 | Lluvia B, Fortnait (se mueve) y Robucks (se cierra) sobre trampas |
| — | 1400 | **Punto de restauración** (`RestorePoint`) |
| C | 1480–1830 | Escalera Stim → Pokimon GO+ (se cierra) → Clash Royal (sube y baja) sobre un foso de trampas |
| D | 1820–2300 | Lluvia C (la más intensa) y 3 vallas cortas que hay que saltar |
| E | 2320–2900 | Lluvia D, Fri Fayer → Valorante (se mueve) → Brawl Starz (se cierra) → Zeldo sobre un foso largo |
| Final | 2956–3310 | «¡Profe, aquí está el error!», la **terminal** (x=3036) y la cuenta del profesor |

**Componentes de SPAM** (`world/digital/spam/`, se ven también en el editor y sirven para otros niveles):

| Componente | Qué hace |
|---|---|
| `SpamPopup` (AnimatableBody2D) | Ventana de anuncio cuya barra de título es una plataforma de un sentido. `move_offset` / `move_time` (se mueve de ida y vuelta y lleva a Kai), `closes_when_stepped` (parpadea, se cierra al pisarla y vuelve a abrirse). Textos editables: `ad_title`, `ad_lines`, `ad_url`, `accent` |
| `TrapAd` (HitboxComponent) | Botón "¡DESCARGAR GRATIS!": tocarlo es como pisar pinchos (1 máscara y vuelta al suelo seguro) |
| `RestorePoint` (`world/digital/`, Area2D) | Punto de restauración: al pasar Kai pasa a ser el `checkpoint` de la sala (si muere reaparece ahí). No cura. Muestra «Punto de restauración creado» |
| `SpamMailSpawner` + `SpamMail` | Lluvia de correos en una franja, solo con Kai cerca. Cada correo avisa parpadeando (0,35 s), cae balanceándose (200 px/s), quita medio cristal (es un enemigo) y empuja. El 80 % (`aimed_ratio`) apunta a Kai: la mitad cae donde estaba hace 0,15 s (`aim_delay`) y la otra mitad (`lead_ratio`) se adelanta a donde estará si sigue corriendo igual (`lead_amount`). Quedarse quieto o correr siempre al mismo ritmo es peligroso: hay que ver el parpadeo y cambiar el paso. En la PC del profesor, la lluvia A cubre también los saltos entre pop-ups |

Los anuncios usan **nombres parodia** (MineKraft, Terrarya, GTA 6 anticipado, Fortnait, Robucks, Amung Us, Stim, Pokimon GO+,
Clash Royal, Fri Fayer, Valorante, Brawl Starz, Zeldo) con señales de
estafa reales: urgencia, premios, pedir la contraseña, "desactiva tu antivirus" y direcciones raras (`.xyz`, `.click`, `.top`).
Al final, `AccountWindow` (cuenta del profesor: contraseña 123456, sin verificación en dos pasos) y `AccountTab`
("E: cambiar la contraseña"; el combate con la mini espada es H4c).

**`QuestTrigger`** (`systems/quests/`): Area2D que completa un paso de misión al entrar Kai (o al cargar la sala con
`on_ready`) y puede mostrar un diálogo antes. En la PC: `EnteredPc` (entrar_pc) y `FoundError` («¡Profe, aquí está el error!»).

## Terminal simulada (`systems/terminal/`, `ui/terminal/`)

Terminal educativa con comandos reales de Linux sobre un **sistema de archivos ficticio**. Es una simulación:
no ejecuta programas del dispositivo ni lee sus archivos (`test_terminal.gd` lo comprueba).

| Pieza | Qué hace |
|---|---|
| `VirtualFileSystem` | Carpetas (Dictionary) y archivos (String) en memoria. Rutas como en Linux: `~`, `.`, `..`, absolutas |
| `CommandInterpreter` | Lista de comandos permitidos: `help`, `pwd`, `ls`, `cd`, `cat`, `clear`, `history`. Mensajes de error como bash (en español). Historial y autocompletado. Emite `command_run` por cada comando que funciona |
| `TerminalChallenge` (Resource, `data/terminals/`) | Un desafío: usuario y equipo del prompt, archivos, objetivo (`goal_file`: leerlo con `cat`), comandos permitidos, pistas y retroalimentación |
| `TerminalWindow` | Ventana encima del juego: objetivo, salida con colores y la línea de comandos. Enter ejecuta, ↑/↓ historial, Tab completa, Esc cierra. Botones rápidos para celular (`ls`, `pwd`, `cd …`, `cd ..`, `cat …`), Pista, Continuar |
| `TerminalStation` (`world/digital/`) | Interactuable: con E abre la ventana. Con `quest_id`/`step_id` solo funciona en ese paso y al resolver muestra `success_dialogue` y completa el paso |

Cada comando usado queda **aprendido** en `GameState` (`learn_command`, se guarda) y desbloquea su página en la
pestaña COMANDOS del Grimorio (`data/grimorio/comando_*.tres`, con `unlock_command`): función, sintaxis, ejemplo,
resultado y concepto relacionado. Para crear una terminal nueva: un `TerminalChallenge` en el Inspector y una `TerminalStation`
en la sala; no hace falta programar.

**Primera terminal** (PC del profesor, paso `revisar_configuracion`): encontrar y leer
`~/cuenta/configuracion.txt` (contraseña 123456, sin verificación en dos pasos). Alineada con indicadores de
décimo de la tabla del MEP 2025 (Operaciones ciberseguras): seguridad en sistemas operativos de código abierto y
conceptos básicos de gestión de contraseñas.

## Misiones (`systems/quests/`)

| Pieza | Responsabilidad |
|---|---|
| `Quest` / `QuestStep` | Recurso con pasos en orden (`id`, `objective`). `completion_title` / `completion_subtitle` (título grande al completarla) y `next_quest` (misión que empieza después) |
| `QuestDB` | Registro id → archivo (`data/quests/`). Cada misión nueva se agrega aquí |
| `GameState` | `start_quest()`, `get_current_step()`, `complete_step(misión, paso)` (solo si es el paso actual), `is_quest_completed()`, `get_objective_text()`. Señales `quest_started`, `quest_step_changed`, `quest_completed`. Se guarda con la partida |
| `NpcConversation` | Lo que dice un NPC en un paso concreto; con `completes_step` completa ese paso al terminar |
| HUD | `ObjectiveDisplay` (OBJETIVO, arriba a la derecha, destella al cambiar) y `TitleCard` (título grande al completar una misión) |

**La contraseña del profesor** (`contrasena_profesor.tres`): entrar a la PC → cruzar el SPAM → revisar la configuración en la terminal → cambiar la contraseña.

**Prólogo** (`data/quests/prologo.tres`): buscar al profesor → revisar la computadora del laboratorio → contarle al
profesor. Al completarlo: **«CAPÍTULO 0 · EL DESPERTAR»** y empieza **La contraseña del profesor**
(`contrasena_profesor.tres`; su primer paso: revisar la cuenta del profesor en la computadora del laboratorio).
"Jugar" empieza el prólogo. Diálogos en `data/dialogues/prologo/`.

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

**Sin sala de desarrollo:** las habilidades se prueban en el mapa a medida que se desbloquean. Las pruebas automáticas
declaran el progreso que necesitan con estas mismas funciones antes de cargar la sala gris (`tests/fixtures/combat_test_room.tscn`).

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

## Opciones y Grimorio (`systems/settings/`, `systems/grimorio/`, `ui/menus/`)

| Pieza | Responsabilidad |
|---|---|
| `GameSettings` (`systems/settings/game_settings.gd`) | Clase **estática** (sin autoload) con los ajustes del jugador: volumen general / música / efectos (buses `Master`, `Music`, `SFX`, que crea si no existen), pantalla completa, velocidad del texto (`text_speed_factor()`, 0 = instantáneo), reducción de glitch (`glitch_factor()`, `reduce_glitch`) y teclas (`remap()`, `reset_controls()`, `key_name()`). Se guarda en `user://ajustes.cfg`; `ensure_loaded()` lo carga y aplica (lo llama el menú principal) |
| Pantalla de opciones (`ui/menus/settings/`) | Estilo lila del menú. Filas `SettingRow` (hereda de `MainMenuOption`): deslizador, sí/no, opciones y tecla; ◀ ▶ cambian el valor. Subpantalla de **controles** (elige una acción y presiona la tecla nueva; Esc cancela) |
| Quién usa los ajustes | `DialogueBox` (velocidad del texto; sin temblor de «???» si se reduce el glitch), `DigitalWorld.pulse_glitch()` (más suave) y `LabMonitor` (luz sin parpadeo) |
| `GrimorioEntry` (`systems/grimorio/`, un `.tres` por entrada en `data/grimorio/`) | Página del Grimorio: categoría (MAPA, COMANDOS, AMENAZAS, CONCEPTOS, REGISTROS), título, texto, datos, tecla (`action`), imagen y desbloqueo (`unlock_quest` + `unlock_step`, `unlock_on_complete` o `unlock_property` de `GameState`). Bloqueada se ve como «???» |
| Grimorio (`ui/menus/grimorio/`, `GrimorioScreen`) | Se abre con **G** durante el juego (`CombatHUD` llama a `GrimorioScreen.open()`): queda encima de la sala, que se pausa; G, Esc o CERRAR lo cierran. No se abre en diálogos ni escenas sin control. El libro (concepto de Ariel en `docs/arte/referencias/grimorio_concepto.webp`) dibujado por código (`GrimorioBook`), pestañas con íconos (`GrimorioTab`) y el mapa esquemático (`GrimorioMap`: salas de cada zona en `ZONES`, visitadas según la marca `visitada_<escena>` que deja `Room` o el paso de una misión) |

Para agregar una entrada al Grimorio: copiar un `.tres` de `data/grimorio/`, cambiar textos y desbloqueo. `GameState.has_reached_step(mision, paso)` dice si la misión ya llegó a ese paso.

## Pruebas automáticas

Scripts en `tests/` que se ejecutan sin abrir el editor:

```
godot --headless --path . --script res://tests/<prueba>.gd
```

Cada prueba imprime `OK`/`FAIL` por comprobación y termina con código 0 si todo pasó.
Las pruebas nuevas esperan a que se cumpla cada condición (cuadros de física) en vez de segundos fijos: así no fallan
cuando la computadora está ocupada (por ejemplo, con el editor de Godot abierto).

| Prueba | Comprueba |
|---|---|
| `test_menu_navigation.gd` | Menú → Configuración → Menú → Jugar |
| `test_player_movement.gd` | Correr y frenar, salto completo y corto, coyote time, jump buffer, hueco de 6, plataforma de un sentido, reaparición y límites de cámara |
| `test_player_abilities.gd` | Dash (suelo, aire, reutilización, invulnerabilidad), doble salto, deslizamiento y salto de pared, bloqueo de habilidades no desbloqueadas |
| `test_player_health.gd` | Máscaras, pinchos, suelo seguro, invulnerabilidad, empuje, contacto prolongado, escudo educativo, caída, muerte y niveles del dash |
| `test_heal.gd` | Curación con L: no cura con la vida llena, tiempos (1,141 s y 0,9 s), 1,5 cristales por media barrita, quieto en el suelo, animaciones, cancelar al soltar, sin energía, flotando en el aire, un golpe la corta y el HUD de energía |
| `test_zone0.gd` | "Jugar" abre la Entrada con partida nueva (sin habilidades), Kai de Ariel, HUD, casilleros que se saltan, transición al Pasillo y de vuelta (entrada y orientación correctas), máscaras que se conservan, recorrido hasta el laboratorio, bandejas como plataformas y Esc al menú |
| `test_vision.gd` | Visión Digital bloqueada, desbloqueo, capa digital, oscurecimiento, puente de datos (capa 7), fragmento (una sola vez), apagado manual, recarga y fin por duración |
| `test_dialogue.gd` | Formato de los diálogos, aviso «E: hablar», caja de diálogo (letra por letra, completar, avanzar, cerrar), controles bloqueados, marca del profesor y recordatorio |
| `test_settings_grimorio.gd` | Ajustes (buses de audio, velocidad del texto, glitch, cambiar y restablecer teclas, guardado), pantalla de opciones (◀ ▶, controles, abrir grimorio) y Grimorio (pestañas, desbloqueo por la historia, «???», mapa) |
| `test_prologue.gd` | API de misiones (orden, guardado), el prólogo completo con el objetivo en pantalla, la computadora bloqueada antes de tiempo, la visión involuntaria (sin indicador, Q no la controla, sin recarga), «EL DESPERTAR» y el comienzo de la misión del profesor |
| `test_digital_dive.gd` | La computadora absorbe a Kai (cámara, desaparición), pantalla de carga, llegada al escritorio, materialización, alma digital celeste, límites y regreso al laboratorio |
| `test_spam_level.gd` | Pop-ups (fijo, que se cierra y reabre, que se mueve y lleva a Kai), anuncio trampa, correo que cae (y apunta a Kai), ruta completa solo saltando (bot), punto de restauración (activarlo y reaparecer ahí al morir) y llegada a la cuenta del profesor |
| `test_terminal.gd` | Terminal simulada: sistema de archivos, comandos y errores, autocompletado, comandos permitidos, que no toque el sistema real, y la terminal de la PC del profesor (abrir, Esc, resolver, diálogo, paso de misión, comandos aprendidos y guardados) |
| `test_progress.gd` | Progreso inicial, créditos, penalización al morir, límites, guardar/cargar (también partidas antiguas) y aplicación del progreso al jugador en una sala |
| `test_decision_system.gd` | Datos del incidente de phishing, flujo de investigación, cobro y efectos de las medidas, rechazos (sin evidencia, sin presupuesto, ya resuelto) y guardar/cargar |
