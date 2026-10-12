# Narrativa del videojuego

**[`BIBLIA_NARRATIVA.md`](BIBLIA_NARRATIVA.md) es la fuente principal de referencia** para desarrollar la historia, las
misiones, los diálogos, los personajes y el mundo del juego (versión 1.0, incorporada el 12 de octubre de 2026).

Contiene la premisa, los acontecimientos anteriores al juego, el protagonista, el profesor, Aegis, el antagonista, la
Visión Digital, Nullblade, el Grimorio, los Ecos, los personajes secundarios, la cronología de los tres años y de los
24 niveles, el final, las reglas de coherencia y las decisiones pendientes.

## Cómo se usa

1. **Antes de diseñar** una misión, un personaje, una escena, un diálogo o un acontecimiento importante, se consulta la
   Biblia.
2. Todo contenido nuevo respeta su **cronología**, sus **revelaciones** y sus **reglas de coherencia** (sección XV).
3. Si una propuesta **contradice** la Biblia, se avisa al equipo **antes** de implementarla.
4. Si el equipo aprueba un cambio importante en el lore, se **actualiza la Biblia** (o el documento que corresponda) y se
   explica qué cambió en el commit. Ninguna decisión anterior se cambia en silencio.
5. Los **nombres provisionales** (por ejemplo AXIOM) y los **misterios pendientes** (sección XVI) **no se tratan como
   hechos oficiales** hasta que el equipo los apruebe.
6. La historia se integra poco a poco con los aprendizajes del MEP, pero los contenidos narrativos **no se presentan como
   oficiales del MEP** mientras no se validen contra los programas completos (ver `../curriculo_mep.md`).

La Biblia no reemplaza la documentación técnica (`../arquitectura.md`, `../estructura_del_proyecto.md`) ni el plan del
MVP (`../plan_mvp.md`).

## Diferencias con lo que ya está en el juego (pendientes de decisión)

Lo implementado antes de la Biblia usa algunos nombres y decisiones que la Biblia marca como **pendientes** o resuelve de
otra forma. **No se cambió nada del juego**: quedan anotadas para que el equipo decida.

| Tema | En el juego y la documentación actual | En la Biblia v1.0 |
|---|---|---|
| Nombre del juego | «Nullveil: Beyond the Firewall» (menú, proyecto) | Pendiente; nombre provisional del proyecto de origen: «Proyecto Génesis» |
| Protagonista | «Kai» (arte, diálogos, Grimorio) | Nombre pendiente |
| Profesor | «Prof. Alvarado» (diálogos, retratos, terminal `alvarado@…`, reglas de contraseña) | Nombre y personalidad concreta pendientes |
| Cuándo se obtiene Aegis | Capítulo 2, nivel 3, reparado con comandos (`../curriculo_mep.md`, `../plan_mvp.md`) | Capítulo 3, misión especial «Eco en la Red» (rescate y reparación con comandos); Aegis Bridge en el capítulo 4 |
| Temas de los niveles | Distribución según la tabla del MEP (`../curriculo_mep.md`): redes en décimo (cap. 4) | Distribución narrativa propia, provisional: contraseñas en el nivel 7 («Identidad robada»), redes en undécimo (cap. 6 y 7) |
| La entidad «???» | `../plan_mvp.md` la anota como primera manifestación de «El Núcleo» | Relación entre «El Núcleo» y el «Proyecto Génesis», y el nombre del antagonista (AXIOM es propuesta), pendientes |
| Origen de Nullblade | En el plan, la Nullblade oficial se encuentra en el cuarto viejo al que invita el profesor (H5) | Origen pendiente: no asumir que la creó el profesor ni que su nombre la vincula al antagonista |
| Detonante de la Visión Digital | Implementado: el mensaje de la computadora la activa sola, como un glitch | Detonante preciso pendiente |

**Coinciden** con la Biblia: el prólogo (computadora, «Por fin alguien está mirando», «Tú no deberías poder vernos»,
Nullblade.exe y «EL DESPERTAR»), las 4 etapas de Nullblade, las 3 evoluciones de Aegis más el Salto de Nexo al final
de décimo, el Grimorio, los **Ecos** (nunca «Bits») con su penalización, y la estructura de 3 grados, 12 capítulos y
24 niveles. La contraseña que crea el jugador y que reutiliza en el capítulo 4 encaja con el nivel 7 («Identidad
robada: autenticación, contraseñas, acceso»).
