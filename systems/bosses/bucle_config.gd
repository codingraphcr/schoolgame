class_name BucleConfig
extends Resource
## Valores del jefe Bucle Infinito (Capítulo 2, nivel 4), para equilibrar el combate sin tocar código.
## Uno en data/bosses/bucle.tres. Tiempos en segundos de juego (con la física).

## Los siete ciclos, en orden (el ciclo actual es impactos + 1).
@export var cycles: Array[BucleCycle] = []
## Impactos clave para terminar el combate (uno por ciclo).
@export var key_hits := 7
## Aviso mínimo de cualquier ataque (nunca se vuelve imposible de leer).
@export var min_telegraph := 0.4
## Segundos que anuncia una secuencia nueva (PREPARE_PATTERN).
@export var prepare_time := 0.9
## Reacción al recibir un impacto clave y transformación (invulnerable en los dos).
@export var reaction_time := 0.8
@export var transformation_time := 1.4
## Daño de sus ataques a Kai (en cristales). No sube con los ciclos.
@export var attack_damage := 1.0

@export_group("Ataques")
## Velocidad base de la onda del Pulso (px/s) y de la caída de los bloques.
@export var pulse_speed := 210.0
@export var rain_fall_speed := 300.0
## Carriles de la Lluvia a lo ancho de la arena (siempre quedan por lo menos min_free_lanes libres).
@export var rain_lanes := 8
@export var min_free_lanes := 2
## Velocidad base del Anillo (px/s) y su grosor.
@export var ring_speed := 150.0
@export var ring_width := 10.0
## Segundos que una plataforma queda apagada por un Error de ejecución.
@export var error_time := 4.0
## Segundos que daña el Barrido después de su aviso.
@export var sweep_live := 0.35
## Velocidad (px/s), giro (rad/s) y vida (s) de los procesos huérfanos del Rastreo.
@export var seeker_speed := 115.0
@export var seeker_turn := 2.2
@export var seeker_life := 2.8

@export_group("Movimiento")
## Lugares desde donde ataca (por toda la arena, también arriba, donde Kai no llega).
@export var attack_spots: Array[Vector2] = [Vector2(100, 296), Vector2(320, 296), Vector2(540, 296), Vector2(120, 200),
	Vector2(520, 200), Vector2(200, 92), Vector2(440, 92), Vector2(320, 70), Vector2(80, 124), Vector2(560, 124)]
## Lugares donde descansa (FATIGUE): siempre alcanzables (en el piso o encima de una plataforma).
@export var rest_spots: Array[Vector2] = [Vector2(110, 296), Vector2(320, 296), Vector2(530, 296), Vector2(120, 222),
	Vector2(520, 222), Vector2(320, 162)]
## Distancia a Kai de los lugares de descanso que elige (ni pegado ni imposible de alcanzar a tiempo).
@export var rest_min_distance := 110.0
@export var rest_max_distance := 290.0
## Esquiva: si Kai se acerca a menos de dodge_distance, se teletransporta (con esta recarga).
@export var dodge_distance := 64.0
@export var dodge_cooldown := 0.9
## Segundos del teletransporte (parpadeo; en ese momento no se le puede golpear).
@export var blink_time := 0.22

@export_group("Recompensas")
## Energía que recibe Kai por un golpe arriesgado (mientras Bucle ataca): media barrita = una curación.
@export var risky_energy := 0.5

@export_group("Frases")
## Lo que dice Bucle al recibir cada impacto clave (en globos: no quitan el control).
@export var hit_lines: PackedStringArray = [
	"No pasa nada. Puedo repetirlo.",
	"Otra vez. Esta vez funcionará.",
	"¿Por qué sigue fallando?",
	"Tengo que terminar...",
	"¡NO PUEDO DETENERME!",
	"Una vez más... solamente una vez más...",
	"¿Ya... puedo descansar?",
]


## El ciclo n (1 a 7); si faltan datos, el último.
func cycle(number: int) -> BucleCycle:
	if cycles.is_empty():
		return BucleCycle.new()
	return cycles[clampi(number - 1, 0, cycles.size() - 1)]
