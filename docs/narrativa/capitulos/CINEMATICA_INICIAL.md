# Cinemática inicial — «Otro día normal»

**Estado:** implementada a partir del documento del equipo «Implementación de la cinemática inicial del videojuego»
(16 de octubre de 2026). Arte provisional por código (los decorados son los del cuarto, la casa y la calle de Kai);
música y efectos provisionales generados por código.
**Cuándo:** al empezar una **partida nueva**, antes del prólogo. No se repite al cargar una partida.
**Duración:** unos 2–3 minutos leyendo los diálogos a ritmo normal (sin medir con jugadores).

---

## 1. Qué cuenta

Kai, un estudiante costarricense aparentemente normal: se despierta tarde, se prepara contra reloj, desayuna con sus
papás, cruza el Barrio de los Almendros y llega al colegio técnico. Humor juvenil costarricense, sin poderes
digitales, sin Aegis, Axiom, Chip, Glitch, la Nullblade ni el Grimorio, y sin explicar nada del origen de Kai.

| Escena | Dónde | Qué pasa |
|---|---|---|
| 1. El despertar | Cuarto de Kai | Negro, pájaros y un carro lejos; «Casa de Kai · 6:00 a. m.». El despertador escandaloso (primer plano), la cámara va a la cama: «Cinco minutitos más...». Corte: 6:35. «¡KAIIII!». Kai salta de la cama, sale corriendo y tropieza con la mochila («...Estoy bien»). |
| 2. Contra reloj | Cuarto de Kai | Montaje con cortes: el espejo y el mechón que se vuelve a levantar dos veces («Bueno, ganaste»), los cuadernos que se caen uno tras otro, la mochila, las medias diferentes (primer plano: «...Nadie se va a dar cuenta»). |
| 3. Desayuno | Cocina y comedor | Mamá cocina, papá con su café. El desayuno a toda prisa, las medias («Es moda»), las risas, el consejo del papá, la lonchera olvidada, «¡Los quiero!». La puerta se cierra y los papás **se miran un momento en silencio** (pista sutil: no se explica nada). |
| 4. El barrio | Barrio de los Almendros | La cámara sigue a Kai de lado: montañas, casas, la vecina barriendo, el gato en el muro, el bus, estudiantes. Don Carlos en la pulpería («¡Es tradición!»). El perrito detrás de la verja («...O no»). «¡Uy, no!»: a correr. |
| 5. El colegio | Portón del colegio técnico | Kai llega sin aliento; el amigo: «Mae, venís todo despeinado»; el mechón (primer plano); «Bueno... otro día normal». La cámara se eleva, baja la música, fundido a negro y el **título del juego** (el nombre configurado en el proyecto). |

Después: la Entrada del colegio, con Kai en su lugar, la cámara de siempre, el control y el objetivo
**«Habla con el profesor Alvarado»**. El prólogo sigue igual que antes.

## 2. Controles

- Durante la cinemática Kai no se mueve, no ataca ni usa habilidades; no hay HUD de juego.
- Los diálogos avanzan como siempre (E, Espacio o Aceptar).
- **Omitir:** Esc (aparece «Esc otra vez: omitir la cinemática») y Esc otra vez. Corta todo, deja la cinemática
  como vista y lleva a la Entrada con el control y el objetivo, sin duplicar nada.
- **Volver a verla:** menú de pruebas (F9, solo en el editor) → «Ver la cinemática inicial» (no guarda nada).

## 3. Guardado

La cinemática no es una sala: no se guarda durante ella. Al terminar (o al omitirla) queda la marca
`cinematica_inicial_vista` y la partida sigue en la Entrada, donde se guarda como siempre. «Continuar» y «Cargar
partida» van al punto de guardado: no la repiten. Las tres ranuras no cambian.

## 4. Cómo está hecha

- `world/cinematics/intro/intro.tscn` (armada por un constructor a partir de las escenas del barrio) e
  `intro_cinematic.gd` (la secuencia: cámara, cortes, diálogos, música, omitir).
- Decorados: los scripts de arte del cuarto (`bedroom_props.gd`, la cama con Kai dormido, el escritorio, las
  estanterías; **sin** el soporte de la Nullblade), la casa (`house_props.gd`, los papás de `casa.tscn`) y la calle
  (`street_props.gd`, que termina en el portón del colegio).
- Piezas nuevas (`intro_prop.gd`): despertador, mochila, espejo, cuadernos, desayuno, lonchera, verja con el perro,
  muro con el gato y el bus. Primeros planos como viñetas (`intro_closeup.gd`): el despertador, el espejo con el
  mechón (sobre el retrato de Kai de los diálogos) y las medias.
- Kai es el jugador de verdad: camina y corre con sus animaciones (`Player.scripted_axis`), salta de la cama; el
  tropiezo es un giro del dibujo. Los gestos (risas, «¡PUM!», «*ñam*», los ladridos) son globitos (`SpeechBark`).
- Diálogos: `data/dialogues/intro/`. Personaje nuevo: **don Carlos**, el pulpero (`data/characters/don_carlos.tres`;
  usa un NPC de fondo). El amigo es el Compañero (sin nombre).
- Música provisional generada por código: `intro_manana` (la mañana y el desayuno) e `intro_prisa` (prepararse y
  correr); se reemplazan dejando `assets/audio/music/intro_manana.ogg` / `intro_prisa.ogg`. Efectos provisionales en
  `systems/audio/sfx.gd` (despertador, pájaros, carro lejos, «boing», cremallera, plato, «ñam», risas, puerta, bus,
  ladrido, golpe); cada uno se reemplaza con un archivo del mismo nombre en `assets/audio/sfx/`.
- Prueba: `tests/test_cinematica_inicial.gd`.

## 5. Pendiente (arte y sonido)

- Arte definitivo de Ariel para las piezas y los primeros planos; un sprite de don Carlos (hoy, el NPC adulto de
  fondo, el mismo del papá, con otra ropa).
- Animaciones que el juego todavía no tiene: Kai acostado/levantándose, peinándose, comiendo, mirando el reloj; los
  papás sentados o señalando. Hoy se resuelven con cortes, primeros planos, globitos y movimientos de cámara.
- Música y efectos definitivos (con licencia propia).
