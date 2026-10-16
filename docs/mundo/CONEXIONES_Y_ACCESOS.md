# Conexiones y accesos entre mundos

> Datos: `data/world/links/*.tres` (`RegionLink`, con su `WorldRequirement`). Todas son de ida y vuelta salvo que
> digan lo contrario. Estados: ver `MAPA_MAESTRO.md`.

## 1. Tipos de conexión

| Tipo | Qué es | En el mapa |
|---|---|---|
| Camino | Se va caminando, en tren o en bus | Línea |
| Inmersión Digital | Desde un dispositivo concreto (nunca un portal sin explicación) | Línea punteada cian |
| Atajo | Aparece al restaurar un sistema | Línea fina |
| Pasaje oculto | No se dibuja hasta que se puede usar | — |
| Vertical | Sube o baja (raíces, ascensores, la puerta del Velo) | Línea con flecha |

Las conexiones que todavía no se pueden usar se dibujan con candado y dicen por qué (`locked_text`).

## 2. Regla de los accesos de Inmersión (CONFIRMADO)

Cada acceso responde: **1)** ¿qué sistema conecta?, **2)** ¿por qué existe?, **3)** ¿qué región digital representa?,
**4)** ¿qué aprendizaje o acontecimiento permite usarlo?, **5)** ¿qué consecuencias tiene desbloquearlo? Se abren
por progresión narrativa, habilidades, problemas resueltos, conexiones reparadas, autorización legítima dentro de la
ficción o misiones secundarias. **No todas las puertas son cuestionarios.**

| Acceso | 1. Sistema | 2. Por qué existe | 3. Región | 4. Qué lo permite | 5. Consecuencia | Estado |
|---|---|---|---|---|---|---|
| Computadoras del colegio (Sala 3, cuarto técnico, laboratorio) | Equipos de práctica y servidores | Clases y entrenamiento | Sistemas del colegio | Inmersión Digital (Cap. 1) | Persecución, combates y simulador | IMPLEMENTADO |
| **Caja de fibra óptica del barrio** | Distribución de fibra de la cuadra | Lleva internet a las casas | Bosque de Fibra | Atajo: se abre al terminar «El bosque que dejó de brillar» (el bosque se descubre cayendo, Capítulo 3) | La cuadra recupera la señal | IMPLEMENTADO |
| **Rack de red del cuarto técnico** | Troncal de fibra del colegio | Une la red del colegio con el exterior | Bosque de Fibra (el claro) | Restaurar la señal del barrio (misión terminada) | Segunda entrada al bosque desde el colegio | IMPLEMENTADO (MVP) |
| Computadoras públicas de la biblioteca | Red de la biblioteca | Servicio público | Distrito Caché | Capítulo 4 (acceso limitado en décimo) | Primeras visitas a la ciudad digital | FUTURO |
| Planta de energía del puerto | Sistemas industriales | Energía del puerto | Núcleo Térmico | Undécimo (Cap. 6) | Ruta al Núcleo sin pasar por el Caché | FUTURO |
| Estación antigua de los Altos | Comunicaciones viejas | Abandonada hace años | Archivo Criogénico | Capítulo 8 | Registros antiguos | FUTURO |
| Servidores de los Conductos | Sistemas que nadie apagó | Parte de la instalación secreta | Santuario Raíz | Duodécimo | Historia de Aegis y Axiom | FUTURO |
| Núcleo del Laboratorio Génesis | El sistema central del laboratorio | Los experimentos | El Velo Nulo | Capítulo 12 | Conflicto final | FUTURO |

## 3. Todas las conexiones

| Id | Regiones | Tipo | Dónde | Requisito (texto del candado) | Estado |
|---|---|---|---|---|---|
| `barrio_central` | Barrio ↔ Distrito Central | Camino | La calle hasta el portón del colegio | Capítulo 1 terminado («Todavía no terminan las clases») | IMPLEMENTADO |
| `central_sistemas` | Distrito Central ↔ Sistemas del colegio | Inmersión | Computadoras del colegio | Inmersión Digital | IMPLEMENTADO |
| `barrio_bosque` | Barrio ↔ Bosque de Fibra | Inmersión | Caja de fibra del poste | «El bosque que dejó de brillar» terminada (atajo) | IMPLEMENTADO |
| `central_bosque` | Distrito Central ↔ Bosque de Fibra | Inmersión | Rack de red del cuarto técnico | Entrar desde el colegio: «El bosque que dejó de brillar» terminada. Salir del bosque al colegio (troncal del claro): desde el escape de la Estación Lázaro (Nivel 6) | IMPLEMENTADO |
| `bosque_cache` | Bosque de Fibra ↔ Distrito Caché | Camino | La troncal de fibra | Capítulo 4 («La troncal... no tiene enlace») | Bloqueada a la vista (IMPLEMENTADO); el Caché, FUTURO |
| `central_cartago` | Distrito Central ↔ Altos de Cartago | Camino | Estación del tren | Capítulo 5 | FUTURO |
| `central_costa` | Distrito Central ↔ Costa del Pacífico | Camino | Terminal de buses | Capítulo 6 | FUTURO |
| `central_cache` | Distrito Central ↔ Distrito Caché | Inmersión | Computadoras de la biblioteca | Capítulo 4 | FUTURO |
| `bosque_nucleo` | Bosque de Fibra ↔ Núcleo Térmico | Vertical | Raíces calientes | Capítulo 5 y Aegis Bridge | FUTURO |
| `costa_nucleo` | Costa ↔ Núcleo Térmico | Inmersión | Planta del puerto | Capítulo 6 | FUTURO |
| `nucleo_canales` | Núcleo ↔ Canales Corruptos | Camino | Desagües térmicos | Capítulo 6 | FUTURO |
| `cache_archivo` | Distrito Caché ↔ Archivo | Camino | Puerta de permisos | Capítulo 9 | FUTURO |
| `canales_archivo` | Canales ↔ Archivo | Atajo | Corriente restaurada | Capítulo 7 y sector restaurado | FUTURO |
| `cartago_archivo` | Altos de Cartago ↔ Archivo | Inmersión | Estación antigua | Capítulo 8 | FUTURO |
| `central_conductos` | Distrito Central ↔ Conductos | Oculto | Puerta sellada del pasillo viejo | Capítulo 8 y puerta abierta | FUTURO |
| `cartago_conductos` | Altos de Cartago ↔ Conductos | Oculto | Túneles derrumbados | Capítulo 9 | FUTURO |
| `conductos_laboratorio` | Conductos ↔ Laboratorio Génesis | Vertical | Ascensor de carga | Capítulo 9, energía restaurada y Aegis Bridge | FUTURO |
| `conductos_santuario` | Conductos ↔ Santuario Raíz | Inmersión | Servidores antiguos | Capítulo 9 | FUTURO |
| `archivo_santuario` | Archivo ↔ Santuario Raíz | Camino | Registros antiguos | Capítulo 10 | FUTURO |
| `canales_santuario` | Canales ↔ Santuario Raíz | Oculto | Grieta | Capítulo 10 y Dominio Nulo | FUTURO |
| `santuario_velo` | Santuario ↔ El Velo Nulo | Vertical | La puerta del Velo | Capítulo 12 | FUTURO |
| `laboratorio_velo` | Laboratorio ↔ El Velo Nulo | Inmersión | Núcleo del laboratorio | Capítulo 12 | FUTURO |

Los capítulos de los requisitos FUTUROS son **PROPUESTOS** (se ajustan al diseñar cada capítulo). Las habilidades
pedidas nunca cambian el momento en que se consiguen (Biblia, sección XV).

## 4. Implementación (IMPLEMENTADO)

- **Dentro de una región** se usa lo de siempre: `RoomExit` (bordes de sala, con `requires_quest`), `Stairway`, y
  el mapa de salas (`DistrictLayout`).
- **Entre regiones** se usa `RoomExit` con `door_id` vacío (el destino va en la salida) o `ImmersionPortal` (con
  `requires_quest` / `requires_step`). El `RegionLink` describe la conexión para el mapa y los documentos.
- **Conexión bloqueada a la vista:** una `RoomExit` sin destino con su aviso (`closed_message`), y en el mapa del
  Grimorio la conexión con candado.
