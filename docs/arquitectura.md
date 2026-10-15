# Arquitectura técnica

Documento vivo: se actualiza cada vez que se agrega o cambia un sistema.

Historia, personajes y mundo: [`narrativa/BIBLIA_NARRATIVA.md`](narrativa/BIBLIA_NARRATIVA.md), la referencia
narrativa principal.

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
| `World` | `autoload/world.gd` | El mapa del mundo: grafos de los distritos, sala actual y a dónde lleva cada puerta. Ver «Mapa del mundo». |
| `IdentityManager` | `autoload/identity_manager.gd` | Quién juega (Steam en T9; hoy identidad de desarrollo): la carpeta de partidas de cada identidad. Ver `arquitectura/SISTEMA_USUARIOS_STEAM.md`. |
| `SaveManager` | `autoload/save_manager.gd` | Guardar y continuar la partida (`user://partida.json`). Ver «Guardado». |
| `Economy` | `autoload/economy.gd` | Saldo de **Ecos** (la moneda) y la penalización al morir. Ver «ECOS». |
| `DigitalVision` | `autoload/digital_vision.gd` | Estado de la Visión Digital (lista, activa, recargando), duración, recarga y `blend` para los efectos. Ver "Visión Digital". |
| `GameState` | `autoload/game_state.gd` | Presupuesto, seguridad y confianza; estado de incidentes, pistas, marcas y decisiones. **Progreso del jugador** (habilidades, evoluciones, misiones, comandos, contraseñas). Preparado para guardar partida (`to_dict` / `from_dict`). |

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
| `dash` | C | RB |
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
| `max_speed` | 140 px/s | Velocidad al correr (y la del dash) |
| `walk_speed` | 130 px/s | Velocidad al caminar: al principio Kai solo camina (`can_run = false`); correr se desbloquea más adelante. Los niveles están pensados para unos 130 (con menos, algunos huecos y plataformas no se alcanzan) |
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
Mientras `Player.can_run` es falso, al desplazarse usa `caminar` (las dos poses de perfil de la hoja a 5 cuadros/s, con un rebote de paso de 1 px) en vez de `correr`. En el aire usa la pose de salto (sin el brillo morado de la hoja); `caer`, que en la hoja está agachada, solo dura un instante al aterrizar. `muerte` es Kai desplomado boca abajo con la cabeza hacia adelante: la pose de reposo girada 90° (en la hoja de personaje, la muerte parecía dos personajes). `set_dissolve(cantidad)` lo deshace en píxeles magenta (`world/effects/pixel_dissolve.gdshader`).
**Muerte y reaparición** (`world/effects/death_sequence.gd`, `DeathSequence.play(jugador, reaparecer)`, la llama `Room` al morir), según la hoja de Ariel, en magenta: impacto (estallido), aturdido (`dano`), de rodillas (`curar_suelo_inicio`), desplomado (`muerte`), un instante en el suelo, se desintegra en píxeles con líneas de glitch, pantalla «CONEXIÓN PERDIDA...» (`ConnectionLostScreen`, con franjas de glitch; a oscuras pasa al punto de control y recupera la vida), punto de luz magenta (haz y rombo), se rearma desde los píxeles de rodillas, se levanta y vuelve el control (~5,5 s). Sonidos `death_dissolve`, `connection_lost` y `respawn_build`. Mientras muere no parpadea.
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

**Ataque de Kai:** `characters/player/player_combat.gd` (`PlayerCombat`, nodo `Combat` del jugador; `player.combat`).
Con J (acción `attack`) ataca hacia donde mira usando el arma equipada (`weapon`, un `WeaponData` de
`components/combat/weapon_data.gd`: daño, alcance, preparación, tiempo activo, enfriamiento, empuje, retroceso y
congelamiento al acertar). Sin arma no ataca. Crea su propia zona de golpe (capa 4, `once_per_activation`), dibuja
el arco del tajo y emite `hit_landed` (para energía y combos futuros). La animación es la de Ariel: `ataque_1`
(preparación) y `ataque_2` (tajo, justo cuando hace daño). Las etapas de Nullblade serán otros `WeaponData`.
**Cadencia:** `WeaponData.cooldown` = **0,45 s** entre ataques (un ritmo pausado, como el aguijón de Hollow Knight).
**Ataque hacia abajo y rebote (pogo):** en el aire, **abajo + J** ataca hacia abajo: la zona de golpe va debajo de los pies (girada) y Kai **clava la espada** con las poses de la hoja de pogo de Ariel (`docs/arte/referencias/pogo_concepto.webp` → `kai_hd_pogo_*`, cuadros más altos para la espada): `pogo_clavar` (la pose de preparación de la hoja, que tiene las piernas; `KaiVisual.pogo_attack`), con el rastro de descenso; al rebotar, `pogo_subir` (el ascenso; en el descenso, el rebote y la recuperación de la hoja a Kai le faltan las piernas en el recorte, `KaiVisual.pogo_bounce`), la chispa del impacto (píxeles, rayos y glitch), el chorro vertical y el arco de rastro al subir. Si la apariencia no tiene esas poses, usa `caer` + `WeaponData.sprite`. Si golpea a un enemigo o a una estructura de rebote, Kai **rebota** (`Player.pogo(pogo_height)`: altura fija, recupera el dash en el aire; el doble salto no, solo al tocar suelo, plataforma o estructura), con un destello en la punta y el sonido `pogo` (señal `PlayerCombat.pogo`). Estructuras de rebote: los **pinchos** (`Spikes` crea al jugar una zona `PogoZone` que recibe los ataques; rebotar a tiempo no lastima) y el **nodo de rebote** (`world/objects/pogo_node.gd`, `PogoNode`: cristal de datos flotante que no hace daño ni se rompe; para cruzar huecos rebotando). En el suelo, abajo + J es un ataque normal.

**Ataque hacia arriba:** **arriba + J** (en el piso o en el aire) ataca sobre la cabeza de Kai: la zona de golpe va arriba (`PlayerCombat.UP_REACH_TOP`, angosta y alta). Es el ataque hacia abajo al revés: Kai usa la misma pose del pogo (`arriba_cortar`, `KaiVisual.up_attack`: `pogo_clavar` con las dos manos en el mango, sin la hoja que baja, `tools/art/generar_kai_corte_arriba.gd`) y la Nullblade sale de golpe de sus manos hacia arriba, un poco hacia adelante (`UP_GRIP`, `UP_TILT`), con su luz a lo largo de la hoja, una chispa en la punta y un destello con el rombo de la Nullblade (`_spawn_up_slash`). Sin estela. Sin esa pose, Kai usa la de salto. No empuja a Kai hacia atrás ni rebota. `PlayerCombat.is_up_attack()`.
Armas: `data/weapons/` (`nullblade.tres`, la que se obtiene en el prólogo; `mini_espada.tres` quedó sin uso).
**Energía por golpe:** cada golpe acertado a un **enemigo válido** (`EnemyBase` en pie, sin escudo) recupera `WeaponData.energy_gain` (**12,5 %** de la energía máxima; el ataque cargado futuro, `charged_energy_gain`, **15 %**), nunca más del máximo. Paredes, objetos y el aire no dan energía; un mismo ataque golpea una vez a cada enemigo y cada enemigo distinto cuenta; derrotar no da extra. La barra hace un pulso violeta (`EnergyBar.pulse()`). El tajo es una media luna del color del arma.
**Nullblade:** `world/effects/nullblade_reveal.gd` (`NullbladeReveal.play(jugador)`) la materializa por primera vez en una **escena de cine** (~6 s): franjas negras, la pantalla se oscurece a violeta con un foco sobre Kai (`reveal_shade.gdshader`), la cámara se acerca y la música baja (`Music.duck`). Fases de la hoja de Ariel: activación (datos que suben del suelo), manifestación (fragmentos que giran y una columna de luz), condensación (la espada se define con la punta hacia arriba), materialización (destello blanco, golpe grave, ondas, rayos y franjas de glitch), empuñadura (vuela a la mano de Kai con estela) y un tajo de prueba. Con "reducir glitch" el destello es suave y no hay franjas. Después muestra la tarjeta `ui/equipment/equipment_card.tscn` (`EquipmentCard.show_card()`, reutilizable para otros equipos; pausa el juego). Arte en `assets/art/items/nullblade/` (`tools/art/extraer_nullblade.gd`). Con `GameState.nullblade_stage > 0`, `Player.apply_progress()` la equipa en todas las salas.
**ECOS (la moneda oficial):** residuos de información que dejan las amenazas neutralizadas; solo se obtienen jugando
(sin dinero real). El saldo vive en el autoload **`Economy`** (`autoload/economy.gd`), el único lugar donde cambia:
`add_ecos()` (rechaza 0 o negativos), `spend_ecos()` (false si no alcanza o es inválido), `can_afford_ecos()` y
`apply_death_penalty()` (**10 % hacia abajo, máximo 100, nada durante el tutorial**: hasta la marca `tutorial_terminado`,
al final del prólogo). Señal `ecos_changed(ecos, delta)`. `GameState` la guarda y reinicia con el resto (`to_dict` →
`"economy"`); las partidas viejas con «credits» se convierten en Ecos. `world/pickups/eco_shard.gd` (`EcoShard`):
fragmento que salta, rebota en el mundo (capa 1), flota, brilla y vuela hacia Kai cuando se acerca (36 px); vale 1 o 5;
`EcoShard.spawn_burst(sala, posición, cantidad)` reparte la cantidad en fragmentos de **1, 5 y 25** (`EcoShard.split`,
máx. 14 piezas). **Apariencia (E3):** fragmento **cristalino** dibujado por código (`EcoShard.draw_shard`, también el ícono
del HUD): azul si vale 1, violeta si vale 5 y blanco violáceo, más grande, si vale 25; flota, gira, destella y al recogerlo
se deshace en partículas con un anillo de luz y un tintineo de cristal (`eco_pickup`). **Enemigos:** al morir, `EnemyBase`
se desintegra en píxeles (`world/effects/pixel_burst.gd`) y suelta `get_ecos_reward()` (según su rango, ver E2).
**Misiones:** `Quest.ecos_reward` (prólogo 25). **Cofres:** `world/pickups/eco_chest.gd` (`EcoChest`, un `Interactable`;
queda abierto con la marca `cofre_<chest_id>`). **En la PC del profesor los Ecos solo los da el villano** (la «Contraseña
débil»): no hay cofre y la terminal, el desafío y la misión dan 0. Al
recoger el primer Eco queda la marca `ecos_descubiertos` y se desbloquea su página del ARSENAL. HUD: `EcosDisplay`
(«1.250 ECOS», con +X / −X al cambiar).

**Valores y recompensas únicas (E2):** `EconomyConfig` (`systems/economy/`, archivo `data/economy/economia.tres`, se edita
en el Inspector) tiene los rangos de cada fuente —enemigo común 5–10, especial 20–40, jefe 150–250, terminal 30–60, desafío
de elección 20–40, misión secundaria 75–150, depósito oculto 15–40— y la penalización (10 %, máximo 100).
`Economy.roll(fuente)` sortea un valor dentro del rango; `reward_for(fuente, fijo)` usa el fijo si es ≥ 0. **Recompensas
únicas** con id estable: `claim_reward(id, cantidad)` paga solo la primera vez; `claim_drop(id)` registra las que caen al
suelo. Los ids cobrados se guardan con la partida (`"claimed"`). Ids: `mision:<id>`, `terminal:<id>`, `desafio:<id>`,
`cofre:<id>`, `fragmento:<marca>`, `enemigo:<id>`. Los enemigos tienen `rank` (común, especial, jefe) y, si son de la historia,
`reward_id` (la «Contraseña débil»: especial, `enemigo:contrasena_debil`). `TerminalChallenge.ecos_reward` y
`ChoiceChallenge.ecos_reward` (-1 = sorteado). **Los Ecos no se pierden:** si Kai sale de la sala sin recoger los
fragmentos, se suman solos (`EcoShard._exit_tree`; `discard()` los quita sin sumar).

**Enemigos:** `characters/enemies/enemy_base.gd` (`EnemyBase`, CharacterBody2D). Crea su cuerpo (capa 3), su
`HealthComponent`, su `HurtboxComponent` (recibe golpes de la capa 4) y su golpe por contacto (capa 5). Al recibir un
golpe: destello, empuje y aturdimiento breve (`hurt_time`). Señales `damaged` y `died`. Cada enemigo escribe su
comportamiento en `_ai()` y sus reacciones en `_on_damaged()` / `_on_died()`. `ai_enabled = false` lo deja quieto
(presentaciones y pruebas). Kai atraviesa a los enemigos recibiendo daño, como en Hollow Knight.

**La «Contraseña débil»** (`characters/enemies/weak_password/`, `WeakPasswordEnemy`): **10 de vida**, tipo de amenaza
`credenciales`, especial y de la historia (20–40 Ecos, una sola vez). **Persigue a Kai por toda la arena**: cada salto
se calcula para caer donde está él (`_jump_toward_player`), también arriba de los pop-ups (hasta `max_jump_speed`).
Aparece al fondo de la arena (x≈3860), lejos de Kai. Tres fases: 1) se agacha avisando (`TELEGRAPH`) y salta hacia Kai; 2) con la mitad de la vida, **fuerza bruta**: avisa menos, salta más seguido y más lejos y al caer lanza
un **intento** (`PasswordGuess`: una contraseña débil real que corre a ras del suelo; hay que saltarla, quita medio
cristal); 3) con el 30 %, **ataque de diccionario**: dos intentos seguidos (`dictionary_gap`). Cada golpe suelta una
contraseña débil real (`123456`, `qwerty`…) y al morir se deshace en números. Dibujo vectorial provisional hasta que Ariel haga el suyo.

**Curación:** `characters/player/player_heal.gd` (`PlayerHeal`, nodo `Heal`): manteniendo **L**, Kai canaliza su energía. Cada curación gasta **media barrita** (`Player.energy`, máximo `GameState.max_energy_cells`) y devuelve **1,5 cristales**. La primera tarda **1,141 s** (incluye **0,30 s** de inicio); manteniendo L y con energía, cada una más tarda **0,9 s**. Soltar antes cancela sin gastar; un golpe la corta; para volver a curarse hay que soltar y presionar L. En el suelo Kai se arrodilla y en el aire queda flotando (animaciones `curar_suelo*` / `curar_aire*` de `assets/art/characters/kai/hd/kai_hd_curacion.json`, extraídas de `docs/arte/referencias/kai_curacion_concepto.webp` con `tools/art/extraer_personajes_concepto.gd -- kai_curacion`; flotando, la herramienta tapa la mano del pecho con el color de la camisa —`cover`— porque en la hoja se veían tres brazos). La energía se conserva entre salas (`GameState.current_energy`), se llena al reaparecer y `Player.add_energy()` queda para recompensas futuras.

**Peligros:** `world/hazards/spikes.gd` (`Spikes`): pinchos con ancho configurable, visibles en el editor. Quitan medio cristal.

**HUD:** `ui/hud/combat_hud.tscn` muestra los **cristales de integridad** (`MaskIcon`, el Núcleo de integridad del concepto de Ariel en `docs/arte/referencias/vidas_concepto.webp`: completo, a la mitad o vacío, con un glitch al perder integridad), las **barritas de energía** con su marco (`EnergyBar`: una por cada `GameState.max_energy_cells`, empiezan 2 y suben con la historia con `set_max_energy_cells()`; para habilidades futuras: `CombatHUD.set_energy(actual, máximo)` o una señal `energy_changed` en el jugador) y los créditos (`CreditsDisplay`, con +X / −X al cambiar).

**Autoloads en scripts compartidos:** `Room` y `PlayerDamage` obtienen `SceneManager` por ruta (`/root/SceneManager`)
para que compilen también en las pruebas de línea de comandos.

## Salas (`world/`)

- `world/zones/zone0/pasillo.tscn` y `laboratorio.tscn`: las **primeras salas reales** (Zona 0), creadas a partir de
  la muestra de Ariel y editables en Godot: tiles (`Background`, `Cables`, tileset `world/tilesets/colegio_tileset.tres`),
  colisiones como rectángulos (`Collisions`: suelo, paredes y bandejas de cables de un sentido), objetos, luces (`Lights`,
  textura compartida `assets/art/light_soft.tres`) y paquetes de datos (`Packets`). Eran una sola escena; en **M3** se
  separaron en dos salas del mapa:
  - **Pasillo** (688 px): el profesor, los casilleros, el router, las bandejas de cables y el puente de datos con su
    fragmento (Visión Digital). Salida izquierda → Entrada; derecha → Laboratorio (`desde_pasillo`).
  - **Laboratorio** (720 px): la computadora del laboratorio (prólogo y entrada a la PC del profesor), el monitor de la
    entidad, los servidores (dos más, provisionales, con los sprites de Ariel) y la carnada del phishing. Su fondo es el
    patrón diagonal de Ariel, ensanchado. Salida izquierda → Pasillo (`desde_laboratorio`); al salir de la PC se llega
    aquí (`desde_pc`).
  - La red de la Visión Digital (`red_zona0.gd`) está en las dos salas: `show_bridge` (puente y fragmento, en el
    Pasillo) y `show_threat` (el pez del phishing, en el Laboratorio).
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
| `DataFragment` | Objeto oculto que solo se recoge con la visión activa: da Ecos y deja una marca en `GameState` |
| `Room` | Q llama a `DigitalVision.toggle()` |
| HUD | `VisionMeter` (LISTA / ACTIVA / RECARGANDO, arriba a la derecha) y `Toast` (mensajes: `get_tree().call_group(&"toast", &"show_message", texto)`) |

**Para que algo exista solo en el mundo digital:** ponerlo en la capa de colisión 7 (puentes, plataformas) o en el
grupo `digital_only` (dibujos). No hace falta duplicar la sala.

**Zona 0:** `DigitalLayer/Network` (`red_zona0.gd`, dibujo vectorial de Ariel: red, servidores, puente de datos y el
pez del phishing), `DataBridge` (capa 7), `DataFragment` (+25 Ecos, marca `zona0_fragmento_recogido`) y
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
| `DialogueCharacter` (`systems/dialogue/`, uno por personaje en `data/characters/`) | Nombre, otros nombres (`aliases`, p. ej. "Profesor"), título, retrato, expresiones, lado de la pantalla, color de acento y voz (`voice`, `voice_pitch`, `voice_variation`, `voice_every`) |
| `DialogueBox` (`ui/dialogue/`) | Caja de diálogo **estilo Hades**, dentro del HUD de cada sala: muestra el **retrato grande** del que habla (Kai a la izquierda, los demás a la derecha; el otro se oscurece y retrocede), una **placa oscura** con nombre y título y un emblema hexagonal (`DialogueNamePlate`), y una **caja clara inclinada** con marco doble del color del personaje (`DialogueFrameArt`, dibujada por código) que aparece con un pequeño salto cuando cambia quien habla, más un triángulo para continuar. Sin retrato (narración) la caja va centrada. Carga sola los personajes de `data/characters/`. Texto letra por letra; **E / Espacio** completa la línea o pasa a la siguiente. `await DialogueBox.find(self).play(dialogo)` |
| Retratos | `tools/art/extraer_retratos.gd`: Kai y el Prof. Alvarado de `dialogos_hoja_concepto.webp`; Glitch y Chip de `dialogos_hermanos.webp` (se borra lo oscuro desde los bordes y queda la figura más grande, con sus efectos: llamas rojas y hologramas). Glitch y Chip hablan del lado derecho con el retrato dado vuelta (`flip_portrait`) y más chico (`portrait_scale` 0,68: su dibujo es casi todo cabeza y la caja les tapaba la cara), caja roja y celeste |
| `Npc` (`characters/npcs/npc.gd`, plantilla `npc.tscn`) | Personaje con `dialogue` (primera vez) y `repeat_dialogue` (las siguientes), animaciones `idle` / `talk`, mira hacia Kai y deja la marca `talked_flag` en `GameState`. Opcional: `idle_extra_animation`, que hace de vez en cuando mientras espera |
| `BackgroundNpc` (`characters/npcs/background_npc.gd`) | **NPC de fondo**: no se habla con ellos ni chocan; solo dan vida al colegio. `character` (m1-m3 / f1-f3 estudiantes, pm / pf profesor y profesora, cj conserje, x1-x3 y v1-v21 variantes de un cuadro) y `mode`: QUIETO (respira y mira a los lados), CAMINAR (va y viene entre `walk_left` y `walk_right`), CHARLAR (con `partner` y el mismo `chat_offset`: se miran y se turnan; al que habla le sale un globito), BARRER (el conserje camina despacio con el trapeador y levanta polvo) y ESPALDA. Van en un nodo `Gente` antes de `Player` (quedan detrás de Kai), un poco más apagados. Sprites de la hoja de Ariel `docs/arte/referencias/npcs_fondo_concepto.webp` con `tools/art/extraer_personajes_concepto.gd -- npcs_fondo` → `assets/art/characters/npcs_fondo/` (`npc.json`). La profesora camina solo con los cuadros de blusa blanca (otro tenía cárdigan morado), la chica f2 con dos pasos (el tercero tenía una media oscura) y al conserje `clip` le quita la sombra del suelo y el polvo pintado (`refill` borra el fondo que quedaba entre la pierna y el trapeador). En la **Entrada**: una pareja que charla y el conserje; en el **Pasillo**: una chica en los casilleros, dos chicos que charlan y la profesora. El laboratorio y el pasillo viejo quedan vacíos (a propósito) |

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

`world/zones/pc_profesor/escritorio.tscn`: **nivel de SPAM** dentro de la computadora del profesor (3920 px, solo caminar
y saltar). La salida izquierda vuelve al laboratorio (entrada `desde_pc`, también con materialización).

**Aspecto del escritorio (concepto de Ariel, `docs/arte/referencias/escritorio_entidad_concepto.webp`):** `escritorio_fondo.gd` dibuja una pantalla clara invadida por la entidad, en rosa: columnas de binario que caen y cambian, código hex, terminales que se escriben solas, paneles «ANALIZANDO», circuitos con pulsos y cuadritos; solo dibuja lo que está en pantalla. Los íconos del escritorio están corruptos (glitch de color, franjas y nombres dañados). `entity_eye.gd` (`EntityEye`): el ojo de la entidad en un monitor con el panel «OBSERVANDO»; acompaña a la cámara, mira hacia Kai y a veces hacia otros lados, parpadea, y al acercarse Kai a la terminal se cierra y desaparece; desde el paso `cambiar_contrasena` ya no está. El brillo `SoulGlow` de Kai se bajó a 0,35 para el fondo claro.

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
| Arena | 2992–3920 | Combate contra la «Contraseña débil»: pop-ups, anuncios trampa y lluvia de correos solo durante la pelea |

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
("E: cambiar la contraseña"; el combate con la Nullblade es H4c).

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

**Jefe del prólogo: la «Contraseña débil»** (`world/zones/pc_profesor/password_fight.gd`, `PasswordFight`; el jefe es
`characters/enemies/weak_password_boss/`, `WeakPasswordBoss`; hoja general de Ariel `docs/arte/referencias/jefe_contrasena_debil_concepto.webp`).
**Sprites:** la hoja de Ariel `docs/arte/referencias/jefe_contrasena_sprites.webp` (fondo verde) recortada con `tools/art/extraer_jefe_contrasena.gd` → `assets/art/characters/jefe_contrasena/` (`jefe.json` + tiras): quieto, caminar, preparar, embestir, agachado, daño, muerte y alerta, Cada fila de la hoja está dibujada a otra escala: la herramienta las iguala (la ventana "123456" mide lo mismo en todas), alinea el torso de todos los cuadros en el mismo punto (no salta ni se corre al cambiar de animación), desvanece las estelas de la embestida y lo pasa a **pixel art como Kai** (paleta común de 28 colores, bordes duros, contorno oscuro de 1 píxel; píxel 1,5 veces el de Kai: `PIXEL_BLOCK`). En el juego se ve al 80 % (`WeakPasswordBoss.SIZE`). La embestida usa los 4 cuadros de «EMBESTIDA (DASH)» de la hoja; las estelas pintadas cambiaban en cada cuadro y parpadeaban, así que la herramienta las borra detrás de las patas (`destreak`: el rosa brillante y las líneas horizontales delgadas) y el juego dibuja las suyas, parejas (`STREAK_ROWS`). Se echa hacia atrás al prepararse, sale disparado, rebota en cada zancada, levanta polvo y deja fantasmas magenta que se desvanecen. Caminar y embestir miran a la derecha en la hoja: la herramienta genera su versión `_izq` espejada pero con el texto de las ventanas rosas al derecho (si no, "123456" se leería al revés).
La pestaña «Cambiar contraseña» (`AccountTab`, paso `cambiar_contrasena`) lo inicia: la cámara va al fondo de la arena, aparece una
ventanita "123456" que dice «Tú no deberías poder vernos», **decenas de ventanas de error se juntan y forman el jefe** (`assemble()`),
la cámara vuelve a Kai, la Nullblade se materializa (`NullbladeReveal`, sin tarjeta; al reintentar no se repite y el armado es corto)
y aparece su **barra de vida** (`ui/hud/boss_bar.gd`, `BossBar`: ícono, nombre, marca de la fase 2 y estela blanca).
Encima del sprite se dibujan la ventanita y las ventanas de error de la aparición (el jefe se arma desde los píxeles con `pixel_dissolve`), la estela de la embestida,
«ACCESO DENEGADO» y los fragmentos de código. En la fase 2, glitch en franjas (`world/effects/glitch_slices.gdshader`). **24 de vida**, rango `JEFE` (`jefe:contrasena_debil`, 150-250 Ecos una sola vez), no lo empujan los golpes.
Ataques: **camina** hacia Kai para presionarlo, **embiste** en línea recta (avisa: la pantalla se pone roja; el choque quita un cristal) y
lanza **ventanas de contraseñas** (`PasswordWindowShot`, hija de `PasswordGuess`, como en la hoja de concepto: borde de neón rosa que brilla, "qwerty"/"123456"… o un candado, estela punteada; en la fase 2 alterna disparos rectos y en arco). Tras la embestida **choca y queda agachado** (`CROUCHED`, más bajo): ahí se le puede hacer
**pogo**, que le quita el doble (¡CRÍTICO!). **Fase 1** (100-50 %): alterna embestida y proyectiles, lento. **Fase 2** (50-0 %): «¡VENTANAS
INESTABLES!», tiemblan y parpadean, todo ×1,3 y al levantarse del choque dispara enseguida (combina sus ataques).
Una `ArenaBarrier` (`world/digital/`, un pequeño firewall) cierra la **arena** (~930 px): 3 pop-ups para saltar (uno sube y baja),
3 anuncios trampa y una lluvia de correos suave (`MailRainFight`, uno cada 1,8 s, en `fight_hazards`) que **solo cae durante la pelea**.
**Al ganar:** todas sus ventanas muestran **«ACCESO DENEGADO»** y explotan en píxeles magenta; el cuerpo se deshace en fragmentos de código
(`death_finished`). La Nullblade parpadea en la mano de Kai, él la aprieta y **se deshace en partículas violetas** (`world/effects/nullblade_fade.gd`,
`NullbladeFade`; le quita el arma): «¿Eh...? ¿A dónde se fue?». Intenta invocarla (`try_summon`) y no pasa nada: «Genial... justo cuando
empezaba a acostumbrarme». El jefe deja el **primer fragmento de vida** (vuela hacia Kai), habla el profesor y el paso pasa a
`elegir_seguridad` (H4d; ahí llega la Visión Digital). Si Kai muere, el combate se cancela, reaparece en `RestorePointFinal` y puede reintentarlo.

**Fragmentos de vida** (`GameState.life_fragments`, `add_life_fragment()`): pedazos rotos (un cuarto) de un cristal de integridad.
Con **4** (`LIFE_FRAGMENTS_PER_MASK`) se forma una **vida nueva** llena (`max_masks` + 1). Se guardan en la partida. En el mundo:
`world/pickups/life_fragment.gd` (`LifeFragment`: flota, vuela hacia Kai, se recoge una sola vez con un flag). Al tocarlo aparece la ventana
`ui/rewards/life_fragment_window.gd` (`LifeFragmentWindow`, pausa el juego): «¡Has obtenido un fragmento de vida!» y [E] Reclamar; al reclamarlo
el pedazo entra en el cristal de vida en negro y explica que se necesitan 4 y dónde encontrarlos. Reclamarlo suma el fragmento y desbloquea su página
del Grimorio (flag `fragmento_vida_obtenido`).
No aparece en el HUD: se ve en el **INVENTARIO** del Grimorio (`ui/rewards/life_fragment_icon.gd`, `LifeFragmentIcon`: el cristal de vida en negro que se va llenando).

**Desafíos de elección** (`systems/challenges/`, `ui/challenges/`): un `ChoiceChallenge` (en `data/challenges/`) tiene
preguntas (`ChoiceQuestion`) con opciones (`ChoiceOption`: texto, detalle, si es correcta y su explicación).
`ChoiceWindow` las muestra: una opción incorrecta explica por qué y queda descartada; la correcta habilita «Continuar».
Cuenta los errores por pregunta (`mistakes`) para registros futuros. Funciona con teclado, mando, mouse y pantalla táctil.

**Contraseña creada por el jugador** (`systems/security/password_rules.gd`, `ui/challenges/password_window.gd`):
`PasswordRules.evaluate()` revisa 4 reglas (larga, no de las más usadas —también con trucos como `P@ssw0rd`—, sin datos
personales, sin secuencias ni repeticiones) y estima la fortaleza (nivel, bits y tiempo para adivinarla); `suggest()`
arma una frase de 4 palabras al azar y `backup_code()` un código de respaldo. **Entrada segura:** `sanitize()` deja solo
letras (también ñ y con tilde), números, espacios y `! @ # $ % ^ & * ( ) - _ = + . , ; : ? / ~`, hasta 64 caracteres;
quita lo que parece código o etiquetas (< > [ ] { }, comillas, acento grave, barra vertical y barra invertida), saltos de línea, tabulaciones y caracteres
invisibles mientras se escribe. El campo no permite copiar, pegar, arrastrar ni sugerencias del teclado del celular, y
el juego queda en **pausa** mientras la ventana está abierta. `GameState.set_password` vuelve a validar (`is_clean`) y
rechaza cualquier otra cosa sin tocar la partida. La contraseña nunca se ejecuta ni se interpreta: solo se calcula su
huella. **Flechas:** en `PasswordWindow` y `ChoiceWindow` las flechas (o el mando) se mueven entre el campo y los
botones (no por el texto); Enter activa. `PasswordWindow` tiene 3 pasos: crearla
(medidor en vivo, mostrar/ocultar, «Sugerir frase»), confirmarla y anotar el código de respaldo. **Solo se guarda la
huella** (SHA-256 con sal) en `GameState` (`set_password`, `check_password`, `check_backup_code`, `has_password`): ni el
archivo de guardado contiene la contraseña. El jugador tendrá que recordarla en el **capítulo 4** y en **misiones
extra** (`GameState.check_password(&"profesor", intento)`).

**Final de la misión** (`account_security.gd`, `AccountSecurity`, paso `elegir_seguridad`): primero el jugador **crea**
la contraseña del profesor (`PasswordWindow`, paso 1 de 2; si cierra en el paso 2 no tiene que crearla otra vez) y luego
elige el método de verificación en dos pasos (desafío `cuenta_profesor_seguridad`, paso 2 de 2). Al terminar: diálogo, Visión
Digital desbloqueada, el destello de la Nullblade se apaga (`nullblade_stage` sigue en 0), la misión se completa
y Kai vuelve al laboratorio (entrada `desde_pc`).

**Primera terminal** (PC del profesor, paso `revisar_configuracion`): encontrar y leer
`~/cuenta/configuracion.txt` (contraseña 123456, sin verificación en dos pasos). Alineada con indicadores de
décimo de la tabla del MEP 2025 (Operaciones ciberseguras): seguridad en sistemas operativos de código abierto y
conceptos básicos de gestión de contraseñas.

**Archivos ocultos y carpetas protegidas (H5):** los nombres que empiezan con «.» no aparecen con `ls`, sí con `ls -a`
(que muestra también `.` y `..`; otra opción da «opción inválida», como en Linux). Un `TerminalChallenge` puede tener
`protected_folder`: ver o abrir su contenido oculto devuelve `"password": true` y la `TerminalWindow` muestra
`password_options` (flechas y Enter, o 1/2/3; Esc cancela). La correcta llama a `CommandInterpreter.unlock()` y
repite el comando; cada opción explica por qué sí o por qué no. Tab no completa lo oculto sin la contraseña.
`goal_file` puede ser una ruta absoluta. Al resolver una terminal se ocultan los botones de comandos.

**Seguridad de la entrada (sanitización):** `CommandInterpreter.unsafe_reason()` revisa cada línea antes de
interpretarla. Solo se aceptan letras y números sin tilde, espacios y `. _ - / ~`, hasta `MAX_LINE` (120)
caracteres (la `LineEdit` tampoco deja escribir más). Todo lo demás (`;` `&&` `|` `$()` comillas invertidas `>` `<`
`*` `?` comillas, saltos de línea, tabuladores, caracteres invisibles o de ancho completo, BBCode) se rechaza con
«Entrada rechazada: …» sin ejecutar nada ni quedar en el historial. Además, la terminal es una simulación: no hay
`OS.execute` ni acceso a archivos reales (`test_terminal` lo comprueba), y su sistema de archivos solo contiene los
datos de esa terminal, así que rutas como `/etc/passwd` o `../../..` no llevan a nada.

**Solo lo que pide la misión:** cada `TerminalChallenge` tiene en `allowed_commands` exactamente los comandos de su
misión, con sus opciones (`"ls -a"`). Cualquier otro comando u opción responde «`<comando>`: comando inejecutable», y
`help`, Tab y los botones solo muestran los permitidos. Cada terminal tiene solo los archivos que necesita:
- PC del profesor: `help`, `ls`, `cd`, `cat`; solo `cuenta/configuracion.txt`.
- LAB 2: `help`, `ls`, `ls -a`, `cd`, `cat`; `LEEME.txt`, `/home/alvarado/notas.txt` y `.puerta/codigo.txt`.

## Guardado (`autoload/save_manager.gd`, `systems/save/`, `world/digital/save_point.gd`)

**3 ranuras independientes por identidad** (`IdentityManager`), en `user://partidas/<identidad>/ranura_N/`
(`partida.sav`, `partida.respaldo.sav` y el temporal `partida.sav.tmp`). Cada ranura guarda todo el progreso
(`GameState.to_dict()`), dónde continuar y sus metadatos (id de la partida, revisión, tiempo jugado, año, capítulo,
nivel, lugar). Formato v2 de `SaveSerializer` (JSON con huella de integridad), revisado por `SaveValidator` y adaptado
por `SaveMigrator`. Escritura segura: temporal → verificación → la principal pasa a respaldo → el temporal pasa a
principal; al cargar se elige la mejor copia (principal, temporal más nuevo o respaldo). Diseño completo en
`arquitectura/SISTEMA_USUARIOS_STEAM.md`.

**Computadora segura** (`SavePoint`, un `Interactable`): monitor verde con un escudo (distinto de las terminales y de los
nodos de Aegis). Al pasar queda como **punto de control** (si Kai muere, reaparece ahí); con **E** guarda la partida y
llena los cristales y la energía. Por ahora hay una en la Entrada del colegio. En la PC del profesor (prólogo y combate) **no hay
computadoras de guardado**: solo puntos de restauración (`RestorePoint`), que son puntos de control al pasar. El menú principal muestra **CONTINUAR** si hay una partida guardada.

## Mapa del mundo (`systems/world/`, `data/world/`)

Plan aprobado del mapa 2D semi-procedural, tareas **M1–M8**. **M1 (hecho): el modelo de datos.**

- **`RoomTemplate`** (`data/world/rooms/*.tres`): la ficha de una escena de sala, separada del dibujo: id, nombre,
  escena, tipo (`corridor`, `classroom`, `library`, `stairs`…), distrito, **tamaño en celdas** de la cuadrícula del mapa,
  puertas, si es fija o secreta, peso de aparición, dificultad, habilidades mínimas para recorrerla, capítulo, enemigos,
  objetivos educativos y misiones. `validate()` encuentra fichas mal hechas; `RoomTemplate.load_folder()` carga todas
  (también en el juego exportado). Hoy hay fichas de la Entrada, el Pasillo, el Laboratorio y la PC del profesor
  (distrito `pc_profesor`, se entra por la computadora, sin puertas).
- **`DoorSpec`**: una puerta de la ficha: id, **lado** (izquierda, derecha, arriba, abajo), **celda** de la sala,
  **clase** (paso, puerta, escalera, ascensor, secreta) y la `RoomEntry` donde aparece Kai al llegar. Las escaleras y
  ascensores van arriba o abajo; las puertas, a los costados; un paso secreto solo se abre hacia un paso o una puerta.
- **`RoomGraph`** (código puro, sin escenas): las salas colocadas en celdas (sin chocar) y las conexiones entre puertas.
  Solo conecta puertas **enfrentadas** (celdas vecinas, lados opuestos) y de **clases compatibles**. Cada conexión puede
  pedir habilidades (`&"dash"`, `&"double_jump"`, `&"wall_jump"`, `&"vision"`) y ser de **un solo sentido** (atajos);
  un paso secreto pide la Visión Digital solo. `target_of()` dice a dónde lleva una puerta, `open_doors()` las que
  quedan sueltas, `reachable()` / `find_path()` recorren según las habilidades (`RoomGraph.abilities_of(GameState)`),
  y `to_dict()` / `from_dict()` lo guardan (también en JSON); un grafo de otra versión o que ya no encaja no se usa.

**M2 (hecho): el mapa en el juego, todavía fijo.**

- **`DistrictLayout`** (`data/world/districts/*.tres`): la parte fija de un distrito: sus salas (`LayoutRoom`: id único
  en todo el mundo, ficha y celda), sus conexiones (`LayoutLink`: puertas, habilidades, un solo sentido) y la sala de
  inicio. `build()` arma el `RoomGraph`. Hoy: **Colegio** (Entrada ↔ Pasillo ↔ Laboratorio) y **PC del profesor**.
- **`World`** (autoload): carga fichas y distritos, sabe la sala actual (`current_room`, `current_district`, señal
  `room_entered`) y responde `destination(sala, puerta)` → `{room, scene, entry}`.
- **`Room.room_id`**: al cargarse, la sala avisa a `World` con el id con que se llegó (`SceneManager.go_to_room(escena,
  entrada, room_id)`) o, si no hay (p. ej. al continuar una partida), se busca por la escena.
- **`RoomExit.door_id`**: si la sala está en el mapa, la salida le pregunta el destino a `World`; si no, usa
  `target_scene` / `target_entry`, que quedan como respaldo. `test_world` comprueba que ambos coinciden.
- Las marcas `visitada_<escena>` siguen igual (las usa el mapa del Grimorio hasta M5).

**M3 (hecho, junto con H5):** ✅ Pasillo y Laboratorio son dos salas. ✅ **Pasillo viejo** (`pasillo_viejo.tscn`,
960 px, 2 celdas): al fondo del Laboratorio, con las baldosas y objetos de Ariel más oscuros y arte provisional por
código (`old_hallway_props.gd`: cajas, sillas, telarañas, la puerta «LAB 2» con cinta). ✅ Cuarto viejo (H5).
✅ **Escaleras y biblioteca** (arte provisional por código, hasta que Ariel las dibuje):

- **`Stairway`** (`world/rooms/stairway.gd`): una escalera entre pisos. Es como una salida (`door_id`, respaldo
  `target_scene` / `target_entry`), pero se usa con **E** («E: subir» / «E: bajar») y se dibuja sola (el hueco con los
  escalones y un cartel). `RoomExit.destination_of()` y `RoomExit.travel()` son comunes a las dos. También sirve de
  **puerta de un aula** en la pared del fondo: `action_text` («entrar», «salir») cambia el aviso y `show_art = false`
  no dibuja nada (el arte es otro nodo, p. ej. `door.png`). Así se entra a la **Sala 3** desde el Pasillo.
- **Escaleras** (`escaleras.tscn`, ficha `escaleras`: tipo `stairs`, 1 × 2 celdas, 640 px de ancho): se entra desde la
  escalera del **Pasillo** (puerta `escalera`, clase escalera, hacia arriba). Kai sube saltando de descanso en descanso
  (plataformas de un solo sentido, 58–62 px de alto: alcanza el salto simple) y arriba sale a la biblioteca. Arte:
  `stairs_props.gd` (descansos, tramos, baranda, ventanas, carteles «1° PISO» y «2° PISO · BIBLIOTECA»).
- **Biblioteca** (`biblioteca.tscn`, ficha `biblioteca`: tipo `library`, 2 × 1 celdas): estanterías con libros (las
  bajas sirven de plataforma), mesas de lectura, el mostrador con una computadora y una ventana grande
  (`library_props.gd`). Todavía no tiene contenido de historia: lo pondrá el Capítulo 1 (consultar la Biblia).
- En el mapa del Colegio: Pasillo (1,0) ↑ Escaleras (1,−2)–(1,−1) → Biblioteca (2,−2)–(3,−2).
- **El mapa se abre por capítulos:** `RoomTemplate.chapter_requirement` ya se usa. `World.lock_reason(sala)` dice por
  qué no se puede entrar todavía; el capítulo actual sale de `ProgressTracker.chapter()` (0 = prólogo, 1 desde
  `tutorial_terminado`, después la última marca `capitulo_N`). Las escaleras y la biblioteca piden el Capítulo 1: en el
  prólogo la escalera del Pasillo avisa «Por ahora no se puede pasar por aquí. (Se abre en el Capítulo 1)».

**M4 (hecho): el generador, fases A–C y F** (`systems/world/district_generator.gd`, `DistrictGenerator`).

- **A · Estructura fija:** las salas y conexiones del `DistrictLayout`, tal cual.
- **B · Conectividad:** desde la sala de inicio se llega a todas las salas; las del prólogo (capítulo 0), sin
  habilidades.
- **C · Salas opcionales:** de las puertas que quedan libres se cuelgan salas de la biblioteca de plantillas (fichas
  `fixed = false`, no secretas, del mismo distrito, `generation_weight` > 0), elegidas al azar según su peso, sin chocar
  y solo entre puertas enfrentadas y compatibles. Una opcional puede abrir otra, hasta `DistrictLayout.optional_rooms`.
  Los ids son `<ficha>_<n>` (p. ej. `aula_1`, `aula_2`: la misma escena, dos salas distintas del mapa).
- **F · Validación:** conexiones, compatibilidad y vecindad de puertas, salas alcanzables, prólogo sin habilidades,
  escena y punto de aparición de cada puerta usada, opcionales a 3 puertas como mucho de una obligatoria. Si falla, se
  rearma solo la parte variable (hasta 8 tiradas); la fija nunca se toca. Si se agotan, queda solo la parte fija (la
  distribución de respaldo). Si la parte fija está mal, el distrito no se arma (error de datos).
- **Determinista:** `RandomNumberGenerator` con la semilla `hash("semilla|distrito|versión")`. `World.reset()` arma cada
  distrito con `World.world_seed`; `new_world()` y `from_dict()` fijan la semilla antes de armar. Misma semilla y misma
  versión = mismo mapa (también al cargar la partida). D (secretos) y E (contenido) llegan después.
- **Colegio:** `optional_rooms = 2`. La biblioteca tiene una puerta libre al este; ahí el generador cuelga un **aula**
  (`aula.tscn`, puertas oeste y este, peso 2: puede seguir otra sala) o un **depósito** (`deposito.tscn`, solo oeste,
  peso 1, con cajas que sirven de plataforma). Resultados posibles: aula → aula, aula → depósito o depósito. Arte
  provisional: `classroom_props.gd` y `storage_props.gd`. Ambas piden el Capítulo 1.
- Una puerta que el generador deja libre queda **cerrada** (`RoomExit.closed_message`: «La puerta está cerrada.»).
  Las salidas hacia salas opcionales no tienen respaldo (`target_scene` vacío): solo el mapa sabe a dónde llevan.
- **La partida guarda la sala del mapa** (`ubicacion.sala`), porque dos salas pueden usar la misma escena; al continuar
  se vuelve a esa sala. Las partidas anteriores no la tienen (se busca por la escena, como antes).
- Pendiente (M6): guardar el grafo armado en la partida, para que sumar fichas nuevas en una actualización no cambie el
  mapa de una partida existente (hoy el mapa sale de la semilla y de las fichas actuales).

**M5 (hecho): el mapa del Grimorio** (`ui/menus/grimorio/grimorio_map.gd`) se dibuja con el mapa real (`World`): el
grafo del distrito, con sus salas en la cuadrícula (también las del generador) y sus conexiones (las escaleras con
peldaños). Estados (`GrimorioMap.State`): **desconocida** (no se dibuja), **descubierta** (conectada con una visitada:
gris con «?»), **se abre más adelante** (descubierta pero de un capítulo que no empezó, `World.lock_reason`: rayada con
candado), **visitada** (con nombre) y **completada** (visitada y con todas sus `mission_ids` terminadas: marca verde).
Marca las terminales (`RoomTemplate.has_terminal`) y dónde está Kai (rombo cian). Visitada = `World.visited` o, en
partidas anteriores, la marca `visitada_<escena>`. El título sale de `World.district_names`. El mapa no se mueve al
explorar: siempre se encuadra con todas las salas del distrito.

**H5 · El cuarto viejo** (misión `cuarto_viejo`, empieza sola al terminar `contrasena_profesor`):
1. `hablar_profesor`: el profesor invita a Kai al pasillo viejo (`profesor_invitacion.tres`). Cuidado con la Biblia:
   no explica qué hay en el cuarto ni el origen de la Nullblade o del Grimorio.
2. `ir_pasillo_viejo`: la puerta del fondo del Laboratorio (`RoomExit` con `requires_quest` / `requires_step`) está
   cerrada hasta la invitación. Al llegar, un `QuestTrigger` con `on_ready` muestra el comentario de Kai (ahora
   `on_ready` también muestra su diálogo).
3. `abrir_puerta`: con la Visión Digital aparece una nota (`world/vision/vision_note.gd`, grupo `digital_only`,
   dentro de la capa digital para que brille) con la pista «ls -a». La terminal de la puerta
   (`data/terminals/puerta_lab2.tres`, sesión `invitado`) tiene la carpeta protegida `/home/alvarado`: `ls -a` (o
   entrar a lo oculto) pide la contraseña de la cuenta y se elige entre 3 (`password_options`, `ChoiceOption`):
   **123456** abre (el equipo viejo nunca se actualizó); «la contraseña nueva que creaste (••••••••)» y «PAlvarado»
   explican por qué no. La nueva no se muestra: solo se guarda su huella. Al leer `.puerta/codigo.txt` se abre la
   puerta «LAB 2» (se dibuja entreabierta) y se aprende `ls -a`, con su página del Grimorio.
4. `explorar_cuarto`: el **cuarto viejo** (`cuarto_viejo.tscn`, 720 px) está a oscuras (el color lo pone
   `DigitalWorld.physical_ambient`; Kai lleva un brillo tenue). Con la Visión Digital se ven y se toman dos
   `HiddenRelic` (`world/vision/hidden_relic.gd`, dibujadas en la capa digital): el **Grimorio** (marca
   `GameState.GRIMORIO_FLAG`: desde ahí **G lo abre**; antes no hace nada) y la **Nullblade oficial**
   (`NullbladeReveal` con su tarjeta, `nullblade_stage` 1 y el **dash**; el doble salto se consigue más adelante, Biblia v1.4). Lo maneja
   `world/zones/zone0/old_room.gd`; arte provisional en `old_room_props.gd`.
5. `salir_cuarto`: con las dos, el piso cerca de la puerta se corrompe (`Spikes`, 100 px) y cae un armario (52 px):
   se salta el armario y el piso corrupto se cruza con salto + dash. Al volver al pasillo viejo, un `QuestTrigger` cierra la misión: título
   **«EL DESPERTAR»** (antes salía al terminar `prologo`) y después **«CAPÍTULO 1 · EL ORIGEN DIGITAL»**
   (`Quest.followup_title`), y la marca **`tutorial_terminado`** (`Quest.completion_flag`): desde ahí morir cuesta Ecos.

## Inmersión Digital (Capítulo 1)

`ImmersionPortal` (`world/digital/immersion_portal.gd`): la conexión de un monitor. Solo se ve y se usa con la Visión
Digital activa (se dibuja en la capa digital, como `HiddenRelic`). Con E, Kai la atraviesa con el efecto de
`DigitalDive` y entra a `target_scene` / `target_entry` (o a donde diga el mapa por `door_id`; respeta los capítulos
con `World.lock_reason`). La primera vez reproduce `first_dialogue`, desbloquea la habilidad para siempre
(`GameState.immersion_unlocked`, `unlock_immersion()`; se guarda en `player`, la valida `SaveValidator` y la muestra
«Mi perfil») y la transición dice «INMERSIÓN DIGITAL». La transición es la `LoadingScreen` de siempre: se cierra sola
cuando Kai se materializa en la entrada de destino (`arrival_effect = "materialize"`). No es la Visión Digital: la
visión deja ver; la inmersión deja entrar. Con `requires_quest` / `requires_step` la conexión solo aparece cuando la
historia lo pide.

**El cuarto técnico** (`cuarto_tecnico.tscn`, ficha `cuarto_tecnico`: tipo `technical_room`, Capítulo 1) está en el
2° piso, a la izquierda de las escaleras (celda (0, −2)); se llega saltando a un descanso nuevo arriba a la izquierda.
Su puerta está **cerrada con llave** hasta que el profesor da permiso (`requires_quest = travesuras_en_el_sistema`).
Arte provisional en `technical_room_props.gd`: racks con luces, el servidor del sistema de entrenamiento en rojo, su
monitor (con la conexión de la Inmersión Digital, que aparece en el paso `seguirlos_adentro`) y el cartel «SOLO
PERSONAL AUTORIZADO». Una `RoomExit` cerrada recuerda si Kai quedó parado en ella: si se abre mientras sigue ahí, pasa.

## Persecución digital (Capítulo 1)

La red de entrenamiento (`world/zones/red_entrenamiento/persecucion.tscn`, distrito `red_entrenamiento`, 6752 px):
tres tramos fijos y largos (con huecos de salto + dash, plataformas que se mueven o desaparecen, pinchos y nodos que disparan) que terminan en una zona segura con su checkpoint y su puerta (`ArenaBarrier`). Se llega por la
conexión del monitor del cuarto técnico. Valores en `data/chase/persecucion_cap1.tres` (`ChaseConfig`).

| Pieza | Responsabilidad |
|---|---|
| `DataPlatform` | Bloque de datos de un solo sentido: fijo, que se mueve (con la física) o temporal (al pisarlo parpadea, desaparece y vuelve). Los que se mueven o desaparecen están en el grupo `unsafe_ground` |
| `CorruptionBarrier` | Pared que avanza detrás de Kai (`barrier_speeds`: 130, 107 y 117 px/s, calibradas con el recorrido medido en `test_persecucion`: entre el 85 % y el 97 % de lo que aguanta un recorrido perfecto): quita `barrier_damage` (golpe común, con la invulnerabilidad de siempre), no pasa de la zona segura, `disable()` la apaga para siempre. Al arrancar un tramo empieza `barrier_start_gap` detrás de **Kai**; en las zonas seguras, después de un checkpoint y al reaparecer de una caída retrocede hasta quedar por lo menos `barrier_safe_gap` (260 px) detrás de él: nunca queda encima ni delante |
| `CorruptEmitter` | Nodo corrupto que dispara datos (`DataShot`, siempre con aviso): `SHOOT` en línea recta o `RAIN` (lluvia desde arriba en lugares que rotan). Solo dispara con el tramo corriendo y Kai a menos de `active_range` |
| `EducationalCheckpoint` | Pilar con la pregunta del tramo (`ChoiceChallenge` en `ChoiceWindow`, que pausa el juego); con E se vuelve a abrir |
| `DigitalChaseController` | Une todo: arranca la barrera y el reloj al cruzar el inicio de cada tramo, los detiene en la zona segura, −15 s por respuesta incorrecta, marca `cap1_checkpoint_N` y guarda en la entrada `checkpoint_N`, reintentos con tiempo suficiente (tiempo agotado o muerte), y al terminar apaga la barrera y oculta el reloj |
| `ChaseTimer` | El reloj en el HUD («⏱ 3:42»): rojo y latiendo en los últimos 30 s, «−15 s» al descontar |

Caídas: `Room.fall_damage` (1,5 aquí) y `PlayerDamage.fall_out_of_bounds(damage)`: Kai vuelve a la última plataforma
segura. `PlayerDamage.protected` lo protege mientras la historia lo pide. `Room.player_respawned` avisa al reaparecer
después de morir.

## Jefe doble: Glitch y Chip (Capítulo 1)

La arena (`world/zones/red_entrenamiento/arena_hermanos.tscn`, después del tercer tramo), con el fondo
**Cámara de convergencia** (`ConvergenceChamber`): el fondo de Ariel (`docs/arte/referencias/camara_convergencia_fondo.webp`)
pasado a pixel art con `tools/art/generar_fondo_arena.gd` (640 px de ancho, paleta de 48 colores). La herramienta
borra las plataformas dibujadas (`ERASE`: quedaban muy altas sin doble salto); las del juego (`DataPlatform`) van
encima: los lados a 72 px del piso (un salto) y la del centro a 60 px de ellos (salto + dash). El piso lo pone el
dibujo (`FloorVisual.drawn = false`). El anillo empieza apagado y se enciende en la Fase 2; en el Remolino doble
los gemelos suben a él y giran por el aro. Valores en `data/bosses/chip_glitch.tres` (`DualBossConfig`). Diseño de Ariel:
`docs/arte/referencias/glitch_chip_concepto.webp` (los ataques) y el diseño nuevo de los gemelos `glitch_chip_v2.webp`, con Glitch en el rojo de su paleta nueva (`glitch_rojo.webp`:
#FF454F; la herramienta gira el tono con `hue_shift`, y sus ataques y su caja de diálogo usan ese rojo),
de cuya fila «Sprites base» salen sus animaciones en pixel art (quieto, caminar, correr, saltar, caer y aturdido)
con `tools/art/extraer_personajes_concepto.gd -- hermanos_juego`. Los ataques son cuadro por cuadro, de las hojas `glitch_ataques.webp` y `chip_ataques.webp` (`-- glitch_ataques chip_ataques`: filas `rows` ubicadas por el número de cada cuadro, con la silueta cerrada `close` porque el traje negro es del color del fondo y el resplandor semitransparente `soft_glow`): por ataque, `<ataque>_aviso`, la acción y `<ataque>_fin` (`SiblingBoss.ATTACK_ANIMS`, `attack_pose`, `show_recovery`; las animaciones de ataque arrancan desde su primer cuadro y no se repiten). Los ataques en conjunto (`ataques_conjunto.webp`) usan las de cada uno.
El disco sale con `-- hermanos` → `assets/art/characters/hermanos/hd/`. Fuera de los ataques la
animación sale de cómo se mueven (`SiblingBoss.current_pose`); los ataques cambian la pose (`set_pose`). El
movimiento extra (inclinarse, estirarse, temblar, rastros) y los efectos de los ataques los dibuja el juego.
Además de la hoja, los ataques en conjunto toman ideas de Hollow Knight (las Mantis Lords y los Cogwork Dancers):
Danza espejo, Picadas alternas, Discos cruzados, Remolino doble (en el anillo), y sus movimientos clásicos: el
**Barrido** (aparece en una pared y cruza a la altura de Kai, siguiéndolo durante el aviso: `SiblingBoss.barrido`) y la
**Caída** (aparece arriba de Kai y cae sobre él, atravesando las plataformas hasta su altura: `caida`, `fall_to`), solos en la Fase 1 y sincronizados desde la Fase 2 (Tijera,
Doble caída, Caída y barrido). Los gemelos miden 64 px (Kai 92).

| Pieza | Responsabilidad |
|---|---|
| `SiblingBoss` | Base de los dos: vida propia y, en la Fase 3, compartida (`share_health`); vencido antes de la Fase 3 (`knock_down` / `get_up`, `downed`: mareado en el piso, sin atacar ni recibir golpes), `telegraph()` (un «!» de su color) antes de cada ataque, aturdido con `stagger_hits` golpes seguidos (`incapacitated` / `recovered`), proteger al hermano (`guard_for`), `blink_to` / `jump` / `walk_to` / `dash_across` / `hold_at`, el Salto en picada (lo hacen los dos), la pose del sprite (`set_pose`), `frozen` (fase segura), `tempo` y `telegraph_scale` (Fase 3), `restore()`. **Nunca mueren:** con la vida en cero quedan neutralizados (mareados) y no se borran |
| `GlitchBoss` | Corte acelerado, Salto en picada (marca el piso), Embestida en cadena y Lanzamiento de fragmentos (`DataShot` rosa, alargado); queda vulnerable después de atacar; protegiendo a Chip, contraataca si Kai se acerca |
| `ChipBoss` | Discos orbitales (`DiscShot`: se curvan hacia Kai y vuelven), Zona de control (`ControlZone`: `Player.speed_scale`), Proyecciones (`ChipCopy`: copias que lanzan un disco; un golpe las deshace) y Rayo de sincronía (`SyncBeam`); escudo de la fase segura y escudo de discos protegiendo a Glitch (los golpes rebotan: `HurtboxComponent.hit_blocked`) |
| `DualBossController` | Checkpoint al llegar, introducción, una `BossBar` para cada uno (Glitch arriba, Chip abajo) hasta la Fase 3, donde pelean con una sola «GLITCH & CHIP», nueva y llena (`merge_health`, `DualBossConfig.phase3_health`); hay que vencer a cada uno (`SiblingBoss.knock_down`: el vencido queda en el piso y el otro sigue solo con `GLITCH_SOLO` / `CHIP_SOLO`) y con los dos vencidos se levantan (diálogo `ambos_vencidos`: «Interesante enfoque...»); la Fase 2 empieza según la vida de los dos juntos (`total_health`), secuencias fijas por fase (`PHASE1` / `PHASE2` / `PHASE3`) con los 10 ataques en conjunto (Intercepción cruzada, Corte y respuesta, Sincronización aérea, Cambio de posición, Cadena de proyecciones, Campo Dual: `DualField`, Danza espejo, Picadas alternas, Discos cruzados y Remolino doble) y ataques a la vez («a+b»), el vínculo (si uno queda aturdido, el otro deja su ataque y lo protege), Fase 2 (anillo y `Music.set_layer`: la segunda melodía), fase segura del escudo al vencer a los dos (los dos quietos, ataques borrados, `PlayerDamage.protected`, terminal `escudo_chip` y desafío `cap1_escudo_chip`), Fase 3 (Protocolo Dual / Furia fraternal), reinicio si Kai pierde y el cierre (diálogo, `FragmentReading`, recompensa única `capitulo1:hermanos`, salida al cuarto técnico) |

## Capítulo 1 en las salas (nivel 1 y final)

| Pieza | Dónde | Qué hace |
|---|---|---|
| `ClassScene` | Sala 3 (`sala_3.tscn`, ficha `sala_3`: aula fija debajo del Pasillo en el mapa; la conexión `sala_3` ↔ `pasillo` es de clase paso, porque las de clase puerta solo van a los lados; se abre en el Capítulo 1) | La clase (profesor y compañeros de espaldas con `StoryPresence`; computadoras de práctica que fallan: `ClassroomProps.computers` / `glitching`), el registro en la terminal del puesto de Kai (`registro_entrenamiento`) y el desafío «Comportamiento anómalo»; después, una **cinemática** (sin control): Kai mira con la Visión Digital, la cámara va a los monitores, Chip y Glitch se dan cuenta y escapan por la puerta; la cámara vuelve a Kai y empieza la persecución. Pasos: `ir_a_clase` → `revisar_registro` → `ver_fallas` (la cinemática; si se carga la partida en ese paso, se repite) → `seguir_criaturas` |
| `SiblingRun` | Pasillo y escaleras | Persecución corta: los hermanos avanzan cuando Kai se acerca y desaparecen al final del camino. En el Pasillo arranca frente a la puerta de la Sala 3 (al este) y va hasta las escaleras |
| `CatalogScene` | Biblioteca | El archivo privado en el catálogo y el desafío «Un archivo que no es tuyo» |
| `QuestTrigger` (`completes_step = false`, `once_flag`) | Escaleras | Kai piensa en la puerta cerrada del cuarto técnico (una vez) |
| Profesor (`NpcConversation`) | Sala 3 | Recordatorios durante la clase y el permiso para el cuarto técnico («NIVEL 1 COMPLETADO») |
| `TechRoomStory` | Cuarto técnico | El servidor en rojo y los hermanos que se meten en la computadora; al final, la charla con el profesor, Kai se va y, como escena aparte (a negro, «Mientras tanto...», Kai oculto, cámara que se acerca al monitor), el profesor solo ve aparecer `GENESIS_ARCHIVE` (`genesis_dialogue`); «FIN DEL CAPÍTULO 1» sobre esa imagen y Kai aparece en la entrada del colegio (`after_scene` / `after_entry`) |

`SiblingActor` es Chip o Glitch como personaje de escena (sin pelear); `SiblingArt` es su dibujo con los sprites de Ariel (lo comparten con el
jefe). `StoryPresence` muestra u oculta a un personaje según la misión (el profesor del pasillo no está durante el
capítulo). `StoryHelper` reproduce un diálogo con Kai quieto o repite un desafío hasta completarlo. `TerminalStation`
puede usarse en un paso sin completarlo (`completes_step = false`) y avisa con `solved`.

## Misiones (`systems/quests/`)

| Pieza | Responsabilidad |
|---|---|
| `Quest` / `QuestStep` | Recurso con pasos en orden (`id`, `objective`). `completion_title` / `completion_subtitle` (título grande al completarla) y `next_quest` (misión que empieza después) |
| `QuestDB` | Registro id → archivo (`data/quests/`). Cada misión nueva se agrega aquí |
| `GameState` | `start_quest()`, `get_current_step()`, `complete_step(misión, paso)` (solo si es el paso actual), `is_quest_completed()`, `get_objective_text()`. Señales `quest_started`, `quest_step_changed`, `quest_completed`. Se guarda con la partida |
| `NpcConversation` | Lo que dice un NPC en un paso concreto; con `completes_step` completa ese paso al terminar |
| HUD | `ObjectiveDisplay` (OBJETIVO, arriba a la derecha, destella al cambiar) y `TitleCard` (título grande al completar una misión) |

**La contraseña del profesor** (`contrasena_profesor.tres`): entrar a la PC → cruzar el SPAM → revisar la configuración en la terminal → cambiar la contraseña (combate) → elegir la nueva contraseña y la verificación en dos pasos (H4d).

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
| `max_masks` | 4 | Máscaras máximas |
| `dash_level` | 0 | 0–3 (sin dash, Dash, Dash Fantasma, Esquiva Perfecta) |
| `can_double_jump` / `can_wall_jump` | no | Se desbloquean con la historia |
| `vision_unlocked` | no | Visión Digital |
| `nullblade_stage` | 0 | 0 no obtenida · 1 .exe · 2 .zero · 3 .void · 4 .max |
| `aegis_stage` | 0 | 0 no obtenido · 1 Pulse · 2 Bridge · 3 Sync |
| `domain_stage` | 0 | 0 bloqueado · 1–3 Dominio Nulo I–III |

Se modifica solo con funciones que limitan los valores y emiten señales (los Ecos están en `Economy`): `set_dash_level()`, `set_nullblade_stage()`,
`set_aegis_stage()`, `set_domain_stage()`, `set_max_masks()`, `unlock_double_jump()`, `unlock_wall_jump()`, `unlock_vision()`.
Señal: `progress_changed`. Nombres para la interfaz: `DASH_NAMES`, `NULLBLADE_NAMES`, `AEGIS_NAMES`, `DOMAIN_NAMES`.

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
| Grimorio (`ui/menus/grimorio/`, `GrimorioScreen`) | Se abre con **G** durante el juego (`CombatHUD` llama a `GrimorioScreen.open()`): queda encima de la sala, que se pausa; G, Esc o CERRAR lo cierran. No se abre en diálogos ni escenas sin control. El libro (concepto de Ariel en `docs/arte/referencias/grimorio_concepto.webp`) dibujado por código (`GrimorioBook`), pestañas con íconos (`GrimorioTab`; cada una abre la categoría de su `icon_kind`). Tres páginas, como en Hollow Knight (`GrimorioScreen.Page`; arriba `GrimorioNav` con el título y **Q**/**E** para cambiar): el **INVENTARIO** (la principal, `ui/menus/grimorio/inventory_page.gd`, referencia `docs/arte/referencias/grimorio_inventario_concepto.webp`): a la izquierda FRAGMENTOS (vida: un símbolo en cuatro partes, `LifeFragmentIcon`), ENERGÍA (otro símbolo en cuatro, cian: `GameState.energy_fragments`, 4 dan una barrita más), ARMA (la Nullblade grande y en vertical), HABILIDADES (la definitiva en grande y dash, Visión Digital, curación y doble salto) y ECOS (la moneda y la cantidad); en el centro los COLECCIONABLES; a la derecha la descripción de lo elegido. Cada entrada de `ARSENAL` dice su zona con `inventory_kind` y su ícono con `icon`; lo que no se tiene se ve apagado o con candado. Con **Q**, el **MAPA** (el libro sin pestañas) y con **E** el **ARCHIVO** (el libro con COMANDOS, CONCEPTOS, AMENAZAS y REGISTROS) y el mapa esquemático (`GrimorioMap`: salas de cada zona en `ZONES`, visitadas según la marca `visitada_<escena>` que deja `Room` o el paso de una misión) |

Para agregar una entrada al Grimorio: copiar un `.tres` de `data/grimorio/`, cambiar textos y desbloqueo. `GameState.has_reached_step(mision, paso)` dice si la misión ya llegó a ese paso.

## Sonido (`systems/audio/`)

| Pieza | Responsabilidad |
|---|---|
| `Sfx` (`sfx.gd`) | `Sfx.play(&"nombre", tono, volumen_db)`. Si existe `assets/audio/sfx/<nombre>.wav/.ogg/.mp3` usa ese archivo; si no, genera un **sonido provisional** por código (`RECIPES`: onda, barrido de tono, arpegio, vibrato, ruido, bitcrush y filtro `lowpass`; `entity_whisper` es un susurro distorsionado con formantes). Los de movimiento son sutiles, al estilo Hollow Knight; el tajo suena con glitch. Bus `SFX` (volumen de Efectos), suena también en pausa, 16 voces. Se crea solo con el primer `play()`; no es autoload. `Sfx.history` guarda los últimos (pruebas) |
| `Music` (`music.gd`) | `Music.play(&"pista")`: busca `assets/audio/music/<pista>.ogg` y la reproduce en bucle con fundido por el bus `Music`; si no existe, silencio. Pistas: `menu`, `colegio`, `computadora`, `pelea`. `Room.music_track` la pide al entrar a la sala. Mientras no haya archivo, `computadora` (donde vigila el ojo) tiene una música provisional generada por código: ambiente oscuro en La menor, en bucle |
| `PlayerSounds` (`characters/player/player_sounds.gd`, nodo `Sounds`) | Pasos (`Room.footstep`: `step_school` o `step_digital`), salto, doble salto, salto de pared, caída, dash, daño + crujido del cristal (+ error con un anuncio trampa), muerte, curación (carga y cada curación), tajo, golpe y energía |
| Otros ganchos | Enemigo herido / desintegración (`EnemyBase`), «fuerza bruta», aviso del correo SPAM, ventanas que se cierran y abren, Ecos (más agudo si se recogen seguidos), cofre, aparición de la Nullblade, tarjeta de equipamiento (fanfarria), monitor del laboratorio (estática, apagón), ojo de la entidad (latido, parpadeo, cierre y un susurro cada tanto), la entidad «???» susurra en cada línea de diálogo, menús (moverse, aceptar, volver), Grimorio (abrir, página, cerrar) y terminal (teclas, enter, error, objetivo cumplido) |
| Voces de diálogo (`DialogueBox._speak`) | Como los NPC de Zelda: mientras se escribe el texto suena una «sílaba» cada `voice_every` letras con la voz del personaje (`DialogueCharacter.voice`, un sonido de `Sfx`). El tono cambia según la letra (`voice_pitch`, `voice_variation`), así una frase suena siempre igual. Kai: `voice_kai` (electrónica y juvenil, cada 2 letras); Prof. Alvarado: `voice_profesor` (grave y cálida, cada 3); Contraseña débil: `voice_amenaza`. La narración no tiene voz y «???» susurra. Un personaje nuevo solo necesita `voice` en su `.tres` |

Para reemplazar un sonido: dejar el archivo con el mismo nombre en `assets/audio/sfx/` (ver `assets/audio/LEEME.md`).

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
| `test_background_npcs.gd` | NPC de fondo: cuántos hay en la Entrada y el Pasillo, en el suelo, sin colisión, con sus sprites; la pareja se mira y se turna para hablar; el conserje camina con el trapeador sin salirse de su tramo; la profesora con un solo conjunto de ropa va y viene; la chica del casillero de espaldas |
| `test_vision.gd` | Visión Digital bloqueada, desbloqueo, capa digital, oscurecimiento, puente de datos (capa 7), fragmento (una sola vez), apagado manual, recarga y fin por duración |
| `test_dialogue.gd` | Formato de los diálogos, aviso «E: hablar», caja de diálogo (letra por letra, completar, avanzar, cerrar), controles bloqueados, marca del profesor y recordatorio |
| `test_settings_grimorio.gd` | Ajustes (buses de audio, velocidad del texto, glitch, cambiar y restablecer teclas, guardado), pantalla de opciones (◀ ▶, controles, abrir grimorio) y Grimorio (pestañas, desbloqueo por la historia, «???», mapa) |
| `test_sound.gd` | Los 46 sonidos provisionales se generan, bus de Efectos, salto, caída, pasos, tajo, golpe, enemigo, Ecos, curación, daño, la música y los pasos de la computadora y las voces de diálogo (Kai, profesor, la entidad susurra, la narración en silencio) |
| `test_prologue.gd` | API de misiones (orden, guardado), el prólogo completo con el objetivo en pantalla, la computadora bloqueada antes de tiempo, la visión involuntaria (sin indicador, Q no la controla, sin recarga), «EL DESPERTAR» y el comienzo de la misión del profesor |
| `test_digital_dive.gd` | La computadora absorbe a Kai (cámara, desaparición), pantalla de carga, llegada al escritorio, materialización, alma digital celeste, límites y regreso al laboratorio |
| `test_spam_level.gd` | Pop-ups (fijo, que se cierra y reabre, que se mueve y lleva a Kai), anuncio trampa, correo que cae (y apunta a Kai), ruta completa solo saltando (bot), punto de restauración (activarlo y reaparecer ahí al morir) y llegada a la cuenta del profesor |
| `test_custom_password.gd` | Reglas y medidor (débiles, comunes con trucos, datos personales, repeticiones, frases fuertes), frases sugeridas, código de respaldo, guardado de solo la huella (con sal) y la ventana para crearla |
| `test_account_security.gd` | Desafío de elección (opción incorrecta con explicación, correcta, avanzar), contenido educativo, y el final de la misión: Esc, Visión Digital, Ecos, destello de la Nullblade que se apaga, vuelta al laboratorio y Q |
| `test_death.gd` | El ataque hacia abajo tiene su propia pose; al morir: aturdido, de rodillas y desplomado en orden, pantalla «CONEXIÓN PERDIDA...», reaparece en el punto de control con la vida llena, entero y con el control |
| `test_pogo.gd` | Cadencia de 0,45 s; abajo + J en el suelo ataca adelante; en el aire ataca hacia abajo y rebota en un enemigo (lo daña; el doble salto vuelve recién al tocar el suelo), en los pinchos (sin daño) y en un nodo de rebote; sin nada debajo no rebota |
| `test_ataque_arriba.gd` | Arriba + J: ataca hacia arriba en el piso y en el aire, golpea al enemigo sobre la cabeza y no al de adelante, pose del pogo con la espada hacia arriba, sin retroceso; sin arriba, el ataque de siempre |
| `test_combat.gd` | Ataque de Kai (sin arma no ataca, dirección, una vez por tajo, enfriamiento, animación), «Contraseña débil» chica (daño, empuje, fuerza bruta, muerte, contacto de medio cristal, salto hacia Kai) y el jefe en la PC (se arma, la Nullblade como destello, barra de vida, barrera, perder y reintentar, ganar: la Nullblade se va, el fragmento de vida, el profesor y avanzar) |
| `test_boss.gd` | El jefe: ventanita al principio (sin golpes), se arma, camina hacia Kai, avisa y embiste, choca y queda agachado (más bajo), el pogo crítico, proyectiles, fase 2 con la mitad de la vida, «ACCESO DENEGADO» y desaparece; fragmentos de vida (recoger, HUD, 4 forman una vida) |
| `test_nullblade.gd` | Energía por golpe de la Nullblade (aire, enemigo, escudo, derrota, dos enemigos, cargado, máximo), pulso de la barra y su página en el ARSENAL |
| `test_room_graph.gd` | M1: fichas de sala válidas (las reales apuntan a entradas que existen), salas sin chocar, puertas que solo conectan enfrentadas y compatibles, caminos según habilidades, atajos de un solo sentido, pasos secretos con la Visión y guardar / cargar el grafo |
| `test_cuarto_viejo.gd` | H5 completo: la misión, la puerta cerrada del Laboratorio, la invitación, el pasillo viejo y su nota, la terminal con la contraseña, el cuarto a oscuras con el Grimorio y la Nullblade, el derrumbe (armario bajo y piso corrupto que se cruza con salto + dash, sin doble salto) y el cierre: «EL DESPERTAR», Capítulo 1 y fin del tutorial |
| `test_world.gd` | M2: distritos fijos, a dónde lleva cada puerta, las salidas de las escenas (y las escaleras) coinciden con el mapa y `World` sabe la sala actual al cambiar de sala |
| `test_capitulo1_datos.gd` | Capítulo 1, etapa 1: misiones y su orden, diálogos con oradores conocidos y los textos de la especificación sin cambios, desafíos con una sola respuesta correcta y explicación, páginas del Grimorio, voces de Chip y Glitch, y ningún texto que revele el origen de Kai |
| `test_inmersion.gd` | Capítulo 1, etapa 2: la conexión del monitor solo con la Visión Digital, la primera vez con diálogo y la transición «INMERSIÓN DIGITAL», la habilidad permanente (partida, validador, «Mi perfil», Grimorio) y la segunda vez sin repetir nada |
| `test_cuarto_tecnico.gd` | Capítulo 1, etapa 3: el cuarto técnico en el mapa, el descanso nuevo de las escaleras con la física real, la puerta cerrada con llave hasta el permiso del profesor (y que se abra con Kai parado ahí), la conexión del monitor solo cuando la historia lo pide, la vuelta y continuar una partida guardada ahí |
| `test_persecucion.gd` | Capítulo 1, etapas 3 a 6: los tres tramos con la física real y solo salto + dash (sin doble salto), la barrera (empieza detrás de Kai, 1 por contacto, invulnerabilidad, sin daño en cada cuadro, después de cada checkpoint queda a 260 px detrás y nunca delante), los nodos que disparan (con aviso y dañan), caídas de exactamente 1,5 con vuelta a una plataforma segura, checkpoints (pausa, −15 s, puerta, guardado), tiempo agotado, muerte, cargar sin repetir checkpoints y el final (barrera apagada, reloj oculto) |
| `test_jefe_hermanos.gd` | Capítulo 1, etapas 7 a 11 (Glitch y Chip, diseño de Ariel): checkpoint y sin temporizador, una barra para cada uno, vencer a cada uno (el vencido queda aturdido y el otro sigue solo) y una sola barra nueva en la Fase 3, los 8 ataques individuales y los 10 en conjunto con su aviso y sus animaciones cuadro por cuadro (aviso, acción y recuperación), el vínculo (el otro protege al aturdido), las tres fases (anillo y segunda melodía en la 2, fase segura con terminal al vencer a los dos, Protocolo Dual / Furia fraternal), hermanos que no se borran, recompensa única, reinicio si Kai pierde y la arena ya ganada |
| `test_capitulo1_historia.gd` | Capítulo 1, la historia de punta a punta: el prólogo lleva al capítulo, la Sala 3 (cerrada en el prólogo; se entra y se sale por su puerta con E), la clase, el registro y su desafío, la cinemática de los hermanos (Visión, cámara, escape), la persecución corta, la biblioteca, el permiso («NIVEL 1 COMPLETADO»), el servidor y el final con `GENESIS_ARCHIVE` («FIN DEL CAPÍTULO 1») |
| `test_grimorio_map.gd` | M5: el mapa del Grimorio con el mapa real: salas desconocidas, descubiertas, cerradas hasta su capítulo, visitadas y completadas; las salas del generador; partidas viejas (marcas `visitada_<escena>`) y el libro abierto en el mapa |
| `test_generador.gd` | M4: con fichas de prueba, la parte fija intacta, misma semilla = mismo mapa, 40 semillas válidas y distintas, solo puertas compatibles, respaldo si la parte variable no valida y error si la fija está mal; con los datos reales, aula o depósito al este de la biblioteca, el mapa se rearma igual al cargar, dos aulas con la misma escena, la puerta libre cerrada y continuar en la misma aula |
| `test_biblioteca.gd` | M3: escaleras y biblioteca en el mapa, cerradas hasta el Capítulo 1, Kai sube los descansos con la física real y sin doble salto, ida y vuelta entre Pasillo, escaleras y biblioteca, estanterías como plataforma y continuar una partida guardada en la biblioteca |
| `test_autosave.gd` | Guardado automático: al avanzar una misión, al obtener una habilidad, al cobrar una recompensa y al salir; nunca sin control, en el aire, en una pelea o en una transición |
| `test_slot_select.gd` | Selección de partida: tarjetas con resumen y estado, cargar solo lo usable, sobrescribir con confirmación, borrar con doble confirmación, posible conflicto y el indicador de guardado |
| `test_profile.gd` | Mi perfil: tiempo total de las ranuras, partida más reciente, habilidades, estadísticas educativas, sin ids ni datos privados, y el botón del menú |
| `test_hardening.gd` | Endurecimiento: mudanza a la carpeta propia sin pisar ni borrar, 150 guardados seguidos, temporal viejo, cambio de identidad en plena partida, tamaño y tiempos de una partida grande |
| `test_save.gd` | Guardar y continuar (todo el progreso), escritura segura con copia, archivos dañados o inválidos, la computadora segura (punto de control al pasar; con E guarda y cura) y CONTINUAR en el menú |
| `test_economy.gd` | Rangos de `EconomyConfig` y sorteo, recompensas únicas (no se cobran dos veces, se guardan), misiones, enemigos por rango y de la historia, cofres aunque se pierda su marca, y fragmentos que se suman al salir de la sala |
| `test_ecos.gd` | Reparto en fragmentos, Ecos según la fuerza del enemigo, desintegración, rebote, recoger al acercarse, HUD, página del Grimorio, cofre (una sola vez y queda abierto) y recompensa de misión |
| `test_entity_eye.gd` | El ojo de la entidad: vigila al entrar, sigue a la cámara, parpadea, se cierra y desaparece en la terminal y no vuelve después de resolverla |
| `test_terminal.gd` | Terminal simulada: sistema de archivos, comandos y errores, autocompletado, comandos permitidos, que no toque el sistema real, y la terminal de la PC del profesor (abrir, Esc, resolver, diálogo, paso de misión, comandos aprendidos y guardados) |
| `test_progress.gd` | Progreso inicial, Ecos (validaciones), penalización al morir (10 %, máximo 100, nada en el tutorial), límites, guardar/cargar (también partidas antiguas) y aplicación del progreso al jugador en una sala |
| `test_decision_system.gd` | Datos del incidente de phishing, flujo de investigación, cobro y efectos de las medidas, rechazos (sin evidencia, sin presupuesto, ya resuelto) y guardar/cargar |
