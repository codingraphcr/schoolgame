class_name BucleCycle
extends Resource
## Un ciclo del combate contra Bucle (Capítulo 2): la secuencia de instrucciones que repite y qué tan
## rápido. Siete en data/bosses/bucle.tres (BucleConfig). Ver docs/jefes/BUCLE_INFINITO.md.

## Ataques en orden: &"pulso" (onda por el suelo), &"lluvia" (bloques desde arriba), &"anillo" (anillo que
## se expande con huecos) e &"iteracion" (rayos que barren la arena con un hueco). Dos a la vez se escriben
## con «+» (&"pulso+anillo").
@export var attacks: Array[StringName] = []
## Multiplica la velocidad de los ataques (1 = base).
@export var speed := 1.0
## Segundos que queda cansado al terminar la secuencia (la ventana clara para golpearlo).
@export var fatigue_time := 2.5
## Segundos de aviso antes de cada ataque (nunca menos que BucleConfig.min_telegraph).
@export var telegraph := 0.7
## Pausa entre un ataque y el siguiente.
@export var gap := 0.5
## Ondas seguidas en cada Pulso repetitivo.
@export var pulse_count := 1
## Bloques en cada Lluvia de instrucciones (siempre quedan carriles libres).
@export var rain_blocks := 3
## Huecos del anillo (en grados, dos huecos opuestos) y cuánto giran por segundo.
@export var ring_gap := 80.0
@export var ring_spin := 30.0
## Si empieza con un Error de ejecución (se apagan plataformas unos segundos) y cuántas apaga a la vez
## (siempre queda una ruta: BucleArenaController).
@export var execution_error := false
@export_range(1, 2) var error_platforms := 1

@export_group("Variantes")
## Iteración: rayos seguidos en cada barrido y si el hueco cambia de altura a mitad de camino.
@export var iteration_beams := 1
@export var iteration_split := false
## Desbordamiento: los bloques de la Lluvia se quedan apilados en el suelo un rato (dañan al tocarlos):
## sube el suelo y obliga a usar las plataformas.
@export var overflow := false
## Recursión: el anillo, al llegar lejos, se divide en anillos chicos que vuelven hacia Bucle.
@export var ring_split := false
## Copias del proceso: dos clones que también atacan (solo el verdadero recibe golpes).
@export var copies := false
## Romper la condición: «tareas pendientes» que aparecen en las plataformas. Rotas todas, se cansa antes y
## por más tiempo; si no, el descanso es muy corto. 0 = sin tareas (descanso normal).
@export var condition_nodes := 0
## Sin descanso: al terminar la secuencia empieza otra (solo se le gana con golpes arriesgados).
@export var no_fatigue := false
## Se cansa en distintos lugares (puntos del puente o una plataforma de los costados).
@export var roam_fatigue := false
