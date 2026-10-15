# El hogar de Kai

> Escenario recurrente de los tres años (décimo, undécimo y duodécimo). Primera versión jugable: Capítulo 1,
> misión **«Camino a casa»** (después de Chip y Glitch). Arte provisional dibujado por código hasta que Ariel
> lo dibuje.

## 1. Propósito narrativo

La casa rompe la cadena «aprender → actividad → siguiente misión» con momentos tranquilos: exploración,
conversaciones, descubrimientos y desarrollo de personajes. Transmite seguridad, familiaridad, nostalgia,
crecimiento, vínculos familiares y misterio. **No es solo un punto de descanso: es un diario físico de la
vida de Kai.** Cada objeto representa algo que vivió; cada conversación ayuda a entenderlo; cada año deja
huellas visibles en su cuarto.

**Canon (Biblia Narrativa, sección 5, actualizada):** mamá y papá son padres adoptivos que **conocen parte**
del origen de Kai. No saben todas sus capacidades, ni cómo evolucionarán, ni tienen todas las respuestas sobre el
Proyecto Génesis. No lo manipulan ni lo ven como un experimento: es su hijo. En el juego, por ahora, solo se nota
en miradas y frases con doble sentido. **Kai no descubre nada en el Capítulo 1** y nunca se dice «Génesis» en casa.

## 2. «Camino a casa» (Capítulo 1)

Misión `camino_a_casa` (`data/quests/camino_a_casa.tres`), entre `travesuras_en_el_sistema` (Chip y Glitch,
«FIN DEL CAPÍTULO 1») y `el_lenguaje_de_las_maquinas`. Sin combate ni examen.

| Paso | Objetivo | Dónde | Qué pasa |
|---|---|---|---|
| `charla_amigos` | Tus amigos te esperan en la entrada del colegio. | Entrada | Los amigos (sin nombre por ahora: «Compañera» y «Compañero») comentan lo que pasó (`hogar_amigos`). Terminó la jornada: tarde. |
| `volver_a_casa` | Regresá a casa. | Calle → Casa | Se abre la salida oeste de la Entrada. En la calle: un comentario de Kai al salir, el vecino barriendo la acera, un estudiante que vuelve a su casa, la pulpería, la parada y Canelo, el perro del barrio (todo opcional). Al entrar a la casa se completa. |
| `hablar_familia` | Saludá a tu familia. | Casa | Al llegar a la sala, mamá viene de la cocina (parte 1) y papá se levanta y se acerca (parte 2): la primera charla familiar. Fundido: «Más tarde, después de la cena...». Es de noche. |
| `descansar` | Descansá en tu cuarto. | Cuarto de Kai | Exploración libre (estanterías, Nullblade, computadora, juguetes; los papás tienen frases de noche). La cama pregunta «¿Descansar hasta mañana?». |

Al descansar: Kai se duerme → **escena aparte** «Mientras tanto, en la sala...»: los papás hablan a solas
(`hogar_padres_noche`) → **Resonancia Digital** en el cuarto → amanece, Kai despierta confundido
(`hogar_despertar`) → se completa la misión: **«CAPÍTULO 2 · LOS PRIMEROS CÓDIGOS»** → se guarda en la cama
(cristales y energía llenos) → empieza `el_lenguaje_de_las_maquinas` (marca `capitulo_2`). De mañana los papás
tienen sus frases del desayuno (`hogar_mama_manana`, `hogar_papa_manana`) y Kai va al colegio por la calle.

## 3. Distribución

Distrito **Barrio de Kai** (`data/world/districts/barrio.tres`), aparte del Colegio: la calle se une a la Entrada
del colegio por una salida sin puerta en la ficha (como los portales: `RoomExit` con `door_id` vacío).

```
[Colegio: Entrada] ←→ [Calle (1800 px)] ←→ [Casa (1040 px)] ←→ [Cuarto de Kai (640 px)]
```

- **Calle** (`world/zones/barrio/calle.tscn`): portón del colegio, montañas al fondo, casas de colores con rejas,
  postes con cables, árboles, la parada del bus, la «Pulpería La Esquina» (inventada) y la casa de Kai (celeste,
  techo de teja, número 24). Atmósfera, no relleno: se cruza en menos de un minuto.
- **Casa** (`casa.tscn`): de izquierda a derecha, la puerta de la calle y el recibidor (perchero, zapatera,
  **fotos familiares**), la sala (sofá, ventana con cortinas, lámpara de pie, **tele**), el comedor (mesa con tres
  sillas), la cocina (con la **refri** y el dibujo de Kai de chiquito) y el pasillito con las **marcas de estatura**
  en el marco y la puerta del cuarto.
- **Cuarto de Kai** (`cuarto_kai.tscn`): puerta, ropero, **caja de juguetes**, escritorio con la **computadora**,
  afiches, **estantería de recuerdos**, **vitrina de Fragmentos de Datos**, **soporte de la Nullblade**, la ventana
  y la **cama**. Estrellitas en la pared que brillan de noche.

Cada sala se puede ampliar (otra habitación es otra ficha y otro enlace en el distrito).

## 4. Interacciones (todas con E, el sistema de siempre: `Interactable`)

| Pieza | Script | Qué hace |
|---|---|---|
| Objetos que se miran | `world/objects/examinable.gd` (`Examinable`) | Un diálogo distinto cada vez (luego repite el último). Sin evaluación. |
| Estanterías | `world/home/keepsake_shelf.gd` (`KeepsakeShelf`) | Muestra en sus repisas lo que Kai ya tiene y abre la inspección. |
| Ventana de inspección | `ui/home/inspection_window.gd` (`InspectionWindow`) | Lista a la izquierda; a la derecha el objeto en grande, nombre, descripción y lo que piensa Kai. Pausa el juego; ↑/↓, mando o mouse; E/Esc vuelve. Estilo de panel del Grimorio, en ámbar (lo personal). |
| Soporte de la Nullblade | `world/home/nullblade_stand.gd` (`NullbladeStand`) | La espada descansa ahí (solo se ve; sigue con Kai al salir) y se inspecciona: forma actual, historia, capacidades y las formas que faltan («???»). |
| Computadora | `world/home/kai_computer.gd` + `ui/home/kai_computer_window.gd` | Mensajes, proyectos y notas del juego (`ComputerEntry`). Sin internet ni archivos reales. Punto rojo si hay mensajes sin leer. |
| Cama | `world/home/kai_bed.gd` (`KaiBed`) | Solo cuando la historia lo permite: pregunta (empieza en «No») y termina el día. Si no es momento, Kai lo dice y no pasa nada. |
| Mamá y papá | `characters/npcs/familia/family_member.gd` (`FamilyMember`, un `Npc`) | Se habla con E; lo que dicen depende del paso de la misión (`NpcConversation`). Respiran y hacen su tarea (cocinar, leer). |

## 5. Recuerdos y coleccionables

`Keepsake` (`systems/home/keepsake.gd`, datos en `data/home/keepsakes/`, registro en `HomeCollection`):
identificador, nombre, categoría (**Recuerdo**, **Fragmento de Datos**, **Regalo**), descripción, marca de
desbloqueo, lugar en la estantería, dibujo (o textura) y **notas** (`KeepsakeNote`).

**Recuerdos dinámicos:** cada nota vale desde un capítulo (`min_chapter`) y/o con una marca; se usa la última que
valga. El mismo objeto dice algo distinto en décimo (capítulos 1–4), undécimo (5–8) y duodécimo (9–12) sin tocar
la lógica: se agregan notas al .tres.

| Objeto | Categoría | Aparece | Notas |
|---|---|---|---|
| Robot de juguete | Recuerdo | Siempre | Décimo, undécimo y duodécimo (los textos de la propuesta) |
| Fotografía familiar | Recuerdo | Siempre | Tres etapas |
| Fotografía escolar | Recuerdo | Siempre | Décimo |
| Kit de electrónica (regalo de cumpleaños) | Regalo | Siempre | Décimo y undécimo |
| Dibujo de Chip y Glitch | Recuerdo | `capitulo_1_completado` (aparece en la primera visita) | Décimo |
| Pulsera de la amistad | Recuerdo | `recuerdo_pulsera_amistad` (misión futura) | — |
| Reloj de papá | Regalo | `regalo_reloj_papa` (preparado para una misión de décimo) | Sin secretos revelados |
| Fragmento de Datos del pasillo | Fragmento | `zona0_fragmento_recogido` (el de la Visión Digital) | — |
| Fragmento de Datos de Chip y Glitch | Fragmento | `cap1_fragmento_leido` (cierre del combate) | Con las líneas que leyó el Grimorio |

**Reglas:** los Fragmentos de Datos **no son moneda** (los Ecos se cobran donde se recogen: `DataFragment`,
`Economy.claim_reward`); la vitrina usa las mismas marcas que sus recolectores. Todo vive en las marcas de
`GameState` de la ranura: nada se consigue dos veces y nada pasa de una partida a otra. En la vitrina, los que
faltan se ven como «???»; en los recuerdos, los que faltan no se listan.

## 6. Nullblade

`NullbladeForm` (`data/home/nullblade/`): `Nullblade.exe`, `.zero`, `.void`, `.max`. Se conoce una forma cuando
`GameState.nullblade_stage` llega a su etapa: **solo la historia** (nunca Ecos). Las que faltan se ven bloqueadas.
La historia de `.exe` no explica su origen (pendiente en la Biblia).

## 7. Momento del día y rutinas

`DayPhase` (`systems/home/day_phase.gd`): **Día**, **Tarde**, **Noche**, **Mañana**, según la misión (no un reloj).
Reglas en `DayPhase.RULES` (misión, paso, momento y una marca opcional). Lo usan la luz (`PhaseLight`), las ventanas
y el cielo de la calle, y las rutinas de los papás (`FamilyMember.routine`: posición, mirada y tarea por momento).

| Momento | Mamá | Papá |
|---|---|---|
| Tarde | Cocina (cocinando) | Sala, leyendo |
| Noche | Comedor | Sala, viendo la tele |
| Mañana | Cocina | Mesa del comedor (café) |
| Día | Cocina | Sala |

## 8. Resonancia Digital (provisional)

La primera noche: interferencias en la imagen, una señal digital lejana (`distant_signal`) y, por un instante,
datos de la computadora de Kai (`ResonanceOverlay`): «SEÑAL DETECTADA · DISPOSITIVO CERCANO: PC_KAI · PAQUETE:
01001011 01000001 01001001 · SINCRONIZACIÓN INTERRUMPIDA» (el paquete dice «KAI» en binario; nadie lo explica).
Queda la marca `resonancia_digital_1` (**evento narrativo, no una habilidad**: no reemplaza a la Visión ni a la
Inmersión y no tiene que ver con Dominio Nulo I, que llega al final del Capítulo 2). Kai anota el sueño en su
computadora (nota «El sueño»).

## 9. Guardado

Todo va en la ranura activa (3 ranuras locales), con las marcas de `GameState` y el progreso de misiones:
`cap1_charla_familiar`, `cap1_kai_dormido`, `cap1_padres_hablaron`, `resonancia_digital_1`, `cap1_calle_comentario`,
`camino_a_casa_completado`, los mensajes leídos (`pc_leido_<archivo>`) y las marcas de los objetos. El autoguardado
de siempre guarda al cambiar de paso cuando es seguro; la cama guarda al despertar (punto `cama`). La noche no se
puede guardar a la mitad (Kai no tiene control); si una partida quedara «dormida» sin la charla de los papás, Kai
vuelve a estar despierto. No se guarda nada sensible.

## 10. Evolución por año (preparado)

| Año | Cuarto | Tono |
|---|---|---|
| Décimo | Sencillo: juguetes de chiquito, pocas fotos, primeros proyectos, primeros coleccionables, `Nullblade.exe` | Descubrimiento e inocencia |
| Undécimo | Más fotos, proyectos, trofeos, recuerdos de aventuras; charlas más profundas | Preguntas sobre identidad y origen |
| Duodécimo | Lleno de recuerdos, colecciones avanzadas, evoluciones de Nullblade, objetos de decisiones | Madurez, identidad y elección |

Los cambios llegan **de a poco, después de acontecimientos importantes** (marcas), no de golpe al cambiar de año:
un objeto nuevo es un `Keepsake` con su marca; un mueble nuevo, una pieza del cuarto que aparece con una marca.

## 11. Regalos de los papás

Los regalos son `Keepsake` de categoría **Regalo** que aparecen con su marca. Preparado: **el reloj de papá**
(`regalo_reloj_papa`), para entregarlo en una misión de décimo (por definir). Su descripción puede cambiar con
notas por etapa; no revela ningún secreto por sí solo.

## 12. Escena futura: antes de la graduación (no implementada)

Final de duodécimo: Kai vuelve a su cuarto antes de graduarse y puede recorrer los recuerdos de tres años. Mira la
foto familiar: «Durante mucho tiempo quise entender de dónde venía.» / «Pero creo que estaba olvidando algo
importante.» / «También soy todas las personas que estuvieron conmigo mientras crecía.» Sus papás lo esperan para
ir a la graduación. **No se anticipa en el Capítulo 1.**

## 13. Ampliaciones posibles

- Arte definitivo de Ariel (casa, calle, papás con retratos y animaciones, objetos con `Keepsake.texture`).
- Música tranquila para la casa (`assets/audio/music/hogar.ogg`) y el barrio (`barrio.ogg`): ya están pedidas
  por las salas; mientras no existan, hay silencio.
- Nombres de los papás y de los amigos.
- Más rutinas (fines de semana, cumpleaños), más regalos, la soda del colegio y el doble salto con Ecos.
- El camino de la mañana practicando la Visión Digital (Capítulo 2).
- Idea para decidir: ¿hay fotos de Kai de bebé? (Si no, sería otra pista; hoy no se menciona.)

## 14. Pruebas

`tests/test_hogar.gd` recorre la misión entera y los criterios de aceptación.
