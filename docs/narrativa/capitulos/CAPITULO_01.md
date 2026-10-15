# Capítulo 1 — El origen digital

**Estado:** especificación oficial del equipo (13 de octubre de 2026), incorporada a la Biblia v1.3. Implementación autorizada por etapas
(sección 19): **el capítulo se puede jugar de punta a punta** (guion en [`CAPITULO_01_GUION.md`](CAPITULO_01_GUION.md)). Arte provisional por código hasta que Ariel lo dibuje. Las notas de coherencia de la sección 18 ya tienen las decisiones del equipo.
**Grado:** Décimo. **Capítulo:** 1. **Niveles:** 1 · *Una clase diferente* — 2 · *Travesuras en el sistema*.
**Referencia:** `docs/narrativa/BIBLIA_NARRATIVA.md` (v1.2). Este documento **no** reemplaza la Biblia.

---

## 1. Punto de partida

Ocurre después del prólogo («EL DESPERTAR»). Kai ya tiene **Visión Digital**, **`Nullblade.exe`** (con el **dash**;
el doble salto se consigue más adelante, Biblia v1.4) y el **Grimorio** básico (Grimorio Despertado). Todavía **no** tiene Aegis (capítulo 3)
ni Dominio Nulo (capítulo 2).

## 2. Objetivos educativos

Adaptaciones propias del juego, a validar con el programa completo del MEP (referencia preliminar: tabla de
especificaciones de 2025, `docs/curriculo_mep.md`):

- Uso ético de la información.
- Acceso autorizado y confidencialidad.
- Protección de datos.
- Mantenimiento seguro y respaldos.
- Reconocimiento de comportamientos anómalos.

En `docs/curriculo_mep.md` el capítulo 1 trabaja: principios de ciberseguridad, ética y leyes de los datos,
protección e integridad de la información, tipos de ataques, control de acceso y primeros comandos de Linux.

## 3. Chip y Glitch

Dos criaturas digitales originales, pequeñas y traviesas. **Hermanos** (o se consideran hermanos).

| | Chip | Glitch |
|---|---|---|
| Carácter | El estratega: calcula, planea, se cree muy listo | El impulsivo: actúa primero, pregunta después |
| En combate | Modifica mecanismos, prepara trampas, dispara proyectiles, controla el espacio | Corre, salta, embiste, ataques rápidos |

- Sus travesuras causan errores en los **sistemas de entrenamiento del colegio**. No buscan una catástrofe, pero no
  entienden las consecuencias.
- **No son subordinados confirmados del antagonista** (Biblia VI: «no todos los incidentes son planes del
  antagonista»).
- Los demás no los ven: solo Kai, con la Visión Digital (Biblia VII).
- Nunca mueren: quedan neutralizados y pueden volver más adelante.

## 4. Nivel 1 — Una clase diferente

Durante una clase de ciberseguridad, Kai descubre que Chip y Glitch alteran las computadoras por diversión. Los
hermanos se dan cuenta de que **Kai puede verlos** y escapan. Kai los persigue por pasillos y laboratorios y resuelve
pequeños desafíos educativos que representan los problemas que causaron.

Introduce: investigación, interacción con terminales, uso del Grimorio, decisiones de seguridad y primeras
persecuciones cortas. Al final, Chip y Glitch escapan hacia una **zona técnica**.

## 5. Nivel 2 — Travesuras en el sistema

Kai sigue la persecución. Chip y Glitch desaparecen dentro de una computadora. Kai intenta seguirlos, pero no sabe
cómo. Por instinto activa la Visión Digital y descubre una conexión con el sistema. Al atravesar el monitor desbloquea
**INMERSIÓN DIGITAL**.

## 6. Inmersión Digital

Habilidad **permanente**: permite entrar a determinados **entornos digitales simulados** del universo del juego y
explorarlos como escenarios 2D.

- **No es lo mismo que la Visión Digital.** Visión: percibir anomalías en el mundo cotidiano. Inmersión: explorar
  espacios virtuales internos.
- En el capítulo 1 Kai todavía no la domina.
- La primera entrada tiene una pequeña secuencia narrativa y una transición visual.
- Nunca representa acceso real a sistemas informáticos externos.

## 7. Persecución digital

Plataformas flotantes, grandes vacíos, estructuras de datos, obstáculos, **una barrera de corrupción**, **tres
checkpoints educativos** y **un temporizador**. Ritmo ágil de plataformas de acción, con diseños, personajes y
recursos originales.

### Barrera de corrupción

1. Si toca a Kai, le quita vida.
2. No causa derrota instantánea.
3. Después del impacto, invulnerabilidad breve (nunca daño en cada cuadro).
4. El daño es configurable. Valor inicial: **1** por contacto (ajustar con pruebas).
5. Deja de avanzar al llegar a una zona segura.
6. Se desactiva definitivamente antes del combate final.

### Caída al vacío

- Kai reaparece en la **última plataforma segura** registrada.
- Pierde exactamente **1,5** de vida (la salud admite fracciones).
- Si conserva vida, sigue. Si llega a cero, reaparece desde el checkpoint correspondiente.

### Temporizador

- Valor inicial: **1:02** (v3, 14 de octubre de 2026, pedido del equipo: «mega difícil»). Un recorrido perfecto de los
  tres tramos tarda unos 47 s; el reloj da poco margen. Al reintentar un tramo: 22, 25 y 22 s.
- Una respuesta incorrecta en un checkpoint descuenta **20 segundos** (nunca por debajo de 20 s).
- Si se agota, se reintenta desde el último checkpoint con tiempo suficiente: nunca un bloqueo imposible.
- **Al entrar a la batalla contra Chip y Glitch, el temporizador desaparece. El combate no tiene límite de tiempo.**

## 8. Los tres checkpoints educativos

Cada tramo termina en una **zona segura**: la barrera se detiene y aparece una pregunta. No se avanza hasta responder
bien. Mientras se responde, Kai no recibe daño. Si responde mal: pierde 20 segundos, recibe una explicación y puede
volver a intentarlo. Cada checkpoint tiene **tres preguntas** de casos concretos con **cuatro opciones** creíbles (v3);
la primera es la de la tabla. Al responder bien: se guarda el progreso, se abre la puerta y se habilita el siguiente tramo. Un
checkpoint completado no se repite al cargar la partida.

| | Pregunta | Respuesta correcta |
|---|---|---|
| 1 | ¿Qué debe hacerse al encontrar archivos privados durante una revisión autorizada? | Consultar únicamente la información para la que se tiene autorización. |
| 2 | ¿Qué se recomienda antes de restaurar información importante? | Verificar que la copia de respaldo sea válida. |
| 3 | ¿Qué ayuda a proteger la confidencialidad? | Utilizar controles de acceso adecuados. |

Las otras dos preguntas de cada checkpoint (v3): el permiso temporal de administrador y qué se puede revisar al
arreglar una impresora (1); qué respaldo restaurar después de un virus y dónde guardar una copia (2); mínimo
privilegio en un grupo de trabajo y una sesión ajena abierta en la biblioteca (3).

**Dificultad (v4):** la barrera **persigue de cerca**: avanza como mínimo a 130, 80 y 105 px/s y, si Kai le saca más
de 120 px, acelera (hasta 320 px/s) para volver a quedar encima; si Kai se detiene, lo alcanza. Simulada sobre el
recorrido perfecto que mide la prueba automática, ese recorrido no la toca pero la tiene a 85, 21 y 27 px (en promedio
va a 136, 110 y 119 px/s: Kai camina a 130). Tocarla quita 1,5 y empuja poco; plataformas que se mueven
más rápido (hay que atraparlas con salto + dash), temporales que se caen antes y 12 nodos que disparan.

## 9. Los tramos

| Tramo | Diseño |
|---|---|
| 1 | Plataformas amplias y saltos sencillos. Presenta la barrera. |
| 2 | Plataformas más pequeñas, rutas alternativas y obstáculos digitales. |
| 3 | Plataformas temporales y más presión de movimiento. |

Los tres se superan **solo con las habilidades del capítulo 1**. El primer prototipo usa un **diseño fijo y validado**;
la variación semi-procedural puede sumarse después sin cambiar los objetivos obligatorios.

## 10. Arena del jefe

Al salir del tercer tramo: se detiene la barrera, se desactiva el modo persecución, se oculta el cronómetro, se
registra el checkpoint, se reproduce la introducción y empieza el combate sin límite de tiempo.

> **GLITCH:** «¡LO LOGRAMOS!».
> **CHIP:** «Por supuesto. Era un plan perfecto».
> **GLITCH:** «¿Y si sobrevivió?».
> **CHIP:** «Imposible».
>
> *(Kai entra a la arena.)*
>
> **KAI:** «¿Decían algo?».
> **CHIP:** «...».
> **GLITCH:** «...».
> **CHIP:** «¡PLAN B!».

## 11. Jefe dual: Glitch y Chip

Diseño de Ariel (`docs/arte/referencias/glitch_chip_concepto.webp`, «Glitch & Chip, los gemelos»): dos entidades
artificiales creadas para mantener el equilibrio y la sincronización de los sistemas; inseparables, actúan como una
sola unidad. **Glitch** (rosa) es el impulsivo: ataques rápidos, movimiento agresivo, inicia la mayoría de los ataques
en conjunto. **Chip** (azul) es el estratega: ataques precisos, control del espacio, anticipa y convierte el caos de
Glitch en un plan.

Cada uno tiene **su barra de vida** en las Fases 1 y 2 y **hay que vencer a cada uno**: el que se queda sin vida queda
vencido (aturdido en el piso) y el otro sigue peleando solo. Con los dos vencidos se levantan (Chip: «Interesante
enfoque. Lástima que ya lo habíamos anticipado.»), viene la fase segura del escudo y en la **Fase 3 pelean con una sola
barra nueva** (ahí funcionan como una unidad). La Fase 2 empieza según la vida de los dos juntos (70 %).
Todos los ataques tienen señales de anticipación (un «!» de su color) y
una forma razonable de esquivarlos.

**Ataques individuales**

- **Glitch:** 1. Corte acelerado (dash con varios cortes) · 2. Salto en picada (cae desde arriba; marca el piso) ·
  3. Embestida en cadena (serie de dashes rápidos) · 4. Lanzamiento de fragmentos (cuchillas de energía).
- **Chip:** 1. Discos orbitales (lanza y controla discos que vuelven) · 2. Zona de control (campo que ralentiza) ·
  3. Proyecciones (copias temporales que lanzan discos) · 4. Rayo de sincronía (ataque en línea de largo alcance).

**Ataques en conjunto**

1. **Intercepción cruzada:** atacan desde lados opuestos.
2. **Corte y respuesta:** Glitch inicia, Chip completa.
3. **Sincronización aérea:** los dos saltan y atacan en el aire.
4. **Cambio de posición:** se intercambian de lugar en plena secuencia.
5. **Cadena de proyecciones:** Chip crea copias mientras Glitch presiona.
6. **Campo Dual:** combinan sus habilidades para crear una zona peligrosa (el ataque definitivo).

Como en Hollow Knight (las Mantis Lords y los Cogwork Dancers), también se coordinan como una coreografía:

7. **Danza espejo:** cada uno salta a una pared y cruzan la arena a la vez, Glitch por el piso y Chip volando.
8. **Picadas alternas:** caen sobre Kai por turnos, uno tras otro.
9. **Discos cruzados:** desde paredes opuestas, Chip lanza discos mientras Glitch embiste.
10. **Remolino doble** (Fase 3): suben al gran anillo del fondo y giran por el aro, uno frente al otro, disparando.

Y sus movimientos clásicos, como las Mantis Lords: el **Barrido** (aparecen en una pared y cruzan a la altura de Kai) y la
**Caída** (aparecen arriba de Kai y caen sobre él); los dos siguen a Kai durante el aviso. En la Fase 1 los hacen de a uno;
desde la Fase 2, sincronizados: **Tijera** (desde paredes opuestas, uno por el piso y el otro por arriba), **Doble caída**
(uno a cada lado de Kai) y **Caída y barrido** (cuando uno aterriza, el otro ya está cruzando).

Desde la Fase 1 también atacan los dos a la vez (por ejemplo, Glitch corta mientras Chip lanza discos).

**El vínculo:** cuando uno queda momentáneamente incapacitado (varios golpes seguidos), el otro **abandona su ataque
para protegerlo** hasta que se recupera: Chip lo cubre con un escudo de discos que hace rebotar los golpes; Glitch se
para delante con la espada y contraataca. Así el jugador percibe un vínculo genuino entre ellos, no solo una mecánica.

**Escenario:** la Cámara de convergencia (columnas, luces rosas y azules y un gran anillo con un rombo).

## 12. Fases

- **Fase 1 · Reconocimiento (100-70 %):** alternan ataques individuales y algunos en conjunto sencillos. El jugador
  aprende sus señales.
- **Fase 2 · Sincronización (desde el 70 %, hasta vencer a los dos):** encadenan ataques y cambian de posición. La música incorpora una segunda
  melodía y el anillo del fondo se activa.
- **Fase 3 · Protocolo Dual — Furia fraternal (barra única):** sus movimientos se vuelven más rápidos, pero no aleatorios.
  Ejecutan secuencias combinadas y su ataque definitivo (Campo Dual). Pelean juntos: nadie pelea solo.

Las fases dependen de la vida de los dos juntos. Si Chip ya está neutralizado, no hay escudo: la Fase 3 empieza
directamente. El combate termina cuando las dos barras llegan a cero. Ninguno muere: quedan neutralizados.

## 13. Desafío educativo durante el combate

Al vencer a los dos (antes de la Fase 3), Chip activa un **escudo** ligado a una **configuración insegura**. Para desactivarlo, Kai resuelve un desafío en una
terminal simulada. Mientras tanto el combate entra en una **fase segura claramente delimitada**, para leer y decidir
con calma. El desafío trabaja los conceptos del capítulo **sin repetir literalmente** las preguntas de los
checkpoints.

## 14. Cierre

> **GLITCH:** «¡Ay, ay, ay! ¡Ya no quiero jugar!».
> **CHIP:** «Está bien, está bien. ¡Ganaste!».
> **KAI:** «¿Por qué estaban dañando las computadoras?».
> **GLITCH:** «Porque hacen ruidos graciosos cuando fallan».
> **CHIP:** «¡No digás eso! ¡Teníamos un plan!».
> **KAI:** «¿Cuál plan?».
> **CHIP:** «... Todavía estábamos trabajando en eso».

Kai les explica que sus travesuras afectan el trabajo y la información de personas reales. Por primera vez, los
hermanos muestran cierta comprensión. Uno deja caer un **Fragmento de Datos**. El Grimorio muestra:

```
ORIGEN: DESCONOCIDO
ESTADO: INCOMPLETO
OBSERVADOR: RECONOCIDO
PROTOCOLO: [DATOS CORRUPTOS]
```

Después Kai habla con el profesor. Cuando Kai se va, en una escena aparte («Mientras tanto...»), el profesor mira
la computadora y aparece el archivo **`GENESIS_ARCHIVE`**. Corte. **FIN DEL CAPÍTULO 1.** Kai aparece en la entrada
del colegio: él no vio el archivo.

**No revelar todavía que Kai es un organismo artificial** (Biblia XV, reglas 1 y 11).

## 15. Recompensas

Ecos · registro de Chip y Glitch en el Grimorio · **Inmersión Digital** permanente · página educativa · Fragmento de
Datos narrativo · progreso y salas descubiertas. **Ninguna recompensa única se puede cobrar dos veces.**

## 16. Arquitectura (resumen; detalle en la propuesta de implementación)

Piezas de referencia de la especificación: DigitalImmersionController, DigitalChaseController, CorruptionBarrier,
SafePlatformTracker, EducationalCheckpoint, QuestionManager, ChaseTimer, DualBossController, ChipBoss, GlitchBoss,
BossSynergyManager, BossRageState. **No duplicar gestores existentes**: por ejemplo, las preguntas usan
`ChoiceChallenge`, la plataforma segura sale de `PlayerDamage.last_safe_position`, la entrada a la computadora usa
`DigitalDive` y las recompensas únicas pasan por `Economy.claim_reward()`. Todos los valores configurables van en
recursos de datos (`data/`), separados de las escenas y de la lógica.

## 17. Pruebas obligatorias

- Inmersión Digital se desbloquea correctamente.
- La barrera solo daña al contacto, con invulnerabilidad breve después.
- Las caídas restan 1,5 y Kai reaparece sobre una plataforma segura.
- Las preguntas bloquean el avance hasta responder bien; las incorrectas restan tiempo.
- El tiempo agotado permite reintentar.
- El temporizador desaparece al entrar a la arena; el jefe no usa temporizador.
- Glitch y Chip tienen una barra cada uno hasta la Fase 3, donde pelean con una sola; hay que vencer a cada uno (el vencido queda aturdido).
- Sus 8 ataques individuales y los 10 en conjunto funcionan y avisan antes.
- Cuando uno queda aturdido, el otro deja su ataque y lo protege.
- La Fase 2 empieza al 70 % y la Fase 3 al vencer a los dos (con la fase segura del escudo antes).
- Los enemigos sobreviven narrativamente.
- Las recompensas se guardan una sola vez.
- El capítulo respeta la Biblia Narrativa.

## 18. Notas de coherencia con la Biblia

**Decisiones del equipo (13 de octubre de 2026, Biblia v1.3):** la entrada a la computadora del profesor sale del
prólogo y va a otro lugar por definir (nota 1); los títulos de los niveles quedan (nota 2); Chip, Glitch y la Inmersión
Digital entran a la Biblia (nota 4); `GENESIS_ARCHIVE` es oficial (nota 5). Las demás notas siguen como propuestas.

| # | Tema | Qué dice hoy el juego / la Biblia | Propuesta |
|---|---|---|---|
| 1 | **Entrar a una computadora** | En el prólogo, la computadora del laboratorio **absorbe** a Kai (`DigitalDive`) y juega el nivel del SPAM dentro de la PC del profesor («Ahora sal de ahí... como sea que hayas entrado»). | Fue **involuntario**: la anomalía lo arrastró. En el capítulo 1, Kai **elige** entrar por primera vez: eso es la Inmersión Digital. Ej.: «La otra vez la computadora me jaló. Esta vez... voy yo». |
| 2 | **Títulos de los niveles** | Biblia XII: «El primer incidente» y «Algo no está bien». | Cambiar a «Una clase diferente» y «Travesuras en el sistema» en la Biblia (v1.3), con aprobación. |
| 3 | **Compañeros** | Biblia XII, nivel 1: «conoce herramientas iniciales y **compañeros**». Los tres amigos no tienen nombre (XVI). | La clase puede mostrar compañeros sin nombre (fondo). Presentarlos de verdad queda para cuando se definan. |
| 4 | **Chip, Glitch e Inmersión Digital** | No están en la Biblia. | Registrarlos en la Biblia v1.3 (personajes recurrentes y habilidad), con aprobación. |
| 5 | **`GENESIS_ARCHIVE`** | «Proyecto Génesis» es el nombre provisional del proyecto de origen; su relación con «El Núcleo» está pendiente (XVI). El profesor es el creador (IV) y en décimo tiene «reacciones extrañas» frente a las anomalías. | Es una pista coherente (la ve el jugador, no Kai). Confirmar que el nombre del archivo queda como canon. |
| 6 | **No repetir el tutorial** | Biblia XII. El prólogo ya enseñó `ls`, `cd`, `cat`, `ls -a` y una pelea con jefe dentro de una PC. | Nivel 1 con mecánicas nuevas: investigar **registros** (comportamientos anómalos), decisiones de acceso autorizado y persecuciones; nada de «revisar la PC del profe» otra vez. |
| 7 | **Plataformas** | El capítulo pide optimizar para Windows y Android. La decisión oficial de usuarios (13 de octubre) fija **solo Steam para PC**; Android pospuesto. | Optimizar para Windows; mantener los controles táctiles que ya existen sin trabajo extra para Android. |
| 8 | **Vida** | Kai empieza con 4 cristales. | Con 1,5 por caída y 1,5 por la barrera (v3); los valores van en datos. |
| 9 | **Respaldos** | «Mantenimiento seguro y respaldos» no aparece con ese nombre en la tabla de décimo de `curriculo_mep.md`. | Ubicarlo en «Protección de la información e integridad»; validar con el programa completo. |

## 19. Implementación por etapas

| # | Etapa | Estado |
|---|---|---|
| 1 | Guion y datos de misión | ✅ Hecha (guion para revisar con el equipo) |
| 2 | Inmersión Digital (solo la transición) | ✅ Hecha: `ImmersionPortal`, habilidad guardada; se coloca en el cuarto técnico en la etapa 3 |
| 3 | Sala inicial de persecución | ✅ El cuarto técnico (2° piso, cerrado con llave hasta el permiso del profesor; la conexión en el monitor) y la red de entrenamiento (`persecucion.tscn`, 3 tramos fijos) |
| 4 | Barrera, salud y caídas | ✅ `CorruptionBarrier` (1 por contacto, invulnerabilidad breve, se detiene en las zonas seguras, se apaga al final); caídas de 1,5 (`Room.fall_damage`) con vuelta a la última plataforma segura (nunca una que se mueve o desaparece) |
| 5 | Checkpoints y preguntas | ✅ `EducationalCheckpoint` con `ChoiceWindow` (pausa el juego: Kai no recibe daño); tres preguntas de cuatro opciones; incorrecta −20 s; correcta: puerta, marca `cap1_checkpoint_N` y guardado; no se repiten al cargar |
| 6 | Temporizador | ✅ `ChaseTimer` (1:02, con la física); tiempo agotado o muerte: vuelta al último checkpoint con tiempo suficiente; desaparece después del tercer checkpoint |
| 7 | Chip como enemigo | ✅ `ChipBoss` (rediseño de Ariel): Discos orbitales, Zona de control, Proyecciones y Rayo de sincronía; escudo de la fase segura y escudo para proteger a Glitch |
| 8 | Glitch como enemigo | ✅ `GlitchBoss` (rediseño de Ariel): Corte acelerado, Salto en picada, Embestida en cadena y Lanzamiento de fragmentos; queda vulnerable después de atacar; contraataca protegiendo a Chip |
| 9 | Coordinación de ataques | ✅ `DualBossController`: vida compartida, secuencias fijas por fase y los 10 ataques en conjunto (también a la vez); el vínculo (proteger al aturdido); fase segura del escudo con terminal (mínimo privilegio) al vencer a los dos |
| 10 | Furia fraternal | ✅ Es la Fase 3 (Protocolo Dual): los dos juntos, más rápidos y con avisos más cortos, y el Campo Dual |
| 11 | Arena y transiciones | ✅ La arena (checkpoint al llegar, sin temporizador, reinicio si Kai pierde, salida al cuarto técnico); el nivel 1 en la Sala 3 (el aula de Kai, junto al pasillo), el pasillo, las escaleras y la biblioteca; el prólogo lleva al capítulo |
| 12 | Cinemáticas y recompensas | ✅ Introducción y cierre de los hermanos, lectura del Fragmento de Datos, el profesor y `GENESIS_ARCHIVE`, «FIN DEL CAPÍTULO 1»; Ecos una sola vez, páginas del Grimorio, Inmersión Digital |
| 13 | Pruebas y optimización | ✅ Pruebas de cada etapa y de la historia completa; tiempos con la física (estables con la PC cargada). Falta probarlo a mano y ajustar valores (vida, tiempos, daño) |
