# Diseño del sistema de combate

Referencia acordada con el director del proyecto. Resume el diseño y las decisiones del MVP.
La historia, los personajes y sus revelaciones se rigen por la Biblia Narrativa (`narrativa/BIBLIA_NARRATIVA.md`).

## Regla fundamental

Los **enemigos comunes** se derrotan con combate tradicional. Los **enemigos especiales y jefes**
requieren identificar y resolver un problema de ciberseguridad.

El combate combina **acción** (atacar, saltar, esquivar), **análisis** (Visión Digital)
y **defensa** (herramientas reales de ciberseguridad).

## Capacidades de combate

| Capacidad | Rol | Cuándo se obtiene | Evoluciones |
|---|---|---|---|
| **Nullblade** | Espada digital, cuerpo a cuerpo. Carga energía al golpear | Tutorial | .exe → .zero → .void → .max |
| **Aegis** | Núcleo flotante: disparo teledirigido manual (I), barrera, plataformas | Capítulo 3, misión especial «Eco en la Red»: Kai lo rescata y lo repara con comandos | Pulse → Bridge → Sync |
| **Expansión Digital: Dominio Nulo** | Ultimate: enemigos al 80 % de velocidad y bonificación de daño. Barra propia | Por definir (ya no con Bucle, cap. 2) | I (15 s, +10 %, 100) · II (20 s, +15 %, 115) · III (30 s, +30 %, 138) |
| **Dash-parry** | Un dash justo antes de recibir un golpe hace el parry (no hay botón de parry). Reemplaza al Escudo MFA | Con el primer dash | Mejora con los niveles del dash |

Ninguna capacidad ni bonificación puede saltarse un **escudo educativo** (ver `HurtboxComponent.immune`).

## Progresión de la historia

| Momento | Qué pasa | Qué tiene Kai |
|---|---|---|
| **Capítulo 0: Prólogo** | Entrada del colegio → pasillo (el profesor le pide revisar una computadora) → laboratorio: «Por fin alguien está mirando» y la **Visión Digital se activa sola**, como un glitch, sin pulsar nada | Caminar, saltar, interactuar (E) |
| **Primera misión: la contraseña del profesor** | Kai entra a la PC como **alma digital**: nivel de plataformas con estética de escritorio hasta la pestaña "Cambiar contraseña" / MFA. Kai humano: «Profe, ¡aquí está el error!». En la **terminal** de la PC encuentra la configuración de la cuenta (`ls`, `cd`, `cat`: contraseña 123456, sin verificación en dos pasos). En la pestaña, con E aparece el enemigo **"Contraseña débil"** y se vence con una **mini espada digital** (sin nombre, solo para aprender a golpear: se desbloquea **J**). Después, **2 elecciones**: la contraseña nueva más segura y un método de MFA, con explicación | + mini espada (solo en este combate) |
| **Combate (jefe)** | La «Contraseña débil» es el **jefe del prólogo**: de una ventanita "123456" salen decenas de ventanas de error que forman su cuerpo; camina para presionar, embiste y lanza contraseñas comunes; tras embestir queda agachado y se le puede hacer **pogo**. Dos fases (la 2, desde la mitad de la vida: ventanas inestables, más rápido, combina ataques). La **Nullblade aparece como un destello** (animación de Ariel). Al vencerlo sus ventanas muestran «ACCESO DENEGADO» y explotan; **la Nullblade se deshace en la mano de Kai** («¿Eh...? ¿A dónde se fue?») y no logra invocarla otra vez. Deja el **primer fragmento de vida** (4 forman una vida nueva) | Nullblade (solo en la pelea) + 1 fragmento de vida |
| **Recompensa** | El jugador **crea su propia contraseña** para el profesor (con un medidor que explica cada regla; se guarda solo su huella y tendrá que recordarla en el capítulo 4 y en misiones extra) y elige el segundo paso (aplicación de autenticación), con explicación de cada opción. El profesor agradece, la **Visión Digital se usa con Q** desde aquí y Kai vuelve al laboratorio. En la PC los Ecos solo los da el villano | + Visión Digital |
| **La habitación vieja** | El profesor lo invita a visitar unas instalaciones: un pasillo donde está el cuarto viejo. Para entrar hay un desafío de **Visión Digital + terminal** (con Q se ven pistas ocultas; con ellas se resuelve el acceso en una terminal; tema del MEP: control de acceso). Adentro está la **Nullblade oficial**: con ella llega el **dash** (el doble salto, más adelante en la historia), la tarjeta «NUEVO EQUIPAMIENTO» y el título **«EL DESPERTAR»** | + Nullblade (para siempre) y **dash** (nivel 1) |
| **Capítulo 1** | Empieza la aventura | Más adelante: salto de pared, Dominio Nulo (dónde, por definir), **Aegis (cap. 3, «Eco en la Red»)** y mejoras con Ecos |

**No existe una sala de pruebas dentro del juego:** cada arma y habilidad se prueba en el mapa a medida que
se desbloquea. La sala gris (`tests/fixtures/`) solo la usan las pruebas automáticas.

## Vida y daño (basado en Hollow Knight)

| Tema | Decisión |
|---|---|
| Vida | **4 máscaras**. Un golpe normal quita 1 (los fuertes, 2). HUD de máscaras arriba a la izquierda |
| Tras un golpe | Congelamiento breve (0,08 s), sacudida de cámara, empuje y **1 s de invulnerabilidad** con parpadeo |
| Peligros (pinchos, vacío) | Quitan 1 máscara y devuelven al **último suelo seguro** (el de ~0,3 s antes del golpe) |
| Curación | Mantener **L** gasta energía y recupera 1 máscara (tarea C5) |
| Muerte | Reaparece en el punto de control con las máscaras llenas y **pierde el 10 % de sus Ecos** (hacia abajo, **máximo 100**; **nada durante el tutorial**). Nunca pierde habilidades, evoluciones, comandos, páginas ni progreso |
| Monedas | **ECOS** (moneda oficial, solo se obtienen jugando) para mejoras y tiendas, separados del **presupuesto** del colegio (decisiones de seguridad). Cada artículo tiene su propio precio. **La bolsa llega como máximo a 999 Ecos** (lo que sobra se pierde); las recompensas se bajaron para ese tope (común 1–3, especial 4–8, jefe 60–90, terminal 10–20, desafío 8–15, misión 30–50, depósito 10–25; `data/economy/economia.tres`). La tienda oficial es la de la soda del colegio (`docs/mundo/COLEGIO.md`) |

## Decisiones de movimiento

| Tema | Decisión |
|---|---|
| Dash | **Por niveles**, se adquiere en la mini aventura y se mejora con Ecos (el nivel 2 se vende en la tienda de la soda; el 3 cuando exista el parry): 0 sin dash · 1 Dash (no protege, pero **un dash en el momento justo hace el parry**) · 2 **Dash Fantasma** (atraviesa enemigos y ataques sin daño) · 3 **Esquiva Perfecta** (ventana de parry más amplia y mejor recompensa) |
| Doble salto | Se **compra** en la tienda de la soda (800 Ecos, desde el Capítulo 2; decisión del equipo, Biblia v1.9) |
| Pared | Deslizar + salto de pared, se desbloquea con la historia. Al agarrarse se recuperan el doble salto y el dash aéreo |
| Caída | Más rápida y firme (gravedad ×2 al caer); la cámara se adelanta hacia abajo en caídas rápidas |

## Arquitectura de combate

- **Un solo canal de daño:** `HitData` viaja de `HitboxComponent` a `HurtboxComponent`. El multiplicador final
  (evolución del arma × Dominio Nulo) se calculará en un único lugar, una vez por impacto.
- **Reloj de combate local** (`CombatClock`, C4): enemigos y proyectiles escalan su tiempo; el Dominio Nulo
  no usa `Engine.time_scale` (que solo se usa unos milisegundos para el congelamiento por impacto).
- **Progreso en `GameState`** (C2): etapas de Nullblade/Aegis/Dominio, nivel del dash y habilidades.
- **Evoluciones como datos** (`.tres`): un solo sistema que cambia de datos, no un script por etapa.

## Tipos de amenaza

Cada fuente de daño lleva un **tipo de amenaza**. Cada defensa contrarresta tipos concretos.
Es el vínculo entre el combate y el contenido educativo.

| Tipo | Ejemplo de enemigo | Defensa que lo contrarresta |
|---|---|---|
| credenciales | El Usurpador | Escudo MFA |
| phishing | El Imitador | Filtro Anti-Phishing |
| malware | El Parásito | Pulso Antivirus |
| ransomware | El Carcelero | Sistema de Respaldos |
| disponibilidad | El Enjambre | Firewall |
| vulnerabilidad | El Corruptor | Parche Rápido |
| ingenieria_social | El Suplantador | Verificador de Identidad |

## Pendiente de definir

- Dash-parry (C7): qué se puede parrear (proyectiles, ataques cuerpo a cuerpo) y la recompensa exacta (energía, carga del Dominio, devolver proyectiles).

## Plan de implementación

| # | Tarea | Estado |
|---|---|---|
| T0 | Reestructuración, controles, capas, pixel art, documentación | ✅ |
| T1 | Sala de pruebas + movimiento + cámara | ✅ |
| T2 | Movimiento avanzado: dash + doble salto + deslizar/salto de pared | ✅ |
| C1 | Daño compartido, 4 máscaras, invulnerabilidad, peligros, muerte, dash por niveles, HUD | ✅ |
| C2 | `GameState`: progreso de combate y moneda (pérdida al morir) | ✅ |
| E1 | **ECOS**: autoload `Economy`, BITS → Ecos, penalización (10 %, máx. 100, nada en el tutorial) | ✅ |
| E2 | `EconomyConfig` (valores configurables) y recompensas únicas que no se cobran dos veces; enemigos por rango | ✅ |
| E4 | Guardado de la partida (`SaveManager`), computadoras seguras y CONTINUAR | ✅ |
| E3 | Ecos cristalinos (1 azul, 5 violeta, 25 blanco violáceo), partículas y sonido; combate más largo y difícil en una arena con obstáculos | ✅ |
| Z1 | Retirar la sala de desarrollo (la sala gris queda solo para pruebas automáticas) | ✅ |
| Z2 | Arte oficial de Ariel (estilo D) en el proyecto + Kai como personaje | ✅ |
| Z3 | Primera sala real: Pasillo + Laboratorio (Zona 0) | ✅ |
| Z4 | Visión Digital como sistema (transición, red vectorial, puente de datos, evento del laboratorio) | ✅ |
| H1 | Transiciones entre salas + Entrada del colegio (máscaras que se conservan) | ✅ |
| H2 | Interacción y diálogos + el profesor (NPC) | ✅ |
| H3 | Misiones (objetivo en pantalla) + Visión Digital involuntaria del prólogo | ✅ |
| H4a | Entrar a la PC: succión por la pantalla, pantalla de carga, materialización como alma digital y escritorio provisional | ✅ |
| H4b | Nivel de SPAM dentro de la PC (pop-ups, anuncios trampa, correos que caen) hasta la cuenta del profesor | ✅ |
| T1 | Terminal simulada (pwd, ls, cd, cat…) + primera terminal en la PC del profesor | ✅ |
| H4c | Combate contra la "Contraseña débil" con la mini espada (J): `PlayerCombat`, `WeaponData`, `EnemyBase`, `ArenaBarrier` | ✅ |
| H4d | 2 elecciones (contraseña y MFA) → desbloquea Q y sale de la PC: `ChoiceChallenge`, `ChoiceWindow`, `AccountSecurity` | ✅ |
| H5 | Invitación del profesor → pasillo de las instalaciones → desafío Visión Digital + terminal → cuarto viejo: Nullblade oficial, dash y «EL DESPERTAR» | ⏳ |
| C3 | Nullblade.exe (datos de las 4 etapas) + sensación de impacto | ⏳ |
| C4 | `EnemyBase` + `EnemyData` + `CombatClock` + enemigo patrullero | 🟡 `CombatClock` hecho (`systems/combat/combat_clock.gd`: lo leen `EnemyBase` y los proyectiles compatibles) |
| C5 | Energía (curación con L) + carga del Dominio | ✅ La carga del Dominio sube 10 por golpe de la Nullblade a un enemigo |
| C7 | Dash-parry + torreta de llaves | ⏳ |
| C8 | Terminal + escudo educativo | ⏳ |
| C9 | Dominio Nulo I | ✅ `PlayerDomain` (R): 15 s, +10 %, 100 de carga, amenazas al 80 %; dónde se obtiene: por definir (ya no después de Bucle) |
| C10 | Aegis Pulse (si hay tiempo) | ⏳ |
| C11 | Evoluciones visuales y ataque cargado de Nullblade (si hay tiempo) | ⏳ |
| C12 | Controles táctiles + prueba en Android | ⏳ |
