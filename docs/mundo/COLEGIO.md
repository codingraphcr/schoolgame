# El colegio de Kai (distrito `colegio`)

> El colegio técnico es el centro narrativo y de navegación de los tres años (décimo, undécimo y duodécimo).
> Es un lugar **explorable e interconectado** que se reutiliza: las mismas salas cambian con el capítulo (gente,
> avisos, diálogos, objetos), no se rehacen. Región: Distrito Central (`REGIONES_FISICAS.md`).
> Estados: **IMPLEMENTADO**, **EN CURSO** (expansión de los capítulos 1 y 2) y **FUTURO**.

## Mapa

```
                                                         [pasillo_segundo] ── [biblioteca]
                                                                 │
[cuarto_viejo] ── [pasillo_viejo] ── [laboratorio] ── [pasillo] ── [escaleras] ── [cuarto_tecnico]
                                                       │     │
                                                  [sala_3] [entrada] ── (calle del barrio)
                                                               │
                                              [soda] ── [patio]
```

Las uniones están en `data/world/districts/colegio.tres` (cada puerta con su pareja en la sala vecina). Las salas
con `chapter_requirement` se abren al llegar a ese capítulo (`World.lock_reason`).

## Zonas

| Zona | Escena | Para qué sirve | Se abre | Estado |
|---|---|---|---|---|
| Entrada | `zone0/entrada.tscn` | Llegada y salida al barrio; los amigos; escalera al patio | Prólogo | IMPLEMENTADO |
| Pasillo central | `zone0/pasillo.tscn` | Une la entrada, la Sala 3, el laboratorio y las escaleras | Prólogo | IMPLEMENTADO |
| Sala 3 (aula) | `zone0/sala_3.tscn` | Clases del profesor Alvarado | Prólogo | IMPLEMENTADO |
| Laboratorio / taller de informática y robótica | `zone0/laboratorio.tscn` | Prácticas; en el Cap. 2, las estaciones de robótica y el simulador | Prólogo | IMPLEMENTADO (las estaciones: EN CURSO) |
| Escaleras | `zone0/escaleras.tscn` | Une los dos pisos y el cuarto técnico | Cap. 1 | IMPLEMENTADO |
| Pasillo del segundo piso | `zone0/pasillo_segundo.tscn` | Persecución larga del Cap. 1 | Cap. 1 | IMPLEMENTADO |
| Biblioteca | `zone0/biblioteca.tscn` | La computadora del archivo; la fotografía antigua; el estante y la mesa de lectura | Cap. 1 | IMPLEMENTADO |
| Cuarto técnico (servidores) | `zone0/cuarto_tecnico.tscn` | El servidor en rojo; acceso a la red de entrenamiento | Cap. 1 | IMPLEMENTADO |
| Pasillo viejo y cuarto viejo (Laboratorio 2) | `zone0/pasillo_viejo.tscn`, `cuarto_viejo.tscn` | La Nullblade (prólogo) | Prólogo | IMPLEMENTADO |
| **Patio** | `zone0/patio.tscn` | **Punto de encuentro (hub social)**: recreo, tablón de anuncios, une la entrada con la soda | Cap. 1 | IMPLEMENTADO |
| **Soda** | `zone0/soda.tscn` | Zona social: la señora de la soda, compañeros comiendo | Cap. 1 | IMPLEMENTADO |

## El patio

- Arte provisional por código (`world/school/patio_props.gd`) hasta que Ariel lo dibuje: la fachada de dos pisos
  con el mural de la especialidad («CIBERSEGURIDAD»), almendros, bancas, jardineras, el bebedero, el asta con la
  bandera y el corredor techado hacia la entrada. El cielo sigue el momento del día (`DayPhase`).
- **Se examinan:** el mural, el almendro, el bebedero y la bandera (comentarios breves de Kai).
- **El tablón de anuncios** (`world/school/notice_board.gd`, avisos en `data/school/anuncios/`): cada aviso es un
  `Announcement` (actividad, misión opcional o aviso) con requisito de capítulo y, si hace falta, una marca que lo
  esconde. Con E se abre en la ventana de inspección (pausa el juego); los nuevos van primero con «●» y leerlos
  deja la marca `anuncio_leido_<id>` en la ranura. Sirve para anunciar actividades sin carteles de tutorial (p. ej.
  «Actividad de robótica (pronto)» en el Cap. 1 y «Hoy: actividad de robótica» en el Cap. 2). Agregar un aviso es
  agregar un `.tres` y ponerlo en la lista del tablón.
- **Gente de fondo** (`BackgroundNpc` con comentarios): una pareja que charla, alguien caminando, alguien leyendo y
  dos estudiantes quebrando almendras.
- En el prólogo la escalera de la entrada al patio no aparece (`StoryPresence`) y la sala está cerrada
  (`chapter_requirement = 1`): el prólogo no cambia.

## La soda

- Arte provisional (`world/school/soda_props.gd`): azulejos, la pizarra del menú (casado, empanada, gallo pinto,
  fresco de cas, arroz con leche), el mostrador con la vitrina, la refri, mesas, la radio y un abanico que gira.
- **La señora de la soda** (NPC nuevo 1 de 2 permitidos; sin nombre propio por ahora): la primera vez se presenta
  (`intro_first`, marca `soda_presentada`); después dice lo del momento: antes de clase manda a Kai a la Sala 3;
  durante el Cap. 1 comenta lo de las computadoras; en el Cap. 2, la actividad de robótica.
- **Se examinan:** el menú, la radio y la refri.
- Es una zona **social**: no hay hambre ni economía de comida. *Pendiente de decisión (Biblia, sección XVI):* la
  propuesta de comprar el doble salto con Ecos en la soda del colegio.

## La biblioteca

- Estanterías, mesas de lectura, la computadora del catálogo (la escena de Chip y Glitch del Capítulo 1) y gente
  leyendo. **Se examinan:** el estante de informática y la mesa de lectura.
- **Descubrimiento «Una fotografía antigua»** (`world/school/old_photo.gd`): ver
  `../misiones/MISIONES_SECUNDARIAS.md`. Se ve en la ventana de inspección y después en el Grimorio (Registros).

## «Tras las huellas del error» (Capítulo 1)

Después de pedir permiso, el profesor prepara el acceso al cuarto técnico y Kai busca rastros de la falla con la
Visión Digital: en el patio, la soda y el pasillo (`world/school/error_trace.gd`). Bastan dos; después vuelve con el
profesor a la Sala 3. Es el momento pensado para explorar el patio, la soda y la biblioteca. Detalle:
`../narrativa/capitulos/CAPITULO_01_GUION.md` (escena 1.6). Con la Visión, el patio (luz del día, `PhaseLight`) y la
soda también se oscurecen, como el resto del colegio.

## Actividades opcionales del Capítulo 1

- **«Un recreo diferente»** (soda): el Compañero espera a Kai en la mesa de la derecha; charla con una elección pequeña.
- **«El proyecto perdido»** (laboratorio): la estudiante y la computadora «Equipo 4» (terminal simulada).
- Las dos están desde que el profesor prepara el acceso; detalle en `../misiones/MISIONES_SECUNDARIAS.md`.

## Lo que viene en la expansión (EN CURSO)

- Cap. 2: las tres estaciones de robótica en el taller (antes del simulador) y las anomalías antes de Bucle.

## Reutilización en los tres años (FUTURO)

Las mismas salas cambian por capítulo con datos: `StoryPresence` (quién está), `NpcConversation` (qué dice cada
uno según la misión), `Announcement` (el tablón) y las marcas de la ranura. Undécimo y duodécimo agregan avisos,
conversaciones y gente, no salas nuevas, salvo que la historia lo pida.

## Pruebas

`tests/test_patio_soda.gd` (mapa, prólogo, examinables, tablón, la señora de la soda, guardado y otra ranura),
`tests/test_foto_antigua.gd` (la foto, el registro, el Grimorio, guardado y otra ranura),
`tests/test_tras_las_huellas.gd` (los rastros, el profesor, guardado), `tests/test_recreo.gd`,
`tests/test_proyecto_perdido.gd` y los puntos «El patio y la soda (recreo)» y «Tras las huellas del error» del menú de pruebas (F9).
