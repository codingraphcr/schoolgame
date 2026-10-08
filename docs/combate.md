# Diseño del sistema de combate

Referencia acordada con el director del proyecto. Resume el diseño y las decisiones del MVP.

## Regla fundamental

Los **enemigos comunes** se derrotan con combate tradicional. Los **enemigos especiales y jefes**
requieren identificar y resolver un problema de ciberseguridad.

El combate combina **acción** (atacar, saltar, esquivar), **análisis** (Visión Digital)
y **defensa** (herramientas reales de ciberseguridad).

## Decisiones del MVP

| Tema | Decisión |
|---|---|
| Ataque básico (Pulso Digital) | Solo horizontal, en el suelo y en el aire. Ataques hacia arriba/abajo: después del MVP |
| Dash | 1 en el aire por salto, con **invulnerabilidad breve (~0,15 s)** |
| Habilidad especial | Solo **Escudo MFA**: bloquea daño de tipo *credenciales*, cuesta energía, tiene tiempo de reutilización |
| Integridad (vida) | Al llegar a 0: fundido y regreso al último punto de control, sin perder progreso |
| Energía defensiva | Independiente de la integridad. Se gana al acertar ataques, completar acciones defensivas y recoger recursos |
| Enemigos especiales | Fuera del MVP como tipo propio; el jefe enseña la mecánica |
| Jefe El Usurpador | 1 patrón de ataque (llaves en abanico) + 1 embestida, escudo alimentado por 3 terminales-reto |
| Retos educativos | Pausan el juego mientras están abiertos |

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

## Pendiente de definir (antes del Capítulo 2)

- Diferencia entre **Visión Digital** (revela amenazas) y **Filtro Anti-Phishing** (propuesta: desenmascara disfraces).
- Diferencia entre **Parche Rápido** (habilidad) y resolver terminales mediante retos.
- Si la Visión Digital tendrá un límite de uso.

## Plan de implementación del prototipo

| # | Tarea | Estado |
|---|---|---|
| T0 | Reestructuración, controles, capas, pixel art, documentación | ✅ |
| T1 | Sala de pruebas + movimiento + cámara | ⏳ |
| T2 | Dash | ⏳ |
| T3 | Componentes de daño + integridad + invulnerabilidad + reaparición | ⏳ |
| T4 | Pulso Digital + sensación de impacto | ⏳ |
| T5 | Enemigo patrullero | ⏳ |
| T6 | Energía defensiva | ⏳ |
| T7 | Visión Digital | ⏳ |
| T8 | Terminal vulnerable conectada a una barrera | ⏳ |
| T9 | Escudo MFA | ⏳ |
| T10 | Controles táctiles + prueba en Android | ⏳ |
