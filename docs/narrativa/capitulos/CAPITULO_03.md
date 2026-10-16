# Capítulo 3 — Amenazas invisibles: el último guardián

**Estado:** implementado a partir del documento del equipo «Capítulo 3 — Amenazas invisibles: el último guardián» y
de «Continuidad narrativa y misiones secundarias de Aegis» (16 de octubre de 2026), con la Biblia v1.10. Jugable de
punta a punta con **arte provisional por código** (la Estación Lázaro, Aegis, los guardianes y las Bitcucarachas
esperan el arte de Ariel).
**Grado:** Décimo. **Capítulo:** 3. **Niveles:** 5 · *Contagio digital* — 6 · *La señal perdida*.

---

## 1. Requisito y punto de partida

- El capítulo empieza **durmiendo en la cama de Kai** (`world/home/chapter_three_rest.gd`). Pide las historias de
  los capítulos 1 y 2 **y todas sus secundarias y tareas** (`systems/quests/chapter_gate.gd`, se lee del estado real de
  las misiones). Si falta algo, Kai dice qué le queda y el Grimorio muestra la página **«Asuntos pendientes»**
  («Todavía quedan asuntos pendientes antes de continuar esta aventura»).
- Las secundarias viejas siguen disponibles hasta terminarlas y **no** piden a Aegis.
- Al despertar: «CAPÍTULO 3 · AMENAZAS INVISIBLES · EL ÚLTIMO GUARDIÁN».

## 2. Objetivos educativos

- **Nivel 5:** software malicioso y propagación (una carpeta compartida contagia equipos), diagnóstico con indicadores,
  **aislar** el equipo afectado antes de investigar, investigación autorizada (el profesor da permiso).
- **Nivel 6:** contener una amenaza, recuperación de sistemas por etapas (energía → módulos → núcleo), condiciones de
  finalización de un proceso y **control de acceso**.

Todo es simulado: nada se ejecuta de verdad.

## 3. Nivel 5 — Contagio digital (`contagio_digital`)

1. **Un día normal** (`dia_normal`): los amigos en la entrada y la clase en la Sala 3.
2. **Diagnóstico** (`diagnostico`): tres computadoras (equipos 2, 7 y 11) muestran síntomas; la consola pide
   comparar (3 preguntas, con reintentos). Con la Visión, rastros oscuros salen de la carpeta compartida. El profesor
   aísla la carpeta y **autoriza** una investigación controlada.
3. **La conexión del equipo 7** (`investigar_conexion`): con la Visión aparece la conexión; Kai entra con la
   Inmersión, se confía... y **cae** al Bosque de Fibra (única forma de descubrirlo). Fibroluz se ríe;
   «NUEVA REGIÓN: BOSQUE DE FIBRA».
4. **Encontrar otra salida** (`encontrar_salida`): del claro se trepa al puente. Una **señal azul desconocida**
   estabiliza el puente («RUTA ALTERNATIVA DISPONIBLE · RIESGO DE CAÍDA: ELEVADO · POR FAVOR, TEN CUIDADO»).
5. **Contener el contagio** (`contener_contagio`): en el nodo de distribución, cinco válvulas; con la Visión se ven las
   tres dañadas. La señal salva a Kai de otra caída («POR FAVOR, EVITA VOLVER A CAER»).
6. **La Estación Lázaro** (`llegar_estacion`): la compuerta rechaza el acceso; Kai insiste y la señal la abre
   («ACCESO CONCEDIDO · ENERGÍA RESTANTE: CRÍTICA · POR FAVOR... NO TE DETENGAS»). **NIVEL 5 COMPLETADO.**

**Secundaria — «El bosque que dejó de brillar»** (`senal_del_barrio`, fusiona «Sin señal en el barrio»): empieza en
el bosque después de la caída; ayudar a Fibroluz y reconectar el claro devuelve la señal del barrio y la caja de fibra
queda como atajo. Si se hace después de rescatar a Aegis, Aegis comenta (una vez).

## 4. Nivel 6 — La señal perdida (`la_senal_perdida`)

| Paso | Dónde | Qué pasa |
|---|---|---|
| `explorar_estacion` | Vestíbulo | La estación medio apagada. El **registro principal**: UNIDAD: AEGIS · FUNCIÓN: PROTECCIÓN · ESTADO: AISLADA · ÚLTIMA DIRECTIVA: CONTENER AMENAZA · RESULTADO: CONTENCIÓN INCOMPLETA · ORIGEN DEL INCIDENTE: [DATOS NO DISPONIBLES]. Abre la página de Aegis en el Grimorio. |
| `encontrar_aegis` | Núcleo | Aegis, dañado en el piso: era la luz azul («Función principal... proteger» · «Evaluación... correcta»). Empieza **«Eco en la Red»**. |
| `reparar_aegis` | Toda la estación | «Eco en la Red» (abajo). |
| `decision` | Núcleo | «No te pregunté qué te ordenaron. Te pregunté qué querés vos.» · «Es una invitación.» · «En ese caso... acepto.» Aegis pasa a ser compañero (**Aegis Pulse**) y suena la alarma. |
| `escapar` | Salida de emergencia → afueras | Un interruptor fuera del alcance de Kai: Aegis Pulse. Aegis sostiene el puente que se deshace; «¡Aegis, la tuya también importa!»: lo suelta y se salva. En el bosque: los colores y la caída de veintitrés metros. La estación se calma (se puede volver). |
| `volver_colegio` | El claro → cuarto técnico | La troncal del rack de red. |
| `hablar_profesor` | Cuarto técnico | «¿Qué encontraste?» «Un amigo.» El profesor mira un instante donde flota Aegis y aparta la vista. **FIN DEL CAPÍTULO 3.** |

Después, la primera vez que Kai pasa por un pasillo del colegio: Aegis observa a los humanos (los memes, «me muero de
hambre», «parezco loco hablando solo»).

### «Eco en la Red» (`eco_en_la_red`, misión especial)

1. **Energía** (`restablecer_energia`): tablero eléctrico de 5 × 4 en el núcleo (`data/puzzles/lazaro_energia.tres`).
   Se mueve con las teclas de movimiento del Input Map, interactuar gira la ficha, hay botón de reinicio y se puede
   salir sin perder nada. Mínimo 14 giros. Sin energía, las escaleras a los sectores están bloqueadas.
2. **Módulos** (`recuperar_modulos`): tres sectores lejos entre sí, cada uno con un **guardián de conocimiento**
   (proyección holográfica original) y **una** pregunta; si Kai se equivoca, recibe una pista y vuelve a intentar.
   - Sector superior · procesamiento: aislar los equipos afectados.
   - Antena (exterior) · comunicación: la condición de finalización.
   - Mantenimiento (inferior) · protección: control de acceso.
3. **Núcleo** (`estabilizar_nucleo`): instalar los módulos; tres oleadas chicas de **Bitcucarachas** (4, 6, 6) corren
   al núcleo. Si llegan, pierde estabilidad; si se acaba, la oleada se repite (no hay derrota).

## 5. Salas

Distrito `bosque_fibra` (el mapa del Grimorio): `bosque_caida`, `bosque_puente`, `bosque_nodo`, `bosque_estacion` y la
estación `lazaro_vestibulo`, `lazaro_nucleo`, `lazaro_superior`, `lazaro_exterior`, `lazaro_inferior`, `lazaro_escape`
(escenas en `world/zones/lazaro/`, constructor de piezas en `world/lazaro/`). No es una región física nueva: la
estación está dentro del bosque.

## 6. Aegis como compañero

`characters/companions/aegis_companion.gd`: desde la decisión (marca `aegis_companero`), cada sala lo agrega junto a
Kai (`Room.spawn_companion`). Flota cerca del hombro, sigue a Kai con suavidad, no choca ni bloquea, no se controla.
**Aegis Pulse** (tecla «Disparo Aegis»): solo por orden del jugador, al objetivo válido y alcanzable más cercano, con
una espera corta. Se guarda en la partida (`aegis_stage`, la marca).

## 7. Pruebas

`tests/test_continuidad.gd` (requisito y asuntos pendientes), `tests/test_contagio.gd` (Nivel 5 hasta la caída),
`tests/test_senal_protectora.gd` (el bosque hasta la compuerta), `tests/test_mundo.gd` (la secundaria fusionada) y
`tests/test_estacion_lazaro.gd` (todo el Nivel 6, el regreso y el guardado).

## 8. Duración estimada (sin probar con jugadores)

Nivel 5: 35–50 min (más 10–15 de la secundaria). Nivel 6: 40–60 min (tablero 5–8, guardianes 10–15 con el recorrido,
Bitcucarachas 2–4, escape 5). Hay que medirlo con jugadores reales.

## 9. Pendiente

- Arte definitivo (estación, Aegis, guardianes, Bitcucarachas) y sonidos propios.
- La «Pista» de la Biblia («Aegis parece conocer algo de su origen»): no se incluyó (el documento del capítulo pedía no
  revelar el origen de Kai).
- La tienda vende «Aegis: núcleo pulido» desde el Capítulo 3 (Aegis Pulse con menos espera: 0,45 s en vez de 0,7 s).
  Aegis Bridge y Aegis Sync siguen siendo de la historia (capítulos posteriores).
