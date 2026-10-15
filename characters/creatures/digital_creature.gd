class_name DigitalCreature
extends Node2D
## Base de las criaturas digitales (docs/criaturas/BESTIARIO_DIGITAL.md): una máquina de estados chica y
## reutilizable. No todas usan todos los estados:
##   REPOSO        : quieta un rato (se recarga, duerme).
##   PATRULLA      : va y viene por sus puntos (patrol), haciendo su trabajo en el ecosistema.
##   INVESTIGACION : Kai está cerca y quieto: se acerca con curiosidad.
##   HUIDA         : Kai ataca, hace dash o corre hacia ella: se aleja rápido y vuelve después.
##   DEFENSA       : (territoriales y hostiles) se planta frente a Kai. Gancho para las que lo necesiten.
##   INTERACCION   : guía a Kai por guide_points: va al siguiente y espera a que Kai llegue (guide()).
## Disposición: AMISTOSA y NEUTRAL no hacen daño; TERRITORIAL y HOSTIL quedan para criaturas futuras.
## Con la Visión Digital activa, Kai la registra en el bestiario (Bestiary): verla = avistamiento, seguir
## mirándola = observación. Se mueve flotando (sin física): las del MVP no chocan con nada.

signal guide_finished

enum State { REPOSO, PATRULLA, INVESTIGACION, HUIDA, DEFENSA, INTERACCION }
enum Disposition { AMISTOSA, NEUTRAL, TERRITORIAL, HOSTIL }

@export var entry: CreatureEntry
@export var disposition := Disposition.AMISTOSA
## Puntos de patrulla (en coordenadas de la sala). Vacío = se queda donde está.
@export var patrol: Array[Vector2] = []
@export var speed := 60.0
@export var flee_speed := 220.0
## Distancia a la que nota a Kai y a la que lo registra la Visión.
@export var notice_distance := 110.0
@export var sight_distance := 220.0
@export var rest_every := Vector2(5.0, 9.0)

var state := State.PATRULLA
var face := 1.0
var guide_points: Array[Vector2] = []
var guide_index := 0
var _timer := 0.0
var _patrol_index := 0
var _flee_from := Vector2.ZERO
var _observed := 0.0
var _clock := 0.0


func _ready() -> void:
	_timer = randf_range(rest_every.x, rest_every.y)
	state = State.PATRULLA if not patrol.is_empty() else State.REPOSO


## Empieza a guiar a Kai por esos puntos (INTERACCION): va a cada uno y espera a que Kai se acerque.
func guide(points: Array[Vector2]) -> void:
	guide_points = points
	guide_index = 0
	state = State.INTERACCION


func is_guiding() -> bool:
	return state == State.INTERACCION


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_clock += delta
	var player := StoryHelper.room_player(self)
	_watch_vision(player, delta)
	match state:
		State.REPOSO:
			_timer -= delta
			if _timer <= 0.0 and not patrol.is_empty():
				state = State.PATRULLA
				_timer = randf_range(rest_every.x, rest_every.y)
		State.PATRULLA:
			_move_to(patrol[_patrol_index], speed, delta)
			if global_position.distance_to(patrol[_patrol_index]) < 4.0:
				_patrol_index = (_patrol_index + 1) % patrol.size()
			_timer -= delta
			if _timer <= 0.0:
				state = State.REPOSO
				_timer = randf_range(1.5, 3.0)
		State.INVESTIGACION:
			if player == null or global_position.distance_to(player.global_position) > notice_distance * 1.4:
				state = State.PATRULLA if not patrol.is_empty() else State.REPOSO
			else:
				_move_to(player.global_position + Vector2(-face * 34.0, -26.0), speed * 0.5, delta)
		State.HUIDA:
			_move_to(global_position + (global_position - _flee_from).normalized() * 40.0, flee_speed, delta)
			_timer -= delta
			if _timer <= 0.0:
				state = State.PATRULLA if not patrol.is_empty() else State.REPOSO
		State.INTERACCION:
			_guide_step(player, delta)
	if player and state in [State.PATRULLA, State.REPOSO, State.INVESTIGACION]:
		_react_to(player)
	queue_redraw()


func _react_to(player: Player) -> void:
	var distance := global_position.distance_to(player.global_position)
	if distance > notice_distance:
		return
	var startled: bool = player.is_dashing or (player.combat and player.combat.is_attacking()) or absf(player.velocity.x) > 200.0
	if startled and disposition != Disposition.HOSTIL:
		_flee_from = player.global_position
		state = State.HUIDA
		_timer = 1.2
	elif absf(player.velocity.x) < 5.0:
		state = State.INVESTIGACION


func _guide_step(player: Player, delta: float) -> void:
	if guide_index >= guide_points.size():
		return
	var target := guide_points[guide_index]
	if global_position.distance_to(target) > 3.0:
		_move_to(target, speed * 1.6, delta)
		return
	# Llegó: espera a que Kai se acerque para seguir.
	if player and player.global_position.distance_to(global_position) < notice_distance:
		guide_index += 1
		if guide_index >= guide_points.size():
			state = State.REPOSO
			_timer = 9999.0
			guide_finished.emit()


func _move_to(target: Vector2, move_speed: float, delta: float) -> void:
	var step := global_position.move_toward(target, move_speed * delta)
	if absf(step.x - global_position.x) > 0.1:
		face = signf(step.x - global_position.x)
	global_position = step


## Registro en el bestiario: con la Visión activa y a la vista, avistamiento; si sigue mirándola, observación.
func _watch_vision(player: Player, delta: float) -> void:
	if entry == null or player == null:
		return
	var vision := get_node_or_null("/root/DigitalVision")
	if vision == null or not vision.is_active() or global_position.distance_to(player.global_position) > sight_distance:
		return
	var state_node := get_node("/root/GameState")
	if Bestiary.advance(state_node, entry, 1):
		_announce("Bestiario: %s · avistamiento" % entry.display_name)
	_observed += delta
	if _observed >= entry.observe_seconds and Bestiary.advance(state_node, entry, 2):
		_announce("Bestiario: %s · observación" % entry.display_name)


func _announce(text: String) -> void:
	get_tree().call_group(&"toast", &"show_message", text, 2.2)
	Sfx.play(&"mail_ding", 1.2)
