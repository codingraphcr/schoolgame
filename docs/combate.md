# Diseño del sistema de combate

Referencia acordada con el director del proyecto. Resume el diseño y las decisiones del MVP.

## Regla fundamental

Los **enemigos comunes** se derrotan con combate tradicional. Los **enemigos especiales y jefes**
requieren identificar y resolver un problema de ciberseguridad.

El combate combina **acción** (atacar, saltar, esquivar), **análisis** (Visión Digital)
y **defensa** (herramientas reales de ciberseguridad).

## Capacidades de combate

| Capacidad | Rol | Cuándo se obtiene | Evoluciones |
|---|---|---|---|
| **Nullblade** | Espada digital, cuerpo a cuerpo. Carga energía al golpear | Tutorial | .exe → .zero → .void → .max |
| **Aegis** | Núcleo flotante: disparo teledirigido manual (K), barrera, plataformas | Capítulo 5 (misión "Eco en la Red") | Pulse → Bridge → Sync |
| **Expansión Digital: Dominio Nulo** | Ultimate: enemigos al 80 % de velocidad y bonificación de daño. Barra propia | Capítulo 2 | I (15 s, +10 %, 100) · II (20 s, +15 %, 115) · III (30 s, +30 %, 138) |
| **Dash-parry** | Un dash justo antes de recibir un golpe hace el parry (no hay botón de parry). Reemplaza al Escudo MFA | Con el primer dash | Mejora con los niveles del dash |

Ninguna capacidad ni bonificación puede saltarse un **escudo educativo** (ver `HurtboxComponent.immune`).

## Progresión de la historia

| Momento | Qué pasa | Qué tiene Kai |
|---|---|---|
| **Capítulo 0: Prólogo** | Entrada del colegio → pasillo (el profesor le pide revisar una computadora) → laboratorio: «Por fin alguien está mirando» y la **Visión Digital se activa sola**, como un glitch, sin pulsar nada | Caminar, saltar, interactuar (E) |
| **Primera misión: la contraseña del profesor** | Kai entra a la PC como **alma digital**: nivel de plataformas con estética de escritorio hasta la pestaña "Cambiar contraseña" / MFA. Kai humano: «Profe, ¡aquí está el error!». Con E aparece el enemigo **"Contraseña débil"** y se vence con una **mini espada digital** (sin nombre, solo para aprender a golpear: se desbloquea **J**). Después, **2 elecciones**: la contraseña nueva más segura y un método de MFA, con explicación | + mini espada (solo en este combate) |
| **Recompensa** | El profesor agradece. Desde aquí la **Visión Digital se usa con Q** | + Visión Digital |
| **La habitación vieja** | El profesor lo invita a un cuarto viejo y lleno de polvo del colegio: allí está **Nullblade.exe** | + Nullblade, **dash** (nivel 1) y **doble salto** |
| **Capítulo 1** | Empieza la aventura | Más adelante: salto de pared, Dominio Nulo (cap. 2), Aegis (cap. 5) y mejoras con créditos |

**No existe una sala de pruebas dentro del juego:** cada arma y habilidad se prueba en el mapa a medida que
se desbloquea. La sala gris (`tests/fixtures/`) solo la usan las pruebas automáticas.

## Vida y daño (basado en Hollow Knight)

| Tema | Decisión |
|---|---|
| Vida | **4 máscaras**. Un golpe normal quita 1 (los fuertes, 2). HUD de máscaras arriba a la izquierda |
| Tras un golpe | Congelamiento breve (0,08 s), sacudida de cámara, empuje y **1 s de invulnerabilidad** con parpadeo |
| Peligros (pinchos, vacío) | Quitan 1 máscara y devuelven al **último suelo seguro** (el de ~0,3 s antes del golpe) |
| Curación | Mantener **L** gasta energía y recupera 1 máscara (tarea C5) |
| Muerte | Reaparece en el punto de control con las máscaras llenas y **pierde el 10 % de los créditos** (redondeado hacia abajo) |
| Monedas | **Créditos** del jugador (mejoras: dash, máscaras…) separados del **presupuesto** del colegio (decisiones de seguridad). Cada mejora tiene su propio precio |

## Decisiones de movimiento

| Tema | Decisión |
|---|---|
| Dash | **Por niveles**, se adquiere en la mini aventura y se mejora con créditos: 0 sin dash · 1 Dash (no protege, pero **un dash en el momento justo hace el parry**) · 2 **Dash Fantasma** (atraviesa enemigos y ataques sin daño) · 3 **Esquiva Perfecta** (ventana de parry más amplia y mejor recompensa) |
| Doble salto | Se desbloquea con la historia |
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
| C2 | `GameState`: progreso de combate y créditos (pérdida al morir) | ✅ |
| Z1 | Retirar la sala de desarrollo (la sala gris queda solo para pruebas automáticas) | ✅ |
| Z2 | Arte oficial de Ariel (estilo D) en el proyecto + Kai como personaje | ✅ |
| Z3 | Primera sala real: Pasillo + Laboratorio (Zona 0) | ✅ |
| Z4 | Visión Digital como sistema (transición, red vectorial, puente de datos, evento del laboratorio) | ✅ |
| H1 | Transiciones entre salas + Entrada del colegio (máscaras que se conservan) | ✅ |
| H2 | Interacción y diálogos + el profesor (NPC) | ⏳ |
| H3 | Misiones (objetivo en pantalla) + Visión Digital involuntaria del prólogo | ⏳ |
| H4 | Dentro de la PC: nivel de plataformas, enemigo "Contraseña débil", mini espada (J) y 2 elecciones (contraseña y MFA) → desbloquea Q | ⏳ |
| H5 | Habitación vieja: Nullblade.exe (dash, doble salto, ataque) + cartel "Capítulo 1" | ⏳ |
| C3 | Nullblade.exe (datos de las 4 etapas) + sensación de impacto | ⏳ |
| C4 | `EnemyBase` + `EnemyData` + `CombatClock` + enemigo patrullero | ⏳ |
| C5 | Energía (curación con L) + carga del Dominio | ⏳ |
| C7 | Dash-parry + torreta de llaves | ⏳ |
| C8 | Terminal + escudo educativo | ⏳ |
| C9 | Dominio Nulo I (si hay tiempo) | ⏳ |
| C10 | Aegis Pulse (si hay tiempo) | ⏳ |
| C11 | Evoluciones visuales y ataque cargado de Nullblade (si hay tiempo) | ⏳ |
| C12 | Controles táctiles + prueba en Android | ⏳ |
