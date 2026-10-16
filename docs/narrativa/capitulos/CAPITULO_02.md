# Capítulo 2 — Los primeros códigos

**Estado:** **propuesta** del equipo técnico (14 de octubre de 2026) a partir de la Biblia (v1.5, sección XII) y de la
tabla del MEP (`docs/curriculo_mep.md`). El jefe Bucle es oficial (`docs/jefes/BUCLE_INFINITO.md`). Lo demás (el
simulador del colegio, las salas y los acertijos) se puede cambiar sin tocar la Biblia. Implementado y jugable de punta
a punta con arte provisional por código.
**Grado:** Décimo. **Capítulo:** 2. **Niveles:** 3 · *El lenguaje de las máquinas* — 4 · *Código fuera de control*.

---

## 1. Punto de partida

Después de «FIN DEL CAPÍTULO 1» Kai vuelve a casa (misión «Camino a casa», `docs/escenarios/HOGAR_DE_KAI.md`). El
capítulo empieza **a la mañana siguiente**, en su cuarto («CAPÍTULO 2 · LOS PRIMEROS CÓDIGOS» al despertar): Kai
desayuna con su familia y va caminando al colegio. Tiene Visión Digital, Inmersión Digital, `Nullblade.exe` con el
dash y el Grimorio. (El **Dominio Nulo I** no se obtiene en este capítulo: provisionalmente, en el Capítulo 4; Biblia v1.8.)

## 2. Objetivos educativos (décimo, a validar con el programa completo del MEP)

- **Nivel 3:** variables, condicionales (si / si no), ciclos (repetir *n* veces) y una primera idea de funciones y de
  objetos (repaso al final del nivel).
- **Nivel 4:** control de flujo, estructuras de datos (una lista de procesos en un registro), errores y excepciones
  (manejar un error en lugar de repetir para siempre), condiciones de salida y desarrollo seguro.

Todo ocurre en una **simulación**: nunca se ejecuta código real del jugador.

## 3. Historia (propuesta)

**Nivel 3 — El lenguaje de las máquinas.** En la Sala 3 el Prof. Alvarado empieza la unidad de programación con el
**simulador de prácticas** del colegio: un entorno donde los programas de los estudiantes mueven plataformas, puertas y
robots de práctica. Hoy anda lento: los ejercicios se traban. Kai, con la Visión, ve en la pantalla procesos que se
repiten solos. En el laboratorio entra al simulador con la Inmersión Digital. Los ejercicios trabados son las puertas
del simulador: para avanzar resuelve **variables** (cambiar valores hasta que la condición de una puerta se cumpla),
**condiciones** (plataformas que existen *si* algo es verdadero y otras *si no*) y **ciclos** (un puente que se arma
repitiendo un bloque *n* veces: ni uno más, ni uno menos). Al final, un repaso de funciones y objetos.

**Nivel 4 — Código fuera de control.** Más adentro, un proceso automático repite su tarea sin parar: el simulador se
llena de **procesos repetidos** (enemigos que no dejan de aparecer). Kai lee el registro (una lista de procesos), elige
cómo manejar el error y corta la repetición. En el núcleo está **Bucle** (jefe). Después del puzle de la condición de
salida aparece la pista de la anomalía y se abre la salida al laboratorio.

**Pista de la Biblia («Una anomalía reconoce su arquitectura digital»):** después del puzle de la condición de salida, el
simulador muestra un mensaje que nadie escribió: «ANOMALÍA DETECTADA · ARQUITECTURA DIGITAL: RECONOCIDA». No se explica
quién ni por qué (Biblia XV, regla 11; el antagonista en décimo solo observa y deja señales).

**Cierre:** Kai sale al laboratorio; el profesor nota que el simulador volvió a funcionar. Habla de errores pequeños
repetidos, sin explicar nada más. «FIN DEL CAPÍTULO 2».

## 4. Misiones

| Misión | Pasos (sala) |
|---|---|
| `el_lenguaje_de_las_maquinas` (nivel 3) | `clase_programacion` (Sala 3) → `taller_robotica` (taller: las tres estaciones) → `investigar_anomalias` (taller, con la Visión) → `entrar_simulador` (Laboratorio, conexión con la Visión) → `variables` (sim_variables) → `condiciones` (sim_condiciones) → `ciclos` (sim_ciclos, con el repaso). «NIVEL 3 COMPLETADO» |
| `codigo_fuera_de_control` (nivel 4) | `procesos` (sim_procesos) → `vencer_bucle` (arena_bucle) → `hablar_profesor` (Laboratorio). «FIN DEL CAPÍTULO 2» |

El capítulo empieza al terminar «Travesuras en el sistema» (marca `capitulo_2`: se abren las salas del capítulo 2).

## 4b. Expansión (Biblia v1.9): el taller de robótica y las anomalías

Entre la clase y el simulador, sin tocar el simulador ni a Bucle:

- **La clase** termina con el simulador lento: el profesor lo va a revisar y manda a décimo a la **actividad de
  robótica** del taller (el anexo del laboratorio, detrás de la puerta de vidrio).
- **Tres estaciones con la misma ventana** (`RoboticsWindow`): el jugador arma un programa corto eligiendo opciones,
  lo ejecuta y mira la simulación; si falla, la explicación dice por qué y se corrige.
  - **Condicionales · robot clasificador:** «si el objeto es [metal] → [Ruta A]; si no → [Ruta B]».
  - **Ciclos · cinta automática:** «repetir [para siempre / 3 / 8 veces]» + «detener cuando [nunca / no queden
    cajas / se movieron 3]». Empieza sin condición de salida: la cinta gira vacía y la simulación la corta por
    seguridad (anticipa a Bucle, que no sabe detenerse).
  - **Funciones · asistente modular:** `preparar_mesa()` con tres instrucciones en orden y cuántas veces llamarla
    (tres mesas: tres llamadas en vez de nueve instrucciones).
- **Anomalías progresivas** (de a una): el robot de prueba mueve una caja de ida y vuelta, un brazo repite el mismo
  gesto, la pantalla repite «TAREA 7: REPETIR» y la puerta de la bodega abre y cierra. Los compañeros creen que son
  errores normales; con la Visión, Kai ve un ↻ de datos sobre cada una y un hilo hacia el simulador. Con las cuatro,
  Kai entiende que todo viene del simulador: «Adentro hay algo que no sabe detenerse». **No se revela a Bucle.**
- **Continuidad:** el Compañero recuerda lo que se habló en «Un recreo diferente» si Kai cambió de tema a la robótica.
- **El Dominio Nulo sigue bloqueado** (provisionalmente, Capítulo 4).
- **Alineación curricular (provisional):** condicionales, ciclos y funciones están en la tabla de décimo de
  `docs/curriculo_mep.md` (Programación); también se practica la identificación y corrección de errores. No se
  afirma una alineación oficial con el MEP hasta validarla con los programas completos.

## 5. El simulador (zona «Simulador»)

| Sala | Qué se aprende y cómo |
|---|---|
| `sim_entrada` | Llegada (la conexión del laboratorio). Carteles: cómo se cambian los valores (E sobre un nodo de variable) |
| `sim_variables` | Nodos de **variable** (`llave`, `energia`): con E cambia su valor. La puerta muestra su condición (`si llave == verdadero y energia >= 3`) y se abre cuando se cumple |
| `sim_condiciones` | Un nodo `modo` (día / noche). Plataformas **si** `modo == día` y **si no**: hay que cambiar el modo en el camino para cruzar |
| `sim_ciclos` | `repetir n veces: poner bloque`: el puente se arma solo con el *n* exacto (con menos queda corto; con más choca con la pared: error). Al final, el repaso de funciones y objetos |
| `sim_procesos` | Un generador de **procesos repetidos** crea enemigos sin parar (un ciclo sin salida). En la terminal: `cat procesos.log` (la lista); después el desafío de manejo de errores corta la repetición y abre la puerta |
| `arena_bucle` | Bucle, el puzle y la pista. Sale al laboratorio |

## 6. Piezas técnicas

`SimVariables` (variables de una sala), `VariableNode` (E cambia el valor), `LogicDoor` (puerta con condición),
`LogicPlatform` (plataforma si / si no), `LoopBridge` (puente de *n* bloques), `ProcessSpawner` y `RepeatedProcess`
(enemigo). Ver `docs/arquitectura.md`.
