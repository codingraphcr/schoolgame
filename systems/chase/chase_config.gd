class_name ChaseConfig
extends Resource
## Valores de una persecución digital (Capítulo 1), para ajustarlos con pruebas sin tocar código ni
## escenas. Uno por persecución en data/chase/. Lo usa DigitalChaseController.

## Tiempo inicial del temporizador (segundos).
@export var start_seconds := 240.0
## Lo que descuenta una respuesta incorrecta en un checkpoint.
@export var wrong_answer_penalty := 15.0
## El tiempo nunca baja de esto por una respuesta incorrecta (para no dejar un tramo imposible).
@export var min_seconds_after_penalty := 20.0
## Tiempo mínimo al reintentar cada tramo (por tiempo agotado, por morir o al cargar la partida):
## [tramo 1, tramo 2, tramo 3]. Se usa el mayor entre esto y lo que quedaba al pasar el checkpoint.
@export var retry_seconds: PackedFloat32Array = [120.0, 100.0, 90.0]

@export_group("Barrera de corrupción")
## Integridad que quita al tocar a Kai (después tiene invulnerabilidad breve).
@export var barrier_damage := 1.0
## Velocidad de la barrera en cada tramo (píxeles por segundo).
@export var barrier_speeds: PackedFloat32Array = [55.0, 65.0, 75.0]
## A cuántos píxeles detrás del inicio del tramo empieza la barrera.
@export var barrier_start_gap := 220.0
## Empujón al tocarla (hacia adelante y arriba).
@export var barrier_knockback := Vector2(260, -160)

@export_group("Caídas")
## Integridad que quita caer al vacío (Kai vuelve a la última plataforma segura).
@export var fall_damage := 1.5
