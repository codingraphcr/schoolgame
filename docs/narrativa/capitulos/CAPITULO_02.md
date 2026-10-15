# Capítulo 2 — Los primeros códigos

**Estado:** **propuesta** del equipo técnico (14 de octubre de 2026) a partir de la Biblia (v1.5, sección XII) y de la
tabla del MEP (`docs/curriculo_mep.md`). El jefe Bucle es oficial (`docs/jefes/BUCLE_INFINITO.md`). Lo demás (el
simulador del colegio, las salas y los acertijos) se puede cambiar sin tocar la Biblia. Implementado y jugable de punta
a punta con arte provisional por código.
**Grado:** Décimo. **Capítulo:** 2. **Niveles:** 3 · *El lenguaje de las máquinas* — 4 · *Código fuera de control*.

---

## 1. Punto de partida

Después de «FIN DEL CAPÍTULO 1» Kai aparece en la entrada del colegio. Tiene Visión Digital, Inmersión Digital,
`Nullblade.exe` con el dash y el Grimorio. Al terminar el capítulo obtiene **Dominio Nulo I**.

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
salida el simulador se derrumba y Kai obtiene **Dominio Nulo I**.

**Pista de la Biblia («Una anomalía reconoce su arquitectura digital»):** al activar el Dominio por primera vez, el
simulador muestra un mensaje que nadie escribió: «ANOMALÍA DETECTADA · ARQUITECTURA DIGITAL: RECONOCIDA». No se explica
quién ni por qué (Biblia XV, regla 11; el antagonista en décimo solo observa y deja señales).

**Cierre:** Kai sale al laboratorio; el profesor nota que el simulador volvió a funcionar. Habla de errores pequeños
repetidos, sin explicar nada más. «FIN DEL CAPÍTULO 2».

## 4. Misiones

| Misión | Pasos (sala) |
|---|---|
| `el_lenguaje_de_las_maquinas` (nivel 3) | `clase_programacion` (Sala 3) → `entrar_simulador` (Laboratorio, conexión con la Visión) → `variables` (sim_variables) → `condiciones` (sim_condiciones) → `ciclos` (sim_ciclos, con el repaso). «NIVEL 3 COMPLETADO» |
| `codigo_fuera_de_control` (nivel 4) | `procesos` (sim_procesos) → `vencer_bucle` (arena_bucle) → `salir_simulador` (arena_bucle) → `hablar_profesor` (Laboratorio). «FIN DEL CAPÍTULO 2» |

El capítulo empieza al terminar «Travesuras en el sistema» (marca `capitulo_2`: se abren las salas del capítulo 2).

## 5. El simulador (zona «Simulador»)

| Sala | Qué se aprende y cómo |
|---|---|
| `sim_entrada` | Llegada (la conexión del laboratorio). Carteles: cómo se cambian los valores (E sobre un nodo de variable) |
| `sim_variables` | Nodos de **variable** (`llave`, `energia`): con E cambia su valor. La puerta muestra su condición (`si llave == verdadero y energia >= 3`) y se abre cuando se cumple |
| `sim_condiciones` | Un nodo `modo` (día / noche). Plataformas **si** `modo == día` y **si no**: hay que cambiar el modo en el camino para cruzar |
| `sim_ciclos` | `repetir n veces: poner bloque`: el puente se arma solo con el *n* exacto (con menos queda corto; con más choca con la pared: error). Al final, el repaso de funciones y objetos |
| `sim_procesos` | Un generador de **procesos repetidos** crea enemigos sin parar (un ciclo sin salida). En la terminal: `cat procesos.log` (la lista); después el desafío de manejo de errores corta la repetición y abre la puerta |
| `arena_bucle` | Bucle, el puzle y el Dominio Nulo I. Sale al laboratorio |

## 6. Piezas técnicas

`SimVariables` (variables de una sala), `VariableNode` (E cambia el valor), `LogicDoor` (puerta con condición),
`LogicPlatform` (plataforma si / si no), `LoopBridge` (puente de *n* bloques), `ProcessSpawner` y `RepeatedProcess`
(enemigo). Ver `docs/arquitectura.md`.
