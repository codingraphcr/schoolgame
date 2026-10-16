class_name AegisCompanion
extends Node2D
## Aegis como compañero de Kai (desde el final del Capítulo 3): flota cerca de su hombro, lo sigue con suavidad entre
## salas (Room lo agrega si la partida tiene FLAG), no choca con nada ni bloquea el movimiento. No es controlable.
## Aegis Pulse (aegis_stage ≥ 1, tecla aegis_fire): dispara solo por orden del jugador, con fijación automática al
## objetivo válido y alcanzable más cercano (enemigos o blancos del grupo «aegis_target»), con una espera corta entre
## disparos. Puede comentar (comment) con un globito.

const FLAG := &"aegis_companero"
const RANGE := 240.0
const COOLDOWN := 0.7
## Con la mejora de la tienda («Aegis: núcleo pulido», marca aegis_mejora_1), dispara más seguido.
const POLISHED_COOLDOWN := 0.45
const SHOT := preload("res://characters/companions/aegis_shot.gd")

var body: AegisBody
var player: Player
var cooldown := 0.0
var _offset := Vector2(-22, -48)


func _ready() -> void:
	z_index = 5
	body = AegisBody.new()
	body.mood = AegisBody.Mood.FLOTANDO
	add_child(body)
	if player:
		global_position = player.global_position + _offset


static func is_active(state: Node) -> bool:
	return state.has_flag(FLAG)


func _physics_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	cooldown = maxf(cooldown - delta, 0.0)
	var facing := float(player.facing) if "facing" in player else 1.0
	var target := player.global_position + Vector2(_offset.x * facing, _offset.y)
	global_position = global_position.lerp(target, clampf(delta * 6.0, 0.0, 1.0))
	body.look_dir = Vector2(facing, 0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"aegis_fire") and player and not player.controls_locked:
		pulse()


## Aegis Pulse: dispara al objetivo válido más cercano. Devuelve el objetivo (o null si no había ninguno).
func pulse() -> Node2D:
	var state := get_node("/root/GameState")
	if state.aegis_stage < 1 or cooldown > 0.0:
		return null
	var target := find_target()
	if target == null:
		SpeechBark.say(self, "Sin objetivos válidos.", Vector2(0, -20), 1.2)
		return null
	cooldown = POLISHED_COOLDOWN if state.has_flag(&"aegis_mejora_1") else COOLDOWN
	body.blink()
	var shot := Area2D.new()
	shot.set_script(SHOT)
	shot.target = target
	get_parent().add_child(shot)
	shot.global_position = global_position
	Sfx.play(&"slash")
	return target


## El objetivo más cercano dentro del alcance y sin paredes en el medio.
func find_target() -> Node2D:
	var best: Node2D = null
	var best_distance := RANGE
	var candidates := get_tree().get_nodes_in_group(&"enemy") + get_tree().get_nodes_in_group(&"aegis_target")
	var space := get_world_2d().direct_space_state
	for node in candidates:
		var candidate := node as Node2D
		if candidate == null or not candidate.is_inside_tree() or ("is_dead" in candidate and candidate.is_dead):
			continue
		var aim := candidate.global_position + Vector2(0, -8)
		var distance := global_position.distance_to(aim)
		if distance >= best_distance:
			continue
		var query := PhysicsRayQueryParameters2D.create(global_position, aim, 1)
		if not space.intersect_ray(query).is_empty():
			continue
		best = candidate
		best_distance = distance
	return best


## Un comentario corto en un globito (Aegis no habla con la cara: es su forma de intervenir).
func comment(text: String, seconds := 2.4) -> void:
	SpeechBark.say(self, text, Vector2(0, -22), seconds)
