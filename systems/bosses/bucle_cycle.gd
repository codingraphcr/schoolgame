class_name BucleCycle
extends Resource
## Un ciclo del combate contra Bucle (Capítulo 2): la secuencia de instrucciones que repite y qué tan
## rápido. Siete en data/bosses/bucle.tres (BucleConfig). Ver docs/jefes/BUCLE_INFINITO.md.

## Ataques en orden: &"pulso" (onda por el suelo), &"lluvia" (bloques desde arriba), &"anillo" (anillo
## que se expande con huecos), &"barrido" (línea que cruza la arena a la altura de Kai) y &"rastreo"
## (procesos huérfanos que persiguen a Kai). Con «+» van a la vez: &"pulso+barrido".
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
## Si empieza con un Error de ejecución (una plataforma se apaga unos segundos).
@export var execution_error := false
## Procesos huérfanos en cada Rastreo.
@export var seeker_count := 2
## Si esquiva a Kai (se teletransporta) cuando se le acerca mientras prepara o ataca.
@export var dodge := true
