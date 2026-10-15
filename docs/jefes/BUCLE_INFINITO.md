# Jefe: Bucle Infinito (Bucle)

**Capítulo:** 2 — Los primeros códigos · **Nivel:** 4 — Código fuera de control · **Recompensa:** Dominio Nulo I
**Estado:** especificación oficial del equipo (14 de octubre de 2026) y diseño técnico (sección B). **Autorizado e
implementado** (fases 1 a 9; la 9 es Dominio Nulo I, ver B.8): `characters/enemies/bucle/`, `systems/bosses/bucle_*.gd`, `data/bosses/bucle.tres`,
`world/zones/simulador/` y `tests/test_bucle.gd`. Decisiones tomadas (B.11): Bucle en la Biblia v1.5; la arena se
construye sola (zona «Simulador», capítulo 2) hasta que exista el resto del capítulo; sus ataques quitan 1 cristal;
el golpe arriesgado da media barrita de energía. Se prueba abriendo `world/zones/simulador/arena_bucle.tscn` (F6).

**Lección:** *un error pequeño, repetido sin control, puede terminar causando consecuencias enormes.*

---

## A. Especificación (narrativa y de combate)

### A.1 Concepto

Bucle es una pequeña entidad digital creada a partir de un **proceso de automatización defectuoso**. Al principio
parece inocente, amigable y curiosa. Ejecuta una instrucción una y otra vez, pero su ciclo **no tiene una condición
de finalización válida**: al repetirla genera errores, acumula procesos y altera el entorno digital.

Bucle no quiere hacer daño: está atrapado en una tarea que cree que debe completar. **No muere**: queda agotado y
liberado, y puede volver como personaje secundario más adelante.

**Referencia:** la intensidad y la lectura clara de patrones de los metroidvanias modernos (p. ej. *Hollow Knight:
Silksong*), **sin copiar** animaciones, diseños, ataques, música, escenarios, personajes ni recursos. Identidad
propia: la repetición progresiva de instrucciones digitales.

### A.2 Siete impactos clave

- Bucle termina con **exactamente siete impactos clave**; cada uno suma 1 al contador de progreso.
- Se lo puede golpear **durante sus ataques** (peligroso, y recompensado) y **cuando está cansado** (más fácil).
- **Un solo impacto clave por ciclo.** Después: reacción, transición **invulnerable** y un ciclo más difícil.
- Un ataque normal válido de `Nullblade.exe` cuenta como impacto clave si Bucle es vulnerable y todavía no recibió
  el del ciclo. No se exigen siete golpes en descansos; no se pueden encadenar los siete sin pasar por los ciclos.
- No es una barra de vida convencional: **siete segmentos de integridad**. No se rompe el daño de otros enemigos.

### A.3 Estados

| Estado | Qué pasa |
|---|---|
| `INTRO` | Presentación de Bucle y preparación del escenario |
| `PREPARE_PATTERN` | Anuncia la nueva secuencia |
| `EXECUTE_PATTERN` | Ejecuta los ataques del ciclo; se lo puede golpear, arriesgándose |
| `FATIGUE` | Se detiene, cansado: ventana clara de ataque. Si nadie lo golpea, se recupera y **repite el mismo ciclo** (terminar una secuencia no sube la dificultad; la sube recibir un impacto) |
| `HIT_REACTION` | Interrumpe el ataque de forma segura, suma el impacto, apaga los peligros que deban cancelarse, reacciona; no registra otro impacto |
| `TRANSFORMATION` | Acumula más instrucciones visuales, el escenario cambia; empieza el ciclo siguiente |
| `DEFEATED` | Tras el séptimo: termina todo, apaga los peligros, detiene la lógica, final narrativo, jefe completado, recompensa única |

### A.4 Los siete ciclos (valores provisionales, configurables)

| Ciclo | Secuencia | Velocidad | Descanso |
|---|---|---|---|
| 1 | Pulso · Lluvia | base | 2,5 s |
| 2 | Pulso · Lluvia · Anillo | un poco mayor | 2,3 s |
| 3 | Lluvia · Pulso · Anillo (orden cambiado) | | 2,1 s |
| 4 | Pulso · Anillo · Lluvia · Pulso | | 1,9 s |
| 5 | Anillo · Lluvia · Pulso · Anillo | superior | 1,7 s |
| 6 | Pulso · Lluvia · Anillo · Pulso · Lluvia | | 1,5 s |
| 7 | Lluvia · Anillo · Pulso · Lluvia · Anillo | mayor | 1,5 s |

La dificultad sube con más ataques, menos tiempo entre ellos, combinaciones, cambios de orden, de velocidad y del
escenario; **no** subiendo el daño. Las secuencias finales nunca son imposibles de esquivar.

### A.5 Ataques

- **Pulso repetitivo:** una onda recorre el suelo. Se esquiva saltando, subiendo a una plataforma o con el dash.
  Aviso visual antes.
- **Lluvia de instrucciones:** bloques digitales caen desde arriba, con indicador de peligro antes. Más bloques en
  ciclos altos, pero **siempre** con zonas de escape.
- **Ciclo circular:** un anillo de energía se expande desde Bucle. La colisión coincide con lo que se ve.
- **Error de ejecución** (ocasional): altera una plataforma o mecanismo (activar una plataforma temporal,
  desactivar una ruta unos segundos, mover un obstáculo o crear una zona de peligro anunciada). Nunca todas las
  plataformas a la vez; siempre hay rutas de recuperación.

### A.6 Arena

2D lateral, distribución **fija** (no procedural) para las primeras pruebas: suelo principal, dos plataformas
laterales, una plataforma central elevada, espacio para saltar y esquivar, límites claros y cámara del encuentro.
Las plataformas sirven para esquivar las ondas, evitar ataques, acercarse a Bucle, cambiar de posición y crear
oportunidades de ataque. Ningún lugar es seguro para siempre, pero tampoco hay que moverse sin parar: la arena
permite observar y aprender los patrones.

### A.7 Transformación visual

El cuerpo mantiene su tamaño; crece la acumulación de instrucciones a su alrededor.

| # | Nombre | Cómo se ve |
|---|---|---|
| 1 | Inocencia | Un anillo sencillo, colores cálidos, movimiento tranquilo, expresión alegre |
| 2 | Repetición | Dos anillos, más velocidad, expresión confiada |
| 3 | Acumulación | Más instrucciones, primeras señales de cansancio, distorsiones menores |
| 4 | Sobrecarga | Anillos superpuestos, el código afecta plataformas, Bucle confundido |
| 5 | Corrupción | Interferencias, más intensidad visual, Bucle asustado |
| 6 | Descontrol | Muchísimas instrucciones, parte del escenario alterado, Bucle apenas se distingue |
| 7 | Último ciclo | Máxima acumulación, instrucciones fragmentadas, agotamiento, atrapado en el centro |

Siempre se distingue la posición real de Bucle; ningún efecto tapa ataques, plataformas ni zonas seguras.
Opción de accesibilidad para reducir destellos y efectos intensos.

### A.8 Diálogos durante el combate (sin quitarle injustamente el control al jugador)

| Impacto | Bucle |
|---|---|
| 1 | «No pasa nada. Puedo repetirlo». |
| 2 | «Otra vez. Esta vez funcionará». |
| 3 | «¿Por qué sigue fallando?». |
| 4 | «Tengo que terminar...». |
| 5 | «¡NO PUEDO DETENERME!». |
| 6 | «Una vez más... solamente una vez más...». |
| 7 | «¿Ya... puedo descansar?». |

Las transformaciones largas solo ocurren en momentos seguros.

### A.9 Animaciones (placeholders primero)

Idle, introducción, preparación del ataque, pulso, lluvia, anillo, error de ejecución, cansancio, impacto,
recuperación, transformación y derrota narrativa. Recursos provisionales, reemplazables por el arte de Ariel.

### A.10 Relación con el MEP (décimo)

Ciclos de repetición, condicionales, control de flujo, **condiciones de finalización**, reconocimiento y corrección
de errores. Después del combate, un **puzle educativo** para corregir la condición de salida:

```
mientras tarea_pendiente:
    realizar_tarea()
```

Si la condición de salida nunca se cumple, el ciclo sigue para siempre. Todo es una **simulación controlada**: nunca
se ejecuta código del jugador en el sistema operativo.

### A.11 Final narrativo

Tras el séptimo impacto, Bucle queda agotado y los anillos se desintegran.

> **Kai:** Ya terminaste.
> **Bucle:** Pero... la instrucción...
> **Kai:** No tenés que seguir repitiéndola.
> **Bucle:** ¿Y qué hago ahora?
> **Kai:** Podés decidirlo.
> *(Bucle ve que las instrucciones desaparecieron.)*
> **Bucle:** ¿Eso significa que fallé?
> **Kai:** No. Significa que terminaste.

### A.12 Transición a Dominio Nulo I

El simulador se desestabiliza por los procesos acumulados; Kai intenta escapar y una estructura digital bloquea el
camino. Instintivamente activa **EXPANSIÓN DIGITAL: DOMINIO NULO I**: 15 s, +10 % de daño, cuesta 100 de carga,
ralentiza **solo** las amenazas digitales y los proyectiles compatibles (no el tiempo global de Godot ni los
temporizadores de la interfaz). Se enseña en una situación segura y controlada.

### A.13 Validaciones pedidas

1. Empieza en el ciclo 1. 2. Un impacto válido suma exactamente 1. 3. No hay dos impactos en el mismo ciclo.
4. Se puede golpear durante ataques y durante la fatiga. 5. La fatiga llega al terminar un patrón. 6. Sin golpe en la
fatiga, repite el ciclo. 7. Cada impacto sube la dificultad. 8. Los ataques se cancelan al cambiar de estado.
9. Las plataformas mantienen rutas seguras. 10. Todo ataque tiene aviso. 11. El séptimo termina el combate.
12. No hay octava transformación. 13. Sin recompensas duplicadas. 14. El jefe no sigue activo después del final.
15. Los efectos no tapan al jugador. 16. La cámara muestra los peligros. 17. Se reinicia desde un checkpoint.
18. El progreso se guarda. 19. Los estados no se traban por animaciones interrumpidas. 20. Funciona con arte provisional.

---

## B. Diseño técnico propuesto

### B.1 Lo que ya existe y se reutiliza

| Sistema | Pieza actual | Uso en Bucle |
|---|---|---|
| Enemigos | `EnemyBase` (`characters/enemies/enemy_base.gd`): crea cuerpo, `HealthComponent`, `HurtboxComponent` (capa 4: ataques de Kai) y el `HitboxComponent` de contacto; `_on_hit_received()` aplica daño, destello y empuje | `BucleBoss` extiende `EnemyBase` y **redefine** `_on_hit_received()` (solo para Bucle: el resto de los enemigos no cambia) |
| Daño | `HitData` / `HitboxComponent` (`once_per_activation`) / `HurtboxComponent` (`immune`, `hit_blocked`) | Los ataques de Bucle son `HitboxComponent` en la capa 5; los golpes que no cuentan muestran el efecto de «bloqueado» |
| Vida | `HealthComponent` | `max_health = 7`: cada impacto clave quita **exactamente 1**, sin importar el daño del arma (evoluciones de la Nullblade o el Dominio no cambian la cuenta) |
| Jefes | `SiblingBoss` (`_epoch` para cancelar ataques en curso, `telegraph()`), `BossAttacks` (grupo `boss_attack`), `DualBossController` (checkpoint al llegar, `Room.player_respawned` → reinicio, `Economy.claim_reward` único, `ArenaBarrier`, salida) | Mismo patrón: un **token de época** cancela el patrón al ser golpeado; todos los peligros en `boss_attack`; el controlador de la arena copia el flujo de checkpoint, reinicio y recompensa |
| UI | `BossBar.show_for()` | Se le agrega `segments` (7 marcas) para mostrar los siete segmentos de integridad |
| Plataformas | `DataPlatform` (fija, que se mueve o temporal; `force_close`), un solo sentido (S para bajar) | Plataformas laterales y central; el Error de ejecución usa `force_close` en **una** plataforma por vez |
| Diálogos | `StoryHelper.say` / `DialogueBox` (pausa el combate) | Solo en la introducción y el final. Durante el combate, un **globo flotante** sobre Bucle que no quita el control |
| Desafíos | `ChoiceChallenge` / `ChoiceWindow`, `TerminalStation` (intérprete simulado) | El puzle de la condición de salida (simulado, sin ejecutar código) |
| Tiempos | Física (`create_timer(t, false, true)`, tweens en `TWEEN_PROCESS_PHYSICS`) | Todo el combate corre con la física: las pruebas son deterministas |

### B.2 Archivos que crearía

| Archivo | Clase | Qué hace |
|---|---|---|
| `characters/enemies/bucle/bucle_boss.gd` | `BucleBoss` (`EnemyBase`) | Máquina de estados, registro de impactos clave, señales (`state_changed`, `key_hit(count)`, `cycle_started(n)`, `defeated`) |
| `characters/enemies/bucle/bucle_pattern_runner.gd` | `BuclePatternRunner` (`Node`) | Ejecuta la secuencia de un ciclo ataque por ataque; se cancela con el token de época |
| `characters/enemies/bucle/loop_pulse.gd` | `LoopPulse` | Onda por el suelo (aviso → onda que avanza hacia los dos lados) |
| `characters/enemies/bucle/instruction_block.gd` | `InstructionBlock` | Bloque que cae (marca de peligro en el suelo → cae → se rompe) |
| `characters/enemies/bucle/loop_ring.gd` | `LoopRing` | Anillo que se expande con un hueco; la colisión son círculos pequeños sobre el mismo arco que se dibuja |
| `characters/enemies/bucle/bucle_art.gd` | `BucleArt` | Dibujo provisional por código: el cuerpo (mismo tamaño siempre, con contorno) y las 7 etapas de instrucciones |
| `systems/bosses/bucle_cycle.gd` | `BucleCycle` (`Resource`) | Un ciclo: `attacks: Array[StringName]`, `speed`, `fatigue_time`, `telegraph`, `gap_between`, `rain_blocks`, `ring_gap`, `execution_error` |
| `systems/bosses/bucle_config.gd` | `BucleConfig` (`Resource`) | Los 7 ciclos, tiempos de reacción y transformación, daño de los ataques, frases de cada impacto |
| `data/bosses/bucle.tres` | — | Los valores de la tabla A.4 (para equilibrar sin tocar código) |
| `world/effects/speech_bark.gd` | `SpeechBark` | Globo de texto flotante que no pausa ni bloquea |
| `world/zones/simulador/bucle_arena.gd` | `BucleArenaController` | Introducción, checkpoint, barra, Error de ejecución en el escenario, reinicio si Kai pierde, final, recompensa y paso a Dominio Nulo |
| `world/zones/simulador/arena_bucle.tscn` | — | La arena fija (B.6) |
| `data/world/rooms/arena_bucle.tres` | — | Ficha de la sala (capítulo 2) |
| `data/dialogues/capitulo2/bucle_*.tres`, `data/challenges/cap2_condicion_salida.tres` | — | Introducción, final y el puzle |
| `tests/test_bucle.gd` | — | Las pruebas (B.9) |

**Modificaría:** `ui/hud/boss_bar.gd` (opción `segments`), `docs/arquitectura.md` (sección del jefe) y, con
aprobación, la Biblia (B.11).

### B.3 Máquina de estados

```
INTRO ──► PREPARE_PATTERN ──► EXECUTE_PATTERN ──► FATIGUE ──(sin golpe)──► PREPARE_PATTERN (mismo ciclo)
              ▲                 │ golpe válido         │ golpe válido
              │                 ▼                      ▼
        TRANSFORMATION ◄──── HIT_REACTION ◄────────────┘
                                │ impactos == 7
                                ▼
                             DEFEATED
```

- Un único `enum State` y una función `_enter(state)` que hace todo lo de la entrada (sube el token de época,
  arranca los temporizadores). Cada estado temporizado guarda su tiempo restante y lo descuenta en
  `_physics_process`: **nada depende de que termine una animación**, así un estado nunca queda trabado (punto 19).
- **Vulnerable** en `PREPARE_PATTERN`, `EXECUTE_PATTERN` y `FATIGUE`; **invulnerable** en `INTRO`,
  `HIT_REACTION`, `TRANSFORMATION` y `DEFEATED`.

### B.4 Cómo se registra un impacto (y por qué solo uno por ciclo)

`BucleBoss._on_hit_received(hit)` reemplaza la reacción común:

1. Si no está en un estado vulnerable, o `_hit_this_cycle` es `true`: efecto de golpe bloqueado y nada más.
2. Si cuenta: `_hit_this_cycle = true`, `health.take_damage(1.0)` (un segmento), `key_hit.emit(impactos)` y
   `HIT_REACTION`. Si el golpe llegó durante `EXECUTE_PATTERN` es un **golpe arriesgado**: Kai recibe la
   recompensa (propuesta: energía extra para curarse) y se acorta la reacción.
3. `HIT_REACTION` sube el token de época (el patrón en curso se termina solo en su próximo paso) y borra los
   peligros del grupo `boss_attack`.
4. `_hit_this_cycle` vuelve a `false` **recién** al entrar en el `PREPARE_PATTERN` del ciclo siguiente.

Como entre un impacto y el siguiente siempre hay reacción + transformación invulnerables y un ciclo nuevo, no se
pueden encadenar los siete golpes. `health.died` no llama al `_die()` común (que desintegra y borra al enemigo):
Bucle pasa a `DEFEATED` y se queda en la arena.

### B.5 Cómo se guardan los siete patrones

Un `BucleConfig` con siete `BucleCycle` en `data/bosses/bucle.tres`. Por ciclo: la secuencia de ataques (p. ej.
`[&"pulso", &"lluvia", &"anillo"]`), la velocidad, la fatiga, el tiempo de aviso (con un mínimo de 0,4 s), la pausa
entre ataques, la cantidad de bloques de la lluvia, el tamaño del hueco del anillo y si empieza con un Error de
ejecución (ciclos 4 a 7, una plataforma por vez). El ciclo actual es `impactos + 1`.

**Rutas de escape garantizadas:** la lluvia divide la arena en carriles y nunca tapa todos (siempre quedan por lo
menos dos libres y no contiguos a una pared). Lo comprueba una prueba que recorre los siete ciclos.

### B.6 La arena (fija, 640 × 360: entra entera en la pantalla, la cámara no se mueve)

```
            [ plataforma central (260–380, y 170) ]
 [ lateral izq. (60–180, y 230) ]                  [ lateral der. (460–580, y 230) ]
 ═══════════════════════════ suelo (y 304) ══════════════════════════
                              Bucle (flota bajo, x 320)
```

Plataformas de un solo sentido (se sube saltando, S para bajar). Bucle flota bajo en el centro (se lo alcanza desde
el suelo y con pogo desde la plataforma central) y en algunos ciclos cambia entre tres puntos (x 200 / 320 / 440).
Al entrar: checkpoint (como la arena de Chip y Glitch) y una barrera cierra la salida hasta el final.

### B.7 Transformación visual

`BucleArt` dibuja por código: el cuerpo siempre igual de grande y con contorno claro (y por encima de sus
instrucciones), y alrededor `stage` (1 a 7) capas: anillos, fragmentos de pseudocódigo que giran (`mientras`,
`repetir`, `i = i + 1`), colores de cálidos a violetas y rojos, cara alegre → confiada → cansada → confundida →
asustada → agotada. Etapas 5 y más: interferencias (franjas); etapa 6: el controlador altera el fondo. Con la
opción **reducir destellos** (nueva en Ajustes) las interferencias y parpadeos se reemplazan por cambios de color
suaves. Se cambia de etapa en `TRANSFORMATION`, cuando no hay peligros en la arena.

### B.8 Dominio Nulo I (fase 9, hecha)

- `CombatClock` (`systems/combat/combat_clock.gd`): multiplicador del tiempo de las amenazas (0,8 con el Dominio).
  Lo leen `EnemyBase` (IA y movimiento), los ataques de Bucle, `DataShot` y las esperas de Bucle. Nunca toca
  `Engine.time_scale`, la interfaz ni a Kai.
- `PlayerDomain` (`characters/player/player_domain.gd`, hijo de Kai): carga en `GameState.domain_charge` (10 por
  golpe a un enemigo), activación con **R** (acción `ultimate`), 15 s, +10 % de daño (aplicado en un solo lugar:
  `PlayerCombat` al activar el golpe), barra en el HUD y un velo violeta.
- La lección: después del puzle, el simulador se desestabiliza y un **muro de procesos** (`ProcessWall`) bloquea la
  salida. Se reconstruye entero 1,6 s (del tiempo de las amenazas) después del primer golpe: sin el Dominio hacen
  falta 5 golpes (1,95 s), imposible; con el Dominio bastan 4 (1,5 s) y el bucle tarda 2 s. Kai obtiene el Dominio
  con la carga llena y se le pide pulsar R; si se termina sin romperlo, se vuelve a cargar. Nada hace daño.
  Después se abre la salida (provisoria: al cuarto técnico, hasta que exista el resto del capítulo 2).
  Marca `cap2_dominio_nulo`; `test_dominio_nulo.gd` lo prueba con golpes reales.

### B.9 Cómo se prueba cada etapa (`tests/test_bucle.gd`, física determinista)

| Fase | Qué se comprueba |
|---|---|
| 1. Prototipo y estados | Empieza en el ciclo 1; las transiciones siguen el diagrama con tiempos de física; un estado temporizado nunca se traba aunque se interrumpa |
| 2. Un ataque + impactos | Un golpe válido suma 1; un segundo golpe en el mismo ciclo no suma; golpes en `INTRO`, `HIT_REACTION` y `TRANSFORMATION` no suman; se puede golpear durante el ataque |
| 3. Fatiga y ciclos | La fatiga llega al terminar el patrón; sin golpe se repite el mismo ciclo; con golpe sube el ciclo y su velocidad |
| 4. Los otros ataques | Todos tienen aviso (≥ 0,4 s); al ser golpeado no queda ningún peligro en la arena; la colisión del anillo coincide con el arco dibujado |
| 5. Las siete secuencias | La lluvia siempre deja carriles libres; un bot esquiva el pulso saltando y subiendo a una plataforma |
| 6. Arena | Con un Error de ejecución activo siempre hay una ruta a cada plataforma y al suelo |
| 7. Transformación | 7 etapas, nunca una octava; Bucle siempre visible y por encima de sus efectos |
| 8. Diálogos y final | Los globos no quitan el control; el séptimo impacto termina todo, el jefe queda quieto y sin ataques |
| 9. Recompensas | Recompensa única aunque se repita el final o se cargue la partida; marca guardada; reinicio desde el checkpoint |
| 10. Dificultad | Capturas, tiempos de cada ciclo y prueba a mano |

### B.10 Fases de implementación (una por vez, con autorización)

1. Prototipo de Bucle con su máquina de estados. 2. Un ataque (Pulso) y la detección de impactos clave. 3. Fatiga y
transición entre ciclos. 4. Lluvia, Anillo y Error de ejecución. 5. Las siete secuencias. 6. Arena con plataformas.
7. Transformación visual. 8. Diálogos, cinemática y puzle. 9. Recompensas y Dominio Nulo I. 10. Pruebas de
dificultad, rendimiento y accesibilidad.

### B.11 Decisiones pendientes del equipo

- **Biblia:** Bucle es un personaje nuevo (la Biblia solo dice, del nivel 4, «Corrige errores de un sistema
  automatizado en una simulación»). No la contradice, pero hay que agregarlo (v1.5) con aprobación.
- **Dónde está la arena:** el capítulo 2 todavía no existe (ni misiones ni salas). Propuesta: la arena se construye
  sola (se prueba abriendo la escena) y se conecta al mapa cuando se diseñe el capítulo 2.
- **Daño de los ataques a Kai:** propuesta, 1 cristal (sin subir con los ciclos).
- **Recompensa del golpe arriesgado:** propuesta, energía extra para curarse.
- **Dominio Nulo:** reloj local, carga y tecla (ver B.8).
