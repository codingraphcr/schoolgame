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
## Repulsión (RepulseBurst): si Kai está a menos de repulse_range px mientras Bucle anuncia o ataca, después
## de repulse_telegraph segundos estalla alrededor (radio repulse_radius). Una cada repulse_cooldown segundos.
@export var repulse_range := 72.0
@export var repulse_radius := 56.0
@export var repulse_telegraph := 0.45
@export var repulse_cooldown := 1.3

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
